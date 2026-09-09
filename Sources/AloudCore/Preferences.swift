//
//  Preferences.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import Foundation

/// What the user has chosen.
///
/// A value type in the pure module, so the encoding can be tested without a defaults
/// database and so nothing about how it is stored leaks into the rest of the app.
public struct Preferences: Equatable, Codable, Sendable {

    public var hotkey: Hotkey

    /// The tidy up pass. Off unless the user turns it on, and that default is not a
    /// preference, it is the answer to the loudest complaint about the competition: their
    /// cleanup step answers the sentence instead of typing it.
    public var cleanupEnabled: Bool

    public init(hotkey: Hotkey = .suggested, cleanupEnabled: Bool = false) {
        self.hotkey = hotkey
        self.cleanupEnabled = cleanupEnabled
    }

    /// Decoding never fails into nothing.
    ///
    /// A stored blob written by an older version, or corrupted, must not leave the user
    /// with no shortcut at all: an app that silently stops responding to its only control
    /// is indistinguishable from a broken one. Anything unreadable falls back to the
    /// defaults, which always work.
    public init(decoding data: Data?) {
        guard
            let data,
            let decoded = try? JSONDecoder().decode(Preferences.self, from: data)
        else {
            self = Preferences()
            return
        }
        self = decoded
    }

    public func encoded() -> Data? {
        try? JSONEncoder().encode(self)
    }
}
