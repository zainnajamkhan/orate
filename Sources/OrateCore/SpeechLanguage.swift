//
//  SpeechLanguage.swift
//  Orate
//
//  Created by Zain Najam on 09/09/2026.
//  Copyright © 2026 Zain Najam. All rights reserved.
//

import Foundation

/// Choosing which language to transcribe in.
///
/// macOS supports thirty locales, and a Mac set to any other one is not a rare edge case:
/// English alone is the everyday language of Pakistan, Nigeria, Bangladesh, Kenya, the UAE
/// and a dozen more countries that are not on the list. Demanding an exact match, which is
/// what the first version did, gave every one of those users an app that started and failed
/// instantly with no visible reason.
///
/// So an unsupported region falls back to the nearest supported one in the same language
/// rather than refusing. Kept here in the pure module because it is a decision worth
/// testing, and testing it needs no speech framework at all.
public enum SpeechLanguage {

    /// The best supported locale for someone whose Mac is set to `preferred`.
    ///
    /// Returns nil only when the language itself is unsupported, which is a real failure
    /// worth telling the user about, as opposed to an unlisted region, which is not.
    public static func best(
        for preferred: Locale,
        from supported: [Locale]
    ) -> Locale? {
        let wanted = preferred.identifier(.bcp47).lowercased()

        // The region is supported outright.
        if let exact = supported.first(where: { $0.identifier(.bcp47).lowercased() == wanted }) {
            return exact
        }

        guard let language = preferred.language.languageCode?.identifier.lowercased() else {
            return nil
        }
        let sameLanguage = supported.filter {
            $0.language.languageCode?.identifier.lowercased() == language
        }
        guard !sameLanguage.isEmpty else { return nil }

        // A neighbour, where one is a genuinely better acoustic match than the language's
        // headline region. South Asian English is much closer to Indian English than to
        // American, and someone in Karachi being transcribed as though they were in
        // California is the difference between the app working and the app being wrong
        // about every third word.
        if let region = preferred.region?.identifier.uppercased(),
           let neighbour = neighbours[region],
           let match = sameLanguage.first(where: {
               $0.identifier(.bcp47).lowercased() == neighbour.lowercased()
           }) {
            return match
        }

        // Otherwise the language's usual default.
        if let usual = defaults[language],
           let match = sameLanguage.first(where: {
               $0.identifier(.bcp47).lowercased() == usual.lowercased()
           }) {
            return match
        }

        return sameLanguage.sorted { $0.identifier < $1.identifier }.first
    }

    /// Regions whose nearest supported accent is not the language's headline region.
    private static let neighbours: [String: String] = [
        // South Asia and the Gulf, where Indian English is the closest supported model.
        "PK": "en-IN",
        "BD": "en-IN",
        "LK": "en-IN",
        "NP": "en-IN",
        "AE": "en-IN",
        "QA": "en-IN",
        "SA": "en-IN",
        "KW": "en-IN",
        "BH": "en-IN",
        "OM": "en-IN",
        // Africa and the Caribbean, closer to British or South African English.
        "NG": "en-GB",
        "GH": "en-GB",
        "KE": "en-ZA",
        "TZ": "en-ZA",
        "UG": "en-ZA",
        "ZW": "en-ZA",
        "JM": "en-GB",
        "TT": "en-GB",
        "MT": "en-GB",
        // European English speakers, who mostly learned the British variety.
        "NL": "en-GB",
        "DE": "en-GB",
        "FR": "en-GB",
        "SE": "en-GB",
        "NO": "en-GB",
        "DK": "en-GB",
        "PL": "en-GB",
    ]

    /// The headline region for each language.
    private static let defaults: [String: String] = [
        "en": "en-US",
        "es": "es-ES",
        "fr": "fr-FR",
        "de": "de-DE",
        "it": "it-IT",
        "pt": "pt-PT",
        "ja": "ja-JP",
        "ko": "ko-KR",
        "zh": "zh-CN",
        "yue": "yue-CN",
    ]
}
