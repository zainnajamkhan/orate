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
/// Quality here is judged by looking, not by a test, so there has to be something to look
/// at before the rest of Aloud exists. This is not shipped and is not signed; it opens the
/// window, and quitting it quits the process.
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
