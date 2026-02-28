//
//  ReflectionViewModel.swift
//  every_day
//

import Foundation

@Observable final class ReflectionViewModel {

    private(set) var todaysPrompt: ReflectionPrompt
    private(set) var favoriteIDs: Set<Int>

    private let favoritesKey = "reflection_favorite_ids"

    init() {
        todaysPrompt = ReflectionPromptLibrary.todaysPrompt()
        let saved = UserDefaults.standard.array(forKey: "reflection_favorite_ids") as? [Int] ?? []
        favoriteIDs = Set(saved)
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
