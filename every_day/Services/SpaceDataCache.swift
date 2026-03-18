//
//  SpaceDataCache.swift
//  every_day
//

import Foundation

nonisolated enum SpaceDataCachePolicy: String, Sendable {
    case nasaAPOD
    case nasaEarthEPICMetadata
    case nasaNearEarthObjects
    case solarSystemReferenceData
    case solarSystemSkyPositions

    var ttl: TimeInterval {
        switch self {
        case .nasaAPOD:
            return 60 * 60 * 24
        case .nasaEarthEPICMetadata:
            return 60 * 60 * 12
        case .nasaNearEarthObjects:
            return 60 * 60
        case .solarSystemReferenceData:
            return 60 * 60 * 24 * 7
        case .solarSystemSkyPositions:
            return 60 * 15
        }
    }

    var debugName: String {
        switch self {
        case .nasaAPOD:
            return "NASA APOD"
        case .nasaEarthEPICMetadata:
            return "NASA Earth / EPIC"
        case .nasaNearEarthObjects:
            return "NASA NEO Feed"
        case .solarSystemReferenceData:
            return "Solar System Reference"
        case .solarSystemSkyPositions:
            return "Solar System Positions"
        }
    }
}

nonisolated enum SpaceDataCacheLookup<Value: Sendable>: Sendable {
    case valid(Value)
    case stale(Value)
    case miss
}

nonisolated enum SpaceDataCacheSource: String {
    case freshNetwork = "fresh network"
    case validCache = "valid cache"
    case expiredCacheRefresh = "expired cache refresh"
    case staleCacheFallback = "stale cache fallback"
}

nonisolated enum SpaceDataCacheLogger {
    static func log(_ source: SpaceDataCacheSource, policy: SpaceDataCachePolicy, key: String) {
        #if DEBUG
        print("[SpaceDataCache] \(policy.debugName) -> \(source.rawValue) (\(key))")
        #endif
    }

    static func logWriteFailure(policy: SpaceDataCachePolicy, key: String, error: Error) {
        #if DEBUG
        print("[SpaceDataCache] \(policy.debugName) -> cache write failure (\(key)): \(error.localizedDescription)")
        #endif
    }
}

nonisolated actor SpaceDataCache {
    static let shared = SpaceDataCache()

    private struct StoredEntry: Codable, Sendable {
        let payload: Data
        let storedAt: Date
        let expiration: Date
    }

    private static let maxInMemoryEntries = 64

    private let cacheDirectory: URL
    private var memoryEntries: [String: StoredEntry] = [:]

    init(cacheDirectory: URL? = nil) {
        self.cacheDirectory = cacheDirectory ?? Self.defaultCacheDirectory()
    }

    func lookup<Value: Decodable & Sendable>(
        for key: String,
        as type: Value.Type,
        now: Date = .now
    ) -> SpaceDataCacheLookup<Value> {
        if let memoryEntry = memoryEntries[key] {
            return decode(memoryEntry, for: key, as: type, now: now)
        }

        guard let diskEntry = loadDiskEntry(for: key) else {
            return .miss
        }

        memoryEntries[key] = diskEntry
        return decode(diskEntry, for: key, as: type, now: now)
    }

    @discardableResult
    func store<Value: Encodable & Sendable>(
        _ value: Value,
        for key: String,
        policy: SpaceDataCachePolicy,
        now: Date = .now
    ) -> Bool {
        do {
            let payload = try JSONEncoder().encode(value)
            let entry = StoredEntry(
                payload: payload,
                storedAt: now,
                expiration: now.addingTimeInterval(policy.ttl)
            )

            memoryEntries[key] = entry
            trimMemory(now: now)

            try FileManager.default.createDirectory(
                at: cacheDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            let fileData = try JSONEncoder().encode(entry)
            try fileData.write(to: cacheFileURL(for: key), options: .atomic)
            return true
        } catch {
            SpaceDataCacheLogger.logWriteFailure(policy: policy, key: key, error: error)
            return false
        }
    }

    private func decode<Value: Decodable & Sendable>(
        _ entry: StoredEntry,
        for key: String,
        as type: Value.Type,
        now: Date
    ) -> SpaceDataCacheLookup<Value> {
        do {
            let value = try JSONDecoder().decode(type, from: entry.payload)
            return entry.expiration > now ? .valid(value) : .stale(value)
        } catch {
            removeCorruptEntry(for: key)
            return .miss
        }
    }

    private func loadDiskEntry(for key: String) -> StoredEntry? {
        let url = cacheFileURL(for: key)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(StoredEntry.self, from: data)
        } catch {
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    private func removeCorruptEntry(for key: String) {
        memoryEntries[key] = nil
        try? FileManager.default.removeItem(at: cacheFileURL(for: key))
    }

    private func trimMemory(now: Date) {
        memoryEntries = memoryEntries.filter { $0.value.expiration > now }

        guard memoryEntries.count > Self.maxInMemoryEntries else { return }

        let sortedKeys = memoryEntries
            .sorted { $0.value.storedAt < $1.value.storedAt }
            .map(\.key)

        for key in sortedKeys.prefix(memoryEntries.count - Self.maxInMemoryEntries) {
            memoryEntries[key] = nil
        }
    }

    private func cacheFileURL(for key: String) -> URL {
        cacheDirectory
            .appendingPathComponent(cacheFileName(for: key), isDirectory: false)
            .appendingPathExtension("json")
    }

    private func cacheFileName(for key: String) -> String {
        Data(key.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func defaultCacheDirectory() -> URL {
        let baseDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)

        return baseDirectory.appendingPathComponent("SpaceDataCache", isDirectory: true)
    }
}
