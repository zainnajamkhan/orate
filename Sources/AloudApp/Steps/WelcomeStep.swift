//
//  WelcomeStep.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import SwiftUI

/// Screen one.
///
/// Every competitor's first screen asks the user to choose a model and start a download of
/// between five hundred megabytes and three gigabytes. This one says there is nothing to
/// download, because that is the product, and it says it here rather than on a marketing
/// page because here is where the user is comparing.
struct WelcomeStep: View {

    var body: some View {
        StepScaffold(
            headline: "Talk. The words appear.",
            lead: "Anywhere you can type, you can now dictate. Setting it up takes about a minute, and most of that is one permission."
        ) {
            VStack(alignment: .leading, spacing: Space.large) {
                Point(
                    symbol: "bolt.horizontal",
                    title: "Nothing to download",
                    detail: "No model to pick, no gigabytes to wait for, no choice between fast and accurate. macOS already has the model and keeps it current."
                )
                .entrance(2)
                Point(
                    symbol: "lock.shield",
                    title: "Your voice never leaves this Mac",
                    detail: "Recognition runs on the Neural Engine. There is no account, no server, and nothing to opt out of."
                )
                .entrance(3)
                Point(
                    symbol: "text.cursor",
                    title: "It types the words you said",
                    detail: "No answering your sentence back at you, no rewriting it. Tidying up is a separate switch, and it starts off."
                )
                .entrance(4)
            }
            .padding(.top, Space.small)
        }
    }
}
