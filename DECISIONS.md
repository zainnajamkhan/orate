# Decisions

Product calls that are open, or that were made by default and deserve ratifying. Read this
before proposing a product change.

## Open, and blocking

### 1. The name has not been cleared

"Aloud" was chosen on 9 September 2026 for tone. Nobody has checked the Mac App Store, the
trademark register, or `aloud.app` and the other domains. Ambit got a naming clearance
table before a line was written and this did not.

**Until it clears, every rename is cheap:** module names, `com.zainnajamkhan.aloud`, and
one tint. After the site and the store listing exist it is not.

### 2. Developer ID, not the Mac App Store

**Made by default on 9 September 2026, and it contradicts the plan.**

Typing into another application needs the Accessibility API, which the App Store sandbox
forbids. So `App/Aloud.entitlements` has no sandbox key and the route is Developer ID,
hardened runtime and notarisation.

`04-next-bet.md` section 8 lists "App Store search: dictation, voice typing, speech to
text" as a distribution channel. **That channel is not available to this build.** The
options are:

- Accept it. Direct sales only, and comparison SEO carries the whole launch.
- Ship a second, sandboxed, clipboard only build to the store as a funnel.
- Reconsider whether clipboard only is actually good enough to be the only product.

This is the single most consequential open question and it changes the marketing site.

### 3. The free tier is capped by minutes, but how many

The plan says cap by minutes per day rather than by model quality, because capping quality
is complaint 2. It does not say how many minutes. This needs a number before `IndieKit`
licensing is wired.

### 4. The default shortcut is not what the plan wants

Competitors bind bare right Option, which needs a `CGEventTap` and therefore Accessibility,
the permission this app deliberately treats as optional. The current default is Option and
Space through the ordinary hotkey API.

**The conflict is real:** the fastest, most copied binding requires the permission whose
optionality is a selling point. Either the bare modifier is a bonus for people who grant
Accessibility, or the app ships a slightly worse default for everyone.

## Made, and settled unless something changes

| Call | Decision | Why |
|---|---|---|
| Price | $39, one payment | Matches VoiceInk and BetterDictation. Do not go below, do not subscribe. |
| Minimum system | macOS 26 | `SpeechAnalyzer` does not exist before it, and a Whisper fallback destroys the product. |
| Cleanup pass | Off by default | Complaint 3 is that the tidy up answers the sentence instead of typing it. |
| Microphone | The only hard gate in first run | There is no version of a dictation app that works without it. |
| Accessibility | Optional, clipboard fallback | Ambit was worthless without it, which is how it failed. |
| Repo visibility | Private | The wedge is that no competitor has adopted `SpeechAnalyzer` yet. A public repo before launch is a public announcement of it. One command to flip. |

## Verify before committing

- **Ten languages at launch.** Cantonese, Chinese, English, French, German, Italian,
  Japanese, Korean, Portuguese, Spanish. Asserted in the plan, never checked against the
  framework.
- **The 55% faster than MacWhisper number.** Third party benchmark, not reproduced here.
  S0 measured what actually matters instead: 0.09s to 0.16s from end of speech to finished
  text, against a 1.0s kill rule. See `KNOWLEDGE-BASE.md`.
