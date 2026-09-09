//
//  DesignSystem.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import SwiftUI

/// The spacing scale.
///
/// Every gap in the app comes from here. Padding chosen one value at a time is the
/// difference between a layout that was designed and one that merely happened.
public enum Space {
    public static let hair: CGFloat = 2
    public static let tight: CGFloat = 4
    public static let small: CGFloat = 8
    public static let medium: CGFloat = 12
    public static let large: CGFloat = 16
    public static let section: CGFloat = 20
    public static let page: CGFloat = 28
    /// The outer margin of a first run window, which wants more air than a settings pane.
    public static let stage: CGFloat = 40
}

/// The corner radius scale.
///
/// Ambit hardcoded 6 and 8 at the four places that needed them and the two never quite
/// agreed. Three named steps, and nesting reads correctly because an inner radius is always
/// the next one down.
public enum Radius {
    public static let small: CGFloat = 6
    public static let medium: CGFloat = 10
    public static let large: CGFloat = 14
}

/// The type scale.
///
/// Every one of these is a *text style*, never a fixed point size, so all of it grows when
/// the user turns text size up. `.system(size: 34)` looks identical on this machine and is
/// simply broken for anyone who needs larger text.
public enum Type {
    /// The one line on a screen that carries it.
    public static let display = Font.system(.largeTitle, design: .rounded, weight: .semibold)
    /// A headline on a step, which needs to outrank the lead by more than one notch or the
    /// two read as a single grey paragraph.
    public static let headline = Font.system(.title, design: .rounded, weight: .semibold)
    public static let title = Font.system(.title2, design: .rounded, weight: .medium)
    /// The sentence under a heading, in the onboarding and the help.
    public static let lead = Font.title3
    public static let heading = Font.headline
    public static let body = Font.body
    public static let detail = Font.callout
    public static let caption = Font.caption
    /// Labels that are read only when looked for.
    public static let micro = Font.caption2
    /// Anything the user could sensibly copy out.
    public static let mono = Font.system(.callout, design: .monospaced)
    /// Inside a keycap. Rounded, because that is the shape of the glyphs macOS itself
    /// draws on menu shortcuts.
    public static let keycap = Font.system(.body, design: .rounded, weight: .medium)
}

public extension Color {

    /// Aloud's own tint.
    ///
    /// An indigo rather than the system blue, so the app has an identity, and defined for
    /// both appearances rather than as one hex value. A single literal colour would be
    /// unreadable in one mode or the other. Indigo also stays out of the way of the
    /// recording red, which is the only other saturated colour this app is allowed, and a
    /// tint that fought with it would make the one signal that must never be ambiguous
    /// harder to read.
    static let aloud = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0.62, green: 0.58, blue: 0.96, alpha: 1)
            : NSColor(srgbRed: 0.33, green: 0.28, blue: 0.72, alpha: 1)
    })

    /// Live. The only saturated red in the app, reserved for the fact that the microphone
    /// is open, so that it never has to compete for meaning.
    static let aloudRecording = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 1.00, green: 0.38, blue: 0.36, alpha: 1)
            : NSColor(srgbRed: 0.83, green: 0.16, blue: 0.16, alpha: 1)
    })

    /// Behind the whole window.
    static let aloudCanvas = Color(nsColor: .windowBackgroundColor)

    /// Content that should feel like paper on top of the canvas: the transcript, the history.
    static let aloudSurface = Color(nsColor: .textBackgroundColor)

    /// A quiet fill for grouped controls and empty tracks.
    static let aloudWell = Color.primary.opacity(0.05)

    /// Hairlines. Deliberately low contrast: separators should be felt, not read.
    static let aloudEdge = Color.primary.opacity(0.09)
}

/// Motion, in one place.
///
/// Two durations rather than a value per call site. `gentle` is for anything a person is
/// looking at directly and `snap` is for state that has already happened and only needs to
/// not jump. Both are routed through `gentleAnimation` so the motion setting is honoured.
public enum Motion {
    public static let gentle = Animation.easeOut(duration: 0.22)
    public static let snap = Animation.easeOut(duration: 0.12)
}

// MARK: - Surfaces

/// A header that sits above content without shouting about it.
///
/// One flat `windowBackgroundColor` from top to bottom is what "default background" looks
/// like. Two surfaces with a hairline between them is the whole difference, and it is what
/// every Mac app that feels built does.
public struct HeaderSurface: ViewModifier {
    public func body(content: Content) -> some View {
        content
            .background(.regularMaterial)
            .overlay(alignment: .bottom) {
                Rectangle().fill(Color.aloudEdge).frame(height: 1)
            }
    }
}

/// A filled block for grouped content.
public struct Well: ViewModifier {
    let radius: CGFloat

    public func body(content: Content) -> some View {
        content
            .padding(Space.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: radius, style: .continuous).fill(Color.aloudWell))
    }
}

/// An outlined block, for content that is being shown rather than offered.
public struct Card: ViewModifier {
    let radius: CGFloat

    public func body(content: Content) -> some View {
        content
            .padding(Space.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(Color.aloudSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(Color.aloudEdge, lineWidth: 1)
            )
    }
}

public extension View {
    func headerSurface() -> some View { modifier(HeaderSurface()) }

