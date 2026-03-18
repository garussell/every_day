//
//  JournalModels.swift
//  every_day
//

import Foundation
import SwiftUI
import SwiftData

// MARK: - JournalEntryType

enum JournalEntryType: String, CaseIterable {
    case dream   = "dream"
    case mood    = "mood"
    case general = "general"

    var label: String {
        switch self {
        case .dream:   return "Dream"
        case .mood:    return "Mood"
        case .general: return "General"
        }
    }

    var icon: String {
        switch self {
        case .dream:   return "moon.fill"
        case .mood:    return "heart.fill"
        case .general: return "pencil"
        }
    }

    /// Accent color for each entry type.
    var color: Color {
        switch self {
        case .dream:   return Color(red: 0.55, green: 0.45, blue: 0.85)  // deep purple/indigo
        case .mood:    return Color(red: 0.95, green: 0.50, blue: 0.60)  // coral/pink
        case .general: return Color(red: 0.35, green: 0.75, blue: 0.65)  // teal/seafoam
        }
    }
}

// MARK: - MoodQuadrant

enum MoodQuadrant: String, CaseIterable {
    case red
    case yellow
    case blue
    case green

    var color: Color {
        switch self {
        case .red:    return Color(red: 0.85, green: 0.25, blue: 0.25)
        case .yellow: return Color(red: 0.95, green: 0.80, blue: 0.20)
        case .blue:   return Color(red: 0.25, green: 0.45, blue: 0.85)
        case .green:  return Color(red: 0.25, green: 0.72, blue: 0.45)
        }
    }

    var title: String {
        switch self {
        case .red:    return "Red Zone"
        case .yellow: return "Yellow Zone"
        case .blue:   return "Blue Zone"
        case .green:  return "Green Zone"
        }
    }

    var energyLabel: String {
        switch self {
        case .red, .yellow: return "High Energy"
        case .blue, .green: return "Low Energy"
        }
    }

    var pleasantnessLabel: String {
        switch self {
        case .red, .blue:    return "Unpleasant"
        case .yellow, .green: return "Pleasant"
        }
    }

    var sfSymbol: String {
        switch self {
        case .red:    return "flame.fill"
        case .yellow: return "sun.max.fill"
        case .blue:   return "cloud.fill"
        case .green:  return "leaf.fill"
        }
    }

    /// Mood score on a 1–5 scale (for display / sorting).
    var moodScore: Int {
        switch self {
        case .blue:   return 1
        case .red:    return 2
        case .green:  return 4
        case .yellow: return 5
        }
    }
}

// MARK: - MoodWord

struct MoodWord: Identifiable {
    let id: UUID = UUID()
    let word: String
    let quadrant: MoodQuadrant
    /// Normalized position in conceptual space:
    ///   x: 0.0 = far left / unpleasant, 1.0 = far right / pleasant
    ///   y: 0.0 = bottom / low energy,   1.0 = top / high energy
    let x: Double
    let y: Double
}

// MARK: - MoodMeter (data + helpers)

enum MoodMeter {

