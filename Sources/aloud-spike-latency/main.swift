//
//  main.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AVFoundation
import CoreMedia
import Foundation
import Speech

/// S0. The only number that decides whether Aloud gets built.
///
/// The kill rule is one second from key release to text. That is not the same as the time
/// to transcribe a file, and measuring the file version would flatter the result badly: in
/// real use the audio is fed to the analyzer while the user is still speaking, so by the
/// time they let go of the key most of the work is already done and only the tail is left.
///
/// So this feeds the audio in at the pace it was spoken, exactly as a live microphone
/// would, and starts the clock at the moment the audio ends. That is the moment the user
/// lets go of the key, and the number that comes out is the number the kill rule is about.
///
/// No microphone is involved, which is the point: the permission prompt, the TCC grant and
/// a human being available to talk are all removed from a measurement that does not need
/// them. Live capture is S1 and adds only the buffer size on top of this.

// MARK: - Arguments

let arguments = CommandLine.arguments
guard arguments.count > 1 else {
    print("""
    usage: aloud-spike-latency <audio file> [more files...]

    Generate one with:
      say -o /tmp/short.aiff "can we push the meeting to Thursday"
    """)
    exit(2)
}
let files = arguments.dropFirst().map { URL(fileURLWithPath: $0) }

// MARK: - The measurement

/// What one run found out.
struct Run {
    let name: String
    let spokenSeconds: Double
    /// Audio end to the last result. The kill rule number.
    let tailLatency: Double
    /// Audio start to the first result of any kind, which is what makes the app feel alive
    /// while the user is still talking.
    let firstResultLatency: Double?
    let transcript: String
}

func measure(_ url: URL, locale: Locale) async throws -> Run {
    // A fresh transcriber per run. `results` is a one shot sequence, so a transcriber that
    // has already been read cannot be reused, and reusing one across runs would also let
    // the first file warm the cache for the second and quietly flatter the numbers.
    let transcriber = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)

    let file = try AVAudioFile(forReading: url)
    let sourceFormat = file.processingFormat
    let spokenSeconds = Double(file.length) / sourceFormat.sampleRate

    guard let analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
        compatibleWith: [transcriber]
    ) else {
        throw Failure("no audio format the transcriber will accept")
    }

    guard let converter = AVAudioConverter(from: sourceFormat, to: analyzerFormat) else {
        throw Failure("cannot convert \(sourceFormat) to \(analyzerFormat)")
    }

    let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()
    let analyzer = SpeechAnalyzer(modules: [transcriber])

    // Results are collected on their own task, because the loop that feeds audio has to
    // keep to the clock and cannot stop to read anything.
    let collector = Task { () -> (String, ContinuousClock.Instant?, ContinuousClock.Instant?) in
        // Results arrive as segments, and a later result can supersede an earlier one that
        // covered the same stretch of audio: that is what "progressive" means. Overwriting
        // a single string keeps only the last sentence, and appending blindly repeats every
        // revised one. Keying by where each segment starts, and dropping anything at or
        // after the new segment's start, gives the sentence the user actually said.
        var segments: [(start: CMTime, text: String)] = []
        var first: ContinuousClock.Instant?
        var last: ContinuousClock.Instant?

        for try await result in transcriber.results {
            let now = ContinuousClock.now
            if first == nil { first = now }
            last = now

            let start = result.range.start
            segments.removeAll { $0.start >= start }
            segments.append((start, String(result.text.characters)))
        }

        let text = segments
            .map { $0.text.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
        return (text, first, last)
    }

    try await analyzer.start(inputSequence: stream)

    let started = ContinuousClock.now

    // Feed at the pace it was spoken. A chunk of 0.1s is the sort of buffer a live tap
    // hands over, so the pacing matches what S1 will actually do.
    let chunkFrames = AVAudioFrameCount(sourceFormat.sampleRate * 0.1)
    var elapsed = 0.0

    while true {
        // Stop on the frame count rather than on a short read. `AVAudioFile.read` past the
        // end throws an error object that is nil, which surfaces as Swift's `nilError` and
        // says nothing at all about what went wrong. Asking first is the only way to tell
        // end of file apart from a real failure.
        let remaining = file.length - file.framePosition
        guard remaining > 0 else { break }

        guard let chunk = AVAudioPCMBuffer(
            pcmFormat: sourceFormat,
            frameCapacity: chunkFrames
        ) else { break }
        try file.read(into: chunk, frameCount: AVAudioFrameCount(min(Int64(chunkFrames), remaining)))
        guard chunk.frameLength > 0 else { break }

        let converted = try convert(chunk, using: converter, to: analyzerFormat)
        continuation.yield(AnalyzerInput(buffer: converted))

        elapsed += Double(chunk.frameLength) / sourceFormat.sampleRate
        // Sleep until this chunk would have finished being spoken, so the analyzer is
        // never handed audio from the future.
        let target = started.advanced(by: .seconds(elapsed))
        if target > ContinuousClock.now {
            try await Task.sleep(until: target, clock: .continuous)
        }
    }

    // The user lets go of the key here.
    let released = ContinuousClock.now
    continuation.finish()
    try await analyzer.finalizeAndFinishThroughEndOfInput()

    let (text, firstResult, lastResult) = try await collector.value
    let finished = lastResult ?? ContinuousClock.now

    return Run(
        name: url.lastPathComponent,
        spokenSeconds: spokenSeconds,
        tailLatency: seconds(from: released, to: finished),
        firstResultLatency: firstResult.map { seconds(from: started, to: $0) },
        transcript: text.trimmingCharacters(in: .whitespacesAndNewlines)
    )
}

