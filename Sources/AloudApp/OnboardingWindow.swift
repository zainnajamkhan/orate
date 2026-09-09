//
//  OnboardingWindow.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import AppKit
import SwiftUI

/// Puts the onboarding on screen.
///
/// A plain `NSWindow` rather than a SwiftUI `Window` scene, because this has to be opened
/// from `applicationDidFinishLaunching` and there is no view alive at that point to carry
/// the `openWindow` action. Aloud is a menu bar app with no Dock icon, so the scene that
/// would normally provide one may never be instantiated at all.
@MainActor
public enum OnboardingWindow {

    /// Interface state, not something the user owns, so it lives in defaults rather than in
    /// any settings document they might copy between machines.
    public static let completedKey = "aloud.onboardingCompleted"

    private static var window: NSWindow?
    private static let delegate = WindowDelegate()

    /// Called with true when the welcome window opens and false when it closes.
    ///
    /// The global shortcut has to stand down while this window is up. Two `DictationEngine`
    /// instances exist by design, one here and one behind the shortcut, and the shortcut
    /// step teaches the user the very key combination that would start the second one. Both
    /// would open the microphone at once, and the shortcut's engine would try to type its
    /// result into this window.
    public static var isOpenChanged: ((Bool) -> Void)?

    public static var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }

    public static func present(
        source: DictationTrialSource? = nil,
        onFinish: (() -> Void)? = nil
    ) {
        // Already up: bring it forward rather than opening a second copy.
        if let window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // The real engine, not a demo. The try step is the screen that convinces someone
        // to buy the app, so it runs exactly the code the shortcut runs. Insertion is off
        // here only because the words are meant to land in this window.
        let trial = DictationTrial(
            source: source ?? DictationEngine(insertsIntoFrontmostApp: false)
        )
        let view = OnboardingView(model: OnboardingModel(trial: trial)) {
            UserDefaults.standard.set(true, forKey: completedKey)
            close()
            onFinish?()
        }

        let hosting = NSHostingView(rootView: view)
        let created = NSWindow(
            contentRect: .zero,
            // No resize control. The layout is fixed at 680 by 580 and every step is
            // composed for it; a resizable first run window is one that can be dragged into
            // a shape nobody designed.
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        created.contentView = hosting
        created.title = "Welcome to Aloud"
        created.titlebarAppearsTransparent = true
        created.titleVisibility = .hidden
        created.isMovableByWindowBackground = true
        created.isReleasedWhenClosed = false

        // Size first, centre second. `contentRect: .zero` means the window has no size at
        // all until the hosting view has been measured, so centring before that centres
        // nothing and leaves the finished window wherever its top left corner landed.
        created.setContentSize(hosting.fittingSize)
        created.center()
        // Closing with the red button has to stand the shortcut back up too, not just
        // finishing the flow.
        created.delegate = delegate

        window = created
        isOpenChanged?(true)
        created.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    public static func close() {
        guard let window else { return }
        window.delegate = nil
        window.close()
        self.window = nil
        isOpenChanged?(false)
    }

    /// Notices the red button.
    private final class WindowDelegate: NSObject, NSWindowDelegate {
        func windowWillClose(_ notification: Notification) {
            MainActor.assumeIsolated {
                OnboardingWindow.window = nil
                OnboardingWindow.isOpenChanged?(false)
            }
        }
    }
}
