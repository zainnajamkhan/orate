// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Orate",
    // macOS 26 is the floor because SpeechAnalyzer does not exist before it, and
    // SpeechAnalyzer is the entire wedge. Shipping a Whisper fallback for older systems
    // would reintroduce the model download that this app exists to remove.
    platforms: [.macOS("26.0")],
    products: [
        .library(name: "OrateCore", targets: ["OrateCore"]),
        .library(name: "OrateApp", targets: ["OrateApp"]),
        // A window with the onboarding in it and nothing else, so the flow can be looked
        // at without the rest of the app existing. Not shipped.
        .executable(name: "orate-onboarding-preview", targets: ["orate-onboarding-preview"]),
        // S0. Measures the one number the whole product is gated on.
        .executable(name: "orate-spike-latency", targets: ["orate-spike-latency"]),
        // Renders every onboarding screen to a PNG so the layout can be reviewed.
        .executable(name: "orate-shots", targets: ["orate-shots"]),
        // Draws the app icon at every size Xcode needs.
        .executable(name: "orate-icon", targets: ["orate-icon"]),
    ],
    targets: [
        // Pure logic. No system frameworks, no I/O, no clock reads, so the whole
        // onboarding flow can be driven from a test without a screen or a microphone.
        .target(
            name: "OrateCore",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),

        // The design system, the onboarding, and the thin system edge the onboarding
        // needs. A library rather than an executable so the Xcode application target can
        // link it once it exists, which is where signing and entitlements will live.
        .target(
            name: "OrateApp",
            dependencies: ["OrateCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        .executableTarget(
            name: "orate-onboarding-preview",
            dependencies: ["OrateApp", "OrateCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        .executableTarget(
            name: "orate-icon",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        .executableTarget(
            name: "orate-shots",
            dependencies: ["OrateApp", "OrateCore"],
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        .executableTarget(
            name: "orate-spike-latency",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),

        .testTarget(
            name: "OrateCoreTests",
            dependencies: ["OrateCore"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
