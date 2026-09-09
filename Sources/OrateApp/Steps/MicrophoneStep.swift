//
//  MicrophoneStep.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import OrateCore
import SwiftUI

/// The one permission that is not optional, and the only step that will not let the user
/// past it.
///
/// The refusal case is a different screen rather than the same screen with the button
/// greyed out, because after a denial the system prompt will never appear again and telling
/// someone to press a button that can no longer work is how support email gets written.
struct MicrophoneStep: View {

    @ObservedObject var model: OnboardingModel

    private var granted: Bool { model.flow.microphone == .granted }

    var body: some View {
        StepScaffold(
            headline: granted ? "Orate can hear you" : "Orate needs your microphone",
            lead: granted
                ? "That was the only permission it cannot work without. Everything after this is optional."
                : "It is the only thing this app cannot work without. The recording is transcribed on this Mac and then discarded."
        ) {
            VStack(alignment: .leading, spacing: Space.large) {
                HStack(spacing: Space.medium) {
                    StatusLine(
                        isSatisfied: granted,
                        text: statusText
                    )
                    Spacer()
                    controls
                }
                .well(radius: Radius.large)
                .entrance(2)

                VStack(alignment: .leading, spacing: Space.large) {
                    Point(
                        symbol: "waveform",
                        title: "Only while you hold the key",
                        detail: "Orate does not sit and listen. The microphone opens when you press the shortcut and closes the moment you let go."
                    )
                    .entrance(3)
                    Point(
                        symbol: "trash",
                        title: "The audio is not kept",
                        detail: "It is transcribed and thrown away. Nothing is written to disk and nothing is uploaded."
                    )
                    .entrance(4)
                }
            }
            .padding(.top, Space.small)
        }
    }

    private var statusText: String {
        switch model.flow.microphone {
        case .granted: "Granted. Orate can hear you."
        case .denied: "Refused. macOS will not ask again, so this has to be changed in Settings."
        case .notDetermined: "Not granted yet."
        }
    }

    @ViewBuilder
    private var controls: some View {
        switch model.flow.microphone {
        case .granted:
            EmptyView()
        case .notDetermined:
            Button("Allow microphone") {
                Task { await model.requestMicrophone() }
            }
            .buttonStyle(.primary)
        case .denied:
            Button("Open Settings") { MicrophoneAuthorization.openSystemSettings() }
                .buttonStyle(.primary)
        }
    }
}
