//
//  HoroscopeCache.swift
//  every_day
//
//  Persists the daily horoscope to UserDefaults so the API is only called
//  once per sign per calendar day.  Caching is keyed per zodiac sign so
//  switching signs correctly fetches a fresh reading for the new sign.
//
//  UserDefaults keys (one pair per sign):
//    horoscope_text_<sign>   — the cached horoscope string
//    horoscope_date_<sign>   — the date it was cached  (yyyy-MM-dd, local TZ)
//

import Foundation

enum HoroscopeCache {

    // MARK: - Keys

    private static func textKey(for sign: ZodiacSign) -> String {
        "horoscope_text_\(sign.rawValue)"
    }

    private static func dateKey(for sign: ZodiacSign) -> String {
        "horoscope_date_\(sign.rawValue)"
    }

    // MARK: - Date Helpers

    /// Today's date as a "yyyy-MM-dd" string in the device's local timezone.
    private static var todayString: String {
        let f = DateFormatter()
        f.locale     = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: .now)
    }

    // MARK: - Public API

    /// Returns the cached horoscope text if it was stored **today**.
    /// Returns `nil` if the cache is missing or from a previous day.
    static func cachedToday(for sign: ZodiacSign) -> String? {
        let defaults = UserDefaults.standard
        guard
            let storedDate = defaults.string(forKey: dateKey(for: sign)),
            storedDate == todayString,
            let text = defaults.string(forKey: textKey(for: sign))
        else { return nil }
        return text
    }

    /// Returns any cached horoscope text for the sign, regardless of date.
    /// Used as a stale fallback when the API call fails.
    static func staleCached(for sign: ZodiacSign) -> String? {
        UserDefaults.standard.string(forKey: textKey(for: sign))
    }

    /// Writes the horoscope text to UserDefaults, tagged with today's date.
    static func store(_ horoscope: String, for sign: ZodiacSign) {
        let defaults = UserDefaults.standard
        defaults.set(horoscope,   forKey: textKey(for: sign))
        defaults.set(todayString, forKey: dateKey(for: sign))
    }

    /// Removes all cached data for a sign, forcing a fresh API call on next fetch.
    static func clearCache(for sign: ZodiacSign) {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: textKey(for: sign))
        defaults.removeObject(forKey: dateKey(for: sign))
    }

    /// Removes cached data for every zodiac sign.
    static func clearAllCaches() {
        ZodiacSign.allCases.forEach { clearCache(for: $0) }
    }
}
