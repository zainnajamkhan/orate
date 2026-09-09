//
//  SingleInstance.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AppKit
import Foundation

/// Refuses to run as a second copy.
///
/// Two copies of a menu bar app are quietly disastrous. Each installs its own status item,
/// each claims the same shortcut, and each opens the microphone when it fires, so a single
/// keypress starts two recordings that compete for the same input. It also looks like
/// nothing more than "the app is behaving strangely", which is the hardest kind of bug to
/// report.
///
/// This happens more often than it sounds: running from Xcode while a copy is already
/// running does it every time, which is exactly how it was found.
@MainActor
public enum SingleInstance {

    /// True when this process should carry on. False means another copy already has it, and
    /// the caller should terminate.
    public static func claim() -> Bool {
        guard let identifier = Bundle.main.bundleIdentifier else { return true }

        let others = NSRunningApplication.runningApplications(withBundleIdentifier: identifier)
            .filter { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }

        guard !others.isEmpty else { return true }

        Diagnostics.log("another copy is already running, standing down")

        // Bring the existing copy forward rather than dying silently, so that double
        // clicking the app does something visible instead of appearing to fail.
        others.first?.activate()
        return false
    }
}
