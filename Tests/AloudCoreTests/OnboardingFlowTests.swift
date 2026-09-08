//
//  OnboardingFlowTests.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import Testing
@testable import AloudCore

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
        #expect(OnboardingFlow(step: .ready).advanceTitle == "Start using Aloud")
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

    @Test("The suggested default is Option and Space")
    func suggestedDefault() {
        #expect(Hotkey.suggested.keycapParts == ["\u{2325}", "Space"])
    }
}
