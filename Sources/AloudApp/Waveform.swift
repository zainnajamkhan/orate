//
//  Waveform.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import SwiftUI

/// The bars that move while the microphone is open.
///
/// This is the only part of the app that answers "is it hearing me" before the text
/// arrives, and that second of doubt is where a dictation app either feels immediate or
/// feels broken. It is a level meter rather than a scrolling waveform: a waveform draws
/// history, which nobody needs, while a meter draws the present, which is the only question
/// being asked.
///
/// Mirrored about the centre line, because a meter that grows only upward reads as a chart
/// and one that grows both ways reads as a voice.
public struct Waveform: View {

    /// Newest last, each between 0 and 1.
    let levels: [Float]
    let isRecording: Bool
    var barWidth: CGFloat = 3
    var spacing: CGFloat = 3
    /// Off on the dark stage, where the tinted gradient has no contrast against indigo.
    var usesBrandColour: Bool = true

    public init(
        levels: [Float],
        isRecording: Bool,
        barWidth: CGFloat = 3,
        spacing: CGFloat = 3,
        usesBrandColour: Bool = true
    ) {
        self.levels = levels
        self.isRecording = isRecording
        self.barWidth = barWidth
        self.spacing = spacing
        self.usesBrandColour = usesBrandColour
    }

    public var body: some View {
        GeometryReader { proxy in
            HStack(alignment: .center, spacing: spacing) {
                ForEach(Array(levels.enumerated()), id: \.offset) { index, level in
                    Capsule(style: .continuous)
                        .fill(fill)
                        // A floor of the bar's own width, so silence is a row of dots
                        // rather than an empty box. An empty box reads as a failure.
                        .frame(
                            width: barWidth,
                            height: max(barWidth, CGFloat(level) * proxy.size.height * falloff(index))
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .gentleAnimation(levels.last ?? 0, Motion.snap)
        }
        .accessibilityHidden(true)
    }

    private var fill: AnyShapeStyle {
        guard isRecording else {
            return AnyShapeStyle(
                usesBrandColour ? Color.secondary.opacity(0.35) : Brand.onStage.opacity(0.25)
            )
        }
        return usesBrandColour ? AnyShapeStyle(Brand.live) : AnyShapeStyle(Brand.onStage)
    }

    /// Tapers the ends toward zero.
    ///
    /// A block of bars that stops dead at both edges looks cropped. Fading the outer fifth
    /// makes it read as a shape rather than as a window onto something larger.
    private func falloff(_ index: Int) -> CGFloat {
        guard levels.count > 1 else { return 1 }
        let position = CGFloat(index) / CGFloat(levels.count - 1)
        let edge = min(position, 1 - position) / 0.2
        return min(1, max(0.15, edge))
    }
}

/// The red dot, with the word next to it.
public struct RecordingBadge: View {

    let isRecording: Bool
    var onDarkGround: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    public init(isRecording: Bool, onDarkGround: Bool = false) {
        self.isRecording = isRecording
        self.onDarkGround = onDarkGround
    }

    public var body: some View {
        HStack(spacing: Space.small) {
            Circle()
                .fill(isRecording ? Color.aloudRecording : idleDot)
                .frame(width: 8, height: 8)
                .overlay {
                    Circle()
                        .stroke(Color.aloudRecording.opacity(0.45), lineWidth: 5)
                        .scaleEffect(pulsing && isRecording ? 2.1 : 1)
                        .opacity(pulsing && isRecording ? 0 : 1)
                }
                .animation(
                    reduceMotion || !isRecording
                        ? nil
                        : .easeOut(duration: 1.1).repeatForever(autoreverses: false),
                    value: pulsing
                )
            Text(isRecording ? "Listening" : "Not listening")
                .font(Type.caption)
                .foregroundStyle(onDarkGround ? Brand.onStageSecondary : Color.secondary)
        }
        .onAppear { pulsing = true }
        .accessibilityElement(children: .combine)
    }

    private var idleDot: Color {
        onDarkGround ? Brand.onStage.opacity(0.35) : Color.secondary.opacity(0.4)
    }
}
