//
//  main.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudApp
import AppKit

/// The onboarding, on its own, with no app around it.
///
/// Quality here is judged by looking, not by a test. This runs the flow with a canned
/// dictation source so it can be looked at on a machine with no microphone permission and
/// no signed bundle. It is not shipped and it is not signed.
final class PreviewDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        OnboardingWindow.present { NSApp.terminate(nil) }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}

let app = NSApplication.shared
let delegate = PreviewDelegate()
app.delegate = delegate
app.run()
