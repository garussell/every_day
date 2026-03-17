//
//  CosmosModels.swift
//  every_day
//

import Foundation

enum PlanetTheme: String, CaseIterable, Hashable {
    case mercury
    case venus
    case earth
    case mars
    case jupiter
    case saturn
    case uranus
    case neptune

    static let ordered: [PlanetTheme] = [
        .mercury, .venus, .earth, .mars, .jupiter, .saturn, .uranus, .neptune
    ]

    init?(apiName: String) {
        switch apiName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "mercury", "mercure":
            self = .mercury
        case "venus", "vénus":
            self = .venus
        case "earth", "terre":
            self = .earth
        case "mars":
            self = .mars
        case "jupiter":
            self = .jupiter
        case "saturn", "saturne":
            self = .saturn
        case "uranus":
            self = .uranus
        case "neptune", "neptun":
            self = .neptune
        default:
            return nil
        }
    }
}

enum SpaceDataSource: String, Hashable {
    case mock
    case live
}

struct PlanetaryBody: Identifiable, Hashable {
    let id: String
    let name: String
    let englishName: String
    let descriptor: String
    let bodyType: String
    let gravity: Double?
    let meanRadius: Double?
    let orbitalPeriodDays: Double?
    let rotationHours: Double?
    let averageTemperatureC: Double?
    let density: Double?
    let moonCount: Int?
    let discoveredBy: String?
    let discoveryDate: String?
    let theme: PlanetTheme
    let dataSource: SpaceDataSource

