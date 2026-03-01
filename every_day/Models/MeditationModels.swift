//
//  MeditationModels.swift
//  every_day
//

import Foundation
import SwiftData
import AudioToolbox

// MARK: - MeditationSession

@Model
final class MeditationSession {
    var id: UUID
    var date: Date
    var durationSeconds: Int
    var completedFully: Bool

    init(
        date: Date = .now,
        durationSeconds: Int,
        completedFully: Bool
    ) {
        self.id              = UUID()
        self.date            = date
        self.durationSeconds = durationSeconds
        self.completedFully  = completedFully
    }

    var durationMinutes: Int { durationSeconds / 60 }

    var formattedDuration: String {
        let m = durationSeconds / 60
        let s = durationSeconds % 60
        return s == 0 ? "\(m) min" : "\(m)m \(s)s"
    }
}

// MARK: - MeditationDuration

enum MeditationDuration: Int, CaseIterable, Identifiable {
    case five    = 300
    case ten     = 600
    case fifteen = 900
    case twenty  = 1200
    case thirty  = 1800

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .five:    return "5 min"
        case .ten:     return "10 min"
        case .fifteen: return "15 min"
        case .twenty:  return "20 min"
        case .thirty:  return "30 min"
        }
    }
}

// MARK: - BellSound

enum BellSound: String, CaseIterable, Identifiable {
    case silent      = "silent"
    case bell        = "bell"
    case singingBowl = "singingBowl"
    case gong        = "gong"
    case softClick   = "softClick"
    case chime       = "chime"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .silent:      return "Silent"
        case .bell:        return "Bell"
        case .singingBowl: return "Singing Bowl"
        case .gong:        return "Gong"
        case .softClick:   return "Soft Click"
        case .chime:       return "Chime"
        }
    }

    var sfSymbol: String {
        switch self {
        case .silent:      return "speaker.slash.fill"
        case .bell:        return "bell.fill"
        case .singingBowl: return "waveform"
        case .gong:        return "music.quarternote.3"
        case .softClick:   return "hand.tap.fill"
        case .chime:       return "music.note"
        }
    }

    /// System sound ID to play, or nil for silent.
    var systemSoundID: UInt32? {
        switch self {
        case .silent:      return nil
        case .bell:        return 1013
        case .singingBowl: return 1016
        case .gong:        return 1008
        case .softClick:   return 1104
        case .chime:       return 1007
        }
    }

    /// Plays a brief preview of this sound. No-ops for `.silent`.
    /// Safe to call from any screen — no external setup required.
    func preview() {
        guard let soundID = systemSoundID else { return }
        AudioServicesPlaySystemSound(soundID)
    }
}
