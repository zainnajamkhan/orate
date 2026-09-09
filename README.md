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
- `PreviewDictationSource` survives for screenshots and for looking at the flow without a
  microphone. It is no longer what the app runs.
- Not started: `SpeechAnalyzer`, the global hotkey
  recorder, pasting into the frontmost app, history, vocabulary, licensing, the app icon.

## S0 passed

**0.09s to 0.16s from the end of speech to the finished text, against a 1.0s kill rule.**
Measured 9 September 2026 on macOS 26.6.2. Details and method in `KNOWLEDGE-BASE.md`.

```bash
say -o /tmp/short.aiff "can we push the meeting to Thursday"
swift run aloud-spike-latency /tmp/short.aiff
```

## S1 built, not yet proven by a human

Hold the shortcut, talk, let go, and the words are typed where your cursor is. Built and
compiling; **nobody has spoken into it yet.** That test needs a person and a microphone.

- `GlobalHotkey` uses Carbon `RegisterEventHotKey`, which is the only system wide shortcut
  API that does **not** need Accessibility. Anything else would make the optional
  permission mandatory in practice.
- `AudioCapture` opens the microphone on press and closes it on release. Not an always on
  engine with a gate, so the recording indicator is honest.
- `TextInsertion` types unicode key events rather than pasting, so your clipboard survives.
  Without Accessibility it falls back to the clipboard and says so.
- The onboarding try step now drives the real engine, not the canned one.

## Next

**Test S1 by hand.** Then S2: cancel with Escape, a history of the last fifty dictations,
and per app preferences.

Still blocking a release: the $99 Apple Developer membership is unpaid, and the name has
not been cleared. See `DECISIONS.md`.

## Run it

```bash
open Aloud.xcodeproj                 # the real app, menu bar and all
swift run aloud-onboarding-preview   # just the first run flow
```

Distribution is Developer ID and notarisation, not the Mac App Store: typing into another
app needs the Accessibility API, which the sandbox forbids.
