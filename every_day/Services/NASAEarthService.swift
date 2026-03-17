//
//  NASAEarthService.swift
//  every_day
//

import Foundation

enum NASAEarthServiceError: LocalizedError {
    case invalidResponse(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case let .invalidResponse(statusCode):
            return "NASA EPIC responded with status \(statusCode)."
        }
    }
}

private actor NASAEarthCache {
    private struct Entry {
        let image: EpicImage
        let expiration: Date
    }

    private var entry: Entry?

    func latestImage() -> EpicImage? {
        guard let entry else { return nil }
        guard entry.expiration > Date() else {
            self.entry = nil
            return nil
        }
        return entry.image
    }

    func store(_ image: EpicImage) {
        let calendar = Calendar(identifier: .gregorian)
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: .now))
            ?? Date().addingTimeInterval(60 * 60 * 12)
        entry = Entry(image: image, expiration: tomorrow)
    }
}

struct NASAEarthService {
    private static let cache = NASAEarthCache()

    private let primaryEndpoint = "https://epic.gsfc.nasa.gov/api/natural"
    private let fallbackEndpoint = "https://api.nasa.gov/EPIC/api/natural/images"

    func fetchLatestEarthImage() async throws -> EpicImage? {
        if let cached = await Self.cache.latestImage() {
            return cached
        }

        let decoded = try await fetchMetadata()
        let latestImage = decoded
            .compactMap(EpicImage.init(response:))
            .sorted { $0.date > $1.date }
            .first

        #if DEBUG
        print("[NASAEarthService] decodedImages=\(decoded.count) latestImage=\(latestImage?.imageName ?? "nil") latestDate=\(latestImage?.formattedDate ?? "nil")")
        #endif

        if let latestImage {
            await Self.cache.store(latestImage)
        }

        return latestImage
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

        let (data, response) = try await URLSession.shared.data(from: url)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard statusCode == 200 else {
            throw NASAEarthServiceError.invalidResponse(statusCode: statusCode)
        }

        #if DEBUG
        print("[NASAEarthService] endpoint=\(endpoint) status=\(statusCode) bytes=\(data.count)")
        #endif

        return try JSONDecoder().decode([EpicImageResponse].self, from: data)
    }
}
