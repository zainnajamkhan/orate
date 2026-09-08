# Aloud

Dictation for macOS. Hold a key, talk, the words appear in whatever app you were already
in. One payment, everything on device, nothing to download and nothing to configure.

App 4 of the portfolio. Plan: `../mac-apps/04-next-bet.md`. Portfolio:
`../mac-apps/README.md`.

## The one sentence

*The dictation app with nothing to set up.* Every competitor's first screen asks the user
to choose a model and download between 500MB and 3GB. Aloud uses `SpeechAnalyzer`, which
macOS 26 ships and maintains, so there is nothing to choose and nothing to wait for. That
is the entire wedge and it is temporary: it closes the moment a competitor adopts the same
framework.

## How we work

The skill `build-macos-apps` governs this project, as it does Ambit. The parts that apply
on every turn, restated because a skill body only loads when it is invoked:

**The user is the product owner. Claude is the developer.** The user describes what they
want and judges whether the result is acceptable. Claude implements, verifies, reports.

1. **Prove, don't promise.** Run `./Tools/test.sh`. Launch the thing and look at it.
2. **Tests for correctness, eyes for quality.** Logic gets a test. Anything visual gets
   launched and looked at by the user.
3. **Report outcomes, not code.**
4. **Small steps, always verified.** Change, verify, report, next.
5. **Ask before, not after.**
6. **Always leave it working.**

**Claude runs the builds on this project.** This overrides the standing
`user-builds-not-claude` preference, which is scoped to the day job repositories.

## Commands

```bash
./Tools/test.sh                            # build, test, lint. The one command.
open Aloud.xcodeproj                       # debug and run the real app (scheme "Aloud", shared)
xcodebuild -project Aloud.xcodeproj -scheme Aloud build
swift run aloud-onboarding-preview         # the first run flow on its own, no app around it
```

## Layout

| Target | What it is |
|---|---|
| `AloudCore` | Pure logic. No system frameworks, no I/O, no clock reads. Swift 6 language mode. |
| `AloudApp` | Design system, onboarding, and the thin system edge it needs. A library, so the Xcode application target can link it once signing and entitlements exist. |
| `aloud-onboarding-preview` | Opens the onboarding with nothing around it. Not shipped, not signed. |
| `Aloud.xcodeproj` | The shippable app. Thin: an `AppDelegate` in `App/Sources` plus the Info.plist and entitlements, linking the two package products. It exists because signing, entitlements and notarisation cannot live in a Swift package. |

## Rules that are easy to get wrong

- **`AloudCore` stays pure.** The onboarding's gating rules live there so they can be
  tested without a screen or a microphone. Anything touching AVFoundation, Accessibility
  or Speech belongs in `AloudApp/System`.
- **The microphone is the only hard gate.** Everything else in first run is skippable, and
  that contrast is the point. Accessibility is a convenience: refuse it and the text goes
  to the clipboard. Ambit failed partly because it was worthless without Accessibility.
- **Cleanup stays off by default.** The most repeated complaint about Superwhisper is that
  the tidy up step answers the sentence instead of typing it. A switch that starts off is
  the answer, and it must never rewrite meaning.
- **No model in the bundle, ever.** If something makes you want to ship a Whisper file,
  the product has stopped being the product.
- **Design from Apple's Human Interface Guidelines.** Native AppKit and SwiftUI idiom. The
  first run window is the one place allowed a little more than stock controls, because it is
  the only screen a person looks at rather than through.
- **Not sandboxed, and that is deliberate.** Typing into another app needs the
  Accessibility API, which the App Store sandbox forbids. Distribution is Developer ID,
  hardened runtime and notarisation. A Mac App Store build would have to be a separate,
  clipboard only product, and that trade should be made on purpose rather than discovered
  during App Review.
- **Launch with `open`, never the bare binary,** once there is a signed app. A binary
  started from the shell inherits the Terminal's permissions and proves nothing.

## Style

Six line header on every file, matching Quiet and Ambit:

```swift
//
//  FileName.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//
```

Doc comments explain **why**, in full sentences, not what the code already says. No force
unwraps. Private stored properties unless something outside needs them. No dashes in prose.
