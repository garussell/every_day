//
//  SolarSystemService.swift
//  every_day
//

import Foundation

nonisolated enum SpaceServiceError: LocalizedError {
    case missingSolarSystemToken
    case invalidResponse(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .missingSolarSystemToken:
            return "Add a Solar System OpenData token in Secrets.swift to unlock live sky data."
        case let .invalidResponse(statusCode):
            return "The space data service responded with status \(statusCode)."
        }
    }
}

nonisolated struct SolarSystemService {
    private static let keychainAccount = "solar_system_opendata_token"
    private let session: NetworkSession
    private let cache: SpaceDataCache
    private let bodiesURL = "https://api.le-systeme-solaire.net/rest/bodies/"
    private let positionsURL = "https://api.le-systeme-solaire.net/rest/positions"

    init(
        session: NetworkSession = URLSession.shared,
        cache: SpaceDataCache = .shared
    ) {
        self.session = session
        self.cache = cache
    }

    private var bearerToken: String {
        (KeychainHelper.load(for: Self.keychainAccount) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func updateAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainHelper.delete(for: keychainAccount)
        } else {
            KeychainHelper.save(trimmed, for: keychainAccount)
        }
    }

    func fetchPlanets() async throws -> [PlanetaryBody] {
        let token = bearerToken
        guard !token.isEmpty else {
            throw SpaceServiceError.missingSolarSystemToken
        }

        let cacheKey = "solar-system.bodies.planets.reference"
        let staleValue: SolarSystemBodiesResponse?

        switch await cache.lookup(for: cacheKey, as: SolarSystemBodiesResponse.self) {
        case let .valid(cached):
            SpaceDataCacheLogger.log(.validCache, policy: .solarSystemReferenceData, key: cacheKey)
            return mapPlanets(from: cached)
        case let .stale(cached):
            staleValue = cached
        case .miss:
            staleValue = nil
        }

        var components = URLComponents(string: bodiesURL)!
        components.queryItems = [
            URLQueryItem(name: "filter[]", value: "isPlanet,eq,true"),
            URLQueryItem(
                name: "data",
                value: "id,name,englishName,isPlanet,moons,bodyType,gravity,meanRadius,sideralOrbit,sideralRotation,avgTemp,density,discoveredBy,discoveryDate"
            ),
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard statusCode == 200 else {
                throw SpaceServiceError.invalidResponse(statusCode: statusCode)
            }

            let decoded = try JSONDecoder().decode(SolarSystemBodiesResponse.self, from: data)
            SpaceDataCacheLogger.log(
                staleValue == nil ? .freshNetwork : .expiredCacheRefresh,
                policy: .solarSystemReferenceData,
                key: cacheKey
            )
            _ = await cache.store(decoded, for: cacheKey, policy: .solarSystemReferenceData)
            return mapPlanets(from: decoded)
        } catch {
            if let staleValue {
                SpaceDataCacheLogger.log(.staleCacheFallback, policy: .solarSystemReferenceData, key: cacheKey)
                return mapPlanets(from: staleValue)
            }
            throw error
        }
    }

    func fetchSkyPositions(
        observer: SkyObserverContext,
        timeZone: TimeZone = .current
    ) async throws -> [SkyPositionObservation] {
        let token = bearerToken
        guard !token.isEmpty else {
            throw SpaceServiceError.missingSolarSystemToken
        }

        let cacheDate = roundedForCache(observer.date, interval: 60 * 15)
        let cacheKey = [
            "solar-system.positions",
            formattedCoordinate(observer.latitude),
            formattedCoordinate(observer.longitude),
            formattedElevation(observer.altitudeMeters),
            formattedDate(cacheDate, timeZone: timeZone),
            formattedTimeZoneOffset(for: cacheDate, timeZone: timeZone),
        ].joined(separator: "|")
        let staleValue: SkyPositionsResponse?

        switch await cache.lookup(for: cacheKey, as: SkyPositionsResponse.self) {
        case let .valid(cached):
            SpaceDataCacheLogger.log(.validCache, policy: .solarSystemSkyPositions, key: cacheKey)
            return cached.positions.map(\.observation)
        case let .stale(cached):
            staleValue = cached
        case .miss:
            staleValue = nil
        }

        var components = URLComponents(string: positionsURL)!
        components.queryItems = [
            URLQueryItem(name: "lon", value: formattedCoordinate(observer.longitude)),
            URLQueryItem(name: "lat", value: formattedCoordinate(observer.latitude)),
            URLQueryItem(name: "elev", value: formattedElevation(observer.altitudeMeters)),
            URLQueryItem(name: "datetime", value: formattedDate(observer.date, timeZone: timeZone)),
            URLQueryItem(name: "zone", value: formattedTimeZoneOffset(for: observer.date, timeZone: timeZone)),
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await session.data(for: request)
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            guard statusCode == 200 else {
                throw SpaceServiceError.invalidResponse(statusCode: statusCode)
            }

            let decoded = try JSONDecoder().decode(SkyPositionsResponse.self, from: data)

            #if DEBUG
            print("SkyTonight positions decoded: \(decoded.positions.count)")
            #endif

            SpaceDataCacheLogger.log(
                staleValue == nil ? .freshNetwork : .expiredCacheRefresh,
                policy: .solarSystemSkyPositions,
                key: cacheKey
            )
            _ = await cache.store(decoded, for: cacheKey, policy: .solarSystemSkyPositions)
            return decoded.positions.map(\.observation)
        } catch {
            if let staleValue {
                SpaceDataCacheLogger.log(.staleCacheFallback, policy: .solarSystemSkyPositions, key: cacheKey)
                return staleValue.positions.map(\.observation)
            }
            throw error
        }
    }

    private func formattedCoordinate(_ value: Double) -> String {
        String(format: "%.4f", value)
    }

    private func formattedElevation(_ value: Double) -> String {
        String(format: "%.0f", value)
    }

    private static let iso8601Formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return f
    }()

    private func formattedDate(_ date: Date, timeZone: TimeZone) -> String {
        Self.iso8601Formatter.timeZone = timeZone
        return Self.iso8601Formatter.string(from: date)
    }

    private func formattedTimeZoneOffset(for date: Date, timeZone: TimeZone) -> String {
        let hours = Double(timeZone.secondsFromGMT(for: date)) / 3600
        if hours.rounded(.towardZero) == hours {
            return String(format: "%.0f", hours)
        }
        return String(format: "%.1f", hours)
    }

    private func mapPlanets(from response: SolarSystemBodiesResponse) -> [PlanetaryBody] {
        let fallbackByTheme = Dictionary(uniqueKeysWithValues: PlanetaryBody.mockPlanets.map { ($0.theme, $0) })

        return response.bodies
            .filter { $0.isPlanet ?? false }
            .compactMap { body -> PlanetaryBody? in
                let nameForTheme = body.englishName.isEmpty ? body.name : body.englishName
                let descriptor = PlanetTheme(apiName: nameForTheme)
                    .flatMap { fallbackByTheme[$0]?.descriptor }
                    ?? "A quiet world in our solar system."
                return PlanetaryBody(solarSystemBody: body, descriptor: descriptor)
            }
            .sorted { lhs, rhs in
                let lhsIndex = PlanetTheme.ordered.firstIndex(of: lhs.theme) ?? 0
                let rhsIndex = PlanetTheme.ordered.firstIndex(of: rhs.theme) ?? 0
                return lhsIndex < rhsIndex
            }
    }

    private func roundedForCache(_ date: Date, interval: TimeInterval) -> Date {
        let seconds = floor(date.timeIntervalSinceReferenceDate / interval) * interval
        return Date(timeIntervalSinceReferenceDate: seconds)
    }
}
