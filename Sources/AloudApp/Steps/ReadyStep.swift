//
//  ReadyStep.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import SwiftUI

/// The last screen, which has one job beyond congratulation: say where the app went.
///
/// Aloud has no Dock icon, so the moment this window closes a first time user has no idea
/// whether anything is still running. Naming the menu bar here, and putting the only
/// optional setting in reach, is the difference between an app that is used tomorrow and
/// one that is assumed to have quit.
struct ReadyStep: View {

    @ObservedObject var model: OnboardingModel

    var body: some View {
        StepScaffold(
            headline: "You are set up",
            lead: "Aloud lives in the menu bar from now on. It has no Dock icon and no window unless you ask for one."
        ) {
            VStack(alignment: .leading, spacing: Space.section) {
                HStack(spacing: Space.medium) {
                    Image(systemName: "waveform")
                        .font(Type.title)
                        .foregroundStyle(Color.aloud)
                    VStack(alignment: .leading, spacing: Space.hair) {
                        Text("Look for the waveform up here")
                            .font(Type.heading)
                        Text("Settings, your history of the last fifty dictations, and this guide again all live behind it.")
                            .font(Type.detail)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer()
                    KeycapRow(model.flow.hotkey)
                }
                .well(radius: Radius.large)
                .entrance(2)

                // The one setting offered during first run, and it is offered off.
                //
                // Complaint three about every competitor is that the tidy up step runs when
                // it was not wanted and answers the sentence instead of typing it. A switch
                // that starts off, explained in one line, is a cheaper answer to that than
                // any amount of prompt engineering.
                Toggle(isOn: $model.wantsCleanup) {
                    VStack(alignment: .leading, spacing: Space.hair) {
                        Text("Tidy up filler words and punctuation")
                            .font(Type.heading)
                        Text("Removes the ums and fixes commas. It never changes your meaning, and you can always see the raw text. Off unless you turn it on.")
                            .font(Type.detail)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .toggleStyle(.switch)
                .tint(Color.aloud)
                .well(radius: Radius.large)
                .entrance(3)
            }
            .padding(.top, Space.small)
        }
    }
}
