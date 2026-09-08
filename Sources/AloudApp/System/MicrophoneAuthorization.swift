//
//  MicrophoneAuthorization.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AVFoundation
import AloudCore
import AppKit

/// The one permission Aloud genuinely cannot work without.
///
/// macOS presents the system prompt at most once for the life of an application, so a
/// second `requestAccess` after a refusal returns false without anything appearing on
/// screen. That is why `current` distinguishes a refusal from a question not yet asked, and
/// why the settings deep link exists at all: after a no, it is the only route left.
@MainActor
public enum MicrophoneAuthorization {

    public static var current: PermissionState {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized: .granted
        case .notDetermined: .notDetermined
        // Restricted means a profile or parental control decided, and the user cannot undo
        // it from Settings. It is still a no, and the honest thing is to treat it as one.
        case .denied, .restricted: .denied
        @unknown default: .denied
        }
    }

    /// Ask, and report what the answer turned out to be.
    public static func request() async -> PermissionState {
        guard current == .notDetermined else { return current }
        _ = await AVCaptureDevice.requestAccess(for: .audio)
        return current
    }

    public static func openSystemSettings() {
        guard let url = URL(
            string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone"
        ) else { return }
        NSWorkspace.shared.open(url)
    }
}
