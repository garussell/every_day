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

nonisolated struct NASAService {
    private let session: NetworkSession
    private let cache: SpaceDataCache
    private let baseURL = "https://api.nasa.gov"

    /// Maximum lookahead window for asteroid feed (NASA API limit).
    private static let maxAsteroidDays = 7

    init(
        session: NetworkSession = URLSession.shared,
        cache: SpaceDataCache = .shared
    ) {
        self.session = session
        self.cache = cache
    }

    static func updateAPIKey(_ key: String) {
        NASAAPIConfiguration.updateAPIKey(key)
    }

    func fetchAPOD(for date: Date = .now) async throws -> APODEntry {
        let key = "nasa.apod.\(apodCacheKey(for: date))"
        let staleValue: APODEntry?

        switch await cache.lookup(for: key, as: APODEntry.self) {
        case let .valid(cached):
            if isUsableAPOD(cached) {
                SpaceDataCacheLogger.log(.validCache, policy: .nasaAPOD, key: key)
                logAPOD(cached, context: "valid cache", requestURL: nil)
                return cached
            }
            logAPODValidationFailure(cached, context: "valid cache rejected")
            staleValue = nil
        case let .stale(cached):
            if isUsableAPOD(cached) {
                staleValue = cached
            } else {
                logAPODValidationFailure(cached, context: "stale cache rejected")
                staleValue = nil
            }
        case .miss:
            staleValue = nil
        }

        var components = URLComponents(string: "\(baseURL)/planetary/apod")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: NASAAPIConfiguration.apiKey),
            URLQueryItem(name: "thumbs", value: "true"),
            URLQueryItem(name: "date", value: apodCacheKey(for: date)),
        ]
        logAPODRequest(components)

        do {
            let decoded: NASAAPODResponse = try await request(components: components)
            let apod = APODEntry(response: decoded)
            logAPOD(apod, context: "fresh decode", requestURL: components.url)
            SpaceDataCacheLogger.log(
                staleValue == nil ? .freshNetwork : .expiredCacheRefresh,
                policy: .nasaAPOD,
                key: key
            )
            _ = await cache.store(apod, for: key, policy: .nasaAPOD)
            return apod
        } catch {
            if let staleValue {
                SpaceDataCacheLogger.log(.staleCacheFallback, policy: .nasaAPOD, key: key)
                logAPOD(staleValue, context: "stale cache fallback", requestURL: nil)
                return staleValue
            }
            throw error
        }
    }

    func fetchUpcomingAsteroids(startDate: Date = .now, daysAhead: Int = 5) async throws -> [AsteroidApproach] {
        let normalizedDays = max(1, min(daysAhead, Self.maxAsteroidDays))
        let endDate = Calendar.current.date(byAdding: .day, value: normalizedDays - 1, to: startDate) ?? startDate
        let cacheKey = "nasa.neo.\(apodCacheKey(for: startDate))-\(apodCacheKey(for: endDate))"
        let staleValue: [AsteroidApproach]?

        switch await cache.lookup(for: cacheKey, as: [AsteroidApproach].self) {
        case let .valid(cached):
            SpaceDataCacheLogger.log(.validCache, policy: .nasaNearEarthObjects, key: cacheKey)
            return cached
        case let .stale(cached):
            staleValue = cached
        case .miss:
            staleValue = nil
        }

        var components = URLComponents(string: "\(baseURL)/neo/rest/v1/feed")!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: NASAAPIConfiguration.apiKey),
            URLQueryItem(name: "start_date", value: apodCacheKey(for: startDate)),
            URLQueryItem(name: "end_date", value: apodCacheKey(for: endDate)),
        ]

        do {
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

            SpaceDataCacheLogger.log(
                staleValue == nil ? .freshNetwork : .expiredCacheRefresh,
                policy: .nasaNearEarthObjects,
                key: cacheKey
            )
            _ = await cache.store(asteroids, for: cacheKey, policy: .nasaNearEarthObjects)
            return asteroids
        } catch {
            if let staleValue {
                SpaceDataCacheLogger.log(.staleCacheFallback, policy: .nasaNearEarthObjects, key: cacheKey)
                return staleValue
            }
            throw error
        }
    }

    private func request<T: Decodable>(components: URLComponents) async throws -> T {
        guard let url = components.url else { throw URLError(.badURL) }
        let (data, response) = try await session.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        #if DEBUG
        print("[NASAService][APOD] httpStatus=\(statusCode) url=\(sanitized(url))")
        #endif
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

    private func isUsableAPOD(_ apod: APODEntry) -> Bool {
        switch apod.mediaType {
        case .image:
            return apod.displayImageURL != nil
        case .video:
            return apod.linkURL != nil || apod.thumbnailURL != nil
        case .unknown:
            return apod.displayImageURL != nil || apod.linkURL != nil
        }
    }

    private func logAPODRequest(_ components: URLComponents) {
        guard let url = components.url else { return }
        #if DEBUG
        print("[NASAService][APOD] requestURL=\(sanitized(url))")
        #endif
    }

    private func logAPOD(_ apod: APODEntry, context: String, requestURL: URL?) {
        #if DEBUG
        let requestText = requestURL.map(sanitized(_:)) ?? "n/a"
        print(
            "[NASAService][APOD] context=\(context) requestURL=\(requestText) mediaType=\(apod.mediaType.rawValue) displayURL=\(apod.displayImageURL?.absoluteString ?? "nil") hdURL=\(apod.hdURL?.absoluteString ?? "nil")"
        )
        #endif
    }

    private func logAPODValidationFailure(_ apod: APODEntry, context: String) {
        #if DEBUG
        print(
            "[NASAService][APOD] context=\(context) reason=unusable cached entry mediaType=\(apod.mediaType.rawValue) url=\(apod.url?.absoluteString ?? "nil") hdURL=\(apod.hdURL?.absoluteString ?? "nil") thumbnailURL=\(apod.thumbnailURL?.absoluteString ?? "nil")"
        )
        #endif
    }

    private func sanitized(_ url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url.absoluteString
        }
        components.queryItems = components.queryItems?.map { item in
            if item.name == "api_key" {
                return URLQueryItem(name: item.name, value: "***MASKED***")
            }
            return item
        }
        return components.string ?? url.absoluteString
    }
}
