# Aloud

Hold a key, talk, and the words appear wherever your cursor already is.

On device, one payment, no account, no server. Nothing to download and nothing to
configure, because macOS 26 supplies and maintains the speech model.

## State

**Scaffolded, 9 September 2026.** Design system and first run onboarding built and
passing. The transcription engine is not written yet.

- Built: `AloudCore` flow logic, `AloudApp` design system, the six step onboarding across
  two panes with an illustrated stage, microphone and Accessibility permission wrappers,
  the preview harness, and `Aloud.xcodeproj` producing a signed menu bar `Aloud.app`.
  14 tests.
- Stubbed: `PreviewDictationSource` types a fixed sentence so the try step can be looked
  at. It is not transcription and it is the first thing deleted in S0.
- Not started: S0 latency spike, audio capture, `SpeechAnalyzer`, the global hotkey
  recorder, pasting into the frontmost app, history, vocabulary, licensing, the app icon.

## Next

**S0, the latency spike.** Hold a hotkey, record, transcribe with `SpeechTranscriber`,
print to the console, and measure key release to text. Kill rule: if it is above one
second for a short sentence, stop and reconsider. Nothing else should be built until that
number is known.

Blocking everything downstream: the $99 Apple Developer membership is unpaid.

## Run it

```bash
open Aloud.xcodeproj                 # the real app, menu bar and all
swift run aloud-onboarding-preview   # just the first run flow
```

Distribution is Developer ID and notarisation, not the Mac App Store: typing into another
app needs the Accessibility API, which the sandbox forbids.