    var displayName: String {
        let trimmedEnglish = englishName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedEnglish.isEmpty { return trimmedEnglish }
        return name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var sourceBadgeText: String {
        dataSource == .live ? "Live data" : "Mock preview"
    }

    var radiusText: String {
        formattedValue(meanRadius, unit: "km", maximumFractionDigits: 0)
    }

    var gravityText: String {
        formattedValue(gravity, unit: "m/s²", maximumFractionDigits: 2)
    }

    var orbitalPeriodText: String {
        guard let orbitalPeriodDays else { return "Unknown" }
        if orbitalPeriodDays >= 365 {
            let years = orbitalPeriodDays / 365
            return "\(Self.formattedNumber(years, maximumFractionDigits: 1)) years"
        }
        return "\(Self.formattedNumber(orbitalPeriodDays, maximumFractionDigits: 0)) days"
    }

    var rotationText: String {
        guard let rotationHours else { return "Unknown" }
        let absoluteHours = abs(rotationHours)
        let prefix = rotationHours < 0 ? "Retrograde " : ""

        if absoluteHours >= 24 {
            let days = absoluteHours / 24
            return "\(prefix)\(Self.formattedNumber(days, maximumFractionDigits: days > 100 ? 0 : 1)) days"
        }

        return "\(prefix)\(Self.formattedNumber(absoluteHours, maximumFractionDigits: 1)) hours"
    }

    var moonCountText: String {
        guard let moonCount else { return "Unknown" }
        return moonCount == 1 ? "1 moon" : "\(moonCount) moons"
    }

    var densityText: String {
        formattedValue(density, unit: "g/cm³", maximumFractionDigits: 2)
    }

    var temperatureText: String {
        formattedValue(averageTemperatureC, unit: "°C", maximumFractionDigits: 0)
    }

    var discoveryText: String? {
        let discoverer = discoveredBy?.trimmingCharacters(in: .whitespacesAndNewlines)
        let date = discoveryDate?.trimmingCharacters(in: .whitespacesAndNewlines)

        switch (discoverer?.isEmpty == false ? discoverer : nil, date?.isEmpty == false ? date : nil) {
        case let (.some(discoverer), .some(date)):
            return "\(discoverer), \(date)"
        case let (.some(discoverer), .none):
            return discoverer
        case let (.none, .some(date)):
            return date
        case (.none, .none):
            return nil
        }
    }

    static let mockPlanets: [PlanetaryBody] = [
        PlanetaryBody(
            id: "mercury",
            name: "Mercury",
            englishName: "Mercury",
            descriptor: "A swift, sun-drenched world of iron and silence.",
            bodyType: "Planet",
            gravity: 3.7,
            meanRadius: 2_439.7,
            orbitalPeriodDays: 88,
            rotationHours: 1_407.6,
            averageTemperatureC: 167,
            density: 5.43,
            moonCount: 0,
            discoveredBy: nil,
            discoveryDate: nil,
            theme: .mercury,
            dataSource: .mock
        ),
        PlanetaryBody(
            id: "venus",
            name: "Venus",
            englishName: "Venus",
            descriptor: "A veiled world glowing beneath thick golden clouds.",
            bodyType: "Planet",
            gravity: 8.87,
            meanRadius: 6_051.8,
            orbitalPeriodDays: 225,
            rotationHours: -5_832.5,
            averageTemperatureC: 464,
            density: 5.24,
            moonCount: 0,
            discoveredBy: nil,
            discoveryDate: nil,
            theme: .venus,
            dataSource: .mock
        ),
        PlanetaryBody(
            id: "earth",
            name: "Earth",
            englishName: "Earth",
            descriptor: "Our blue refuge, shaped by oceans, weather, and wonder.",
            bodyType: "Planet",
            gravity: 9.81,
            meanRadius: 6_371,
            orbitalPeriodDays: 365.25,
            rotationHours: 23.93,
            averageTemperatureC: 15,
            density: 5.51,
            moonCount: 1,
            discoveredBy: nil,
            discoveryDate: nil,
            theme: .earth,
            dataSource: .mock
        ),
        PlanetaryBody(
            id: "mars",
            name: "Mars",
            englishName: "Mars",
            descriptor: "A rust-red frontier etched with ancient valleys and dust.",
            bodyType: "Planet",
            gravity: 3.71,
            meanRadius: 3_389.5,
            orbitalPeriodDays: 687,
            rotationHours: 24.6,
            averageTemperatureC: -63,
            density: 3.93,
            moonCount: 2,
            discoveredBy: nil,
            discoveryDate: nil,
            theme: .mars,
            dataSource: .mock
        ),
        PlanetaryBody(
            id: "jupiter",
            name: "Jupiter",
            englishName: "Jupiter",
            descriptor: "A vast striped giant with storms older than memory.",
            bodyType: "Planet",
            gravity: 24.79,
            meanRadius: 69_911,
            orbitalPeriodDays: 4_333,
            rotationHours: 9.9,
            averageTemperatureC: -110,
            density: 1.33,
            moonCount: 95,
            discoveredBy: nil,
            discoveryDate: nil,
            theme: .jupiter,
            dataSource: .mock
        ),
        PlanetaryBody(
            id: "saturn",
            name: "Saturn",
            englishName: "Saturn",
            descriptor: "A ringed lantern drifting at the edge of the inner dark.",
            bodyType: "Planet",
            gravity: 10.44,
            meanRadius: 58_232,
            orbitalPeriodDays: 10_759,
            rotationHours: 10.7,
            averageTemperatureC: -140,
            density: 0.69,
            moonCount: 146,
            discoveredBy: nil,
            discoveryDate: nil,
            theme: .saturn,
            dataSource: .mock
        ),
        PlanetaryBody(
            id: "uranus",
            name: "Uranus",
            englishName: "Uranus",
            descriptor: "An ice giant tilted into a long, luminous hush.",
            bodyType: "Planet",
            gravity: 8.69,
            meanRadius: 25_362,
            orbitalPeriodDays: 30_687,
            rotationHours: -17.2,
            averageTemperatureC: -195,
            density: 1.27,
            moonCount: 28,
            discoveredBy: "William Herschel",
            discoveryDate: "1781",
            theme: .uranus,
            dataSource: .mock
        ),
        PlanetaryBody(
            id: "neptune",
            name: "Neptune",
            englishName: "Neptune",
            descriptor: "A deep cobalt world where fierce winds circle in cold light.",
            bodyType: "Planet",
            gravity: 11.15,
            meanRadius: 24_622,
            orbitalPeriodDays: 60_190,
            rotationHours: 16.1,
            averageTemperatureC: -200,
            density: 1.64,
            moonCount: 16,
            discoveredBy: "Urbain Le Verrier",
            discoveryDate: "1846",
            theme: .neptune,
            dataSource: .mock
        ),
    ]

    static func mergedWithFallback(livePlanets: [PlanetaryBody], fallbackPlanets: [PlanetaryBody]) -> [PlanetaryBody] {
        let liveByTheme = Dictionary(uniqueKeysWithValues: livePlanets.map { ($0.theme, $0) })
        let fallbackByTheme = Dictionary(uniqueKeysWithValues: fallbackPlanets.map { ($0.theme, $0) })

        return PlanetTheme.ordered.compactMap { theme in
            if let livePlanet = liveByTheme[theme] {
                return livePlanet.mergingMissingDetails(from: fallbackByTheme[theme])
            }
            return fallbackByTheme[theme]
        }
    }

    private func mergingMissingDetails(from fallback: PlanetaryBody?) -> PlanetaryBody {
        guard let fallback else { return self }

        return PlanetaryBody(
            id: id,
            name: name.isEmpty ? fallback.name : name,
            englishName: englishName.isEmpty ? fallback.englishName : englishName,
            descriptor: descriptor.isEmpty ? fallback.descriptor : descriptor,
            bodyType: bodyType.isEmpty ? fallback.bodyType : bodyType,
            gravity: gravity ?? fallback.gravity,
            meanRadius: meanRadius ?? fallback.meanRadius,
            orbitalPeriodDays: orbitalPeriodDays ?? fallback.orbitalPeriodDays,
            rotationHours: rotationHours ?? fallback.rotationHours,
            averageTemperatureC: averageTemperatureC ?? fallback.averageTemperatureC,
            density: density ?? fallback.density,
            moonCount: moonCount ?? fallback.moonCount,
            discoveredBy: Self.normalizedString(discoveredBy) ?? fallback.discoveredBy,
            discoveryDate: Self.normalizedString(discoveryDate) ?? fallback.discoveryDate,
            theme: theme,
            dataSource: dataSource
        )
    }

    private static func normalizedString(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }

    private func formattedValue(_ value: Double?, unit: String, maximumFractionDigits: Int) -> String {
        guard let value else { return "Unknown" }
        return "\(Self.formattedNumber(value, maximumFractionDigits: maximumFractionDigits)) \(unit)"
    }

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.minimumFractionDigits = 0
        return f
    }()

