//
//  PreferencesStore.swift
//  Aloud
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import AloudCore
import Combine
import Foundation

/// The user's choices, kept between launches.
///
/// One store, shared, because the onboarding writes to it and the shortcut reads from it.
/// Without this the shortcut chosen during first run was written to a struct the onboarding
/// owned and then thrown away, so the app went on listening for the default while the
/// welcome screen showed a different key. That is worse than the feature being missing.
@MainActor
public final class PreferencesStore: ObservableObject {

    public static let shared = PreferencesStore()

    private static let key = "aloud.preferences"

    @Published public var preferences: Preferences {
        didSet {
            guard preferences != oldValue else { return }
            defaults.set(preferences.encoded(), forKey: Self.key)
        }
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.preferences = Preferences(decoding: defaults.data(forKey: Self.key))
    }

    public var hotkey: Hotkey {
        get { preferences.hotkey }
        set { preferences.hotkey = newValue }
    }

    public var cleanupEnabled: Bool {
        get { preferences.cleanupEnabled }
        set { preferences.cleanupEnabled = newValue }
    }
}
