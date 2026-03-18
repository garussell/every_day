//
//  NASAAPIModels.swift
//  every_day
//

import Foundation

nonisolated struct NASAAPODResponse: Decodable, Sendable {
    let date: String
    let title: String
    let explanation: String
    let mediaType: APODMediaType
    let url: URL?
    let hdurl: URL?
    let thumbnailURL: URL?
    let copyright: String?

    enum CodingKeys: String, CodingKey {
        case date
        case title
        case explanation
        case mediaType = "media_type"
        case url
        case hdurl
        case thumbnailURL = "thumbnail_url"
        case copyright
    }
}

nonisolated struct NASANEOFeedResponse: Decodable, Sendable {
    let nearEarthObjects: [String: [NASANearEarthObject]]

    enum CodingKeys: String, CodingKey {
        case nearEarthObjects = "near_earth_objects"
    }
}

nonisolated struct NASANearEarthObject: Decodable, Sendable {
    let id: String
    let name: String
    let estimatedDiameter: NASAEstimatedDiameter
    let isPotentiallyHazardousAsteroid: Bool
    let closeApproachData: [NASACloseApproachData]

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case estimatedDiameter = "estimated_diameter"
        case isPotentiallyHazardousAsteroid = "is_potentially_hazardous_asteroid"
        case closeApproachData = "close_approach_data"
    }
}

nonisolated struct NASAEstimatedDiameter: Decodable, Sendable {
    let kilometers: NASAEstimatedDiameterRange
}

nonisolated struct NASAEstimatedDiameterRange: Decodable, Sendable {
    let estimatedDiameterMin: Double?
    let estimatedDiameterMax: Double?

    enum CodingKeys: String, CodingKey {
        case estimatedDiameterMin = "estimated_diameter_min"
        case estimatedDiameterMax = "estimated_diameter_max"
    }
}

nonisolated struct NASACloseApproachData: Decodable, Sendable {
    let closeApproachDate: String?
    let relativeVelocity: NASAStringMetricContainer
    let missDistance: NASAStringMetricContainer

    enum CodingKeys: String, CodingKey {
        case closeApproachDate = "close_approach_date"
        case relativeVelocity = "relative_velocity"
        case missDistance = "miss_distance"
    }
}

nonisolated struct NASAStringMetricContainer: Decodable, Sendable {
    let kilometersPerHour: String?
    let kilometers: String?

    enum CodingKeys: String, CodingKey {
        case kilometersPerHour = "kilometers_per_hour"
        case kilometers
    }
}

extension APODEntry {
    init(response: NASAAPODResponse) {
        self.init(
            id: response.date,
            title: response.title,
            dateString: response.date,
            explanation: response.explanation,
            mediaType: response.mediaType,
            url: response.url,
            hdURL: response.hdurl,
            thumbnailURL: response.thumbnailURL,
            copyright: response.copyright
        )
    }
}

extension AsteroidApproach {
    init(neo: NASANearEarthObject, closeApproach: NASACloseApproachData) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        self.init(
            id: neo.id,
            name: neo.name,
            approachDate: closeApproach.closeApproachDate.flatMap { formatter.date(from: $0) },
            estimatedDiameterMinKilometers: neo.estimatedDiameter.kilometers.estimatedDiameterMin,
            estimatedDiameterMaxKilometers: neo.estimatedDiameter.kilometers.estimatedDiameterMax,
            missDistanceKilometers: closeApproach.missDistance.kilometers.flatMap(Double.init),
            relativeVelocityKilometersPerHour: closeApproach.relativeVelocity.kilometersPerHour.flatMap(Double.init),
            isPotentiallyHazardous: neo.isPotentiallyHazardousAsteroid
        )
    }
}
