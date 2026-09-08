//
//  Hotkey.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import Foundation

/// A key combination, stored as the numbers the system reports rather than as a string.
///
/// Kept here in the pure module, with no Carbon or AppKit import, so the display logic can
/// be tested without a window server. The recorder that captures one of these lives at the
/// system edge; everything about how it reads on screen is decided here.
public struct Hotkey: Equatable, Hashable, Codable, Sendable {

    /// The virtual key code, as `NSEvent.keyCode` reports it.
    public let keyCode: UInt16

    /// The modifiers held down with it.
    public let modifiers: Modifiers

    public init(keyCode: UInt16, modifiers: Modifiers) {
        self.keyCode = keyCode
        self.modifiers = modifiers
    }

    public struct Modifiers: OptionSet, Hashable, Codable, Sendable {
        public let rawValue: Int
        public init(rawValue: Int) { self.rawValue = rawValue }

        public static let control = Modifiers(rawValue: 1 << 0)
        public static let option = Modifiers(rawValue: 1 << 1)
        public static let shift = Modifiers(rawValue: 1 << 2)
        public static let command = Modifiers(rawValue: 1 << 3)

        /// Ordered the way macOS prints them in a menu, which is the order every Mac user
        /// has been reading modifiers in for twenty years. Any other order looks wrong
        /// without the reader being able to say why.
        public var glyphs: [String] {
            var result: [String] = []
            if contains(.control) { result.append("\u{2303}") }
            if contains(.option) { result.append("\u{2325}") }
            if contains(.shift) { result.append("\u{21E7}") }
            if contains(.command) { result.append("\u{2318}") }
            return result
        }
    }

    /// The default offered on the hotkey step.
    ///
    /// Right Option held down on its own is what the fastest competitors use, because it is
    /// the one modifier no application binds and it needs no other finger. Aloud cannot
    /// register a bare modifier through the ordinary hotkey API, so the offer here is the
    /// nearest safe thing and the bare modifier arrives with the real recorder in S1.
    public static let suggested = Hotkey(keyCode: 49, modifiers: [.option])

    /// The pieces to draw, modifiers first, key last.
    ///
    /// Returned as parts rather than as one joined string because the onboarding renders
    /// each one as a separate keycap, and joining them here would mean splitting them there.
    public var keycapParts: [String] {
        modifiers.glyphs + [Self.keyName(for: keyCode)]
    }

    /// The label for a virtual key code.
    ///
    /// Only the keys a person would plausibly choose for a push to talk binding are named.
    /// Anything else falls back to the code itself, which is ugly but honest, and is better
    /// than showing an empty keycap and letting the user think the recording failed.
    public static func keyName(for keyCode: UInt16) -> String {
        switch keyCode {
        case 49: "Space"
        case 36: "\u{21A9}"
        case 48: "\u{21E5}"
        case 53: "esc"
        case 96: "F5"
        case 97: "F6"
        case 98: "F7"
        case 100: "F8"
        case 101: "F9"
        case 109: "F10"
        case 103: "F11"
        case 111: "F12"
        case 122: "F1"
        case 120: "F2"
        case 99: "F3"
        case 118: "F4"
        default: "Key \(keyCode)"
        }
    }
}
