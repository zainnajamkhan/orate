//
//  AudioCapture.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AVFoundation
import Foundation

/// The microphone, open only while a key is held.
///
/// Orate does not sit and listen, and this is where that promise is either kept or broken.
/// The engine is built and torn down around each dictation rather than left running with a
/// gate on it, so the orange recording dot in the menu bar is on exactly when Orate is
/// listening and off the rest of the time. A gated always on engine would be marginally
/// faster to start and would make the app's central claim untrue.
final class AudioCapture {

    /// Buffers already converted into whatever format the analyzer asked for.
    private(set) var format: AVAudioFormat?

    private let engine = AVAudioEngine()
    private var converter: AVAudioConverter?
    private var isRunning = false

    /// Start feeding audio.
    ///
    /// `level` is a rough loudness between 0 and 1 for the waveform, and `buffer` is what
    /// the analyzer consumes. Both are delivered on the main actor, because both end up
    /// driving the interface and hopping once here is cheaper than hopping at every call
    /// site.
    func start(
        analyzerFormat: AVAudioFormat,
        level: @escaping @MainActor (Float) -> Void,
        buffer: @escaping @MainActor (AVAudioPCMBuffer) -> Void
    ) throws {
        guard !isRunning else { return }

        let input = engine.inputNode
        let inputFormat = input.outputFormat(forBus: 0)

        guard inputFormat.sampleRate > 0 else {
            throw DictationError.noInputDevice
        }
        guard let converter = AVAudioConverter(from: inputFormat, to: analyzerFormat) else {
            throw DictationError.unsupportedAudioFormat
        }
        self.converter = converter
        self.format = analyzerFormat

        // 0.1s of audio per callback. Small enough that the level meter looks continuous,
        // large enough that the analyzer is not woken forty times a second.
        let frames = AVAudioFrameCount(inputFormat.sampleRate * 0.1)

        input.installTap(onBus: 0, bufferSize: frames, format: inputFormat) { chunk, _ in
            // This runs on a real time audio thread. Nothing here may allocate much, block,
            // or touch the interface, so the only work done is the arithmetic for the level
            // and the format conversion, and both results are handed straight to the main
            // actor.
            let loudness = Self.level(of: chunk)
            let converted = Self.convert(chunk, using: converter, to: analyzerFormat)

            Task { @MainActor in
                level(loudness)
                if let converted { buffer(converted) }
            }
        }

        engine.prepare()
        try engine.start()
        isRunning = true
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        converter = nil
        isRunning = false
    }

    // MARK: - Arithmetic

    /// Loudness, as something a bar chart can use.
    ///
    /// Root mean square rather than peak, because peak jumps on every consonant and makes
    /// the meter twitch. The result is put on a decibel scale and squashed into 0 to 1,
    /// since raw amplitude spends almost all of its time near zero and would draw a flat
    /// line through normal speech.
    private static func level(of buffer: AVAudioPCMBuffer) -> Float {
        guard let channel = buffer.floatChannelData?[0], buffer.frameLength > 0 else { return 0 }

        var sum: Float = 0
        for frame in 0..<Int(buffer.frameLength) {
            let sample = channel[frame]
            sum += sample * sample
        }
        let rms = sqrt(sum / Float(buffer.frameLength))

        // Quiet speech sits around -50dB and a raised voice around -10dB, so that is the
        // range the meter is scaled across.
        let decibels = 20 * log10(max(rms, 1e-7))
        return min(1, max(0, (decibels + 50) / 40))
    }

    private static func convert(
        _ buffer: AVAudioPCMBuffer,
        using converter: AVAudioConverter,
        to format: AVAudioFormat
    ) -> AVAudioPCMBuffer? {
        let ratio = format.sampleRate / buffer.format.sampleRate
        let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64
        guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
            return nil
        }

        var supplied = false
        var error: NSError?
        converter.convert(to: output, error: &error) { _, status in
            if supplied {
                status.pointee = .noDataNow
                return nil
            }
            supplied = true
            status.pointee = .haveData
            return buffer
        }
        return error == nil ? output : nil
    }
}

/// What can go wrong, in words a person could be shown.
enum DictationError: LocalizedError {
    case noInputDevice
    case unsupportedAudioFormat
    case languageUnavailable(String)
    case modelUnavailable

    var errorDescription: String? {
        switch self {
        case .noInputDevice:
            "No microphone is available. Check that one is connected and selected in Sound settings."
        case .unsupportedAudioFormat:
            "This microphone produces audio Orate cannot read."
        case .languageUnavailable(let language):
            "macOS cannot transcribe \(language) on this Mac."
        case .modelUnavailable:
            "macOS could not install the speech model. Check your connection and try again."
        }
    }
}
