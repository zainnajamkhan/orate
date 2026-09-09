//
//  OnboardingFlowTests.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import Foundation
import Testing
@testable import OrateCore

@Suite("Onboarding flow")
struct OnboardingFlowTests {

    @Test("The microphone step will not let the user past until it is granted")
    func microphoneGates() {
        var flow = OnboardingFlow(step: .microphone, microphone: .notDetermined)
        #expect(flow.canAdvance == false)

        flow.advance()
        #expect(flow.step == .microphone)

        flow.microphone = .granted
        #expect(flow.canAdvance)
        flow.advance()
        #expect(flow.step == .hotkey)
    }

    @Test("A refused microphone is still a wall, not a shrug")
    func deniedMicrophoneStillGates() {
        let flow = OnboardingFlow(step: .microphone, microphone: .denied)
        #expect(flow.canAdvance == false)
    }

    @Test("Every step other than the microphone lets the user through")
    func otherStepsDoNotGate() {
        for step in OnboardingStep.allCases where step != .microphone {
            let flow = OnboardingFlow(step: step, microphone: .notDetermined)
            #expect(flow.canAdvance, "\(step) should not gate")
        }
    }

    @Test("Pasting is the only step that offers a way out, and only while it is unmet")
    func onlyPastingIsSkippable() {
        for step in OnboardingStep.allCases {
            let flow = OnboardingFlow(step: step, accessibility: .notDetermined)
            #expect(flow.isSkippable == (step == .pasting), "\(step)")
        }

        let granted = OnboardingFlow(step: .pasting, accessibility: .granted)
        #expect(granted.isSkippable == false)
    }

    @Test("Back is unavailable on the first screen and available everywhere after it")
    func backAvailability() {
        #expect(OnboardingFlow(step: .welcome).canGoBack == false)
        for step in OnboardingStep.allCases where step != .welcome {
            #expect(OnboardingFlow(step: step).canGoBack, "\(step)")
        }
    }

    @Test("Advancing off the last step stays put, so the caller decides what finishing means")
    func lastStepDoesNotWrap() {
        var flow = OnboardingFlow(step: .ready)
        #expect(flow.isFinished)
        flow.advance()
        #expect(flow.step == .ready)
    }

    @Test("Going back from the first step stays put")
    func firstStepDoesNotWrap() {
        var flow = OnboardingFlow(step: .welcome)
        flow.goBack()
        #expect(flow.step == .welcome)
    }

    @Test("A full walk through reaches the end")
    func fullWalkThrough() {
        var flow = OnboardingFlow(microphone: .granted)
        var guardRail = 0
        while !flow.isFinished && guardRail < 20 {
            flow.advance()
            guardRail += 1
        }
        #expect(flow.isFinished)
        #expect(guardRail == OnboardingStep.allCases.count - 1)
    }

    @Test("Completion runs from nothing to everything")
    func completionSpansTheFlow() {
        #expect(OnboardingFlow(step: .welcome).completion == 0)
        #expect(OnboardingFlow(step: .ready).completion == 1)
    }

    @Test("The button says what it does at the ends and Continue in the middle")
    func advanceTitles() {
        #expect(OnboardingFlow(step: .welcome).advanceTitle == "Get started")
        #expect(OnboardingFlow(step: .ready).advanceTitle == "Start using Orate")
        #expect(OnboardingFlow(step: .tryIt).advanceTitle == "Continue")
    }
}

@Suite("Hotkey")
struct HotkeyTests {

    @Test("Modifiers read in the order macOS prints them")
    func modifierOrder() {
        let all: Hotkey.Modifiers = [.command, .shift, .option, .control]
        #expect(all.glyphs == ["\u{2303}", "\u{2325}", "\u{21E7}", "\u{2318}"])
    }

    @Test("The key comes last, after its modifiers")
    func keycapPartsOrder() {
        let hotkey = Hotkey(keyCode: 49, modifiers: [.control, .option])
        #expect(hotkey.keycapParts == ["\u{2303}", "\u{2325}", "Space"])
    }

    @Test("An unnamed key shows its code rather than an empty cap")
    func unknownKeyIsStillVisible() {
        #expect(Hotkey.keyName(for: 200) == "Key 200")
    }

