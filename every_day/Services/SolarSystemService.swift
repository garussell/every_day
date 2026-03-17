//
//  SolarSystemService.swift
//  every_day
//

import Foundation

enum SpaceServiceError: LocalizedError {
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

struct SolarSystemService {
    private static let keychainAccount = "solar_system_opendata_token"
    private static let cache = SpaceDataCache()
    /// Cache TTL for planet data (12 hours — changes infrequently).
    private static let planetCacheTTL: TimeInterval = 60 * 60 * 12

    private let bodiesURL = "https://api.le-systeme-solaire.net/rest/bodies/"
    private let positionsURL = "https://api.le-systeme-solaire.net/rest/positions"

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
        if let cached = await Self.cache.planets() {
            return cached
        }

        let token = bearerToken
        guard !token.isEmpty else {
            throw SpaceServiceError.missingSolarSystemToken
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

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            throw SpaceServiceError.invalidResponse(statusCode: statusCode)
        }

        let decoded = try JSONDecoder().decode(SolarSystemBodiesResponse.self, from: data)

        let fallbackByTheme = Dictionary(uniqueKeysWithValues: PlanetaryBody.mockPlanets.map { ($0.theme, $0) })

        let planets = decoded.bodies
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

        await Self.cache.store(planets: planets, ttl: Self.planetCacheTTL)
        return planets
    }

    func fetchSkyPositions(
        observer: SkyObserverContext,
        timeZone: TimeZone = .current
    ) async throws -> [SkyPositionObservation] {
        let token = bearerToken
        guard !token.isEmpty else {
            throw SpaceServiceError.missingSolarSystemToken
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

        let (data, response) = try await URLSession.shared.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            throw SpaceServiceError.invalidResponse(statusCode: statusCode)
        }

        let decoded = try JSONDecoder().decode(SkyPositionsResponse.self, from: data)

        #if DEBUG
        print("SkyTonight positions decoded: \(decoded.positions.count)")
        #endif

        return decoded.positions.map(\.observation)
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
}
