//
//  HotkeyStep.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import SwiftUI

/// The shortcut is the whole interface, so it gets a screen.
///
/// A default is offered already chosen rather than an empty recorder waiting to be filled
/// in. An empty field on a first run is a decision handed to someone who has not used the
/// app yet and has no way to make it; the ones who care will change it here, and the rest
/// are served better by a sensible answer already in place.
struct HotkeyStep: View {

    @ObservedObject var model: OnboardingModel

    private static let alternatives: [Hotkey] = [
        .suggested,
        Hotkey(keyCode: 96, modifiers: []),
        Hotkey(keyCode: 49, modifiers: [.control, .option]),
    ]

    var body: some View {
        StepScaffold(
            headline: "Pick your shortcut",
            lead: "Hold it down, say what you want, let go. That is the entire app."
        ) {
            VStack(alignment: .leading, spacing: Space.section) {
                // The chosen key, shown large and pressed, because the thing being taught
                // here is a gesture and the picture of it is worth more than the label.
                HStack(spacing: Space.medium) {
                    KeycapRow(model.flow.hotkey, isPressed: true, scale: 1.2)
                    Text("held down")
                        .font(Type.detail)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .well(radius: Radius.large)
                .entrance(2)

                VStack(alignment: .leading, spacing: Space.small) {
                    Text("Or one of these")
                        .font(Type.caption)
                        .foregroundStyle(.secondary)

                    HStack(spacing: Space.small) {
                        ForEach(Self.alternatives, id: \.self) { candidate in
                            Button {
                                model.setHotkey(candidate)
                            } label: {
                                KeycapRow(candidate)
                                    .opacity(candidate == model.flow.hotkey ? 1 : 0.55)
                            }
                            .buttonStyle(.plain)
                            .accessibilityAddTraits(
                                candidate == model.flow.hotkey ? .isSelected : []
                            )
                        }
                    }
                }
                .entrance(3)

                Point(
                    symbol: "checkmark.shield",
                    title: "Nothing else will steal it",
                    detail: "Aloud claims the shortcut across your whole Mac, and tells you if another app got there first rather than silently doing nothing."
                )
                .entrance(4)
            }
            .padding(.top, Space.small)
        }
    }
}
