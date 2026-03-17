//
//  SpaceDataCache.swift
//  every_day
//

import Foundation

actor SpaceDataCache {
    private struct Entry<Value> {
        let value: Value
        let expiration: Date
    }

    /// Maximum number of date-keyed cache entries to retain per category.
    private static let maxEntriesPerCategory = 30

    private var planetsEntry: Entry<[PlanetaryBody]>?
    private var apodEntries: [String: Entry<APODEntry>] = [:]
    private var asteroidEntries: [String: Entry<[AsteroidApproach]>] = [:]

    func planets() -> [PlanetaryBody]? {
        guard let planetsEntry else { return nil }
        guard planetsEntry.expiration > Date() else {
            self.planetsEntry = nil
            return nil
        }
        return planetsEntry.value
    }

    func store(planets: [PlanetaryBody], ttl: TimeInterval) {
        planetsEntry = Entry(value: planets, expiration: Date().addingTimeInterval(ttl))
    }

    func apod(for key: String) -> APODEntry? {
        guard let entry = apodEntries[key] else { return nil }
        guard entry.expiration > Date() else {
            apodEntries[key] = nil
            return nil
        }
        return entry.value
    }

    func store(apod: APODEntry, key: String, ttl: TimeInterval) {
        if apodEntries.count >= Self.maxEntriesPerCategory {
            evictExpired(from: &apodEntries)
        }
        apodEntries[key] = Entry(value: apod, expiration: Date().addingTimeInterval(ttl))
    }

    func asteroids(for key: String) -> [AsteroidApproach]? {
        guard let entry = asteroidEntries[key] else { return nil }
        guard entry.expiration > Date() else {
            asteroidEntries[key] = nil
            return nil
        }
        return entry.value
    }

    func store(asteroids: [AsteroidApproach], key: String, ttl: TimeInterval) {
        if asteroidEntries.count >= Self.maxEntriesPerCategory {
            evictExpired(from: &asteroidEntries)
        }
        asteroidEntries[key] = Entry(value: asteroids, expiration: Date().addingTimeInterval(ttl))
    }

    // MARK: - Eviction

    private func evictExpired<V>(from dict: inout [String: Entry<V>]) {
        let now = Date()
        dict = dict.filter { $0.value.expiration > now }
    }
}