    // MARK: Word List
    // 10 words per quadrant, distributed within their respective quadrant.
    // Quadrant boundaries in conceptual (x,y) space:
    //   Red:    x 0.0–0.5, y 0.5–1.0
    //   Yellow: x 0.5–1.0, y 0.5–1.0
    //   Blue:   x 0.0–0.5, y 0.0–0.5
    //   Green:  x 0.5–1.0, y 0.0–0.5
    static let words: [MoodWord] = [

        // ── Red: High Energy + Unpleasant ──────────────────────────────────
        MoodWord(word: "Furious",    quadrant: .red, x: 0.07, y: 0.94),
        MoodWord(word: "Panicked",   quadrant: .red, x: 0.24, y: 0.93),
        MoodWord(word: "Alarmed",    quadrant: .red, x: 0.42, y: 0.91),
        MoodWord(word: "Angry",      quadrant: .red, x: 0.08, y: 0.79),
        MoodWord(word: "Anxious",    quadrant: .red, x: 0.23, y: 0.78),
        MoodWord(word: "Fearful",    quadrant: .red, x: 0.40, y: 0.77),
        MoodWord(word: "Stressed",   quadrant: .red, x: 0.08, y: 0.65),
        MoodWord(word: "Frustrated", quadrant: .red, x: 0.22, y: 0.64),
        MoodWord(word: "Tense",      quadrant: .red, x: 0.38, y: 0.62),
        MoodWord(word: "Worried",    quadrant: .red, x: 0.46, y: 0.54),

        // ── Yellow: High Energy + Pleasant ─────────────────────────────────
        MoodWord(word: "Elated",       quadrant: .yellow, x: 0.57, y: 0.94),
        MoodWord(word: "Joyful",       quadrant: .yellow, x: 0.74, y: 0.93),
        MoodWord(word: "Proud",        quadrant: .yellow, x: 0.92, y: 0.91),
        MoodWord(word: "Excited",      quadrant: .yellow, x: 0.56, y: 0.79),
        MoodWord(word: "Passionate",   quadrant: .yellow, x: 0.73, y: 0.78),
        MoodWord(word: "Enthusiastic", quadrant: .yellow, x: 0.90, y: 0.77),
        MoodWord(word: "Inspired",     quadrant: .yellow, x: 0.57, y: 0.65),
        MoodWord(word: "Energized",    quadrant: .yellow, x: 0.74, y: 0.64),
        MoodWord(word: "Hopeful",      quadrant: .yellow, x: 0.91, y: 0.62),
        MoodWord(word: "Happy",        quadrant: .yellow, x: 0.72, y: 0.54),

        // ── Blue: Low Energy + Unpleasant ──────────────────────────────────
        MoodWord(word: "Bored",        quadrant: .blue, x: 0.07, y: 0.38),
        MoodWord(word: "Lonely",       quadrant: .blue, x: 0.23, y: 0.37),
        MoodWord(word: "Hopeless",     quadrant: .blue, x: 0.40, y: 0.36),
        MoodWord(word: "Sad",          quadrant: .blue, x: 0.08, y: 0.26),
        MoodWord(word: "Tired",        quadrant: .blue, x: 0.22, y: 0.25),
        MoodWord(word: "Despondent",   quadrant: .blue, x: 0.40, y: 0.24),
        MoodWord(word: "Drained",      quadrant: .blue, x: 0.08, y: 0.14),
        MoodWord(word: "Melancholy",   quadrant: .blue, x: 0.24, y: 0.13),
        MoodWord(word: "Depressed",    quadrant: .blue, x: 0.38, y: 0.10),
        MoodWord(word: "Disconnected", quadrant: .blue, x: 0.46, y: 0.06),

        // ── Green: Low Energy + Pleasant ───────────────────────────────────
        MoodWord(word: "Content",   quadrant: .green, x: 0.57, y: 0.38),
        MoodWord(word: "Grateful",  quadrant: .green, x: 0.74, y: 0.37),
        MoodWord(word: "Serene",    quadrant: .green, x: 0.93, y: 0.36),
        MoodWord(word: "Calm",      quadrant: .green, x: 0.57, y: 0.26),
        MoodWord(word: "Relaxed",   quadrant: .green, x: 0.74, y: 0.25),
        MoodWord(word: "Peaceful",  quadrant: .green, x: 0.93, y: 0.24),
        MoodWord(word: "Balanced",  quadrant: .green, x: 0.58, y: 0.14),
        MoodWord(word: "At Ease",   quadrant: .green, x: 0.74, y: 0.13),
        MoodWord(word: "Tranquil",  quadrant: .green, x: 0.92, y: 0.10),
        MoodWord(word: "Restored",  quadrant: .green, x: 0.74, y: 0.06),
    ]

    // MARK: Helpers

    /// Returns the quadrant for a given normalized (x, y) position.
    static func quadrant(x: Double, y: Double) -> MoodQuadrant {
        switch (x < 0.5, y >= 0.5) {
        case (true,  true):  return .red
        case (false, true):  return .yellow
        case (true,  false): return .blue
        case (false, false): return .green
        }
    }

