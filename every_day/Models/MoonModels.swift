//
//  MoonModels.swift
//  every_day
//

import Foundation

// MARK: - API Response Models

struct MoonAPIResponse: Codable {
    let daily: MoonDailyData
}

struct MoonDailyData: Codable {
    let time: [String]
    let moonrise: [String?]
    let moonset: [String?]
    let moonPhase: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case moonrise
        case moonset
        case moonPhase = "moon_phase"
    }
}

// MARK: - View-friendly Model

struct MoonData {
    let illumination: Int
    let phase: Double       // 0.0 – 1.0 from Open-Meteo
    let moonrise: String?
    let moonset: String?

    var phaseName: String  { MoonHelper.phaseName(for: phase) }
    var phaseSymbol: String { MoonHelper.phaseSymbol(for: phase) }
}

// MARK: - Moon Phase Helpers

enum MoonHelper {
    /// Calculates illumination % from the 0–1 phase value.
    /// Formula: 50 * (1 - cos(phase * 2π)) — exact at new/quarter/full.
    static func illumination(for phase: Double) -> Int {
        Int((50.0 * (1.0 - cos(phase * 2.0 * .pi))).rounded())
    }

    static func phaseName(for phase: Double) -> String {
        switch phase {
        case 0.00..<0.03:  return "New Moon"
        case 0.03..<0.22:  return "Waxing Crescent"
        case 0.22..<0.28:  return "First Quarter"
        case 0.28..<0.47:  return "Waxing Gibbous"
        case 0.47..<0.53:  return "Full Moon"
        case 0.53..<0.72:  return "Waning Gibbous"
        case 0.72..<0.78:  return "Last Quarter"
        case 0.78..<0.97:  return "Waning Crescent"
        default:           return "New Moon"
        }
    }

    static func phaseSymbol(for phase: Double) -> String {
        switch phase {
        case 0.00..<0.03:  return "moonphase.new.moon"
        case 0.03..<0.22:  return "moonphase.waxing.crescent"
        case 0.22..<0.28:  return "moonphase.first.quarter"
        case 0.28..<0.47:  return "moonphase.waxing.gibbous"
        case 0.47..<0.53:  return "moonphase.full.moon"
        case 0.53..<0.72:  return "moonphase.waning.gibbous"
        case 0.72..<0.78:  return "moonphase.last.quarter"
        case 0.78..<0.97:  return "moonphase.waning.crescent"
        default:           return "moonphase.new.moon"
        }
    }
}
