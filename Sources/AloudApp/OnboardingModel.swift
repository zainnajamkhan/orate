//
//  OnboardingModel.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import SwiftUI

/// Holds the flow and keeps it in step with what the system actually says.
///
/// The rules about what may happen next live in `OnboardingFlow`, in the pure module, where
/// they are tested. This type is only the bridge: it asks the system, writes the answer
/// down, and does nothing clever with it.
@MainActor
public final class OnboardingModel: ObservableObject {

    @Published public private(set) var flow = OnboardingFlow()

    /// The tidy up switch on the last screen.
    ///
    /// Reads and writes the shared store rather than holding its own copy, because a
    /// setting the user turns on during first run and then finds off afterwards is worse
    /// than one that was never offered.
    public var wantsCleanup: Bool {
        get { preferences.cleanupEnabled }
        set {
            objectWillChange.send()
            preferences.cleanupEnabled = newValue
        }
    }

    public let engine: DictationEngine

    private let preferences: PreferencesStore
    private var accessibilityPoll: AnyObject?

    // `PreferencesStore.shared` cannot be a default argument: defaults are evaluated
    // outside the actor, and the store is main actor bound. Same trap as `present`.
    /// `startingAt` exists so a single screen can be rendered on its own for review.
    /// Walking the flow by hand to look at screen five is how screens five and six stop
    /// being looked at.
    public init(
        engine: DictationEngine,
        preferences: PreferencesStore? = nil,
        startingAt step: OnboardingStep = .welcome
    ) {
        let preferences = preferences ?? .shared
        self.engine = engine
        self.preferences = preferences
        flow.step = step
        flow.hotkey = preferences.hotkey
        flow.microphone = MicrophoneAuthorization.current
        flow.accessibility = AccessibilityAuthorization.current

        // The grant lands while the user is in System Settings with this window behind it,
        // and macOS gives no notification when it does. Polling is the only way the tick
        // ever appears without the user coming back and clicking something.
        accessibilityPoll = AccessibilityAuthorization.poll { [weak self] state in
            self?.flow.accessibility = state
        }
    }

    // MARK: - Moving through

    public func advance() { flow.advance() }
    public func goBack() { flow.goBack() }

    public func skip() {
        guard flow.isSkippable else { return }
        flow.advance()
    }

    public func markDictated() {
        flow.hasDictated = true
    }

    /// Chosen on the shortcut step.
    ///
    /// Written straight through to the store, so the key shown in the welcome window is the
    /// key the app is actually listening for. Keeping it only in `flow` meant the two could
    /// disagree, and they did.
    public func setHotkey(_ hotkey: Hotkey) {
        flow.hotkey = hotkey
        preferences.hotkey = hotkey
    }

    // MARK: - Permissions

    public func requestMicrophone() async {
        flow.microphone = await MicrophoneAuthorization.request()
    }

    public func requestAccessibility() {
        AccessibilityAuthorization.request()
    }
}
