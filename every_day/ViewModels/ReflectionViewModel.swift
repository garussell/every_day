//
//  ReflectionViewModel.swift
//  every_day
//
//  Dream Journal prompt selection with intelligent rotation.
//

import Foundation

@Observable final class ReflectionViewModel {

    /// Kept in sync with @AppStorage("defaultPromptCategory") from the view layer.
    /// Initialized from UserDefaults so the first render uses the saved setting.
    var filterCategory: String = UserDefaults.standard.string(forKey: "defaultPromptCategory") ?? "all"

    private(set) var favoriteIDs: Set<Int>

    private let favoritesKey = "reflection_favorite_ids"
    private let firstUseDateKey = "dream_journal_first_use_date"

    init() {
        let saved = UserDefaults.standard.array(forKey: "reflection_favorite_ids") as? [Int] ?? []
        favoriteIDs = Set(saved)

        // Record first use date if not already set
        if UserDefaults.standard.object(forKey: firstUseDateKey) == nil {
            UserDefaults.standard.set(Date.now, forKey: firstUseDateKey)
        }
    }

    // MARK: - First Use Tracking

    /// Number of days since the user first used the dream journal.
    private var daysSinceFirstUse: Int {
        guard let firstUse = UserDefaults.standard.object(forKey: firstUseDateKey) as? Date else {
            return 0
        }
        let calendar = Calendar.current
        return calendar.dateComponents([.day], from: calendar.startOfDay(for: firstUse), to: calendar.startOfDay(for: .now)).day ?? 0
    }

    /// Whether the user is in their first 3 days (days 0, 1, 2).
    private var isNewUser: Bool {
        daysSinceFirstUse < 3
    }

    // MARK: - Category Rotation

    /// Pre-built weighted pool of categories (computed once, reused for every lookup).
    private static let weightedCategories: [DreamCategory] = {
        var pool: [DreamCategory] = []
        for cat in DreamCategory.allCases {
            for _ in 0..<cat.weight {
                pool.append(cat)
            }
        }
        return pool
    }()

    /// Deterministic category for a given day ordinal, respecting weights.
    private func categoryForDay(_ dayOrdinal: Int) -> DreamCategory {
        Self.weightedCategories[dayOrdinal % Self.weightedCategories.count]
    }

    /// Yesterday's category (for avoiding consecutive same category).
    private var yesterdaysCategory: DreamCategory {
        let yesterdayOrdinal = (Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 1) - 1
        return categoryForDay(yesterdayOrdinal)
    }

    // MARK: - Today's Prompt

    /// Deterministic daily prompt with dream-specific logic:
    /// - New users (first 3 days): Immediate Recall only
    /// - Filter by category if set
    /// - Avoid consecutive same category (when filter = "all")
    var todaysPrompt: DreamPrompt {
        let dayOrdinal = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0

        // Determine the pool of prompts
        let pool: [DreamPrompt]

        if isNewUser {
            // New users get Immediate Recall prompts only
            pool = DreamPromptLibrary.prompts(for: .immediateRecall)
        } else if filterCategory == "all" {
            // All categories, but avoid yesterday's category
            let yesterdayCat = yesterdaysCategory
            let filtered = DreamPromptLibrary.all.filter { $0.category != yesterdayCat }
            pool = filtered.isEmpty ? DreamPromptLibrary.all : filtered
        } else if let cat = DreamCategory(rawValue: filterCategory) {
            // Specific category filter
            let filtered = DreamPromptLibrary.prompts(for: cat)
            pool = filtered.isEmpty ? DreamPromptLibrary.all : filtered
        } else {
            pool = DreamPromptLibrary.all
        }

        // Pick deterministically from the pool
        return pool[dayOrdinal % pool.count]
    }

    var isFavorite: Bool { favoriteIDs.contains(todaysPrompt.id) }

    var favoritePrompts: [DreamPrompt] {
        DreamPromptLibrary.all
            .filter { favoriteIDs.contains($0.id) }
    }

    func toggleFavorite() {
        if favoriteIDs.contains(todaysPrompt.id) {
            favoriteIDs.remove(todaysPrompt.id)
        } else {
            favoriteIDs.insert(todaysPrompt.id)
        }
        UserDefaults.standard.set(Array(favoriteIDs), forKey: favoritesKey)
    }

    // MARK: - Unified Daily Prompt

    /// Returns today's daily prompt for the given entry type.
    /// Dream prompts respect the category filter and new-user onboarding logic.
    func dailyPrompt(for type: JournalEntryType) -> JournalDailyPrompt {
        switch type {
        case .dream:
            let p = todaysPrompt
            return JournalDailyPrompt(text: p.text, entryType: .dream, dreamPrompt: p)
        case .mood:
            return JournalDailyPrompt(text: MoodPromptLibrary.todaysPrompt(), entryType: .mood)
        case .general:
            return JournalDailyPrompt(text: GeneralPromptLibrary.todaysPrompt(), entryType: .general)
        }
    }
}
