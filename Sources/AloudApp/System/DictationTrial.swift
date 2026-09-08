//
//  DictationTrial.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import Foundation
import SwiftUI

/// What the try step needs from whatever is doing the listening.
///
/// The seam exists so the onboarding can be designed, built and looked at before
/// SpeechAnalyzer is wired up in S0. When the real engine lands it conforms to this and
/// nothing in the view changes.
@MainActor
public protocol DictationTrialSource: AnyObject {
    /// Begin. `level` arrives many times a second between 0 and 1, `text` arrives whenever
    /// the running transcript grows.
    func start(level: @escaping (Float) -> Void, text: @escaping (String) -> Void)
    func stop()
}

/// The state behind the try step.
@MainActor
public final class DictationTrial: ObservableObject {

    /// Newest last. Held to a fixed width so the meter does not reflow as it fills.
    @Published public private(set) var levels: [Float] = Array(repeating: 0, count: 42)
    @Published public private(set) var isRecording = false
    @Published public private(set) var transcript = ""

    private let source: DictationTrialSource

    public init(source: DictationTrialSource) {
        self.source = source
    }

    public var hasText: Bool { !transcript.isEmpty }

    public func begin() {
        guard !isRecording else { return }
        transcript = ""
        isRecording = true
        source.start(
            level: { [weak self] value in
                guard let self else { return }
                levels.removeFirst()
                levels.append(min(max(value, 0), 1))
            },
            text: { [weak self] value in
                self?.transcript = value
            }
        )
    }

    public func end() {
        guard isRecording else { return }
        isRecording = false
        source.stop()
        levels = Array(repeating: 0, count: levels.count)
    }

    public func reset() {
        end()
        transcript = ""
    }
}

/// A stand in that types a fixed sentence.
///
/// This is not transcription and it is not pretending to be: it exists only so the try step
/// can be laid out, animated and judged before S0 proves the real latency number. It is the
/// first thing deleted once `SpeechTranscriber` is in, and it is named so that nobody
/// mistakes a demo for a working engine.
@MainActor
public final class PreviewDictationSource: DictationTrialSource {

    private var timer: Timer?
    private var wordIndex = 0

    private let words = [
        "This", "is", "your", "voice,", "turned", "into", "text,",
        "with", "nothing", "to", "download", "and", "nothing", "to", "configure.",
    ]

    public init() {}

    public func start(level: @escaping (Float) -> Void, text: @escaping (String) -> Void) {
        wordIndex = 0
        var tick = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self else { return }
                tick += 1
                // Speech is bursty rather than steady, so the level wanders instead of
                // pulsing evenly. An evenly pulsing meter reads as a progress spinner.
                let envelope = 0.45 + 0.4 * sin(Double(tick) / 3.1) * sin(Double(tick) / 7.7)
                level(Float(max(0.06, envelope + Double.random(in: -0.12...0.12))))

                // Roughly three words a second, which is unhurried speech.
                if tick % 5 == 0, self.wordIndex < self.words.count {
                    self.wordIndex += 1
                    text(self.words.prefix(self.wordIndex).joined(separator: " "))
                }
            }
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
    }
}
