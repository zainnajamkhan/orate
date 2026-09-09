//
//  AccessibilityAuthorization.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import OrateCore
import AppKit
import ApplicationServices

/// The optional one.
///
/// Accessibility is what lets Orate put the text straight into whatever window the user was
/// already in. Refuse it and the text goes to the clipboard instead, which is a worse app
/// but still an app. That distinction is the whole reason this permission is asked for
/// after the user has already seen the product work rather than before.
///
/// There is no callback when the grant lands. The system does not notify, the process
/// usually has to be relaunched before the new trust takes effect, and the only reliable
/// way to notice is to keep asking. Hence the poll.
@MainActor
public enum AccessibilityAuthorization {

    public static var current: PermissionState {
        AXIsProcessTrusted() ? .granted : .notDetermined
    }

    /// Ask the system to show its prompt.
    ///
    /// Like the microphone, this appears once per application ever, so the settings link
    /// below is not a fallback for the impatient, it is the only route for anyone who has
    /// already dismissed it.
    public static func request() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    public static func openSystemSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ) else { return }
        NSWorkspace.shared.open(url)
    }

    /// Call `changed` on the main actor whenever the answer flips.
    ///
    /// Returns a token; releasing it stops the timer. One second is chosen because the user
    /// is in System Settings looking away from Orate, and the cost of noticing a second
    /// late is nothing while the cost of a tight poll is a busy CPU on a laptop.
    public static func poll(_ changed: @escaping (PermissionState) -> Void) -> AnyObject {
        Poller(changed: changed)
    }

    @MainActor
    private final class Poller: NSObject {
        private var timer: Timer?
        private var last: PermissionState

        init(changed: @escaping (PermissionState) -> Void) {
            last = MainActor.assumeIsolated { AccessibilityAuthorization.current }
            super.init()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self else { return }
                    let now = AccessibilityAuthorization.current
                    guard now != self.last else { return }
                    self.last = now
                    changed(now)
                }
            }
        }

        deinit { timer?.invalidate() }
    }
}
