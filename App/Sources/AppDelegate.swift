//
//  AppDelegate.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudApp
import AppKit
import SwiftUI

/// The shell.
///
/// Deliberately thin. Everything worth reading lives in the `AloudApp` library, which the
/// preview harness also links, so the two can never drift apart. This target exists because
/// entitlements, signing and notarisation cannot live in a Swift package.
@main
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private var statusItem: NSStatusItem?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        installStatusItem()

        // First run opens the welcome. Afterwards the app starts silently, which for a
        // menu bar utility is the whole point.
        if !OnboardingWindow.hasCompleted {
            OnboardingWindow.present()
        }
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(
            systemSymbolName: "waveform",
            accessibilityDescription: "Aloud"
        )
        item.menu = buildMenu()
        statusItem = item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()
        menu.addItem(
            withTitle: "Welcome to Aloud\u{2026}",
            action: #selector(showOnboarding),
            keyEquivalent: ""
        ).target = self
        menu.addItem(.separator())
        menu.addItem(
            withTitle: "Quit Aloud",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        return menu
    }

    @objc private func showOnboarding() {
        OnboardingWindow.present()
    }
}
