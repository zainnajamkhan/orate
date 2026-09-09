//
//  SpeechTranscription.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AVFoundation
import OrateCore
import CoreMedia
import Foundation
import Speech

/// One dictation, from the analyzer's point of view.
///
/// A session is built and thrown away for each thing the user says. `SpeechTranscriber`
/// hands out its results as a sequence that can only be read once, so a transcriber cannot
/// outlive the dictation it was made for; a shared one crashes with "attempt to await
/// next() on more than one task" the second time it is used. Building a new one also stops
/// one dictation warming the model for the next and quietly changing the timings.
actor SpeechTranscription {

    /// The format the analyzer wants audio in. Fixed for the life of the session.
    let audioFormat: AVAudioFormat

    private let transcriber: SpeechTranscriber
    private let analyzer: SpeechAnalyzer
    private let continuation: AsyncStream<AnalyzerInput>.Continuation

    /// Segments, keyed by where in the audio they start.
    ///
    /// Progressive results supersede each other: a later result can revise the same stretch
    /// of audio an earlier one covered. Overwriting one string keeps only the last sentence
    /// and appending everything repeats every revision, so segments are replaced by
    /// position instead. This cost an hour during S0 and is the only correct way to read
    /// this API.
    private var segments: [(start: CMTime, text: String)] = []
    private var collector: Task<Void, Never>?

    /// Called on the main actor every time the running text changes.
    private let onText: @MainActor (String) -> Void

    init(locale requested: Locale, onText: @escaping @MainActor (String) -> Void) async throws {
        // An unsupported *region* is not a failure. A Mac set to English (Pakistan) gets
        // English (India), which is a far better acoustic match than refusing outright.
        // Only an unsupported language is a real dead end.
        let supported = await SpeechTranscriber.supportedLocales
        guard let locale = SpeechLanguage.best(for: requested, from: supported) else {
            throw DictationError.languageUnavailable(
                Locale.current.localizedString(forIdentifier: requested.identifier)
                    ?? requested.identifier
            )
        }
        if locale.identifier(.bcp47) != requested.identifier(.bcp47) {
            Diagnostics.log(
                "\(requested.identifier(.bcp47)) is not supported, using \(locale.identifier(.bcp47))"
            )
        }

        let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)

        // The whole product claim is that the operating system owns the model. This asks
        // macOS for it; on a machine that already has it, it does nothing at all.
        switch await AssetInventory.status(forModules: [transcriber]) {
        case .installed:
            break
        case .unsupported:
            throw DictationError.modelUnavailable
        default:
            guard let request = try await AssetInventory.assetInstallationRequest(
                supporting: [transcriber]
            ) else {
                throw DictationError.modelUnavailable
            }
            try await request.downloadAndInstall()
        }

        guard let format = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber]
        ) else {
            throw DictationError.unsupportedAudioFormat
        }

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()

        self.transcriber = transcriber
        self.audioFormat = format
        self.continuation = continuation
        self.analyzer = SpeechAnalyzer(modules: [transcriber])
        self.onText = onText

        try await analyzer.start(inputSequence: stream)
        startCollecting()
    }

    private func startCollecting() {
        collector = Task { [transcriber] in
            do {
                for try await result in transcriber.results {
                    self.absorb(result)
                }
            } catch {
                // A failed stream leaves whatever was already transcribed intact, which is
                // better for the user than discarding a sentence they have already said.
            }
        }
    }

    private func absorb(_ result: SpeechTranscriber.Result) {
        let start = result.range.start
        segments.removeAll { $0.start >= start }
        segments.append((start, String(result.text.characters)))

        let joined = text
        Task { @MainActor [onText] in onText(joined) }
    }

    /// Everything said so far, assembled.
    var text: String {
        segments
            .map { $0.text.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    func append(_ buffer: AVAudioPCMBuffer) {
        continuation.yield(AnalyzerInput(buffer: buffer))
    }

    /// Close the input and wait for the last words.
    ///
    /// S0 measured this at 0.09s to 0.16s, which is why the user can let go of the key and
    /// have the text land more or less at once.
    func finish() async -> String {
        continuation.finish()
        try? await analyzer.finalizeAndFinishThroughEndOfInput()
        await collector?.value
        return text
    }

    /// Throw the session away without waiting, for when the user hits Escape.
    func cancel() async {
        continuation.finish()
        collector?.cancel()
        await analyzer.cancelAndFinishNow()
        segments.removeAll()
    }
}
