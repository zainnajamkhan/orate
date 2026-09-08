//
//  Brand.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import SwiftUI

/// The app mark: five bars in a rounded square.
///
/// Drawn rather than shipped as an image, so it scales to any size without an asset
/// catalogue and can be tinted and animated. The bar heights are asymmetric on purpose. A
/// symmetric set reads as a graphic equaliser, which is a music icon; an uneven one reads
/// as speech, which is what this is.
public struct AloudMark: View {

    var size: CGFloat = 48
    /// Drives a gentle idle motion, so the mark on the welcome screen is alive rather than
    /// a logo sitting there.
    var animated: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var phase: Double = 0

    private static let heights: [CGFloat] = [0.34, 0.62, 1.0, 0.72, 0.44]

    public init(size: CGFloat = 48, animated: Bool = false) {
        self.size = size
        self.animated = animated
    }

    public var body: some View {
        RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
            .fill(Brand.accent)
            .overlay {
                HStack(spacing: size * 0.075) {
                    ForEach(Array(Self.heights.enumerated()), id: \.offset) { index, base in
                        Capsule(style: .continuous)
                            .fill(.white)
                            .frame(width: size * 0.085, height: size * 0.46 * scale(index, base))
                    }
                }
            }
            .frame(width: size, height: size)
            .shadow(color: Color.aloud.opacity(0.45), radius: size * 0.22, y: size * 0.08)
            .onAppear(perform: start)
            .accessibilityHidden(true)
    }

    private func scale(_ index: Int, _ base: CGFloat) -> CGFloat {
        guard animated, !reduceMotion else { return base }
        // Each bar runs at a slightly different rate, which is what stops five bars moving
        // together from looking like one bar being stretched.
        let offset = Double(index) * 0.9
        return base * (0.72 + 0.28 * CGFloat(abs(sin(phase + offset))))
    }

    private func start() {
        guard animated, !reduceMotion else { return }
        withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
            phase = .pi
        }
    }
}

/// The mark with the name beside it, for the top of the stage.
public struct Wordmark: View {

    public init() {}

    public var body: some View {
        HStack(spacing: Space.small) {
            AloudMark(size: 22)
            Text("Aloud")
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundStyle(Brand.onStage)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Aloud")
    }
}

/// Concentric rings that breathe outward from the middle of the stage.
///
/// The visual language of sound without drawing a single loudspeaker. Used behind the mark
/// on the welcome screen and behind the microphone once it has been granted.
public struct PulseRings: View {

    var color: Color = Brand.onStage
    var isActive: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var expanded = false

    public init(color: Color = Brand.onStage, isActive: Bool = true) {
        self.color = color
        self.isActive = isActive
    }

    public var body: some View {
        ZStack {
            ForEach(0..<3, id: \.self) { ring in
                Circle()
                    .stroke(color.opacity(0.16), lineWidth: 1)
                    .scaleEffect(expanded ? 1.0 : 0.55)
                    .opacity(expanded ? 0 : 1)
                    .animation(
                        reduceMotion || !isActive
                            ? nil
                            : .easeOut(duration: 3.2)
                                .repeatForever(autoreverses: false)
                                .delay(Double(ring) * 1.05),
                        value: expanded
                    )
            }
        }
        .onAppear { expanded = true }
        .accessibilityHidden(true)
    }
}
