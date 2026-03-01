//
//  ReflectionViewModel.swift
//  every_day
//

import Foundation

@Observable final class ReflectionViewModel {

    /// Kept in sync with @AppStorage("defaultPromptCategory") from the view layer.
    /// Initialized from UserDefaults so the first render uses the saved setting.
    var filterCategory: String = UserDefaults.standard.string(forKey: "defaultPromptCategory") ?? "all"

    private(set) var favoriteIDs: Set<Int>

    private let favoritesKey = "reflection_favorite_ids"

    init() {
        let saved = UserDefaults.standard.array(forKey: "reflection_favorite_ids") as? [Int] ?? []
        favoriteIDs = Set(saved)
    }

    /// Deterministic daily prompt from the active category pool — changes at midnight.
    var todaysPrompt: ReflectionPrompt {
        let pool: [ReflectionPrompt]
        if filterCategory == "all" {
            pool = ReflectionPromptLibrary.all
        } else if let cat = ReflectionCategory(rawValue: filterCategory) {
            let filtered = ReflectionPromptLibrary.all.filter { $0.category == cat }
            pool = filtered.isEmpty ? ReflectionPromptLibrary.all : filtered
        } else {
            pool = ReflectionPromptLibrary.all
        }
        let dayOrdinal = Calendar.current.ordinality(of: .day, in: .era, for: .now) ?? 0
        return pool[dayOrdinal % pool.count]
    }

    var isFavorite: Bool { favoriteIDs.contains(todaysPrompt.id) }

    var favoritePrompts: [ReflectionPrompt] {
        ReflectionPromptLibrary.all
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
}
