//
//  ReflectionModels.swift
//  every_day
//
//  Dream Journal prompt categories and library.
//

import SwiftUI

// MARK: - DreamCategory

enum DreamCategory: String, CaseIterable {
    case immediateRecall      = "Immediate Recall"
    case sensoryImmersion     = "Sensory Immersion"
    case emotionalLandscape   = "Emotional Landscape"
    case charactersAndFigures = "Characters & Figures"
    case dreamscapeAndSetting = "Dreamscape & Setting"
    case symbolsAndPatterns   = "Symbols & Patterns"
    case lucidAndLiminal      = "Lucid & Liminal"
    case integrationAndMeaning = "Integration & Meaning"

    var sfSymbol: String {
        switch self {
        case .immediateRecall:      return "sparkles"
        case .sensoryImmersion:     return "hand.raised.fingers.spread.fill"
        case .emotionalLandscape:   return "heart.text.square.fill"
        case .charactersAndFigures: return "person.2.fill"
        case .dreamscapeAndSetting: return "mountain.2.fill"
        case .symbolsAndPatterns:   return "sparkle.magnifyingglass"
        case .lucidAndLiminal:      return "eye.fill"
        case .integrationAndMeaning: return "brain.head.profile.fill"
        }
    }

    var color: Color {
        switch self {
        case .immediateRecall:      return Color(red: 0.65, green: 0.50, blue: 0.95)  // Soft violet
        case .sensoryImmersion:     return Color(red: 0.45, green: 0.75, blue: 0.90)  // Dream blue
        case .emotionalLandscape:   return Color(red: 0.95, green: 0.55, blue: 0.65)  // Soft rose
        case .charactersAndFigures: return Color(red: 0.80, green: 0.70, blue: 0.55)  // Warm sand
        case .dreamscapeAndSetting: return Color(red: 0.40, green: 0.65, blue: 0.55)  // Misty teal
        case .symbolsAndPatterns:   return Color(red: 0.85, green: 0.75, blue: 0.45)  // Golden amber
        case .lucidAndLiminal:      return Color(red: 0.55, green: 0.55, blue: 0.85)  // Twilight indigo
        case .integrationAndMeaning: return Color(red: 0.70, green: 0.55, blue: 0.75) // Dusk purple
        }
    }

    /// Weight for random selection — higher = more likely to appear.
    var weight: Int {
        switch self {
        case .immediateRecall:      return 3  // Most important for daily use
        case .sensoryImmersion:     return 3  // Equally important
        case .emotionalLandscape:   return 2
        case .charactersAndFigures: return 2
        case .dreamscapeAndSetting: return 2
        case .symbolsAndPatterns:   return 1
        case .lucidAndLiminal:      return 1
        case .integrationAndMeaning: return 1
        }
    }
}

// Keep ReflectionCategory as a typealias for backwards compatibility
typealias ReflectionCategory = DreamCategory

// MARK: - DreamPrompt

struct DreamPrompt: Identifiable {
    let id: Int
    let text: String
    let category: DreamCategory
}

// Keep ReflectionPrompt as a typealias for backwards compatibility
typealias ReflectionPrompt = DreamPrompt

// MARK: - DreamPromptLibrary

enum DreamPromptLibrary {

