//
//  SpaceDataCacheTests.swift
//  every_dayTests
//

import Testing
import Foundation
@testable import every_day

@Suite("SpaceDataCache")
struct SpaceDataCacheTests {
    @Test("Entries are valid before expiry and stale after expiry")
    func entriesExpireButRemainAvailableAsStaleFallback() async throws {
        let cacheDirectory = makeCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }

        let cache = SpaceDataCache(cacheDirectory: cacheDirectory)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let apod = APODEntry(
            id: "2026-03-17",
            title: "Blue Marble",
            dateString: "2026-03-17",
            explanation: "A cached APOD entry.",
            mediaType: .image,
            url: URL(string: "https://example.com/apod.jpg"),
            hdURL: URL(string: "https://example.com/apod-hd.jpg"),
            thumbnailURL: nil,
            copyright: "NASA"
        )

        let stored = await cache.store(apod, for: "test.apod", policy: .nasaAPOD, now: start)
        #expect(stored)

        let validLookup = await cache.lookup(
            for: "test.apod",
            as: APODEntry.self,
            now: start.addingTimeInterval(60)
        )

        switch validLookup {
        case let .valid(cached):
            #expect(cached.id == apod.id)
            #expect(cached.title == apod.title)
        default:
            Issue.record("Expected a valid cache hit before expiration.")
        }

        let staleLookup = await cache.lookup(
            for: "test.apod",
            as: APODEntry.self,
            now: start.addingTimeInterval((60 * 60 * 24) + 60)
        )

        switch staleLookup {
        case let .stale(cached):
            #expect(cached.id == apod.id)
        default:
            Issue.record("Expected a stale cache hit after expiration.")
        }
    }

    @Test("Persistent entries survive a new cache instance")
    func entriesPersistAcrossCacheInstances() async throws {
        let cacheDirectory = makeCacheDirectory()
        defer { try? FileManager.default.removeItem(at: cacheDirectory) }

        let start = Date(timeIntervalSince1970: 1_700_000_100)
        let firstCache = SpaceDataCache(cacheDirectory: cacheDirectory)
        let secondCache = SpaceDataCache(cacheDirectory: cacheDirectory)
        let apod = APODEntry(
            id: "2026-03-18",
            title: "Persistence",
            dateString: "2026-03-18",
            explanation: "A persisted APOD entry.",
            mediaType: .image,
            url: URL(string: "https://example.com/apod-2.jpg"),
            hdURL: nil,
            thumbnailURL: nil,
            copyright: nil
        )

        let stored = await firstCache.store(apod, for: "test.apod.persisted", policy: .nasaAPOD, now: start)
        #expect(stored)

        let lookup = await secondCache.lookup(
            for: "test.apod.persisted",
            as: APODEntry.self,
            now: start.addingTimeInterval(300)
        )

        switch lookup {
        case let .valid(cached):
            #expect(cached.id == apod.id)
            #expect(cached.explanation == apod.explanation)
        default:
            Issue.record("Expected the persisted cache entry to be readable from disk.")
        }
    }

    private func makeCacheDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
    }
}
