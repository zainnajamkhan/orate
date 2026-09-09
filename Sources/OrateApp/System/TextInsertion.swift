//
//  TextInsertion.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AppKit
import ApplicationServices
import Foundation

/// Getting the words into whatever the user was already writing in.
///
/// Two routes, and which one runs is the difference the whole permission story rests on.
/// With Accessibility the text is typed straight at the cursor. Without it the text goes to
/// the clipboard and the user pastes. The second is a worse app but it is still an app,
/// which is exactly what Ambit never had.
@MainActor
enum TextInsertion {

    enum Outcome: Equatable {
        /// Typed at the cursor.
        case typed
        /// Left on the clipboard for the user to paste.
        case copied
    }

    @discardableResult
    static func insert(_ text: String) -> Outcome {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return .copied }

        // Named every time, success or failure, because "it did not work" is meaningless
        // without knowing what was actually in front of the app when it tried. This is
        // what turns a report like "does not work in Xcode" into a fact rather than a
        // guess: the log says exactly what received the keystrokes.
        let target = NSWorkspace.shared.frontmostApplication?.localizedName ?? "unknown"

        guard AXIsProcessTrusted() else {
            Diagnostics.log("not trusted for Accessibility, copying instead of typing (front app: \(target))")
            copy(trimmed)
            return .copied
        }

        type(trimmed)
        Diagnostics.log("typed \(trimmed.count) characters into front app: \(target)")
        return .typed
    }

    // MARK: - Typing

    /// Synthesise the text as keystrokes.
    ///
    /// Deliberately not "put it on the clipboard and send Command V". That is the easy way
    /// and it destroys whatever the user had copied, which for anyone dictating thirty
    /// times a day means their clipboard is permanently full of their own dictation. Typing
    /// unicode directly leaves the clipboard alone.
    private static func type(_ text: String) {
        guard let source = CGEventSource(stateID: .combinedSessionState) else { return }

        // Sent in short runs because the event system truncates a long unicode payload on a
        // single event, and a dictated paragraph is comfortably long enough to hit that.
        for chunk in text.chunked(by: 16) {
            var characters = Array(chunk.utf16)

            guard
                let down = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true),
                let up = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: false)
            else { return }

            down.keyboardSetUnicodeString(stringLength: characters.count, unicodeString: &characters)
            up.keyboardSetUnicodeString(stringLength: characters.count, unicodeString: &characters)

            down.post(tap: .cgAnnotatedSessionEventTap)
            up.post(tap: .cgAnnotatedSessionEventTap)
        }
    }

    // MARK: - Clipboard

    private static func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

private extension String {
    func chunked(by size: Int) -> [String] {
        guard size > 0, !isEmpty else { return [self] }
        var result: [String] = []
        var index = startIndex
        while index < endIndex {
            let end = self.index(index, offsetBy: size, limitedBy: endIndex) ?? endIndex
            result.append(String(self[index..<end]))
            index = end
        }
        return result
    }
}
