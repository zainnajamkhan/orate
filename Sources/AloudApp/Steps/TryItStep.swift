//
//  TryItStep.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import SwiftUI

/// The screen the other five exist to reach.
///
/// A dictation app cannot be explained, only demonstrated, and the demonstration is cheap:
/// hold a key, talk, watch the words land. Putting it inside the first run rather than after
/// it means the user has already had the thing they are buying before they are asked for
/// anything optional.
///
/// The meter lives on the stage opposite and the words live here, which splits the two
/// questions being asked. "Is it hearing me" is answered by movement, over there, and "did
/// it get it right" is answered by text, in a box sized for reading.
struct TryItStep: View {

    @ObservedObject var model: OnboardingModel
    @ObservedObject private var trial: DictationTrial

    init(model: OnboardingModel) {
        self.model = model
        _trial = ObservedObject(wrappedValue: model.trial)
    }

    private var hasFinished: Bool { trial.hasText && !trial.isRecording }

    var body: some View {
        StepScaffold(
            headline: hasFinished ? "That is all there is to it" : "Try it here",
            lead: hasFinished
                ? "In any other app those words would already be in the document, at the cursor, exactly where you were typing."
                : "Hold the button, say anything, and let go. Nothing is being sent anywhere."
        ) {
            VStack(alignment: .leading, spacing: Space.large) {
                transcript
                    .entrance(2)

                HStack(spacing: Space.medium) {
                    HoldToTalkButton(isRecording: trial.isRecording) { isDown in
                        if isDown {
                            trial.begin()
                        } else {
                            trial.end()
                            if trial.hasText { model.markDictated() }
                        }
                    }

                    if hasFinished {
                        Button("Try again") { trial.reset() }
                            .buttonStyle(.quiet)
                    }

                    Spacer()
                }
                .entrance(3)
            }
        }
    }

    /// A fixed height, so the box does not grow as the words arrive and shove the button
    /// down the screen in the middle of a sentence.
    private var transcript: some View {
        ScrollView {
            Text(trial.transcript.isEmpty ? "Your words will appear here." : trial.transcript)
                .font(.system(.title3, design: .default))
                .foregroundStyle(trial.transcript.isEmpty ? .tertiary : .primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .gentleAnimation(trial.transcript)
        }
        .frame(height: 118)
        .padding(Space.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                .fill(Color.aloudSurface)
        }
        .overlay {
            RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                .strokeBorder(
                    trial.isRecording ? Color.aloudRecording.opacity(0.5) : Color.aloudEdge,
                    lineWidth: 1
                )
        }
        .shadow(color: Elevation.resting, radius: 6, y: 2)
        .gentleAnimation(trial.isRecording)
    }
}

/// Push to talk, as a button.
///
/// The real binding is a global hotkey, but inside this window a button is honest about
/// what to do and works before the hotkey has been registered with the system. It is a
/// press and hold rather than a toggle because that is the gesture being taught, and a
/// toggle here would teach the wrong one.
private struct HoldToTalkButton: View {

    let isRecording: Bool
    let changed: (Bool) -> Void

    @State private var isDown = false
    @State private var isHovering = false

    var body: some View {
        HStack(spacing: Space.small) {
            Image(systemName: isRecording ? "waveform" : "mic.fill")
                .font(.system(size: 15, weight: .semibold))
            Text(isRecording ? "Listening, let go when done" : "Hold to talk")
                .font(Type.heading)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Space.section)
        .padding(.vertical, Space.medium)
        .background {
            Capsule(style: .continuous)
                .fill(isRecording ? AnyShapeStyle(Brand.live) : AnyShapeStyle(Brand.accent))
                .brightness(isHovering && !isDown ? 0.06 : 0)
        }
        .shadow(
            color: (isRecording ? Color.aloudRecording : Color.aloud).opacity(0.35),
            radius: isDown ? 3 : 9,
            y: isDown ? 1 : 3
        )
        .scaleEffect(isDown ? 0.975 : 1)
        .gentleAnimation(isRecording)
        .gentleAnimation(isDown, Motion.snap)
        .gentleAnimation(isHovering, Motion.snap)
        .contentShape(Capsule(style: .continuous))
        .onHover { isHovering = $0 }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !isDown else { return }
                    isDown = true
                    changed(true)
                }
                .onEnded { _ in
                    isDown = false
                    changed(false)
                }
        )
        .accessibilityElement()
        .accessibilityLabel("Hold to talk")
        .accessibilityAddTraits(.isButton)
    }
}