    /// Returns the word closest to (x, y) in Euclidean distance.
    static func nearestWord(x: Double, y: Double) -> MoodWord? {
        words.min {
            hypot($0.x - x, $0.y - y) < hypot($1.x - x, $1.y - y)
        }
    }

    /// Quadrant-based mood score on a 1–5 scale.
    static func moodScore(for quadrant: MoodQuadrant?) -> Int {
        quadrant?.moodScore ?? 3
    }
}

// MARK: - JournalEntry

@Model
final class JournalEntry {

    var id: UUID
    var createdAt: Date
    var editedAt: Date
    var title: String
    var body: String

    // MARK: Mood Meter fields

    /// Normalized pin position: 0.0 = unpleasant, 1.0 = pleasant.
    var moodX: Double
    /// Normalized pin position: 0.0 = low energy, 1.0 = high energy.
    var moodY: Double
    /// Quadrant raw-value string ("red" / "yellow" / "blue" / "green"), or nil
    /// when the user has not placed the pin.
    var moodQuadrant: String?
    /// Nearest emotion word to the pin position, or nil when not set.
    var moodWord: String?

    // MARK: Dream Clarity

    /// Dream clarity on a 1–5 scale, or nil if not set.
    /// 1 = Barely a feeling, 2 = Fragments only, 3 = Some scenes,
    /// 4 = Most of it, 5 = Vivid and complete.
    var dreamClarity: Int?

    // MARK: Entry Type

    /// Entry type raw value: "dream", "mood", or "general".
    /// Defaults to "dream" — existing entries migrate as dream entries.
    var entryType: String = "dream"

    // MARK: Mood Check-In Fields

    /// Energy level 1–5 (1 = Exhausted, 5 = Energized). Mood entries only.
    var energyLevel: Int?
    /// Comma-separated context tags (e.g. "Work, Sleep"). Mood entries only.
    var contextTags: String?

    // MARK: General Entry Fields

    /// Comma-separated free-form tags. General entries only.
    var generalTags: String?

    init(
        title: String = "",
        body: String,
        moodX: Double = 0.5,
        moodY: Double = 0.5,
        moodQuadrant: String? = nil,
        moodWord: String? = nil,
        dreamClarity: Int? = nil,
        entryType: String = "dream",
        energyLevel: Int? = nil,
        contextTags: String? = nil,
        generalTags: String? = nil,
        date: Date = .now
    ) {
        self.id           = UUID()
        self.createdAt    = date
        self.editedAt     = date
        self.title        = title
        self.body         = body
        self.moodX        = moodX
        self.moodY        = moodY
        self.moodQuadrant = moodQuadrant
        self.moodWord     = moodWord
        self.dreamClarity = dreamClarity
        self.entryType    = entryType
        self.energyLevel  = energyLevel
        self.contextTags  = contextTags
        self.generalTags  = generalTags
    }

    // MARK: - Computed helpers (not persisted)

    var hasMoodSelection: Bool { moodQuadrant != nil }

    /// Typed entry kind, defaulting to .dream if the stored string is unrecognised.
    var entryTypeEnum: JournalEntryType {
        JournalEntryType(rawValue: entryType) ?? .dream
    }