    private static func formattedNumber(_ value: Double, maximumFractionDigits: Int) -> String {
        Self.numberFormatter.maximumFractionDigits = maximumFractionDigits
        return Self.numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

enum APODMediaType: String, Decodable {
    case image
    case video
    case unknown

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = (try? container.decode(String.self)) ?? ""
        self = APODMediaType(rawValue: value) ?? .unknown
    }
}

struct APODEntry: Identifiable, Hashable {
    let id: String
    let title: String
    let dateString: String
    let explanation: String
    let mediaType: APODMediaType
    let url: URL?
    let hdURL: URL?
    let thumbnailURL: URL?
    let copyright: String?

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let displayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .long
        return f
    }()

    var heroURL: URL? {
        switch mediaType {
        case .image:
            return hdURL ?? url
        case .video:
            return thumbnailURL
        case .unknown:
            return url
        }
    }

    var dateText: String {
        guard let date = Self.isoFormatter.date(from: dateString) else { return dateString }
        return Self.displayFormatter.string(from: date)
    }

    var linkURL: URL? {
        url ?? hdURL
    }

    var creditText: String? {
        guard let copyright,
              !copyright.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        return copyright
    }
}

struct AsteroidApproach: Identifiable, Hashable {
    let id: String
    let name: String
    let approachDate: Date?
    let estimatedDiameterMinKilometers: Double?
    let estimatedDiameterMaxKilometers: Double?
    let missDistanceKilometers: Double?
    let relativeVelocityKilometersPerHour: Double?
    let isPotentiallyHazardous: Bool

    private static let approachFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var approachDateText: String {
        guard let approachDate else { return "Date unavailable" }
        return Self.approachFormatter.string(from: approachDate)
    }

    var sizeText: String {
        switch (estimatedDiameterMinKilometers, estimatedDiameterMaxKilometers) {
        case let (.some(min), .some(max)):
            return "\(formattedNumber(min * 1_000, maximumFractionDigits: 0))–\(formattedNumber(max * 1_000, maximumFractionDigits: 0)) m"
        case let (.some(min), .none):
            return "About \(formattedNumber(min * 1_000, maximumFractionDigits: 0)) m"
        case let (.none, .some(max)):
            return "Up to \(formattedNumber(max * 1_000, maximumFractionDigits: 0)) m"
        case (.none, .none):
            return "Size unavailable"
        }
    }

    var missDistanceText: String {
        guard let missDistanceKilometers else { return "Unknown miss distance" }
        return "\(formattedNumber(missDistanceKilometers, maximumFractionDigits: 0)) km away"
    }

    var velocityText: String {
        guard let relativeVelocityKilometersPerHour else { return "Unknown speed" }
        return "\(formattedNumber(relativeVelocityKilometersPerHour, maximumFractionDigits: 0)) km/h"
    }

    var hazardText: String {
        isPotentiallyHazardous ? "Potentially hazardous" : "Low hazard"
    }

    private static let numberFormatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        return f
    }()

    private func formattedNumber(_ value: Double, maximumFractionDigits: Int) -> String {
        Self.numberFormatter.maximumFractionDigits = maximumFractionDigits
        return Self.numberFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }
}

struct SkyObserverContext: Hashable {
    let latitude: Double
    let longitude: Double
    let altitudeMeters: Double
    let date: Date
}

struct SkyTonightPreview: Hashable {
    let title: String
    let message: String

    static let comingSoon = SkyTonightPreview(
        title: "Sky Tonight",
        message: "Coming soon: nightly guidance based on your location, local sky conditions, and planetary positions."
    )
}

protocol SkyTonightProviding {
    func fetchPreview(for observer: SkyObserverContext) async throws -> SkyTonightPreview
}
