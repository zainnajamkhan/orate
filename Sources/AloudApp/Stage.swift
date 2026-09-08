//
//  Stage.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import SwiftUI

/// The illustrated half of the window.
///
/// A first run made only of headings and bullet points is a document, and a document is
/// what the last version of this was. Every step now has a picture of the thing it is
/// talking about, and four of the six pictures are live: the microphone lights when the
/// permission lands, the keys change when a different shortcut is picked, the waveform is
/// the real level, and the document mock types the words that were actually said.
///
/// It is a fixed column rather than a background behind the text, because text over a
/// gradient is a legibility problem that gets solved with scrims, and a scrim over a
/// gradient is just a worse gradient.
struct Stage: View {

    @ObservedObject var model: OnboardingModel
    @ObservedObject var trial: DictationTrial

    var body: some View {
        ZStack {
            Brand.stage

            // Off centre and low, so the light has a direction. Centred glow reads as a
            // vignette and vignettes look like a filter.
            Brand.halo
                .frame(width: 420, height: 420)
                .offset(x: -30, y: -40)
                .blendMode(.plusLighter)

            VStack(alignment: .leading, spacing: 0) {
                Wordmark()
                    .padding(Space.section)

                Spacer(minLength: 0)

                hero
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, Space.section)

                Spacer(minLength: 0)

                caption
                    .padding(Space.section)
            }
        }
        .frame(width: 348)
        .clipped()
    }

    @ViewBuilder
    private var hero: some View {
        switch model.flow.step {
        case .welcome: WelcomeHero()
        case .microphone: MicrophoneHero(granted: model.flow.microphone == .granted)
        case .hotkey: HotkeyHero(hotkey: model.flow.hotkey)
        case .tryIt: TryItHero(trial: trial, hotkey: model.flow.hotkey)
        case .pasting: PastingHero(granted: model.flow.accessibility == .granted)
        case .ready: ReadyHero(hotkey: model.flow.hotkey)
        }
    }

    /// One line under the picture, in the picture's own voice.
    ///
    /// Not a repeat of the headline opposite. It is the caption to the illustration, which
    /// is the only job it has, and it is what stops the pane looking like an empty poster.
    private var caption: some View {
        Text(captionText)
            .font(Type.caption)
            .foregroundStyle(Brand.onStageSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .id(captionText)
            .transition(.opacity)
            .gentleAnimation(captionText)
    }

    private var captionText: String {
        switch model.flow.step {
        case .welcome: "Dictation that starts working the moment it is installed."
        case .microphone:
            model.flow.microphone == .granted
                ? "The microphone opens on a keypress and closes when you let go."
                : "macOS asks once. Aloud cannot ask on its own behalf."
        case .hotkey: "Held, not tapped. Let go and the words are already on their way."
        case .tryIt:
            trial.isRecording
                ? "Listening. Everything you see is happening on this Mac."
                : "Hold the button opposite and say anything at all."
        case .pasting:
            model.flow.accessibility == .granted
                ? "Straight to the cursor, in whatever you were already writing."
                : "Without permission the words wait on the clipboard instead."
        case .ready: "Up in the menu bar, out of the way until you need it."
        }
    }
}

// MARK: - Welcome

private struct WelcomeHero: View {
    var body: some View {
        ZStack {
            PulseRings()
                .frame(width: 240, height: 240)
            AloudMark(size: 104, animated: true)
        }
        .frame(height: 240)
    }
}

// MARK: - Microphone

private struct MicrophoneHero: View {

    let granted: Bool

    var body: some View {
        ZStack {
            PulseRings(isActive: granted)
                .frame(width: 220, height: 220)

            Circle()
                .fill(.white.opacity(granted ? 0.16 : 0.07))
                .frame(width: 132, height: 132)
                .overlay {
                    Circle().strokeBorder(.white.opacity(granted ? 0.34 : 0.14), lineWidth: 1)
                }

            Image(systemName: "mic.fill")
                .font(.system(size: 46, weight: .medium))
                .foregroundStyle(Brand.onStage.opacity(granted ? 1 : 0.45))

            if granted {
                // The tick sits on the rim rather than over the glyph, so the picture still
                // reads as a microphone after it has been granted.
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white, Color.green)
                    .offset(x: 48, y: 44)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(height: 240)
        .gentleAnimation(granted)
    }
}

// MARK: - Hotkey

private struct HotkeyHero: View {

