//
//  main.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AppKit
import SwiftUI

/// Draws the app icon and every size Xcode needs.
///
/// Rendered rather than exported from a design tool, so the icon and the mark inside the
/// app can never drift apart: both are the same five bars in the same gradient. It also
/// means the icon is in version control as code rather than as a binary nobody can edit.
///
/// The corners must be genuinely transparent. macOS does not mask an application icon for
/// you, so a squircle drawn on a grey square ships with grey corners.
struct IconArtwork: View {

    var size: CGFloat

    /// Asymmetric on purpose. An even rise and fall reads as a graphic equaliser, which is
    /// a music icon. Uneven reads as speech.
    private let heights: [CGFloat] = [0.30, 0.58, 1.0, 0.62, 0.34]

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(.sRGB, red: 0.353, green: 0.294, blue: 0.741),
                            Color(.sRGB, red: 0.231, green: 0.184, blue: 0.561),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                // A light along the top edge only. It is what stops the tile reading as a
                // flat coloured square, and it is the one piece of depth Apple's own icons
                // still use.
                .overlay {
                    RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [.white.opacity(0.28), .white.opacity(0)],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: size * 0.008
                        )
                }

            HStack(spacing: size * 0.052) {
                ForEach(Array(heights.enumerated()), id: \.offset) { _, height in
                    Capsule(style: .continuous)
                        .fill(.white)
                        .frame(width: size * 0.062, height: size * 0.46 * height)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

@MainActor
func render(size: CGFloat) -> Data? {
    let renderer = ImageRenderer(content: IconArtwork(size: size))
    renderer.scale = 1
    renderer.isOpaque = false
    guard
        let image = renderer.nsImage,
        let tiff = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiff)
    else { return nil }
    return bitmap.representation(using: .png, properties: [:])
}

@MainActor
func run() {
    let root = CommandLine.arguments.count > 1
        ? CommandLine.arguments[1]
        : FileManager.default.currentDirectoryPath + "/App/Sources/Assets.xcassets/AppIcon.appiconset"
    let output = URL(fileURLWithPath: root)
    try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

    // Every size a macOS application icon is expected to provide.
    let sizes: [(point: Int, scale: Int)] = [
        (16, 1), (16, 2), (32, 1), (32, 2), (128, 1), (128, 2),
        (256, 1), (256, 2), (512, 1), (512, 2),
    ]

    var entries: [String] = []
    for (point, scale) in sizes {
        let pixels = point * scale
        let name = "icon_\(point)x\(point)\(scale == 2 ? "@2x" : "").png"
        guard let data = render(size: CGFloat(pixels)) else {
            print("failed at \(pixels)")
            continue
        }
        try? data.write(to: output.appendingPathComponent(name))
        entries.append("""
            {
              "filename" : "\(name)",
              "idiom" : "mac",
              "scale" : "\(scale)x",
              "size" : "\(point)x\(point)"
            }
        """)
        print("\(name)  \(pixels)px")
    }

    let contents = """
    {
      "images" : [
    \(entries.joined(separator: ",\n"))
      ],
      "info" : {
        "author" : "xcode",
        "version" : 1
      }
    }
    """
    try? contents.write(
        to: output.appendingPathComponent("Contents.json"),
        atomically: true,
        encoding: .utf8
    )
    print("\nwrote \(output.path)")
}

MainActor.assumeIsolated { run() }