    static let all: [DreamPrompt] = [

        // ═══════════════════════════════════════════════════════════════════
        // IMMEDIATE RECALL (0–7)
        // Quick, sensory, non-analytical — capture before it fades
        // ═══════════════════════════════════════════════════════════════════
        DreamPrompt(id:  0, text: "Before the dream slips away — what is the first image that comes to mind?", category: .immediateRecall),
        DreamPrompt(id:  1, text: "What were you doing in the last moment of your dream?", category: .immediateRecall),
        DreamPrompt(id:  2, text: "Close your eyes. What colors do you see from last night?", category: .immediateRecall),
        DreamPrompt(id:  3, text: "Who was with you? Where were you? Write whatever comes first.", category: .immediateRecall),
        DreamPrompt(id:  4, text: "What feeling did you wake up with? Let that feeling lead you back in.", category: .immediateRecall),
        DreamPrompt(id:  5, text: "Describe the last scene before you woke as if you are still standing in it.", category: .immediateRecall),
        DreamPrompt(id:  6, text: "Without thinking too hard — what single word captures your dream?", category: .immediateRecall),
        DreamPrompt(id:  7, text: "What fragment remains? Even a shape, a sound, a sense of movement.", category: .immediateRecall),

        // ═══════════════════════════════════════════════════════════════════
        // SENSORY IMMERSION (8–15)
        // Use the five senses to pull back into the experience
        // ═══════════════════════════════════════════════════════════════════
        DreamPrompt(id:  8, text: "What did the air feel like in your dream? Was it warm, cold, heavy, electric?", category: .sensoryImmersion),
        DreamPrompt(id:  9, text: "Were there sounds in your dream? Music, voices, silence, something strange?", category: .sensoryImmersion),
        DreamPrompt(id: 10, text: "What textures do you remember? What did you touch or what touched you?", category: .sensoryImmersion),
        DreamPrompt(id: 11, text: "Was there a smell or taste that lingered from your dream world?", category: .sensoryImmersion),
        DreamPrompt(id: 12, text: "Describe the light. Was it daylight, moonlight, artificial, or something that only exists in dreams?", category: .sensoryImmersion),
        DreamPrompt(id: 13, text: "What was the quality of movement in your dream? Slow, fast, floating, frozen?", category: .sensoryImmersion),
        DreamPrompt(id: 14, text: "Did your body feel different in the dream? Heavier, lighter, stronger, smaller?", category: .sensoryImmersion),
        DreamPrompt(id: 15, text: "What was the temperature of the dream? Not just physical — the emotional temperature.", category: .sensoryImmersion),

        // ═══════════════════════════════════════════════════════════════════
        // EMOTIONAL LANDSCAPE (16–23)
        // Focus on the emotional tone rather than the plot
        // ═══════════════════════════════════════════════════════════════════
        DreamPrompt(id: 16, text: "What emotion was running underneath the entire dream like a current?", category: .emotionalLandscape),
        DreamPrompt(id: 17, text: "Was there a moment of fear, wonder, grief, or joy that stands out?", category: .emotionalLandscape),
        DreamPrompt(id: 18, text: "How did your dream self feel different from how you feel in waking life?", category: .emotionalLandscape),
        DreamPrompt(id: 19, text: "What emotion did you wake up carrying, and where do you feel it in your body?", category: .emotionalLandscape),
        DreamPrompt(id: 20, text: "Was there something in the dream you were searching for or running from?", category: .emotionalLandscape),
        DreamPrompt(id: 21, text: "Did the dream leave you with a sense of longing? For what?", category: .emotionalLandscape),
        DreamPrompt(id: 22, text: "What was the most emotionally charged moment, even if it seemed ordinary?", category: .emotionalLandscape),
        DreamPrompt(id: 23, text: "If your dream had a mood, like weather, what would it be? Storm, fog, calm, dusk?", category: .emotionalLandscape),

        // ═══════════════════════════════════════════════════════════════════
        // CHARACTERS AND FIGURES (24–31)
        // People, creatures, and beings that appeared
        // ═══════════════════════════════════════════════════════════════════
        DreamPrompt(id: 24, text: "Who appeared in your dream, and did they feel familiar even if you did not know them?", category: .charactersAndFigures),
        DreamPrompt(id: 25, text: "Was there a figure in shadow, or someone you could not quite see clearly?", category: .charactersAndFigures),
        DreamPrompt(id: 26, text: "How did the people in your dream make you feel — safe, threatened, loved, confused?", category: .charactersAndFigures),
        DreamPrompt(id: 27, text: "Did any animals or non-human beings appear? What did they do or say?", category: .charactersAndFigures),
        DreamPrompt(id: 28, text: "Was there a version of yourself in the dream? How were they different from you?", category: .charactersAndFigures),
        DreamPrompt(id: 29, text: "Did someone speak to you? What did they say, or what did their silence say?", category: .charactersAndFigures),
        DreamPrompt(id: 30, text: "Was there a guide, a stranger, or a presence watching over the dream?", category: .charactersAndFigures),
        DreamPrompt(id: 31, text: "Did anyone from your past appear? What do you think brought them into this dream?", category: .charactersAndFigures),

        // ═══════════════════════════════════════════════════════════════════
        // DREAMSCAPE AND SETTING (32–39)
        // Environment and world of the dream
        // ═══════════════════════════════════════════════════════════════════
        DreamPrompt(id: 32, text: "Describe the place your dream took you. Was it familiar, strange, or somewhere between?", category: .dreamscapeAndSetting),
        DreamPrompt(id: 33, text: "Were there buildings, landscapes, or spaces that felt significant?", category: .dreamscapeAndSetting),
        DreamPrompt(id: 34, text: "Did the setting shift or change during the dream? How did it transform?", category: .dreamscapeAndSetting),
        DreamPrompt(id: 35, text: "Was there a door, a path, a window, or a threshold you crossed or avoided?", category: .dreamscapeAndSetting),
        DreamPrompt(id: 36, text: "What was the sky like in your dream?", category: .dreamscapeAndSetting),
        DreamPrompt(id: 37, text: "Was the space open or enclosed? Did you feel free or contained?", category: .dreamscapeAndSetting),
        DreamPrompt(id: 38, text: "Did the place exist in waking life, or only in the dream? What made it dreamlike?", category: .dreamscapeAndSetting),
        DreamPrompt(id: 39, text: "Was there water in your dream — ocean, river, rain, pool? What was it doing?", category: .dreamscapeAndSetting),

        // ═══════════════════════════════════════════════════════════════════
        // SYMBOLS AND PATTERNS (40–47)
        // Recurring elements and possible symbolic meaning
        // ═══════════════════════════════════════════════════════════════════
        DreamPrompt(id: 40, text: "Is there an image from this dream that feels charged with meaning, even if you cannot explain why?", category: .symbolsAndPatterns),
        DreamPrompt(id: 41, text: "Have you dreamed of this place, person, or feeling before?", category: .symbolsAndPatterns),
        DreamPrompt(id: 42, text: "If this dream were trying to tell you something, what might it be saying?", category: .symbolsAndPatterns),
        DreamPrompt(id: 43, text: "What in waking life does this dream remind you of?", category: .symbolsAndPatterns),
        DreamPrompt(id: 44, text: "Is there a symbol or object that appeared that felt more significant than it should?", category: .symbolsAndPatterns),
        DreamPrompt(id: 45, text: "Did numbers, colors, or words repeat or stand out?", category: .symbolsAndPatterns),
        DreamPrompt(id: 46, text: "What patterns do you notice across your recent dreams?", category: .symbolsAndPatterns),
        DreamPrompt(id: 47, text: "If your dream were a story, what would its title be?", category: .symbolsAndPatterns),

        // ═══════════════════════════════════════════════════════════════════
        // LUCID AND LIMINAL (48–55)
        // Boundary between dreaming and waking consciousness
        // ═══════════════════════════════════════════════════════════════════
        DreamPrompt(id: 48, text: "Did you know you were dreaming at any point? What made you realize it?", category: .lucidAndLiminal),
        DreamPrompt(id: 49, text: "Was there a moment where the dream felt more real than waking life?", category: .lucidAndLiminal),
        DreamPrompt(id: 50, text: "Did you have any control over what happened in the dream?", category: .lucidAndLiminal),
        DreamPrompt(id: 51, text: "What was the last thought you had before falling asleep, and did it appear in the dream?", category: .lucidAndLiminal),
        DreamPrompt(id: 52, text: "In the space between asleep and awake, what image or feeling was waiting for you?", category: .lucidAndLiminal),
        DreamPrompt(id: 53, text: "Did reality flicker or glitch in the dream? Describe the strangeness.", category: .lucidAndLiminal),
        DreamPrompt(id: 54, text: "Were you aware of your sleeping body while dreaming?", category: .lucidAndLiminal),
        DreamPrompt(id: 55, text: "Did the dream have layers — a dream within a dream, or waking up falsely?", category: .lucidAndLiminal),

        // ═══════════════════════════════════════════════════════════════════
        // INTEGRATION AND MEANING (56–63)
        // Connecting the dream to waking life — used after recall
        // ═══════════════════════════════════════════════════════════════════
        DreamPrompt(id: 56, text: "What in your waking life might have inspired this dream?", category: .integrationAndMeaning),
        DreamPrompt(id: 57, text: "Is there something your dream self did that your waking self wishes they could?", category: .integrationAndMeaning),
        DreamPrompt(id: 58, text: "What would you do differently if you could re-enter this dream?", category: .integrationAndMeaning),
        DreamPrompt(id: 59, text: "What is this dream asking you to pay attention to?", category: .integrationAndMeaning),
        DreamPrompt(id: 60, text: "If this dream were a message from a deeper part of yourself, what would it be saying?", category: .integrationAndMeaning),
        DreamPrompt(id: 61, text: "What question does this dream leave you with?", category: .integrationAndMeaning),
        DreamPrompt(id: 62, text: "How might this dream change how you move through today?", category: .integrationAndMeaning),
        DreamPrompt(id: 63, text: "What gift or warning does this dream offer you?", category: .integrationAndMeaning),
    ]

