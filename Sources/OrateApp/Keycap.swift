//
//  Keycap.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import OrateCore
import SwiftUI

/// One key, drawn as a key.
///
/// The hotkey is the entire interface of this app, so it is worth more than a bold word in
/// a sentence. Drawing it as a physical cap means the instruction can be read from across
/// the room and matched against the keyboard without being parsed. Every Mac app that
/// teaches a shortcut well does this, and the ones that write `Option+Space` do not.
public struct Keycap: View {

    let label: String
    /// Held down. The cap sits into the surface and loses its lip, which is what a real key
    /// does and needs no explaining.
    var isPressed: Bool = false
    var scale: CGFloat = 1
    var onDarkGround: Bool = false

    public init(
        _ label: String,
        isPressed: Bool = false,
        scale: CGFloat = 1,
        onDarkGround: Bool = false
    ) {
        self.label = label
        self.isPressed = isPressed
        self.scale = scale
        self.onDarkGround = onDarkGround
    }

    public var body: some View {
        Text(label)
            .font(.system(size: 14 * scale, weight: .medium, design: .rounded))
            .foregroundStyle(foreground)
            // A key is a physical object and does not wrap. Without this, "Space" broke
            // across two lines inside the cap as soon as the row ran short of room.
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .frame(minWidth: 30 * scale, minHeight: 20 * scale)
            .padding(.horizontal, Space.small * scale)
            .padding(.vertical, Space.tight * scale)
            .background {
                RoundedRectangle(cornerRadius: Radius.small * scale, style: .continuous)
                    .fill(background)
            }
            .overlay {
                // A highlight along the top edge only. Stroking the whole outline makes a
                // sticker; lighting the top makes a moulded cap.
                RoundedRectangle(cornerRadius: Radius.small * scale, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [edgeLight, edgeLight.opacity(0.25)],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
                    .opacity(isPressed ? 0.4 : 1)
            }
            .shadow(
                color: Elevation.raised.opacity(isPressed ? 0 : 1),
                radius: 1.5 * scale,
                y: (isPressed ? 0 : 1.5) * scale
            )
            .offset(y: isPressed ? 1 * scale : 0)
            .gentleAnimation(isPressed, Motion.snap)
    }

    private var foreground: Color {
        if isPressed { return .white }
        return onDarkGround ? Brand.onStage : .primary
    }

    private var background: AnyShapeStyle {
        if isPressed { return AnyShapeStyle(Brand.accent) }
        if onDarkGround {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.white.opacity(0.20), .white.opacity(0.10)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        return AnyShapeStyle(
            LinearGradient(
                colors: [Color.orateSurface, Color.orateSurface.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var edgeLight: Color {
        onDarkGround ? .white.opacity(0.4) : .white.opacity(0.7)
    }
}

/// A whole combination, as a row of caps.
public struct KeycapRow: View {

    let hotkey: Hotkey
    var isPressed: Bool = false
    var scale: CGFloat = 1
    var onDarkGround: Bool = false

    public init(
        _ hotkey: Hotkey,
        isPressed: Bool = false,
        scale: CGFloat = 1,
        onDarkGround: Bool = false
    ) {
        self.hotkey = hotkey
        self.isPressed = isPressed
        self.scale = scale
        self.onDarkGround = onDarkGround
    }

    public var body: some View {
        HStack(spacing: Space.tight * scale) {
            ForEach(Array(hotkey.keycapParts.enumerated()), id: \.offset) { _, part in
                Keycap(part, isPressed: isPressed, scale: scale, onDarkGround: onDarkGround)
            }
        }
        // Spoken as the shortcut, not as a list of loose glyphs, which is what VoiceOver
        // would otherwise make of an option symbol next to the word Space.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
    }

    private var spokenLabel: String {
        var parts: [String] = []
        if hotkey.modifiers.contains(.control) { parts.append("Control") }
        if hotkey.modifiers.contains(.option) { parts.append("Option") }
        if hotkey.modifiers.contains(.shift) { parts.append("Shift") }
        if hotkey.modifiers.contains(.command) { parts.append("Command") }
        parts.append(Hotkey.keyName(for: hotkey.keyCode))
        return parts.joined(separator: " ")
    }
}
