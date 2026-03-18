//
//  NASAEarthService.swift
//  every_day
//

import Foundation

nonisolated enum NASAEarthServiceError: LocalizedError {
    case invalidResponse(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case let .invalidResponse(statusCode):
            return "NASA EPIC responded with status \(statusCode)."
        }
    }
}

nonisolated struct NASAEarthService {
    private let session: NetworkSession
    private let cache: SpaceDataCache
    private let primaryEndpoint = "https://epic.gsfc.nasa.gov/api/natural"
    private let fallbackEndpoint = "https://api.nasa.gov/EPIC/api/natural/images"

    init(
        session: NetworkSession = URLSession.shared,
        cache: SpaceDataCache = .shared
    ) {
        self.session = session
        self.cache = cache
    }

    func fetchLatestEarthImage() async throws -> EpicImage? {
        let cacheKey = "nasa.earth.epic.natural.metadata"
        let staleMetadata: [EpicImageResponse]?

        switch await cache.lookup(for: cacheKey, as: [EpicImageResponse].self) {
        case let .valid(cached):
            SpaceDataCacheLogger.log(.validCache, policy: .nasaEarthEPICMetadata, key: cacheKey)
            #if DEBUG
            print("[NASAEarthService] metadata cache hit")
            #endif
            return latestImage(from: cached)
        case let .stale(cached):
            #if DEBUG
            print("[NASAEarthService] metadata cache stale")
            #endif
            staleMetadata = cached
        case .miss:
            #if DEBUG
            print("[NASAEarthService] metadata cache miss")
            #endif
            staleMetadata = nil
        }

        do {
            let decoded = try await fetchMetadata()
            let latestImage = latestImage(from: decoded)

            #if DEBUG
            print("[NASAEarthService] decodedImages=\(decoded.count) latestImage=\(latestImage?.imageName ?? "nil") latestDate=\(latestImage?.formattedDate ?? "nil")")
            #endif

            SpaceDataCacheLogger.log(
                staleMetadata == nil ? .freshNetwork : .expiredCacheRefresh,
                policy: .nasaEarthEPICMetadata,
                key: cacheKey
            )
            _ = await cache.store(decoded, for: cacheKey, policy: .nasaEarthEPICMetadata)
            return latestImage
        } catch {
            if let staleMetadata {
                SpaceDataCacheLogger.log(.staleCacheFallback, policy: .nasaEarthEPICMetadata, key: cacheKey)
                return latestImage(from: staleMetadata)
            }
            throw error
        }
    }

    private func fetchMetadata() async throws -> [EpicImageResponse] {
        do {
            return try await requestMetadata(from: primaryEndpoint, includeAPIKey: false)
        } catch {
            #if DEBUG
            print("[NASAEarthService] Primary EPIC host failed: \(error.localizedDescription). Falling back to api.nasa.gov.")
            #endif
            return try await requestMetadata(from: fallbackEndpoint, includeAPIKey: true)
        }
    }

    private func requestMetadata(from endpoint: String, includeAPIKey: Bool) async throws -> [EpicImageResponse] {
        var components = URLComponents(string: endpoint)!
        if includeAPIKey {
            components.queryItems = [
                URLQueryItem(name: "api_key", value: NASAAPIConfiguration.apiKey),
            ]
        }

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await session.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            throw NASAEarthServiceError.invalidResponse(statusCode: statusCode)
        }

        #if DEBUG
        print("[NASAEarthService] endpoint=\(endpoint) status=\(statusCode) bytes=\(data.count)")
        #endif

        return try JSONDecoder().decode([EpicImageResponse].self, from: data)
    }

    private func latestImage(from responses: [EpicImageResponse]) -> EpicImage? {
        responses
            .compactMap(EpicImage.init(response:))
            .sorted { $0.date > $1.date }
            .first
    }
}
