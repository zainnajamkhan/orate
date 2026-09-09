//
//  DictationController.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import AppKit
import Combine
import SwiftUI

/// What the shortcut is wired to.
///
/// Owns the one engine the app dictates with, keeps the menu bar icon honest about whether
/// the microphone is open, and says where the words went. Kept out of the app target so the
/// preview harness and any future test can drive it without an `NSApplication`.
@MainActor
public final class DictationController: ObservableObject {

    @Published public private(set) var hotkey: Hotkey
    @Published public private(set) var isRegistered = false

    public let engine = DictationEngine()

    private let shortcut = GlobalHotkey()
    private var observations: Set<AnyCancellable> = []

    /// Called whenever the recording state changes, so the status item can follow it.
    public var recordingChanged: ((Bool) -> Void)?
    /// Called once per finished dictation, with something worth showing the user.
    public var finished: ((DictationEngine.Outcome) -> Void)?

    public init(hotkey: Hotkey = .suggested) {
        self.hotkey = hotkey

        engine.$isRecording
            .removeDuplicates()
            .sink { [weak self] recording in self?.recordingChanged?(recording) }
            .store(in: &observations)

        engine.$lastOutcome
            .compactMap { $0 }
            .sink { [weak self] outcome in self?.finished?(outcome) }
            .store(in: &observations)

        shortcut.pressed = { [weak self] in self?.engine.begin() }
        shortcut.released = { [weak self] in self?.engine.end() }
    }

    /// Claim the shortcut.
    ///
    /// A false result means another application already owns the combination. That is worth
    /// surfacing rather than swallowing: the failure mode otherwise is an app that appears
    /// installed and simply never responds.
    @discardableResult
    public func activate() -> Bool {
        isRegistered = shortcut.register(hotkey)
        return isRegistered
    }

    public func change(to hotkey: Hotkey) -> Bool {
        self.hotkey = hotkey
        return activate()
    }

    public func deactivate() {
        shortcut.unregister()
        isRegistered = false
    }
}
