//
//  main.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import OrateApp
import OrateCore
import AppKit
import SwiftUI

/// Renders every onboarding screen to a PNG, in both appearances.
///
/// Written because the layout could not be reviewed any other way: `screencapture` needs
/// Screen Recording, which a command line tool does not have, and walking the flow by hand
/// means the later screens get looked at least. `ImageRenderer` draws the same views
/// offscreen with no permission at all, so every screen can be checked on every change
/// rather than only the one being worked on.
@MainActor
func render() {
    let output = URL(fileURLWithPath: CommandLine.arguments.count > 1
        ? CommandLine.arguments[1]
        : FileManager.default.currentDirectoryPath + "/shots")
    try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

    // Otherwise every screen renders at zero opacity, mid fade in.
    Entrance.isImmediate = true

    for scheme in [ColorScheme.light, .dark] {
        for step in OnboardingStep.allCases {
            let engine = DictationEngine(insertsIntoFrontmostApp: false, isPreview: true)
            let model = OnboardingModel(engine: engine, startingAt: step)
            let view = OnboardingView(model: model) {}
                .environment(\.colorScheme, scheme)

            let renderer = ImageRenderer(content: view)
            renderer.scale = 2

            guard
                let image = renderer.nsImage,
                let tiff = image.tiffRepresentation,
                let bitmap = NSBitmapImageRep(data: tiff),
                let png = bitmap.representation(using: .png, properties: [:])
            else {
                print("could not render \(step)")
                continue
            }

            let name = "\(step.rawValue)-\(step)-\(scheme == .dark ? "dark" : "light").png"
            let file = output.appendingPathComponent(name)
            try? png.write(to: file)
            print(file.path)
        }
    }
}

MainActor.assumeIsolated { render() }
