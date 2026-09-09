//
//  AppDelegate.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudApp
import AloudCore
import AppKit
import ApplicationServices
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
    private let dictation = DictationController()

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Two copies means two status items, two shortcut claims, and one keypress opening
        // the microphone twice. Running from Xcode over an already running copy does it
        // every time, which is how it was found.
        guard SingleInstance.claim() else {
            NSApp.terminate(nil)
            return
        }

        Diagnostics.log("launched, log at \(Diagnostics.path)")
        Diagnostics.log("accessibility trusted: \(AccessibilityAuthorization.current == .granted)")
        installStatusItem()
        wireDictation()

        // The shortcut stays live while the welcome window is up, so the user can prove it
        // reaches Aloud on the step that teaches it. Only the typing is suppressed, because
        // the words are meant to land in the window rather than in it.
        OnboardingWindow.isOpenChanged = { [weak self] isOpen in
            self?.dictation.engine.insertsIntoFrontmostApp = !isOpen
        }

        // First run opens the welcome. Afterwards the app starts silently, which for a menu
        // bar utility is the whole point.
        if !OnboardingWindow.hasCompleted {
            OnboardingWindow.present(engine: dictation.engine)
        }
    }

    // MARK: - Dictation

    private func wireDictation() {
        dictation.recordingChanged = { [weak self] recording in
            self?.updateStatusIcon(recording: recording)
        }
        dictation.finished = { [weak self] outcome in
            self?.report(outcome)
        }

        Diagnostics.log("claiming shortcut \(dictation.hotkey.keycapParts.joined(separator: " "))")
        if !dictation.activate() {
            Diagnostics.log("shortcut refused, another app owns it")
            // Registration fails when another app already owns the combination. An app that
            // looks installed and silently never responds is the worst possible failure, so
            // it is said out loud once.
            let alert = NSAlert()
            alert.messageText = "Another app is already using that shortcut"
            alert.informativeText = """
            Aloud could not claim \(dictation.hotkey.keycapParts.joined(separator: " ")). \
            Pick a different one in Settings.
            """
            alert.runModal()
        }
    }

    /// The menu bar icon is the only thing on screen while dictating, so it carries the one
    /// fact that matters: whether the microphone is open.
    private func updateStatusIcon(recording: Bool) {
        let symbol = recording ? "waveform.circle.fill" : "waveform"
        statusItem?.button?.image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: recording ? "Aloud is listening" : "Aloud"
        )
        statusItem?.button?.contentTintColor = recording ? .systemRed : nil
    }

    /// Explained once, then never again.
    ///
    /// This was a modal alert after every single dictation. For something used thirty times
    /// a day that is not a notice, it is an obstruction: it steals focus from the window the
    /// user was dictating into, and it has to be dismissed before they can carry on. The
    /// information is worth giving exactly once.
    private static let clipboardNoticeKey = "aloud.clipboardNoticeShown"

    private func report(_ outcome: DictationEngine.Outcome) {
        guard case .copied = outcome else { return }
        guard !UserDefaults.standard.bool(forKey: Self.clipboardNoticeKey) else { return }
        UserDefaults.standard.set(true, forKey: Self.clipboardNoticeKey)

        let notice = NSAlert()
        notice.messageText = "Your words are on the clipboard"
        notice.informativeText = """
        Press Command V to paste them. Aloud can type straight into your apps instead, \
        which needs Accessibility permission.

        If Aloud is already ticked in System Settings, switch it off and on again. The \
        permission is tied to each build of the app, so it has to be renewed after an \
        update.

        This will not be shown again.
        """
        notice.addButton(withTitle: "OK")
        notice.addButton(withTitle: "Open Settings")
        if notice.runModal() == .alertSecondButtonReturn {
            AccessibilityAuthorization.openSystemSettings()
        }
    }

    // MARK: - Menu bar

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        item.button?.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: "Aloud")
        item.menu = buildMenu()
        statusItem = item
    }

    private func buildMenu() -> NSMenu {
        let menu = NSMenu()

        let shortcut = NSMenuItem(
            title: "Hold \(dictation.hotkey.keycapParts.joined(separator: " ")) to dictate",
            action: nil,
            keyEquivalent: ""
        )
        shortcut.isEnabled = false
        menu.addItem(shortcut)
        menu.addItem(.separator())

        menu.addItem(
            withTitle: "Welcome to Aloud\u{2026}",
            action: #selector(showOnboarding),
            keyEquivalent: ""
        ).target = self
        menu.addItem(
            withTitle: "Reveal Log\u{2026}",
            action: #selector(revealLog),
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

    @objc private func revealLog() {
        NSWorkspace.shared.selectFile(Diagnostics.path, inFileViewerRootedAtPath: "")
    }

    @objc private func showOnboarding() {
        OnboardingWindow.present(engine: dictation.engine)
    }
}
