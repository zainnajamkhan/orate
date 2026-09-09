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
    private var escapeMonitor: Any?

    /// Called whenever the recording state changes, so the status item can follow it.
    public var recordingChanged: ((Bool) -> Void)?
    /// Called once per finished dictation, with something worth showing the user.
    public var finished: ((DictationEngine.Outcome) -> Void)?

    private let preferences: PreferencesStore

    // Not a default argument: those are evaluated outside the actor and the store is main
    // actor bound.
    public init(preferences: PreferencesStore? = nil) {
        let preferences = preferences ?? .shared
        self.preferences = preferences
        self.hotkey = preferences.hotkey

        // Re-claim the shortcut whenever the user picks a different one, including from the
        // welcome window while the app is already running.
        preferences.$preferences
            .map(\.hotkey)
            .removeDuplicates()
            .dropFirst()
            .sink { [weak self] hotkey in
                guard let self, isRegistered || hotkey != self.hotkey else { return }
                self.hotkey = hotkey
                _ = self.activate()
            }
            .store(in: &observations)

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

        installEscape()
    }

    /// Escape abandons the dictation and types nothing.
    ///
    /// A local monitor rather than a global one, because a global key monitor needs
    /// Accessibility and this must work without it. The cost is that Escape only works
    /// while an Aloud window is frontmost. Cancelling from inside another app needs the
    /// permission, so it waits until there is a window to cancel from, and letting go of
    /// the key and deleting the words is the fallback everywhere else.
    private func installEscape() {
        escapeMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, engine.isRecording, event.keyCode == 53 else { return event }
            engine.cancel()
            return nil
        }
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
        preferences.hotkey = hotkey
        self.hotkey = hotkey
        return activate()
    }

    public func deactivate() {
        shortcut.unregister()
        isRegistered = false
        if let escapeMonitor {
            NSEvent.removeMonitor(escapeMonitor)
            self.escapeMonitor = nil
        }
    }
}
