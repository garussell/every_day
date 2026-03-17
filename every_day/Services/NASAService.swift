//
//  NASAService.swift
//  every_day
//

import Foundation

enum NASAServiceError: LocalizedError {
    case invalidResponse(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case let .invalidResponse(statusCode):
            return "NASA responded with status \(statusCode)."
        }
    }
}

struct NASAService {
    private static let cache = SpaceDataCache()

    private let baseURL = "https://api.nasa.gov"

    /// Cache TTL for Astronomy Picture of the Day (2 hours).
    private static let apodCacheTTL: TimeInterval = 60 * 60 * 2
    /// Cache TTL for near-Earth asteroid data (1 hour).
    private static let asteroidCacheTTL: TimeInterval = 60 * 60
    /// Maximum lookahead window for asteroid feed (NASA API limit).
    private static let maxAsteroidDays = 7

    static func updateAPIKey(_ key: String) {
        NASAAPIConfiguration.updateAPIKey(key)
    }

    func fetchAPOD(for date: Date = .now) async throws -> APODEntry {
        let key = apodCacheKey(for: date)
        if let cached = await Self.cache.apod(for: key) {
            return cached
        }

        var components = URLComponents(string: "\(baseURL)/planetary/apod")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: NASAAPIConfiguration.apiKey),
            URLQueryItem(name: "thumbs", value: "true"),
            URLQueryItem(name: "date", value: key),
        ]

        let decoded: NASAAPODResponse = try await request(components: components)
        let apod = APODEntry(response: decoded)
        await Self.cache.store(apod: apod, key: key, ttl: Self.apodCacheTTL)
        return apod
    }

    func fetchUpcomingAsteroids(startDate: Date = .now, daysAhead: Int = 5) async throws -> [AsteroidApproach] {
        let normalizedDays = max(1, min(daysAhead, Self.maxAsteroidDays))
        let endDate = Calendar.current.date(byAdding: .day, value: normalizedDays - 1, to: startDate) ?? startDate
        let cacheKey = "\(apodCacheKey(for: startDate))-\(apodCacheKey(for: endDate))"

        if let cached = await Self.cache.asteroids(for: cacheKey) {
            return cached
        }

        var components = URLComponents(string: "\(baseURL)/neo/rest/v1/feed")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: NASAAPIConfiguration.apiKey),
            URLQueryItem(name: "start_date", value: apodCacheKey(for: startDate)),
            URLQueryItem(name: "end_date", value: apodCacheKey(for: endDate)),
        ]

        let decoded: NASANEOFeedResponse = try await request(components: components)

        let asteroids = decoded.nearEarthObjects
            .values
            .flatMap { $0 }
            .compactMap { neo -> AsteroidApproach? in
                guard let closeApproach = neo.closeApproachData.first else { return nil }
                return AsteroidApproach(neo: neo, closeApproach: closeApproach)
            }
            .sorted { lhs, rhs in
                switch (lhs.approachDate, rhs.approachDate) {
                case let (.some(lhsDate), .some(rhsDate)):
                    return lhsDate < rhsDate
                case (.some, .none):
                    return true
                case (.none, .some):
                    return false
                case (.none, .none):
                    return lhs.name < rhs.name
                }
            }

        await Self.cache.store(asteroids: asteroids, key: cacheKey, ttl: Self.asteroidCacheTTL)
        return asteroids
    }

    private func request<T: Decodable>(components: URLComponents) async throws -> T {
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            throw NASAServiceError.invalidResponse(statusCode: statusCode)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static let cacheKeyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private func apodCacheKey(for date: Date) -> String {
        Self.cacheKeyFormatter.string(from: date)
    }
}