    @Test("The suggested default avoids Raycast's Option and Space")
    func suggestedDefault() {
        #expect(Hotkey.suggested.keycapParts == ["\u{2303}", "\u{2325}", "Space"])
        // The specific collision that made this necessary: Raycast ships Option Space as
        // its default and eats the event before Orate sees it.
        #expect(Hotkey.suggested != Hotkey(keyCode: 49, modifiers: [.option]))
    }

    @Test("Every offered shortcut carries at least one modifier")
    func alternativesAreNotBareKeys() {
        for candidate in Hotkey.alternatives where candidate.keyCode != 96 {
            #expect(
                candidate.modifiers != [],
                "a bare letter key would fire while typing: \(candidate.keycapParts)"
            )
        }
    }
}

@Suite("Preferences")
struct PreferencesTests {

    @Test("A round trip through storage changes nothing")
    func roundTrip() throws {
        let original = Preferences(
            hotkey: Hotkey(keyCode: 96, modifiers: [.control, .shift]),
            cleanupEnabled: true
        )
        let restored = Preferences(decoding: original.encoded())
        #expect(restored == original)
    }

    @Test("Nothing stored yet gives the defaults")
    func missingDataIsDefaults() {
        #expect(Preferences(decoding: nil) == Preferences())
    }

    @Test("Unreadable storage falls back rather than leaving no shortcut at all")
    func corruptDataIsDefaults() {
        let rubbish = Data([0x00, 0x01, 0x02, 0xFF])
        let recovered = Preferences(decoding: rubbish)
        #expect(recovered == Preferences())
        // The point of the fallback: there is always a working shortcut.
        #expect(recovered.hotkey == .suggested)
    }

    @Test("Cleanup is off unless the user turns it on")
    func cleanupDefaultsOff() {
        #expect(Preferences().cleanupEnabled == false)
        #expect(Preferences(decoding: nil).cleanupEnabled == false)
    }
}

@Suite("Speech language fallback")
struct SpeechLanguageTests {

    /// The thirty macOS 26 actually supports, as read off the framework on 9 Sept 2026.
    static let supported = [
        "de-AT", "de-CH", "de-DE", "en-AU", "en-CA", "en-GB", "en-IE", "en-IN", "en-NZ",
        "en-SG", "en-US", "en-ZA", "es-CL", "es-ES", "es-MX", "es-US", "fr-BE", "fr-CA",
        "fr-CH", "fr-FR", "it-CH", "it-IT", "ja-JP", "ko-KR", "pt-BR", "pt-PT", "yue-CN",
        "zh-CN",
    ].map { Locale(identifier: $0) }

    private func best(_ identifier: String) -> String? {
        SpeechLanguage.best(for: Locale(identifier: identifier), from: Self.supported)?
            .identifier(.bcp47)
    }

    @Test("A supported region is used as it is")
    func exactMatchWins() {
        #expect(best("en_GB") == "en-GB")
        #expect(best("ja_JP") == "ja-JP")
    }

    @Test("English (Pakistan) falls back rather than failing")
    func theBugThatStartedThis() {
        // This exact locale gave a dead app that failed instantly with no visible reason.
        #expect(best("en_PK") == "en-IN")
    }

    @Test("South Asian and Gulf English go to Indian English, not American")
    func southAsianEnglish() {
        for region in ["PK", "BD", "LK", "NP", "AE", "QA", "SA"] {
            #expect(best("en_\(region)") == "en-IN", "en_\(region)")
        }
    }

    @Test("West African and European English go to British English")
    func britishLeaningEnglish() {
        for region in ["NG", "GH", "NL", "DE", "PL"] {
            #expect(best("en_\(region)") == "en-GB", "en_\(region)")
        }
    }

    @Test("An unlisted region with no neighbour gets the language's usual default")
    func unlistedRegionFallsBackToDefault() {
        #expect(best("en_BS") == "en-US")
        #expect(best("es_AR") == "es-ES")
        #expect(best("fr_SN") == "fr-FR")
        #expect(best("pt_AO") == "pt-PT")
    }

    @Test("An unsupported language is a real failure and says so")
    func unsupportedLanguageIsNil() {
        #expect(best("ur_PK") == nil)
        #expect(best("ar_AE") == nil)
        #expect(best("hi_IN") == nil)
    }

    @Test("Every supported locale resolves to itself")
    func everySupportedLocaleIsStable() {
        for locale in Self.supported {
            let resolved = SpeechLanguage.best(for: locale, from: Self.supported)
            #expect(resolved?.identifier(.bcp47) == locale.identifier(.bcp47))
        }
    }
}
