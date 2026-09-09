//
//  OnboardingFlow.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import Foundation

/// Whether the system has said yes to something Orate asked for.
///
/// `notDetermined` and `denied` are kept apart because they need opposite treatment. The
/// first can still be answered by asking, and the second cannot: macOS shows an application
/// its permission prompt at most once ever, so after a denial the only route left is a deep
/// link into System Settings. Collapsing the two into a boolean is how apps end up with a
/// button that silently does nothing.
public enum PermissionState: Equatable, Sendable {
    case notDetermined
    case denied
    case granted
}

/// The screens of first run, in order.
public enum OnboardingStep: Int, CaseIterable, Sendable {
    case welcome
    case microphone
    case hotkey
    case tryIt
    case pasting
    case ready
}

/// Everything the onboarding knows, and the rules about what it will let the user do next.
///
/// This is a value type in the pure module on purpose. The interesting decisions in an
/// onboarding flow are not visual, they are about what is required and what is not, and
/// those decisions are worth a test rather than a careful read of a view body.
public struct OnboardingFlow: Equatable, Sendable {

    public var step: OnboardingStep
    public var microphone: PermissionState
    public var accessibility: PermissionState
    public var hotkey: Hotkey
    /// Set once the user has watched their own speech turn into text, which is the moment
    /// the product explains itself.
    public var hasDictated: Bool

    public init(
        step: OnboardingStep = .welcome,
        microphone: PermissionState = .notDetermined,
        accessibility: PermissionState = .notDetermined,
        hotkey: Hotkey = .suggested,
        hasDictated: Bool = false
    ) {
        self.step = step
        self.microphone = microphone
        self.accessibility = accessibility
        self.hotkey = hotkey
        self.hasDictated = hasDictated
    }

    // MARK: - What the user may do next

    /// The microphone is the one hard gate in the whole flow.
    ///
    /// Orate is a dictation app and there is no version of it that works without hearing
    /// anything, so letting someone walk past this step would only move the failure to a
    /// later screen where it is harder to explain. Every other permission in this flow is
    /// optional, and the contrast is deliberate: it is what stops a required prompt from
    /// reading like the usual wall of them.
    public var canAdvance: Bool {
        switch step {
        case .microphone: microphone == .granted
        default: true
        }
    }

    /// The label on the button that moves forward.
    public var advanceTitle: String {
        switch step {
        case .welcome: "Get started"
        case .ready: "Start using Orate"
        default: "Continue"
        }
    }

    /// Whether the step offers a way past itself without doing the thing it asks for.
    ///
    /// Pasting is the only one. Accessibility is a convenience here rather than the product:
    /// refuse it and the text lands on the clipboard instead of in the document, which is a
    /// worse app but still an app. Saying so out loud, and meaning it by offering the skip,
    /// is worth more than the permission is.
    public var isSkippable: Bool {
        step == .pasting && accessibility != .granted
    }

    public var canGoBack: Bool {
        step != .welcome
    }

    // MARK: - Moving

    public mutating func advance() {
        guard canAdvance else { return }
        guard let next = OnboardingStep(rawValue: step.rawValue + 1) else { return }
        step = next
    }

    public mutating func goBack() {
        guard let previous = OnboardingStep(rawValue: step.rawValue - 1) else { return }
        step = previous
    }

    /// True when the flow is sitting on the last screen and the next move finishes it.
    public var isFinished: Bool {
        step == .ready
    }

    // MARK: - How far along

    /// Progress as a fraction, for the indicator.
    public var completion: Double {
        Double(step.rawValue) / Double(OnboardingStep.allCases.count - 1)
    }
}
