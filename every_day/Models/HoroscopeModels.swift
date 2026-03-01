//
//  HoroscopeModels.swift
//  every_day
//

import Foundation

// MARK: - API Response Model (API Ninjas)
//
// GET https://api.api-ninjas.com/v1/horoscope?zodiac=aries   ← parameter is "zodiac"
// Header: X-Api-Key: <your key>
//
// Response (actual — docs said "zodiac" but real field is "sign"):
// {
//   "date":      "2026-02-28",
//   "sign":      "Aries",           ← real field name confirmed from live response
//   "horoscope": "Today's reading text…"
// }

struct HoroscopeAPIResponse: Codable {
    let date: String?       // optional — may not always be present
    let sign: String
    let horoscope: String
}

// MARK: - View-friendly Model

struct HoroscopeData {
    let sign: String
    let horoscope: String
}

// MARK: - Zodiac Sign Enum (unchanged)

enum ZodiacSign: String, CaseIterable, Identifiable {
    case aries       = "aries"
    case taurus      = "taurus"
    case gemini      = "gemini"
    case cancer      = "cancer"
    case leo         = "leo"
    case virgo       = "virgo"
    case libra       = "libra"
    case scorpio     = "scorpio"
    case sagittarius = "sagittarius"
    case capricorn   = "capricorn"
    case aquarius    = "aquarius"
    case pisces      = "pisces"

    var id: String { rawValue }

    var displayName: String { rawValue.capitalized }

    var glyph: String {
        switch self {
        case .aries:       return "♈"
        case .taurus:      return "♉"
        case .gemini:      return "♊"
        case .cancer:      return "♋"
        case .leo:         return "♌"
        case .virgo:       return "♍"
        case .libra:       return "♎"
        case .scorpio:     return "♏"
        case .sagittarius: return "♐"
        case .capricorn:   return "♑"
        case .aquarius:    return "♒"
        case .pisces:      return "♓"
        }
    }

    var dateRange: String {
        switch self {
        case .aries:       return "Mar 21 – Apr 19"
        case .taurus:      return "Apr 20 – May 20"
        case .gemini:      return "May 21 – Jun 20"
        case .cancer:      return "Jun 21 – Jul 22"
        case .leo:         return "Jul 23 – Aug 22"
        case .virgo:       return "Aug 23 – Sep 22"
        case .libra:       return "Sep 23 – Oct 22"
        case .scorpio:     return "Oct 23 – Nov 21"
        case .sagittarius: return "Nov 22 – Dec 21"
        case .capricorn:   return "Dec 22 – Jan 19"
        case .aquarius:    return "Jan 20 – Feb 18"
        case .pisces:      return "Feb 19 – Mar 20"
        }
    }

    var sfSymbol: String {
        switch self {
        case .aries:       return "flame.fill"
        case .taurus:      return "leaf.fill"
        case .gemini:      return "person.2.fill"
        case .cancer:      return "moon.fill"
        case .leo:         return "sun.max.fill"
        case .virgo:       return "wind"
        case .libra:       return "scale.3d"
        case .scorpio:     return "bolt.fill"
        case .sagittarius: return "arrow.up.right.circle.fill"
        case .capricorn:   return "mountain.2.fill"
        case .aquarius:    return "water.waves"
        case .pisces:      return "fish.fill"
        }
    }
}
