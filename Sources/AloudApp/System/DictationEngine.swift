//
//  DictationEngine.swift
//  Aloud
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
/// It conforms to `DictationTrialSource` so the onboarding's try step drives exactly the
/// same code the shortcut does. The alternative, a demo path beside a real path, means the
/// screen that convinces someone to buy the app is the one screen never exercised.
@MainActor
public final class DictationEngine: ObservableObject, DictationTrialSource {

    @Published public private(set) var isRecording = false
    @Published public private(set) var text = ""
    @Published public private(set) var failure: String?

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
    /// Off inside the onboarding, where the point is to watch the words arrive in the
    /// window rather than to have them typed into it.
    private let insertsIntoFrontmostApp: Bool
    private let locale: Locale

    private let capture = AudioCapture()
    private var session: SpeechTranscription?
    private var startup: Task<Void, Never>?

    /// Set by the onboarding, which wants the running text but not the insertion.
    private var textHandler: (@MainActor (String) -> Void)?
    private var levelHandler: (@MainActor (Float) -> Void)?

    public init(locale: Locale = .current, insertsIntoFrontmostApp: Bool = true) {
        self.locale = locale
        self.insertsIntoFrontmostApp = insertsIntoFrontmostApp
    }

    // MARK: - The loop

    public func begin() {
        guard !isRecording, startup == nil else { return }

        text = ""
        failure = nil
        lastOutcome = nil
        isRecording = true

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
                    textHandler?(running)
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
                    level: { [weak self] value in self?.levelHandler?(value) },
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
            textHandler?(final)
            deliver(final)
        }
    }

    /// Escape. Throw the whole thing away and type nothing.
    public func cancel() {
        guard isRecording || session != nil else { return }
        isRecording = false
        capture.stop()
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
    }

    // MARK: - DictationTrialSource

    /// The onboarding's entry point. Same engine, same code path, no insertion.
    public func start(
        level: @escaping (Float) -> Void,
        text: @escaping (String) -> Void
    ) {
        levelHandler = { value in level(value) }
        textHandler = { running in text(running) }
        begin()
    }

    public func stop() {
        end()
    }
}
