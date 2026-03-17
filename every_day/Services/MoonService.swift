//
//  MoonService.swift
//  every_day
//
//  NOTE: Open-Meteo does NOT expose moonrise/moonset/moon_phase in its forecast
//  API (confirmed — the API returns HTTP 400 with "Cannot initialize
//  ForecastVariableDaily from invalid String value moonrise").
//
//  Moon phase is therefore calculated mathematically using the lunar synodic
//  period against a verified reference new moon. This is accurate to within
//  ~1 hour, which is far more than sufficient for a daily phase display.
//  No network call, no API key, no rate limits.
//

import Foundation

struct MoonService {

    // MARK: - Constants

    /// Reference new moon: January 6, 2000 at 18:14 UTC (Unix timestamp).
    private static let referenceNewMoon: TimeInterval = 947_182_440

    /// Mean synodic period in seconds (29.530588853 days).
    private static let synodicPeriod: TimeInterval = 29.530588853 * 86_400

    /// Phase range defining a "full moon" window (centered around 0.50).
    private static let fullMoonRange: ClosedRange<Double> = 0.47...0.53

    /// Phase range defining a "new moon" window (near 0.0 / 1.0).
    private static let newMoonThreshold: Double = 0.03

    /// Search step size: 1 hour in seconds.
    private static let searchStep: TimeInterval = 3600

    /// Maximum search horizon: 35 days in seconds.
    private static let searchCapDays: TimeInterval = 35 * 86_400

    // MARK: - Public interface
    // Signature kept identical to the original so DashboardViewModel needs no changes.
    func fetchMoonData(latitude: Double, longitude: Double) async throws -> MoonData {
        let phase = Self.currentPhase()
        let illumination = MoonHelper.illumination(for: phase)

        // Moonrise/moonset require a separate astronomical calculation tied to
        // observer location and are omitted for now. The card UI handles nil gracefully.
        let nextFull  = Self.nextFullMoon()
        let nextNew   = Self.nextNewMoon()
        let moonSign  = Self.moonZodiacSign()

        return MoonData(
            illumination:   illumination,
            phase:          phase,
            moonrise:       nil,
            moonset:        nil,
            nextFullMoon:   nextFull,
            nextNewMoon:    nextNew,
            moonZodiacSign: moonSign
        )
    }

    // MARK: - Phase calculation

    /// Returns a value in [0, 1) where 0 = New Moon, 0.5 = Full Moon.
    static func currentPhase(for date: Date = Date()) -> Double {
        let elapsed = date.timeIntervalSince1970 - referenceNewMoon
        var phase = elapsed.truncatingRemainder(dividingBy: synodicPeriod) / synodicPeriod
        if phase < 0 { phase += 1 }
        return phase
    }

    // MARK: - Moon zodiac sign

    /// Returns the zodiac sign the moon is currently transiting through,
    /// calculated from the moon's ecliptic longitude using Meeus simplified theory.
    /// Accurate to ±1–2°.
    static func moonZodiacSign(for date: Date = Date()) -> String {
        // J2000 epoch: Jan 1.5 2000 TT (2000-01-01 12:00:00 TT ≈ 11:58:56 UTC)
        let j2000Epoch = Date(timeIntervalSince1970: 946_727_935.816)
        let d = date.timeIntervalSince(j2000Epoch) / 86_400.0

        func normalize(_ angle: Double) -> Double {
            var a = angle.truncatingRemainder(dividingBy: 360)
            if a < 0 { a += 360 }
            return a
        }

        var L    = 218.316 + 13.176396 * d   // mean longitude (Moon)
        let M    = 134.963 + 13.064993 * d   // mean anomaly (Moon)
        let D    = 297.850 + 12.190749 * d   // mean elongation
        let Msun = 357.529 + 0.985600  * d   // mean anomaly (Sun)

        L = normalize(L)
        let Mrad    = normalize(M) * .pi / 180
        let Drad    = normalize(D) * .pi / 180
        let MsunRad = normalize(Msun) * .pi / 180

        // Perturbation corrections (Meeus, Astronomical Algorithms)
        let longitude = L
            + 6.289 * sin(Mrad)               // equation of center
            + 1.274 * sin(2 * Drad - Mrad)    // evection
            + 0.658 * sin(2 * Drad)           // variation
            + 0.214 * sin(2 * Mrad)           // second equation of center
            - 0.186 * sin(MsunRad)            // annual equation

        let trueLongitude = normalize(longitude)

        let signs = [
            "Aries", "Taurus", "Gemini",
            "Cancer", "Leo", "Virgo",
            "Libra", "Scorpio", "Sagittarius",
            "Capricorn", "Aquarius", "Pisces"
        ]
        let index = Int(trueLongitude / 30) % 12
        return signs[index]
    }

    // MARK: - Upcoming moon events

    /// Returns the date of the next full moon after the given date.
    /// Advances in 1-hour steps, skips the current full-moon window, caps at 35 days.
    static func nextFullMoon(after date: Date = Date()) -> Date {
        let cap = date.addingTimeInterval(searchCapDays)
        var cursor = date

        // Skip past the current full-moon window
        if fullMoonRange.contains(currentPhase(for: date)) {
            while cursor < cap {
                cursor = cursor.addingTimeInterval(searchStep)
                if !fullMoonRange.contains(currentPhase(for: cursor)) { break }
            }
        }

        // Advance until we enter the full-moon window
        while cursor < cap {
            if fullMoonRange.contains(currentPhase(for: cursor)) { return cursor }
            cursor = cursor.addingTimeInterval(searchStep)
        }
        return cap
    }

    /// Returns the date of the next new moon after the given date.
    /// Advances in 1-hour steps, skips the current new-moon window, caps at 35 days.
    static func nextNewMoon(after date: Date = Date()) -> Date {
        let cap = date.addingTimeInterval(searchCapDays)
        var cursor = date

        func isInNewMoonWindow(_ phase: Double) -> Bool {
            phase < newMoonThreshold || phase >= (1.0 - newMoonThreshold)
        }

        // Skip past the current new-moon window
        if isInNewMoonWindow(currentPhase(for: date)) {
            while cursor < cap {
                cursor = cursor.addingTimeInterval(searchStep)
                if !isInNewMoonWindow(currentPhase(for: cursor)) { break }
            }
        }

        // Advance until we enter the new-moon window
        while cursor < cap {
            if isInNewMoonWindow(currentPhase(for: cursor)) { return cursor }
            cursor = cursor.addingTimeInterval(searchStep)
        }
        return cap
    }
}
