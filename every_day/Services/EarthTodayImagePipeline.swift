//
//  EarthTodayImagePipeline.swift
//  every_day
//

import Foundation
import UIKit

nonisolated enum EarthTodayImageMemoryCache {
    private static let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.countLimit = 24
        cache.totalCostLimit = 48 * 1_024 * 1_024
        return cache
    }()

    static func image(for url: URL) -> UIImage? {
        cache.object(forKey: url as NSURL)
    }

    static func insert(_ image: UIImage, for url: URL) {
        let cost = image.pngData()?.count ?? 0
        cache.setObject(image, forKey: url as NSURL, cost: cost)
    }
}

nonisolated enum EarthTodayImageLogger {
    static func log(_ message: String) {
        #if DEBUG
        print("[EarthTodayImage] \(message)")
        #endif
    }
}

nonisolated actor EarthTodayImagePipeline {
    static let shared = EarthTodayImagePipeline()

    private struct StoredImage: Codable, Sendable {
        let data: Data
        let storedAt: Date
        let expiration: Date
    }

    private let session: NetworkSession
    private let cacheDirectory: URL
    private let imageTTL: TimeInterval

    init(
        session: NetworkSession = URLSession.shared,
        cacheDirectory: URL? = nil,
        imageTTL: TimeInterval = 60 * 60 * 24 * 7
    ) {
        self.session = session
        self.imageTTL = imageTTL

        if let cacheDirectory {
            self.cacheDirectory = cacheDirectory
        } else {
            let baseDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
                ?? URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            self.cacheDirectory = baseDirectory.appendingPathComponent("EarthTodayImageCache", isDirectory: true)
        }
    }

    func loadImageData(for url: URL, now: Date = .now) async throws -> Data {
        let key = url.absoluteString
        EarthTodayImageLogger.log("cache key=\(key)")

        let diskLookup = await readDiskEntry(for: url, now: now)
        switch diskLookup {
        case let .valid(data):
            EarthTodayImageLogger.log("image disk cache hit")
            return data
        case let .stale(data):
            EarthTodayImageLogger.log("image disk cache hit (expired)")
            do {
                return try await fetchAndStoreImage(for: url, now: now)
            } catch {
                EarthTodayImageLogger.log("stale image disk fallback")
                return data
            }
        case .miss:
            EarthTodayImageLogger.log("image disk cache miss")
            return try await fetchAndStoreImage(for: url, now: now)
        }
    }

    private func fetchAndStoreImage(for url: URL, now: Date) async throws -> Data {
        EarthTodayImageLogger.log("network fetch triggered")

        var request = URLRequest(url: url)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 60

        let (data, response) = try await session.data(for: request)
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        guard statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        guard UIImage(data: data) != nil else {
            throw URLError(.cannotDecodeRawData)
        }

        let didWrite = await writeDiskEntry(
            StoredImage(
                data: data,
                storedAt: now,
                expiration: now.addingTimeInterval(imageTTL)
            ),
            for: url
        )

        EarthTodayImageLogger.log(didWrite ? "cache write success" : "cache write failure")
        return data
    }

    private enum DiskLookup: Sendable {
        case valid(Data)
        case stale(Data)
        case miss
    }

    private func readDiskEntry(for url: URL, now: Date) async -> DiskLookup {
        let fileURL = cacheFileURL(for: url)

        return await Task.detached(priority: .utility) {
            guard FileManager.default.fileExists(atPath: fileURL.path) else {
                return DiskLookup.miss
            }

            do {
                let data = try Data(contentsOf: fileURL)
                let entry = try JSONDecoder().decode(StoredImage.self, from: data)

                guard UIImage(data: entry.data) != nil else {
                    try? FileManager.default.removeItem(at: fileURL)
                    return .miss
                }

                return entry.expiration > now ? .valid(entry.data) : .stale(entry.data)
            } catch {
                try? FileManager.default.removeItem(at: fileURL)
                return .miss
            }
        }.value
    }

    private func writeDiskEntry(_ entry: StoredImage, for url: URL) async -> Bool {
        let directory = cacheDirectory
        let fileURL = cacheFileURL(for: url)

        return await Task.detached(priority: .utility) {
            do {
                try FileManager.default.createDirectory(
                    at: directory,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                let data = try JSONEncoder().encode(entry)
                try data.write(to: fileURL, options: .atomic)
                return true
            } catch {
                return false
            }
        }.value
    }

    private func cacheFileURL(for url: URL) -> URL {
        cacheDirectory
            .appendingPathComponent(cacheFileName(for: url), isDirectory: false)
            .appendingPathExtension("json")
    }

    private func cacheFileName(for url: URL) -> String {
        Data(url.absoluteString.utf8)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}