    let hotkey: Hotkey

    var body: some View {
        VStack(spacing: Space.section) {
            KeycapRow(hotkey, isPressed: true, scale: 2.0, onDarkGround: true)

            // A hand would be twee and a caption would repeat the one below. Three chevrons
            // pointing down say "push" and nothing else.
            VStack(spacing: 2) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Brand.onStage.opacity(0.5 - Double(index) * 0.15))
                }
            }
        }
        .frame(height: 240)
    }
}

// MARK: - Try it

private struct TryItHero: View {

    @ObservedObject var trial: DictationTrial
    let hotkey: Hotkey

    var body: some View {
        VStack(spacing: Space.section) {
            Waveform(
                levels: trial.levels,
                isRecording: trial.isRecording,
                barWidth: 4,
                spacing: 4,
                usesBrandColour: false
            )
            .frame(height: 130)

            RecordingBadge(isRecording: trial.isRecording, onDarkGround: true)

            KeycapRow(hotkey, isPressed: trial.isRecording, scale: 1.1, onDarkGround: true)
                .opacity(0.8)
        }
        .frame(height: 240)
    }
}

// MARK: - Pasting

private struct PastingHero: View {

    let granted: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var caretVisible = true

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // A window chrome mock. Three dots is the whole of it, and it is enough for
            // anyone to read this as "some other app".
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { _ in
                    Circle().fill(.white.opacity(0.22)).frame(width: 7, height: 7)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Space.small)
            .background(.white.opacity(0.08))

            VStack(alignment: .leading, spacing: Space.small) {
                ForEach(0..<2, id: \.self) { row in
                    Capsule()
                        .fill(.white.opacity(0.16))
                        .frame(width: row == 0 ? 168 : 132, height: 7)
                }

                HStack(spacing: 3) {
                    Capsule()
                        .fill(granted ? Color.aloud.opacity(0.95) : .white.opacity(0.16))
                        .frame(width: granted ? 96 : 54, height: 7)
                    Rectangle()
                        .fill(.white.opacity(caretVisible ? 0.85 : 0.1))
                        .frame(width: 2, height: 13)
                }

                if !granted {
                    HStack(spacing: Space.tight) {
                        Image(systemName: "doc.on.clipboard.fill")
                            .font(.system(size: 9))
                        Text("on your clipboard")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundStyle(Brand.onStageSecondary)
                    .padding(.top, Space.tight)
                }
            }
            .padding(Space.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(width: 232)
        .background {
            RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                .fill(.white.opacity(0.05))
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.medium, style: .continuous)
                .strokeBorder(.white.opacity(0.16), lineWidth: 1)
        }
        .shadow(color: .black.opacity(0.3), radius: 18, y: 8)
        .frame(height: 240)
        .gentleAnimation(granted)
        .onAppear(perform: blink)
    }

    private func blink() {
        guard !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            caretVisible = false
        }
    }
}

// MARK: - Ready

private struct ReadyHero: View {

    let hotkey: Hotkey

    var body: some View {
        VStack(spacing: Space.section) {
            // The menu bar, mocked, with Aloud's icon lit. This is the answer to the one
            // question a menu bar app leaves a new user with, which is "where did it go".
            HStack(spacing: Space.medium) {
                Image(systemName: "wifi")
                Image(systemName: "battery.75percent")
                AloudMark(size: 18)
                Image(systemName: "magnifyingglass")
                Text("9:41")
                    .font(.system(size: 11, weight: .medium))
            }
            .font(.system(size: 11))
            .foregroundStyle(Brand.onStage.opacity(0.75))
            .padding(.horizontal, Space.medium)
            .padding(.vertical, Space.small)
            .background {
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .fill(.white.opacity(0.10))
            }
            .overlay {
                RoundedRectangle(cornerRadius: Radius.small, style: .continuous)
                    .strokeBorder(.white.opacity(0.14), lineWidth: 1)
            }

            Image(systemName: "arrow.down")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Brand.onStage.opacity(0.4))

            KeycapRow(hotkey, scale: 1.3, onDarkGround: true)
        }
        .frame(height: 240)
    }
}