func convert(
    _ buffer: AVAudioPCMBuffer,
    using converter: AVAudioConverter,
    to format: AVAudioFormat
) throws -> AVAudioPCMBuffer {
    let ratio = format.sampleRate / buffer.format.sampleRate
    let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 64
    guard let output = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: capacity) else {
        throw Failure("could not allocate a converted buffer")
    }

    var supplied = false
    var conversionError: NSError?
    converter.convert(to: output, error: &conversionError) { _, status in
        if supplied {
            status.pointee = .noDataNow
            return nil
        }
        supplied = true
        status.pointee = .haveData
        return buffer
    }
    if let conversionError { throw conversionError }
    return output
}

func seconds(from start: ContinuousClock.Instant, to end: ContinuousClock.Instant) -> Double {
    let duration = start.duration(to: end)
    let (whole, attoseconds) = duration.components
    return Double(whole) + Double(attoseconds) / 1e18
}

struct Failure: LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}

// MARK: - Run it

let locale = Locale(identifier: "en-US")

print("Aloud S0: latency from the end of speech to the finished text")
print(String(repeating: "=", count: 62))
print()

let supported = await SpeechTranscriber.supportedLocales.contains {
    $0.identifier(.bcp47) == locale.identifier(.bcp47)
}
guard supported else {
    print("FAIL: \(locale.identifier) is not supported by SpeechTranscriber on this machine.")
    exit(1)
}

// Used only for the asset check below; each measured run builds its own.
let probe = SpeechTranscriber(locale: locale, preset: .progressiveTranscription)

// The whole wedge is that the operating system owns the model, so this asks for it rather
// than shipping one. On a machine that already has it this is a no op.
switch await AssetInventory.status(forModules: [probe]) {
case .installed:
    print("model: already installed, nothing to download")
case .unsupported:
    print("FAIL: this machine cannot run the transcriber for \(locale.identifier).")
    exit(1)
default:
    print("model: asking macOS to install it (this is the OS download, not ours)")
    if let request = try await AssetInventory.assetInstallationRequest(supporting: [probe]) {
        try await request.downloadAndInstall()
    }
    print("model: installed")
}
print()

var failures = 0

for file in files {
    do {
        let run = try await measure(file, locale: locale)
        let verdict = run.tailLatency <= 1.0 ? "PASS" : "FAIL"
        if run.tailLatency > 1.0 { failures += 1 }

        print("\(run.name)  (\(String(format: "%.1f", run.spokenSeconds))s of speech)")
        print("  transcript          \"\(run.transcript)\"")
        if let first = run.firstResultLatency {
            print("  first words after   \(String(format: "%.3f", first))s of speaking")
        }
        print("  END OF SPEECH TO TEXT  \(String(format: "%.3f", run.tailLatency))s   \(verdict) (kill rule: 1.000s)")
        print()
    } catch {
        failures += 1
        print("\(file.lastPathComponent): FAILED, \(error)")
        print()
    }
}

print(String(repeating: "=", count: 62))
if failures == 0 {
    print("VERDICT: under the kill rule. Build it.")
} else {
    print("VERDICT: \(failures) run(s) missed the kill rule. Stop and reconsider.")
}
exit(failures == 0 ? 0 : 1)