    func well(radius: CGFloat = Radius.medium) -> some View { modifier(Well(radius: radius)) }

    func card(radius: CGFloat = Radius.medium) -> some View { modifier(Card(radius: radius)) }

    /// Respects the user's motion setting, which is a High severity accessibility rule and
    /// one line to honour.
    func gentleAnimation<V: Equatable>(_ value: V, _ animation: Animation = Motion.gentle) -> some View {
        modifier(GentleAnimation(value: value, animation: animation))
    }
}

private struct GentleAnimation<V: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: V
    let animation: Animation

    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation, value: value)
    }
}

// MARK: - Repeated pieces

/// One line of a feature list: a symbol, a claim, and the reason to believe it.
public struct Point: View {
    let symbol: String
    let title: String
    let detail: String

    public init(symbol: String, title: String, detail: String) {
        self.symbol = symbol
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HStack(alignment: .top, spacing: Space.medium) {
            Image(systemName: symbol)
                .font(Type.lead)
                .foregroundStyle(Color.aloud)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: Space.hair) {
                Text(title).font(Type.heading)
                Text(detail)
                    .font(Type.detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        // Read as one sentence by VoiceOver rather than as two unrelated fragments.
        .accessibilityElement(children: .combine)
    }
}

/// The state of one permission, said plainly.
public struct StatusLine: View {
    let isSatisfied: Bool
    let text: String

    public init(isSatisfied: Bool, text: String) {
        self.isSatisfied = isSatisfied
        self.text = text
    }

    public var body: some View {
        HStack(spacing: Space.small) {
            Image(systemName: isSatisfied ? "checkmark.circle.fill" : "circle.dashed")
                .foregroundStyle(isSatisfied ? Color.green : Color.secondary)
                .gentleAnimation(isSatisfied)
            Text(text)
                .font(Type.detail)
                .foregroundStyle(isSatisfied ? .primary : .secondary)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Brand

/// The gradients and glows that stop this looking like a settings pane.
///
/// All of them are built from `Color.aloud` rather than from fresh literals, so retinting
/// the app is one edit. Every one is defined for both appearances: a gradient tuned for
/// dark mode turns into grey mud in light mode, which is the usual way a first run window
/// ends up looking worse on half the machines it runs on.
public enum Brand {

    /// Behind the illustration pane. Deep and slightly off axis, so it reads as light
    /// falling across a surface rather than as a fill.
    public static var stage: LinearGradient {
        LinearGradient(
            colors: [
                Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                        ? NSColor(srgbRed: 0.13, green: 0.11, blue: 0.24, alpha: 1)
                        : NSColor(srgbRed: 0.36, green: 0.31, blue: 0.76, alpha: 1)
                }),
                Color(nsColor: NSColor(name: nil) { appearance in
                    appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                        ? NSColor(srgbRed: 0.07, green: 0.06, blue: 0.13, alpha: 1)
                        : NSColor(srgbRed: 0.20, green: 0.16, blue: 0.48, alpha: 1)
                }),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// The soft light behind whatever the stage is showing.
    public static var halo: RadialGradient {
        RadialGradient(
            colors: [.white.opacity(0.22), .white.opacity(0)],
            center: .center,
            startRadius: 4,
            endRadius: 190
        )
    }

    /// Fills the app mark and the primary button.
    public static var accent: LinearGradient {
        LinearGradient(
            colors: [Color.aloud, Color.aloud.opacity(0.72)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// The live one, for the waveform and anything else that is recording.
    public static var live: LinearGradient {
        LinearGradient(
            colors: [Color.aloudRecording, Color.aloudRecording.opacity(0.55)],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    /// Anything sitting on the stage is on a dark ground in both appearances, so its text
    /// is white in both. Reading these off `.primary` would make them black in light mode
    /// on top of an indigo gradient.
    public static let onStage = Color.white
    public static let onStageSecondary = Color.white.opacity(0.62)
}

/// Two shadows, so that "raised" means one thing everywhere.
public enum Elevation {
    public static let resting = Color.black.opacity(0.10)
    public static let raised = Color.black.opacity(0.22)
}

// MARK: - Entrance

/// Fades a step's content up in sequence rather than all at once.
///
/// Six screens that snap into place feel like slides. A forty millisecond stagger down the
/// page is enough to read as one thing arriving, and it is the cheapest polish in the whole
/// window. It collapses to a plain fade when the user has asked for reduced motion.
public struct Entrance: ViewModifier {

    /// Renders fully visible immediately.
    ///
    /// Offscreen rendering never fires `onAppear`, so without this every screenshot of the
    /// onboarding comes out blank and the review that was supposed to catch layout problems
    /// catches nothing.
    public nonisolated(unsafe) static var isImmediate = false

    let index: Int

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    public func body(content: Content) -> some View {
        content
            .opacity(appeared || Self.isImmediate ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 10)
            .animation(
                .easeOut(duration: 0.32).delay(Double(index) * 0.045),
                value: appeared
            )
            .onAppear { appeared = true }
    }
}

public extension View {
    /// `index` is the order down the page, starting at zero.
    func entrance(_ index: Int) -> some View { modifier(Entrance(index: index)) }
}

