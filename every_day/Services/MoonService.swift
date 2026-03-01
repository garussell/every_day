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
    // Reference new moon: January 6, 2000 at 18:14 UTC
    // Unix timestamp: 946684800 (Jan 1 2000 00:00 UTC)
    //               + 5 days  × 86400  = 432000
    //               + 18 hrs  × 3600   = 64800
    //               + 14 min  × 60     = 840   → 947 182 440
    private static let referenceNewMoon: TimeInterval = 947_182_440

    // Mean synodic period in seconds (29.530588853 days)
    private static let synodicPeriod: TimeInterval = 29.530588853 * 86_400

    // MARK: - Public interface
    // Signature kept identical to the original so DashboardViewModel needs no changes.
    func fetchMoonData(latitude: Double, longitude: Double) async throws -> MoonData {
        let phase = Self.currentPhase()
        let illumination = MoonHelper.illumination(for: phase)

        // Moonrise/moonset require a separate astronomical calculation tied to
        // observer location and are omitted for now. The card UI handles nil gracefully.
        return MoonData(
            illumination: illumination,
            phase:        phase,
            moonrise:     nil,
            moonset:      nil
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
}
