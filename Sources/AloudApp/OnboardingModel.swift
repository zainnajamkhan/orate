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
    @Published public var wantsCleanup = false

    public let trial: DictationTrial

    private var accessibilityPoll: AnyObject?

    public init(trial: DictationTrial) {
        self.trial = trial
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

    public func setHotkey(_ hotkey: Hotkey) {
        flow.hotkey = hotkey
    }

    // MARK: - Permissions

    public func requestMicrophone() async {
        flow.microphone = await MicrophoneAuthorization.request()
    }

    public func requestAccessibility() {
        AccessibilityAuthorization.request()
    }
}
