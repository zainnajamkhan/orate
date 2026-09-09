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

## S0: the latency number. Measured 9 September 2026

**The kill rule is passed with room to spare. Build it.**

| Speech | End of speech to finished text | Kill rule |
|---|---|---|
| 1.8s, one sentence | **0.126s** | 1.000s |
| 8.8s, two sentences | **0.155s** | 1.000s |
| 22.0s, a paragraph | **0.094s** | 1.000s |

Run it yourself:

```bash
say -o /tmp/short.aiff "can we push the meeting to Thursday"
swift run aloud-spike-latency /tmp/short.aiff
```

**How it is measured, and why it is not the obvious way.** Transcribing a whole file and
timing it would flatter the result badly. In real use the audio reaches the analyzer while
the user is still speaking, so when they let go of the key only the tail is left to do. The
spike therefore feeds the audio in at the pace it was spoken, in 0.1s chunks exactly as a
live tap would, and starts the clock at the moment the audio ends. No microphone and no
human are involved, which is deliberate: neither is needed to measure the part that was
risky.

**Three findings that change the product:**

1. **The tail does not grow with length.** Twenty two seconds of speech finished in 0.094s,
   faster than the one sentence run. Latency is a function of the last segment, not of the
   session. Complaint 4 about the competition, that accuracy and speed fall off past a few
   minutes, may not apply here at all. Worth testing at true multi minute length before
   claiming it in marketing.
2. **The first words take about a second, every time.** 1.02s to 1.03s across all three
   runs, regardless of length. So there is a fixed dead second at the start of every
   dictation where the user sees nothing happen. **The waveform in the onboarding is not
   decoration, it is the only feedback during that second.** Do not remove it.
3. **Accuracy is good.** Numbers and ordinals were normalised sensibly ("11%", "2nd"). The
   two errors in the long run, "churn" heard as "Schoen" and "shipped" as "ship", came from
   the `say` synthetic voice rather than from the model, so they are not evidence about
   real speech either way.

**Model install is a no op on this machine.** `AssetInventory.status` reported `installed`
without any download, which is the wedge working exactly as the plan claims.

## Gotchas already paid for, S0 edition

**`AVAudioFile.read` past the end throws `nilError`,** a Swift runtime error standing in for
an ObjC method that returned false with a nil error object. It says nothing about what went
wrong and cost twenty minutes. Check `file.length - file.framePosition` before reading
rather than treating a short read as end of file.

**`SpeechTranscriber.results` can only be iterated once.** Reusing one transcriber across
several files crashes with "attempt to await next() on more than one task". Build a fresh
transcriber per session, which also stops the first run warming the cache for the second.

**Progressive results supersede each other.** A later result can cover the same stretch of
audio as an earlier one. Assigning the latest result to a string keeps only the last
sentence; appending every result repeats the revised ones. Key segments by
`result.range.start` and drop anything at or after a new segment's start.

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