    /// Parsed context tags for mood entries.
    var contextTagsArray: [String] {
        guard let raw = contextTags, !raw.isEmpty else { return [] }
        return raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    /// Parsed free-form tags for general entries.
    var generalTagsArray: [String] {
        guard let raw = generalTags, !raw.isEmpty else { return [] }
        return raw.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var quadrantEnum: MoodQuadrant? {
        moodQuadrant.flatMap { MoodQuadrant(rawValue: $0) }
    }

    var quadrantColor: Color {
        quadrantEnum?.color ?? Color.white.opacity(0.2)
    }

    /// Mood score on a 1–5 scale derived from quadrant.
    var moodScore: Int { MoodMeter.moodScore(for: quadrantEnum) }

    /// Star-string representation, e.g. "★★★☆☆"
    var moodStars: String {
        String(repeating: "★", count: moodScore) +
        String(repeating: "☆", count: 5 - moodScore)
    }

    // MARK: - Dream Clarity Helpers

    /// Dream clarity label for display.
    var dreamClarityLabel: String? {
        guard let clarity = dreamClarity else { return nil }
        switch clarity {
        case 1: return "Barely a feeling"
        case 2: return "Fragments only"
        case 3: return "Some scenes"
        case 4: return "Most of it"
        case 5: return "Vivid and complete"
        default: return nil
        }
    }

    /// SF Symbol for dream clarity level.
    var dreamClaritySymbol: String? {
        guard let clarity = dreamClarity else { return nil }
        switch clarity {
        case 1: return "cloud.fog.fill"
        case 2: return "cloud.fill"
        case 3: return "cloud.moon.fill"
        case 4: return "moon.fill"
        case 5: return "sparkles"
        default: return nil
        }
    }

    /// Color for dream clarity level.
    var dreamClarityColor: Color {
        guard let clarity = dreamClarity else { return .white.opacity(0.3) }
        switch clarity {
        case 1: return Color(red: 0.5, green: 0.5, blue: 0.6)   // Muted fog
        case 2: return Color(red: 0.55, green: 0.55, blue: 0.7) // Hazy
        case 3: return Color(red: 0.6, green: 0.6, blue: 0.8)   // Emerging
        case 4: return Color(red: 0.7, green: 0.7, blue: 0.9)   // Clear
        case 5: return Color(red: 0.85, green: 0.75, blue: 0.95) // Vivid violet
        default: return .white.opacity(0.3)
        }
    }

    /// Plain-text representation for sharing.
    var shareText: String {
        let dateStr = createdAt.formatted(date: .long, time: .shortened)
        let header: String
        switch entryTypeEnum {
        case .dream:   header = "🌙 Dream Journal"
        case .mood:    header = "😊 Mood Check-in"
        case .general: header = "📝 Journal Entry"
        }
        var lines: [String] = [header, dateStr]
        if !title.isEmpty { lines.append(title) }
        if entryTypeEnum == .dream, let clarityLabel = dreamClarityLabel {
            lines.append("Clarity: \(clarityLabel)")
        }
        if let word = moodWord, let quadrant = quadrantEnum {
            lines.append("Mood: \(word) (\(quadrant.title))  \(moodStars)")
        }
        if let energy = energyLevel {
            lines.append("Energy: \(energy)/5")
        }
        if !contextTagsArray.isEmpty {
            lines.append("Tags: \(contextTagsArray.joined(separator: ", "))")
        }
        if !generalTagsArray.isEmpty {
            lines.append("Tags: \(generalTagsArray.joined(separator: ", "))")
        }
        lines += ["", body]
        return lines.joined(separator: "\n")
    }

    /// Display title: falls back to a 40-char body preview when untitled.
    var displayTitle: String {
        title.isEmpty ? String(body.prefix(40)) : title
    }

    /// Short formatted date for list rows.
    var shortDate: String {
        createdAt.formatted(date: .abbreviated, time: .shortened)
    }
}

// MARK: - EnergyLevel

enum EnergyLevel: Int, CaseIterable {
    case exhausted = 1
    case low       = 2
    case moderate  = 3
    case high      = 4
    case energized = 5

    var label: String {
        switch self {
        case .exhausted: return "Exhausted"
        case .low:       return "Low"
        case .moderate:  return "Moderate"
        case .high:      return "High"
        case .energized: return "Energized"
        }
    }

    var color: Color {
        switch self {
        case .exhausted: return Color(red: 0.45, green: 0.45, blue: 0.75)
        case .low:       return Color(red: 0.55, green: 0.50, blue: 0.80)
        case .moderate:  return Color(red: 0.75, green: 0.55, blue: 0.75)
        case .high:      return Color(red: 0.90, green: 0.55, blue: 0.60)
        case .energized: return JournalEntryType.mood.color
        }
    }

    static func color(for value: Int) -> Color {
        (EnergyLevel(rawValue: value) ?? .moderate).color
    }

    static func label(for value: Int) -> String {
        (EnergyLevel(rawValue: value) ?? .moderate).label
    }
}
