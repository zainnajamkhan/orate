//
//  OnboardingView.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import SwiftUI

/// First run.
///
/// The order of these six screens is the argument the app is making, and it is not the
/// order most utilities use. Everything that costs the user something is deferred until
/// after they have watched their own speech become text: the microphone is asked for
/// because nothing works without it, the shortcut is chosen because it is the interface,
/// and only then, once the thing has been seen working, is the optional permission raised.
/// Asking for both permissions up front is how a first run turns into a checkpoint.
///
/// Two panes rather than one column. The left is the picture and the right is the argument,
/// which is the shape every first run worth copying uses, and it exists because a stack of
/// headings and bullet points is a document rather than a product.
public struct OnboardingView: View {

    @StateObject private var model: OnboardingModel
    let finish: () -> Void

    public init(model: @autoclosure @escaping () -> OnboardingModel, finish: @escaping () -> Void) {
        _model = StateObject(wrappedValue: model())
        self.finish = finish
    }

    public var body: some View {
        HStack(spacing: 0) {
            Stage(model: model, engine: model.engine)

            VStack(spacing: 0) {
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.horizontal, Space.page)
                    .padding(.top, Space.stage)
                    .padding(.bottom, Space.section)
                    // A step change is a change of subject, so it crossfades rather than
                    // sliding. Sliding implies the two screens are part of one surface.
                    .id(model.flow.step)
                    .transition(.opacity)

                footer
            }
            .frame(width: 552)
            .background(Color.aloudCanvas)
        }
        .frame(width: 900, height: 620)
        .gentleAnimation(model.flow.step)
    }

    @ViewBuilder
    private var content: some View {
        switch model.flow.step {
        case .welcome: WelcomeStep()
        case .microphone: MicrophoneStep(model: model)
        case .hotkey: HotkeyStep(model: model)
        case .tryIt: TryItStep(model: model)
        case .pasting: PastingStep(model: model)
        case .ready: ReadyStep(model: model)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: Space.small) {
            ProgressDots(current: model.flow.step)

            Spacer()

            if model.flow.canGoBack {
                Button("Back") { model.goBack() }
                    .buttonStyle(.quiet)
            }

            // Present only where refusing is a real option, so its absence on the
            // microphone step says, without a sentence, that this one is not optional.
            if model.flow.isSkippable {
                Button("Not now") { model.skip() }
                    .buttonStyle(.quiet)
            }

            Button(model.flow.advanceTitle) {
                if model.flow.isFinished {
                    finish()
                } else {
                    model.advance()
                }
            }
            .buttonStyle(.primary)
            .keyboardShortcut(.defaultAction)
            .disabled(!model.flow.canAdvance)
        }
        .padding(.horizontal, Space.page)
        .padding(.vertical, Space.large)
        .background(.regularMaterial)
        .overlay(alignment: .top) {
            Rectangle().fill(Color.aloudEdge).frame(height: 1)
        }
    }
}

/// How far along, as shape rather than as a number.
///
/// "Step 3 of 6" is a count, and the count is not what the user wants to know. The sense of
/// nearly being done is, and a widening pill says it without being read.
private struct ProgressDots: View {

    let current: OnboardingStep

    var body: some View {
        HStack(spacing: Space.small - 2) {
            ForEach(OnboardingStep.allCases, id: \.rawValue) { step in
                Capsule(style: .continuous)
                    .fill(fill(for: step))
                    .frame(width: step == current ? 20 : 6, height: 6)
            }
        }
        .gentleAnimation(current)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Step \(current.rawValue + 1) of \(OnboardingStep.allCases.count)")
    }

    private func fill(for step: OnboardingStep) -> Color {
        if step == current { return .aloud }
        // Steps already done stay tinted but faint, so the row reads as a route travelled
        // rather than as six identical marks.
        return step.rawValue < current.rawValue ? .aloud.opacity(0.35) : .secondary.opacity(0.22)
    }
}

// MARK: - Shared step layout

/// The frame every step's copy sits in.
///
/// One place decides where a headline sits and how much air is under it, which is what stops
/// six screens built on six different days from drifting apart. The entrance indices start
/// at zero here and continue through whatever the step passes in, so the whole column
/// arrives in reading order.
struct StepScaffold<Content: View>: View {

    let headline: String
    let lead: String
    @ViewBuilder let content: Content

    init(headline: String, lead: String, @ViewBuilder content: () -> Content) {
        self.headline = headline
        self.lead = lead
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Space.section) {
            VStack(alignment: .leading, spacing: Space.medium) {
                Text(headline)
                    .font(Type.headline)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(0)
                Text(lead)
                    .font(Type.lead)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .entrance(1)
            }

            content

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
