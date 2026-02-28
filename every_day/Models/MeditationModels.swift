//
//  MeditationModels.swift
//  every_day
//

import Foundation
import SwiftData

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
