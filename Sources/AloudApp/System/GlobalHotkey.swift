//
//  GlobalHotkey.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import AppKit
import Carbon.HIToolbox
import Foundation

/// A shortcut that works while another application is in front.
///
/// Carbon, in 2026, and on purpose. `RegisterEventHotKey` is the only route to a system
/// wide shortcut that does **not** require the Accessibility permission. `CGEventTap` and
/// `NSEvent.addGlobalMonitorForEvents` both do, and Aloud's whole position is that
/// Accessibility is optional. Using either of those would mean the app could not hear its
/// own shortcut until the user granted the permission it promises they do not need, which
/// would quietly turn the optional permission into a required one.
///
/// It also reports releases, which the alternatives make hard, and hold to talk is nothing
/// without a release.
@MainActor
final class GlobalHotkey {

    /// Called when the key goes down and again when it comes up.
    var pressed: (() -> Void)?
    var released: (() -> Void)?

    private var reference: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var identifier = EventHotKeyID(signature: OSType(0x414C_4F44), id: 1)

    /// Registered instances, so the C callback can find its way back to Swift.
    ///
    /// Carbon hands the handler a bare context pointer and nothing else, so there has to be
    /// somewhere to look the object up. Ambit paid this same tax with `AXObserver`.
    private static var registry: [UInt32: GlobalHotkey] = [:]

    deinit {
        MainActor.assumeIsolated { unregister() }
    }

    /// Claim the shortcut. Returns false when another application already owns it, which is
    /// information the user needs rather than a failure to swallow.
    @discardableResult
    func register(_ hotkey: Hotkey) -> Bool {
        unregister()

        // Both edges. Hold to talk is nothing without the release.
        var specifications = [
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            ),
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyReleased)
            ),
        ]

        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { _, event, _ -> OSStatus in
                var received = EventHotKeyID()
                GetEventParameter(
                    event,
                    EventParamName(kEventParamDirectObject),
                    EventParamType(typeEventHotKeyID),
                    nil,
                    MemoryLayout<EventHotKeyID>.size,
                    nil,
                    &received
                )
                let kind = GetEventKind(event)

                MainActor.assumeIsolated {
                    guard let owner = GlobalHotkey.registry[received.id] else { return }
                    if kind == UInt32(kEventHotKeyPressed) {
                        owner.pressed?()
                    } else {
                        owner.released?()
                    }
                }
                return noErr
            },
            2,
            &specifications,
            nil,
            &handler
        )
        guard status == noErr else { return false }

        Self.registry[identifier.id] = self

        let registration = RegisterEventHotKey(
            UInt32(hotkey.keyCode),
            hotkey.modifiers.carbonFlags,
            identifier,
            GetEventDispatcherTarget(),
            0,
            &reference
        )
        guard registration == noErr else {
            unregister()
            return false
        }
        return true
    }

    func unregister() {
        if let reference {
            UnregisterEventHotKey(reference)
            self.reference = nil
        }
        if let handler {
            RemoveEventHandler(handler)
            self.handler = nil
        }
        Self.registry[identifier.id] = nil
    }
}

private extension Hotkey.Modifiers {
    /// Carbon's own modifier bits, which are not the ones AppKit uses.
    var carbonFlags: UInt32 {
        var flags: UInt32 = 0
        if contains(.control) { flags |= UInt32(controlKey) }
        if contains(.option) { flags |= UInt32(optionKey) }
        if contains(.shift) { flags |= UInt32(shiftKey) }
        if contains(.command) { flags |= UInt32(cmdKey) }
        return flags
    }
}
