//
//  ReflectionModels.swift
//  every_day
//

import SwiftUI

// MARK: - ReflectionCategory

enum ReflectionCategory: String, CaseIterable {
    case gratitude     = "Gratitude"
    case selfDiscovery = "Self-Discovery"
    case emotions      = "Emotions"
    case goals         = "Goals"
    case relationships = "Relationships"
    case mindfulness   = "Mindfulness"

    var sfSymbol: String {
        switch self {
        case .gratitude:     return "heart.fill"
        case .selfDiscovery: return "person.fill.questionmark"
        case .emotions:      return "face.smiling.fill"
        case .goals:         return "star.fill"
        case .relationships: return "person.2.fill"
        case .mindfulness:   return "leaf.fill"
        }
    }

    var color: Color {
        switch self {
        case .gratitude:     return Color(red: 0.95, green: 0.45, blue: 0.50)
        case .selfDiscovery: return Color(red: 0.60, green: 0.48, blue: 0.95)
        case .emotions:      return Color(red: 0.98, green: 0.75, blue: 0.28)
        case .goals:         return Color(red: 0.28, green: 0.75, blue: 0.96)
        case .relationships: return Color(red: 0.95, green: 0.55, blue: 0.78)
        case .mindfulness:   return Color(red: 0.30, green: 0.80, blue: 0.55)
        }
    }
}

// MARK: - ReflectionPrompt

struct ReflectionPrompt: Identifiable {
    let id: Int
    let text: String
    let category: ReflectionCategory
}

// MARK: - ReflectionPromptLibrary

enum ReflectionPromptLibrary {

    static let all: [ReflectionPrompt] = [

        // Gratitude (0–5)
        ReflectionPrompt(id:  0, text: "What are three things you're genuinely grateful for today?",            category: .gratitude),
        ReflectionPrompt(id:  1, text: "Who in your life made today a little brighter?",                        category: .gratitude),
        ReflectionPrompt(id:  2, text: "What small moment today deserves more appreciation?",                   category: .gratitude),
        ReflectionPrompt(id:  3, text: "What challenge are you secretly grateful for?",                         category: .gratitude),
        ReflectionPrompt(id:  4, text: "What ordinary thing brought you unexpected joy today?",                  category: .gratitude),
        ReflectionPrompt(id:  5, text: "What part of your body or health are you thankful for right now?",      category: .gratitude),

        // Self-Discovery (6–11)
        ReflectionPrompt(id:  6, text: "What did you learn about yourself today?",                              category: .selfDiscovery),
        ReflectionPrompt(id:  7, text: "What would your ten-years-older self advise you right now?",            category: .selfDiscovery),
        ReflectionPrompt(id:  8, text: "What belief about yourself is holding you back?",                       category: .selfDiscovery),
        ReflectionPrompt(id:  9, text: "When did you feel most like yourself today?",                           category: .selfDiscovery),
        ReflectionPrompt(id: 10, text: "What does your ideal day look like, and how close was today?",          category: .selfDiscovery),
        ReflectionPrompt(id: 11, text: "What are you afraid to admit about yourself right now?",                category: .selfDiscovery),

        // Emotions (12–17)
        ReflectionPrompt(id: 12, text: "What emotion has been most present today, and what triggered it?",     category: .emotions),
        ReflectionPrompt(id: 13, text: "When did you feel most at peace today?",                               category: .emotions),
        ReflectionPrompt(id: 14, text: "What are you holding onto that you need to let go?",                   category: .emotions),
        ReflectionPrompt(id: 15, text: "What would you say to yourself if you were your own best friend?",     category: .emotions),
        ReflectionPrompt(id: 16, text: "What feeling have you been avoiding, and what does it need from you?", category: .emotions),
        ReflectionPrompt(id: 17, text: "How did your body signal stress today, and how did you respond?",      category: .emotions),

        // Goals (18–23)
        ReflectionPrompt(id: 18, text: "What single step can you take tomorrow toward your biggest goal?",     category: .goals),
        ReflectionPrompt(id: 19, text: "What did you accomplish today that future you will thank you for?",    category: .goals),
        ReflectionPrompt(id: 20, text: "What distracted you from what matters most today?",                    category: .goals),
        ReflectionPrompt(id: 21, text: "What does success mean to you right now, in this season of life?",    category: .goals),
        ReflectionPrompt(id: 22, text: "What habits are quietly shaping your future?",                        category: .goals),
        ReflectionPrompt(id: 23, text: "If today were a chapter in your story, what would you title it?",     category: .goals),

        // Relationships (24–29)
        ReflectionPrompt(id: 24, text: "Who could use a kind word or check-in from you this week?",           category: .relationships),
        ReflectionPrompt(id: 25, text: "What conversation have you been putting off?",                        category: .relationships),
        ReflectionPrompt(id: 26, text: "How have you shown up for the people you love recently?",             category: .relationships),
        ReflectionPrompt(id: 27, text: "What relationship in your life is asking for more of your presence?", category: .relationships),
        ReflectionPrompt(id: 28, text: "What did someone teach you today — knowingly or not?",                category: .relationships),
        ReflectionPrompt(id: 29, text: "How did you contribute to someone else's day today?",                 category: .relationships),

        // Mindfulness (30–35)
        ReflectionPrompt(id: 30, text: "What did you notice today that you might normally overlook?",         category: .mindfulness),
        ReflectionPrompt(id: 31, text: "Where did your mind tend to wander today?",                          category: .mindfulness),
        ReflectionPrompt(id: 32, text: "What does your body need right now?",                                category: .mindfulness),
        ReflectionPrompt(id: 33, text: "What would it feel like to let this day be exactly enough?",         category: .mindfulness),
        ReflectionPrompt(id: 34, text: "If you fully accepted this moment, what would change?",              category: .mindfulness),
        ReflectionPrompt(id: 35, text: "What sound, sight, or sensation stands out from today?",             category: .mindfulness),
    ]

    /// Returns a deterministic daily prompt — cycles through the full list, changes at midnight.
    static func todaysPrompt() -> ReflectionPrompt {
        let dayOrdinal = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return all[dayOrdinal % all.count]
    }
}
