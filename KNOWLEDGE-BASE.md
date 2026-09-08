# Knowledge base

Findings, so they are not re-derived. Add to this rather than rediscovering.

## Toolchain, as of 9 September 2026

| | |
|---|---|
| macOS | 26.6.2 (25G83) |
| Swift | 6.3 (swiftlang-6.3.0.123.5) |
| Xcode | 26.4 (17E192) |

`SpeechAnalyzer` and Foundation Models are both available on this machine, so S0 has no
prerequisite beyond writing it.

## The Xcode project

**It uses `PBXFileSystemSynchronizedRootGroup`,** pointed at `App/Sources`. New Swift files
dropped in that folder are compiled with no `pbxproj` edit and no target membership step.
This is the Xcode 16 and later folder sync, and it is why the `project.pbxproj` is 250
lines rather than thousands.

The object identifiers are hand written sequential hex rather than Xcode's random ones,
copied from Ambit. That is deliberate: the file stays readable and diffable.

`App/Info.plist` and `App/Aloud.entitlements` sit **outside** the synchronized folder on
purpose. Inside it they would be copied into the bundle as resources as well as being
consumed by the build settings.

Build settings that matter:

- `GENERATE_INFOPLIST_FILE = NO` with an explicit `INFOPLIST_FILE`. The generated plist
  cannot express `LSUIElement` and the usage strings cleanly.
- Debug signs with `CODE_SIGN_IDENTITY = "-"` (ad hoc) so it builds with no membership.
  Release is `Developer ID Application` and will fail until the $99 is paid.

## Gotchas already paid for

**Default arguments are evaluated outside the actor.** `static func present(source:
DictationTrialSource = PreviewDictationSource())` fails to compile, because the default is
constructed in a nonisolated context while the type is `@MainActor`. Take an optional and
build it inside the body instead.

**`NSApplicationDelegate` needs `@MainActor` on the class,** not just on the methods, or
every `@objc` action is a nonisolated call into main actor code.

**Size the window before centring it.** `NSWindow(contentRect: .zero)` has no size until
the hosting view is measured, so `center()` before `setContentSize(hosting.fittingSize)`
leaves the window jammed into a corner. Inherited from Ambit, which paid for it first.

**Hardened runtime needs `com.apple.security.device.audio-input`** for the microphone even
though the app is not sandboxed. Without it the process is killed on first audio access
rather than being denied politely.

**`screencapture` from the CLI needs Screen Recording,** which this terminal does not have.
Visual verification is the user's job; do not claim to have looked at something.

## The sandbox wall

The Accessibility API is not available to a sandboxed application. That is not a
configuration problem or a missing entitlement, it is the design of the sandbox. Any plan
that involves both the Mac App Store and typing into a third party window is dead on
arrival. See `DECISIONS.md`.

## Naming clearance

**Not done.** Ambit had a table here before any code was written. Aloud does not. Fill in
before the marketing site exists:

| Check | Status |
|---|---|
| Mac App Store search | not checked |
| USPTO / EUIPO word mark | not checked |
| `aloud.app`, `getaloud.com` | not checked |
| GitHub / npm collision | not checked |
| Existing macOS app called Aloud | not checked |
