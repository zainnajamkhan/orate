//
//  PastingStep.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import OrateCore
import SwiftUI

/// The optional permission, asked for last and on purpose.
///
/// Accessibility is the one macOS users are most suspicious of, and rightly. Asking for it
/// on screen two, before anything has been shown to work, is what makes people quit an
/// installer. Asking for it here, after they have watched their own sentence appear, turns
/// it into a small upgrade to something they already have rather than a toll on the way in.
///
/// The fallback is real and is stated as such: refuse this and the text goes to the
/// clipboard. That is a genuinely worse app and saying so is what makes the offer credible.
struct PastingStep: View {

    @ObservedObject var model: OnboardingModel

    private var granted: Bool { model.flow.accessibility == .granted }

    var body: some View {
        StepScaffold(
            headline: granted ? "It will type straight into your apps" : "One optional extra",
            lead: granted
                ? "Dictated text now goes to the cursor in whatever window you are in, and your clipboard is left alone."
                : "Orate can put the text straight where your cursor is. Without this it copies to the clipboard instead and you paste it yourself."
        ) {
            VStack(alignment: .leading, spacing: Space.large) {
                HStack(spacing: Space.medium) {
                    StatusLine(isSatisfied: granted, text: statusText)
                    Spacer()
                    if !granted {
                        Button("Allow") { model.requestAccessibility() }
                            .buttonStyle(.primary)
                        Button("Open Settings") { AccessibilityAuthorization.openSystemSettings() }
                            .buttonStyle(.quiet)
                    }
                }
                .well(radius: Radius.large)
                .entrance(2)

                // Both outcomes, side by side, so the choice is a comparison rather than a
                // yes or no with an unstated cost.
                HStack(alignment: .top, spacing: Space.medium) {
                    Outcome(
                        symbol: "text.cursor",
                        title: "With it",
                        detail: "The words appear at your cursor, in the app you were already using.",
                        isPreferred: true
                    )
                    Outcome(
                        symbol: "doc.on.clipboard",
                        title: "Without it",
                        detail: "The words go to your clipboard and you press Command V.",
                        isPreferred: false
                    )
                }
                .entrance(3)

                Text("Orate only ever writes. It does not read the contents of your screen or your other windows.")
                    .font(Type.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(4)
            }
            .padding(.top, Space.small)
        }
    }

    private var statusText: String {
        granted ? "Granted. Orate can type for you." : "Not granted. Orate will use the clipboard."
    }
}

private struct Outcome: View {

    let symbol: String
    let title: String
    let detail: String
    let isPreferred: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Space.small) {
            Image(systemName: symbol)
                .font(Type.title)
                .foregroundStyle(isPreferred ? Color.orate : Color.secondary)
            Text(title).font(Type.heading)
            Text(detail)
                .font(Type.detail)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Space.large)
        .background(
            RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                .fill(isPreferred ? Color.orate.opacity(0.08) : Color.orateWell)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.large, style: .continuous)
                .strokeBorder(
                    isPreferred ? Color.orate.opacity(0.28) : Color.clear,
                    lineWidth: 1
                )
        )
        .accessibilityElement(children: .combine)
    }
}
