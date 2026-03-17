//
//  SkyTonightModels.swift
//  every_day
//

import Foundation

struct SkyPositionsResponse: Decodable {
    let positions: [SkyPositionPayload]
}

struct SkyPositionPayload: Decodable {
    let name: String
    let rightAscension: String?
    let declination: String?
    let azimuth: String?
    let altitude: String?

    enum CodingKeys: String, CodingKey {
        case name
        case rightAscension = "ra"
        case declination = "dec"
        case azimuth = "az"
        case altitude = "alt"
    }

    var observation: SkyPositionObservation {
        SkyPositionObservation(
            sourceName: name,
            rightAscensionText: rightAscension,
            declinationText: declination,
            azimuthText: azimuth,
            altitudeText: altitude
        )
    }
}

struct SkyPositionObservation: Hashable {
    let sourceName: String
    let rightAscensionText: String?
    let declinationText: String?
    let azimuthText: String?
    let altitudeText: String?

    var kind: SkyObjectKind? {
        SkyObjectKind(apiName: sourceName)
    }

    var azimuthDegrees: Double? {
        Self.parseAngle(azimuthText)
    }

    var altitudeDegrees: Double? {
        Self.parseAngle(altitudeText)
    }

    private static func parseAngle(_ value: String?) -> Double? {
        guard let rawValue = value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "−", with: "-"),
              !rawValue.isEmpty else {
            return nil
        }

        if let direct = Double(rawValue) {
            return direct
        }

        let degreeParts = rawValue.split(separator: "°", maxSplits: 1, omittingEmptySubsequences: false)
        guard let degreeComponent = degreeParts.first, let degrees = Double(degreeComponent) else {
            return nil
        }

        let sign = degrees < 0 ? -1.0 : 1.0
        let absoluteDegrees = abs(degrees)

        guard degreeParts.count == 2 else { return degrees }

        let remainder = String(degreeParts[1])
        let minuteParts = remainder.split(separator: "'", maxSplits: 1, omittingEmptySubsequences: false)
        let minutes = minuteParts.first.flatMap { Double($0) } ?? 0

        var seconds = 0.0
        if minuteParts.count == 2 {
            let secondText = minuteParts[1].replacingOccurrences(of: "\"", with: "")
            seconds = Double(secondText) ?? 0
        }

        return sign * (absoluteDegrees + minutes / 60 + seconds / 3600)
    }
}

enum SkyObjectKind: String, CaseIterable, Hashable {
    case sun
    case moon
    case mercury
    case venus
    case mars
    case jupiter
    case saturn

    static let featuredOrder: [SkyObjectKind] = [
        .moon, .mercury, .venus, .mars, .jupiter, .saturn,
    ]

    init?(apiName: String) {
        switch apiName.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current).lowercased() {
        case "sun", "soleil":
            self = .sun
        case "moon", "lune":
            self = .moon
        case "mercury", "mercure":
            self = .mercury
        case "venus":
            self = .venus
        case "mars":
            self = .mars
        case "jupiter":
            self = .jupiter
        case "saturn", "saturne":
            self = .saturn
        default:
            return nil
        }
    }

    var displayName: String {
        switch self {
        case .sun:
            return "Sun"
        case .moon:
            return "Moon"
        case .mercury:
            return "Mercury"
        case .venus:
            return "Venus"
        case .mars:
            return "Mars"
        case .jupiter:
            return "Jupiter"
        case .saturn:
            return "Saturn"
        }
    }

    var symbolName: String {
        switch self {
        case .sun:
            return "sun.max.fill"
        case .moon:
            return "moon.fill"
        case .mercury:
            return "sparkles"
        case .venus:
            return "sun.haze.fill"
        case .mars:
            return "flame.fill"
        case .jupiter:
            return "hurricane"
        case .saturn:
            return "circle.hexagongrid.fill"
        }
    }
}

enum SkyViewingQuality: String, Hashable {
    case excellent
    case moderate
    case poor
    case notVisible
    case unavailable

    init(altitude: Double?) {
        guard let altitude else {
            self = .unavailable
            return
        }

        switch altitude {
        case ..<0:
            self = .notVisible
        case 0..<20:
            self = .poor
        case 20..<45:
            self = .moderate
        default:
            self = .excellent
        }
    }

    var label: String {
        switch self {
        case .excellent:
            return "Excellent"
        case .moderate:
            return "Moderate"
        case .poor:
            return "Low"
        case .notVisible:
            return "Below horizon"
        case .unavailable:
            return "Unavailable"
        }
    }
}

enum CompassDirection: String, Hashable {
    case north = "N"
    case northEast = "NE"
    case east = "E"
    case southEast = "SE"
    case south = "S"
    case southWest = "SW"
    case west = "W"
    case northWest = "NW"

