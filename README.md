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
- Measured: S0 passed. `aloud-spike-latency` runs real `SpeechTranscriber` transcription
  against a paced audio file.
- Stubbed: `PreviewDictationSource` types a fixed sentence so the onboarding try step can
  be looked at. It is not transcription, and S1 replaces it with the real engine.
- Not started: live audio capture, `SpeechAnalyzer`, the global hotkey
  recorder, pasting into the frontmost app, history, vocabulary, licensing, the app icon.

## S0 passed

**0.09s to 0.16s from the end of speech to the finished text, against a 1.0s kill rule.**
Measured 9 September 2026 on macOS 26.6.2. Details and method in `KNOWLEDGE-BASE.md`.

```bash
say -o /tmp/short.aiff "can we push the meeting to Thursday"
swift run aloud-spike-latency /tmp/short.aiff
```

## Next

**S1, the loop.** Global hotkey, live microphone capture, transcribe, paste into the
frontmost app, clipboard fallback when Accessibility is refused.

Still blocking a release: the $99 Apple Developer membership is unpaid, and the name has
not been cleared. See `DECISIONS.md`.

## Run it

```bash
open Aloud.xcodeproj                 # the real app, menu bar and all
swift run aloud-onboarding-preview   # just the first run flow
```

Distribution is Developer ID and notarisation, not the Mac App Store: typing into another
app needs the Accessibility API, which the sandbox forbids.
