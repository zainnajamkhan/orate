// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Aloud",
    // macOS 26 is the floor because SpeechAnalyzer does not exist before it, and
    // SpeechAnalyzer is the entire wedge. Shipping a Whisper fallback for older systems
    // would reintroduce the model download that this app exists to remove.
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "AloudCore", targets: ["AloudCore"]),
        .library(name: "AloudApp", targets: ["AloudApp"]),
        // A window with the onboarding in it and nothing else, so the flow can be looked
        // at without the rest of the app existing. Not shipped.
        .executable(name: "aloud-onboarding-preview", targets: ["aloud-onboarding-preview"]),
    ],
    targets: [
        // Pure logic. No system frameworks, no I/O, no clock reads, so the whole
        // onboarding flow can be driven from a test without a screen or a microphone.
        .target(
            name: "AloudCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),

        // The design system, the onboarding, and the thin system edge the onboarding
        // needs. A library rather than an executable so the Xcode application target can
        // link it once it exists, which is where signing and entitlements will live.
        .target(
            name: "AloudApp",
            dependencies: ["AloudCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        .executableTarget(
            name: "aloud-onboarding-preview",
            dependencies: ["AloudApp", "AloudCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        .testTarget(
            name: "AloudCoreTests",
            dependencies: ["AloudCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