    init?(azimuthDegrees: Double?) {
        guard let azimuthDegrees else { return nil }
        let normalized = azimuthDegrees.truncatingRemainder(dividingBy: 360)
        let positive = normalized >= 0 ? normalized : normalized + 360

        switch positive {
        case 337.5..., ..<22.5:
            self = .north
        case 22.5..<67.5:
            self = .northEast
        case 67.5..<112.5:
            self = .east
        case 112.5..<157.5:
            self = .southEast
        case 157.5..<202.5:
            self = .south
        case 202.5..<247.5:
            self = .southWest
        case 247.5..<292.5:
            self = .west
        default:
            self = .northWest
        }
    }

    var spokenName: String {
        switch self {
        case .north:
            return "north"
        case .northEast:
            return "northeast"
        case .east:
            return "east"
        case .southEast:
            return "southeast"
        case .south:
            return "south"
        case .southWest:
            return "southwest"
        case .west:
            return "west"
        case .northWest:
            return "northwest"
        }
    }
}

struct SkyObject: Identifiable, Hashable {
    let kind: SkyObjectKind
    let altitudeDegrees: Double?
    let azimuthDegrees: Double?
    let rightAscensionText: String?
    let declinationText: String?
    let isAboveHorizon: Bool
    let viewingQuality: SkyViewingQuality
    let direction: CompassDirection?
    let note: String

    init(kind: SkyObjectKind, observation: SkyPositionObservation?, sunAltitudeDegrees: Double?) {
        self.kind = kind
        self.altitudeDegrees = observation?.altitudeDegrees
        self.azimuthDegrees = observation?.azimuthDegrees
        self.rightAscensionText = observation?.rightAscensionText
        self.declinationText = observation?.declinationText
        self.viewingQuality = SkyViewingQuality(altitude: observation?.altitudeDegrees)
        self.direction = CompassDirection(azimuthDegrees: observation?.azimuthDegrees)
        self.isAboveHorizon = (observation?.altitudeDegrees ?? -90) > 0
        self.note = SkyObject.makeNote(
            altitudeDegrees: observation?.altitudeDegrees,
            direction: direction,
            sunAltitudeDegrees: sunAltitudeDegrees
        )
    }

    var id: String {
        kind.rawValue
    }

    var name: String {
        kind.displayName
    }

    var symbolName: String {
        kind.symbolName
    }

    var aboveHorizonText: String {
        isAboveHorizon ? "Yes" : "No"
    }

    var altitudeText: String {
        guard let altitudeDegrees else { return "Unavailable" }
        return "\(Self.formattedDegrees(altitudeDegrees))°"
    }

    var azimuthText: String {
        guard let azimuthDegrees else { return "Unavailable" }
        let degreeText = "\(Self.formattedDegrees(azimuthDegrees))°"
        if let direction {
            return "\(direction.rawValue) • \(degreeText)"
        }
        return degreeText
    }

    private static func makeNote(
        altitudeDegrees: Double?,
        direction: CompassDirection?,
        sunAltitudeDegrees: Double?
    ) -> String {
        guard let altitudeDegrees else {
            return "Position data is unavailable right now"
        }

        guard altitudeDegrees > 0 else {
            return "Currently below the horizon"
        }

        let directionText = direction?.spokenName ?? "sky"

        if let sunAltitudeDegrees, sunAltitudeDegrees > 0 {
            return "Visible in the \(directionText), but easier after sunset"
        }

        switch altitudeDegrees {
        case 55...:
            return "High in the \(directionText)"
        case 30..<55:
            return "Well placed in the \(directionText)"
        case 10..<30:
            return "Visible low in the \(directionText)"
        default:
            return "Best seen soon, low in the \(directionText)"
        }
    }

    private static func formattedDegrees(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
    }
}

struct SkyViewingConditions: Hashable {
    let condition: String?
    let cloudCoverPercent: Int?
    let temperatureF: Double?
    let windSpeedMph: Double?
    let humidityPercent: Int?

    var cloudCoverText: String {
        guard let cloudCoverPercent else { return "Unavailable" }
        return "\(cloudCoverPercent)%"
    }

    var temperatureText: String {
        guard let temperatureF else { return "Unavailable" }
        return "\(Int(temperatureF.rounded()))°F"
    }

    var windText: String {
        guard let windSpeedMph else { return "Unavailable" }
        return "\(Int(windSpeedMph.rounded())) mph"
    }

    var humidityText: String {
        guard let humidityPercent else { return "Unavailable" }
        return "\(humidityPercent)%"
    }

    var viewingNote: String {
        if let cloudCoverPercent {
            switch cloudCoverPercent {
            case ..<25:
                return "Skies look mostly clear for viewing."
            case 25..<60:
                return "Some cloud cover may drift through tonight."
            default:
                return "Cloud cover may limit visibility tonight."
            }
        }

        if let condition, condition != "Unknown" {
            return "\(condition) conditions from the current weather feed."
        }

        return "Sky conditions are limited right now."
    }
}