    /// Returns prompts filtered by category.
    static func prompts(for category: DreamCategory) -> [DreamPrompt] {
        all.filter { $0.category == category }
    }

    /// Returns a deterministic daily prompt — cycles through the full list, changes at midnight.
    static func todaysPrompt() -> DreamPrompt {
        let dayOrdinal = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return all[dayOrdinal % all.count]
    }
}

// Keep ReflectionPromptLibrary as a typealias for backwards compatibility
typealias ReflectionPromptLibrary = DreamPromptLibrary

// MARK: - JournalDailyPrompt (unified across all entry types)

struct JournalDailyPrompt {
    let text: String
    let entryType: JournalEntryType
    /// Present only for dream prompts (carries category + ID for favorites).
    var dreamPrompt: DreamPrompt? = nil
}

// MARK: - MoodPromptLibrary

enum MoodPromptLibrary {

    static let all: [String] = [
        "What triggered this feeling?",
        "What do you need right now?",
        "What would shift this mood?",
        "Who or what are you grateful for right now?",
        "How has your mood changed throughout today?",
        "What does your body need in this moment?",
        "What emotion is underneath this feeling?",
        "What would feel most nourishing right now?",
        "What are you resisting or avoiding?",
        "What small act of self-care could you offer yourself today?",
        "Is there something you have been afraid to feel?",
        "What would it look like to fully accept this feeling?",
        "What is your mood trying to tell you?",
        "What conversation or interaction has stayed with you today?",
        "Where do you feel this emotion in your body?",
        "What would your future self say about this feeling?",
    ]

    /// Returns a deterministic daily prompt, changes at midnight.
    static func todaysPrompt() -> String {
        let dayOrdinal = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return all[dayOrdinal % all.count]
    }
}

// MARK: - GeneralPromptLibrary

enum GeneralPromptLibrary {

    static let all: [String] = [
        "What is on your mind today?",
        "What made you smile recently?",
        "What are you looking forward to?",
        "What did you learn today?",
        "What do you want to remember about this moment?",
        "Describe your day in three words, then expand on one of them.",
        "What surprised you recently?",
        "What are you grateful for right now?",
        "What challenge are you working through?",
        "What creative idea has been on your mind?",
        "What is something you would like to let go of?",
        "What conversation has stayed with you lately?",
        "If today had a theme, what would it be?",
        "What did you notice today that you might normally walk past?",
        "What question is living in you right now?",
        "What would you tell yourself one year from today?",
    ]

    /// Returns a deterministic daily prompt, changes at midnight.
    static func todaysPrompt() -> String {
        let dayOrdinal = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return all[dayOrdinal % all.count]
    }
}
