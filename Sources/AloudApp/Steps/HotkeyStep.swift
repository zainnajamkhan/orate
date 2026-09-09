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
    @ObservedObject private var engine: DictationEngine

    /// How many dictations had started when this screen appeared.
    ///
    /// Anything above it means a press actually arrived.
    @State private var baseline: Int?

    init(model: OnboardingModel) {
        self.model = model
        _engine = ObservedObject(wrappedValue: model.engine)
    }

    private var wasHeard: Bool {
        guard let baseline else { return false }
        return engine.startCount > baseline
    }

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
                        ForEach(Hotkey.alternatives, id: \.self) { candidate in
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

                proof
                    .entrance(4)
            }
            .padding(.top, Space.small)
        }
        .onAppear { baseline = engine.startCount }
        .onChange(of: model.flow.hotkey) { _, _ in baseline = engine.startCount }
    }

    /// Ask the user to press it, and say whether it arrived.
    ///
    /// This exists because a shortcut can be registered successfully and still never fire.
    /// Another app running a global key monitor, Raycast being the common one, swallows the
    /// press before Aloud sees it, and the registration reports no error at all. Nothing
    /// but an actual press can tell the difference, so the user is asked for one here
    /// rather than discovering months later that the app "does not work".
    @ViewBuilder
    private var proof: some View {
        HStack(spacing: Space.medium) {
            Image(systemName: wasHeard ? "checkmark.circle.fill" : "hand.tap")
                .font(Type.lead)
                .foregroundStyle(wasHeard ? Color.green : Color.aloud)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: Space.hair) {
                Text(wasHeard ? "Aloud heard it" : "Press it now to check")
                    .font(Type.heading)
                Text(wasHeard
                    ? "The shortcut is yours. Nothing else on this Mac is taking it first."
                    : "Some apps take a shortcut before Aloud can see it. Launchers like Raycast and Alfred are the usual ones. Press yours and this will confirm it arrived.")
                    .font(Type.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .well(radius: Radius.large)
        .gentleAnimation(wasHeard)
        .accessibilityElement(children: .combine)
    }
}
