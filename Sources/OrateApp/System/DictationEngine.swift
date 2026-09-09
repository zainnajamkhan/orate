//
//  DictationEngine.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AVFoundation
import Foundation
import SwiftUI

/// The loop: hold, talk, let go, the words appear.
///
/// This is the whole product, and it is deliberately small. Capture hands buffers to the
/// transcriber, the transcriber hands text back, and on release the finished text is typed
/// into whatever the user was already in. Everything hard is in the two objects underneath
/// and in the operating system.
///
/// There is exactly one of these in the running app, shared by the shortcut and by the
/// onboarding's try step. Two of them was a real bug: a single keypress opened the
/// microphone twice, and the second engine tried to type its result into the window that
/// was explaining the shortcut. One engine also means the screen that convinces someone to
/// buy the app is running the same code the app runs.
@MainActor
public final class DictationEngine: ObservableObject {

    @Published public private(set) var isRecording = false
    @Published public private(set) var text = ""
    @Published public private(set) var failure: String?

    /// Newest last. A fixed width so the waveform does not reflow as it fills.
    @Published public private(set) var levels: [Float] = Array(repeating: 0, count: 42)

    /// Bumped every time a dictation starts, whatever started it.
    ///
    /// The shortcut step watches this to prove the key actually reached Orate. Nothing else
    /// can prove it: another app can swallow a shortcut before Orate sees it, and the
    /// registration still succeeds, so the only honest test is whether a press arrives.
    @Published public private(set) var startCount = 0

    /// Where the finished text went. `nil` until a dictation completes.
    @Published public private(set) var lastOutcome: Outcome?

    public enum Outcome: Equatable {
        case typed(String)
        case copied(String)
        case cancelled
        case heardNothing
    }

    /// Whether to put the finished text into the frontmost app.
    ///
    /// Turned off while the onboarding is open, where the point is to watch the words
    /// arrive in the window rather than to have them typed into it.
    public var insertsIntoFrontmostApp: Bool
    private let locale: Locale

    /// Types a fixed sentence instead of listening.
    ///
    /// Only for the preview harness, which has to render the flow on a machine with no
    /// microphone permission. Never true in the shipping app.
    private let isPreview: Bool
    private var previewTimer: Timer?

    private let capture = AudioCapture()
    private var session: SpeechTranscription?
    private var startup: Task<Void, Never>?

    public init(
        locale: Locale = .current,
        insertsIntoFrontmostApp: Bool = true,
        isPreview: Bool = false
    ) {
        self.locale = locale
        self.insertsIntoFrontmostApp = insertsIntoFrontmostApp
        self.isPreview = isPreview
    }

    // MARK: - The loop

    public func begin() {
        guard !isRecording, startup == nil else { return }

        text = ""
        failure = nil
        lastOutcome = nil
        isRecording = true
        startCount += 1
        Diagnostics.log("dictation started")

        guard !isPreview else {
            beginPreview()
            return
        }

        // Building the session touches the asset inventory and can suspend, so the recorder
        // is started inside a task. The interface is already showing "listening" by then,
        // which is honest: the microphone opens a few milliseconds later and the user has
        // barely begun the first word.
        startup = Task { [weak self] in
            guard let self else { return }
            do {
                let session = try await SpeechTranscription(locale: locale) { [weak self] running in
                    guard let self, isRecording else { return }
                    text = running
                }
                // Released the key while the session was still being built.
                guard isRecording else {
                    await session.cancel()
                    startup = nil
                    return
                }

                let format = session.audioFormat

                // The buffer closure holds the session directly rather than reading
                // `self.session`. Two bugs otherwise, and both eat words. Reading the
                // property drops every buffer that arrives before the assignment below,
                // which is the first tenth of a second and therefore the first word. And on
                // release, `end` clears the property before the buffers already in flight
                // reach the main actor, which loses the last word. Appending to a finished
                // session is harmless, so holding it is simply correct.
                self.session = session
                try capture.start(
                    analyzerFormat: format,
                    level: { [weak self] value in self?.push(value) },
                    buffer: { buffer in
                        Task { await session.append(buffer) }
                    }
                )
            } catch {
                fail(with: error)
            }
            startup = nil
        }
    }

    public func end() {
        guard isRecording else { return }
        isRecording = false
        capture.stop()
        levels = Array(repeating: 0, count: levels.count)

        guard !isPreview else {
            previewTimer?.invalidate()
            previewTimer = nil
            deliver(text)
            return
        }

        guard let session else {
            // Let go before the microphone was even open.
            lastOutcome = .heardNothing
            return
        }
        self.session = nil

        Task { [weak self] in
            let final = await session.finish()
            guard let self else { return }
            text = final
            deliver(final)
        }
    }

    /// Escape. Throw the whole thing away and type nothing.
    public func cancel() {
        guard isRecording || session != nil else { return }
        Diagnostics.log("dictation cancelled")
        isRecording = false
        capture.stop()
        previewTimer?.invalidate()
        previewTimer = nil
        levels = Array(repeating: 0, count: levels.count)
        startup?.cancel()
        startup = nil

        let session = self.session
        self.session = nil
        text = ""
        lastOutcome = .cancelled

        Task { await session?.cancel() }
    }

    // MARK: - Delivery

    private func deliver(_ final: String) {
        let trimmed = final.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            lastOutcome = .heardNothing
            return
        }
        guard insertsIntoFrontmostApp else {
            lastOutcome = .typed(trimmed)
            return
        }
        switch TextInsertion.insert(trimmed) {
        case .typed: lastOutcome = .typed(trimmed)
        case .copied: lastOutcome = .copied(trimmed)
        }
    }

    private func fail(with error: Error) {
        isRecording = false
        capture.stop()
        session = nil
        failure = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
        Diagnostics.log("dictation failed: \(failure ?? "unknown")")
    }

    private func push(_ level: Float) {
        levels.removeFirst()
        levels.append(min(max(level, 0), 1))
    }

    // MARK: - Preview

    private static let previewWords = [
        "This", "is", "your", "voice,", "turned", "into", "text,",
        "with", "nothing", "to", "download", "and", "nothing", "to", "configure.",
    ]

    private func beginPreview() {
        var tick = 0
        var spoken = 0
        previewTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                tick += 1
                // Speech is bursty rather than steady, so the level wanders instead of
                // pulsing evenly. An evenly pulsing meter reads as a progress spinner.
                let envelope = 0.45 + 0.4 * sin(Double(tick) / 3.1) * sin(Double(tick) / 7.7)
                self.push(Float(max(0.06, envelope + Double.random(in: -0.12...0.12))))

                if tick % 5 == 0, spoken < Self.previewWords.count {
                    spoken += 1
                    self.text = Self.previewWords.prefix(spoken).joined(separator: " ")
                }
            }
        }
    }
}
