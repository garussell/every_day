//
//  SolarSystemAPIModels.swift
//  every_day
//

import Foundation

struct SolarSystemBodiesResponse: Decodable {
    let bodies: [SolarSystemBodyResponse]
}

struct SolarSystemBodyResponse: Decodable {
    let id: String
    let name: String
    let englishName: String
    let isPlanet: Bool?
    let moons: [SolarSystemMoonResponse]?
    let bodyType: String?
    let gravity: Double?
    let meanRadius: Double?
    let sideralOrbit: Double?       // API spells it "sideral" (not "sidereal")
    let sideralRotation: Double?    // API spells it "sideral" (not "sidereal")
    let avgTemp: Double?
    let density: Double?
    let discoveredBy: String?
    let discoveryDate: String?
}

struct SolarSystemMoonResponse: Decodable {
    let moon: String?
    let rel: String?
}

extension PlanetaryBody {
    init?(solarSystemBody: SolarSystemBodyResponse, descriptor: String) {
        let nameForTheme = solarSystemBody.englishName.isEmpty ? solarSystemBody.name : solarSystemBody.englishName
        guard let theme = PlanetTheme(apiName: nameForTheme) else { return nil }

        self.init(
            id: solarSystemBody.id,
            name: solarSystemBody.name,
            englishName: solarSystemBody.englishName,
            descriptor: descriptor,
            bodyType: solarSystemBody.bodyType ?? "Planet",
            gravity: solarSystemBody.gravity,
            meanRadius: solarSystemBody.meanRadius,
            orbitalPeriodDays: solarSystemBody.sideralOrbit,
            rotationHours: solarSystemBody.sideralRotation,
            averageTemperatureC: solarSystemBody.avgTemp,
            density: solarSystemBody.density,
            moonCount: solarSystemBody.moons?.count,
            discoveredBy: solarSystemBody.discoveredBy,
            discoveryDate: solarSystemBody.discoveryDate,
            theme: theme,
            dataSource: .live
        )
    }
}
