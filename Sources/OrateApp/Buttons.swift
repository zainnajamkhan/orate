//
//  Buttons.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import SwiftUI

/// The one button on a screen that the user is meant to press.
///
/// `.borderedProminent` would do the job and would be the right answer in a settings pane.
/// A first run window is the one place an app is allowed a little more, because it is the
/// only screen a person looks at rather than through, and a stock button surrounded by
/// custom work is the detail that makes the whole thing read as a template.
public struct PrimaryButtonStyle: ButtonStyle {

    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovering = false

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.heading)
            .foregroundStyle(.white)
            .padding(.horizontal, Space.section)
            .padding(.vertical, Space.small + 2)
            .background {
                Capsule(style: .continuous)
                    .fill(Brand.accent)
                    // Lifts on hover and settles on press, which is the feedback a pointer
                    // expects and costs two lines.
                    .brightness(isEnabled && isHovering && !configuration.isPressed ? 0.06 : 0)
            }
            .shadow(
                color: Color.orate.opacity(isEnabled ? 0.34 : 0),
                radius: configuration.isPressed ? 3 : 8,
                y: configuration.isPressed ? 1 : 3
            )
            .scaleEffect(configuration.isPressed ? 0.975 : 1)
            .opacity(isEnabled ? 1 : 0.4)
            .gentleAnimation(configuration.isPressed, Motion.snap)
            .gentleAnimation(isHovering, Motion.snap)
            .onHover { isHovering = $0 }
    }
}

/// Everything that is not the main action: Back, Not now, Open Settings.
public struct QuietButtonStyle: ButtonStyle {

    /// Sits on the indigo stage rather than on the window background.
    var onDarkGround: Bool = false

    @State private var isHovering = false

    public init(onDarkGround: Bool = false) {
        self.onDarkGround = onDarkGround
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Type.detail.weight(.medium))
            .foregroundStyle(onDarkGround ? Brand.onStage : Color.primary)
            .padding(.horizontal, Space.medium)
            .padding(.vertical, Space.small)
            .background {
                Capsule(style: .continuous)
                    .fill(fill(pressed: configuration.isPressed))
            }
            .gentleAnimation(isHovering, Motion.snap)
            .onHover { isHovering = $0 }
    }

    private func fill(pressed: Bool) -> Color {
        let base = onDarkGround ? Color.white : Color.primary
        if pressed { return base.opacity(0.16) }
        return isHovering ? base.opacity(0.09) : .clear
    }
}

public extension ButtonStyle where Self == PrimaryButtonStyle {
    static var primary: PrimaryButtonStyle { PrimaryButtonStyle() }
}

public extension ButtonStyle where Self == QuietButtonStyle {
    static var quiet: QuietButtonStyle { QuietButtonStyle() }
}
