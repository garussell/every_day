//
//  CosmosViewModel.swift
//  every_day
//

import Foundation

@MainActor
@Observable
final class CosmosViewModel {
    var planets: [PlanetaryBody] = PlanetaryBody.mockPlanets
    var asteroidPreview: [AsteroidApproach] = []

    var isLoadingPlanets = false
    var isLoadingAsteroids = false

    var planetError: String?
    var asteroidError: String?

    private(set) var hasLoaded = false

    @ObservationIgnored private let solarSystemService: SolarSystemService
    @ObservationIgnored private let nasaService: NASAService

    init(
        solarSystemService: SolarSystemService = SolarSystemService(),
        nasaService: NASAService = NASAService()
    ) {
        self.solarSystemService = solarSystemService
        self.nasaService = nasaService
    }

    var featuredPlanet: PlanetaryBody {
        planets.first(where: { $0.theme == .saturn })
            ?? planets.first(where: { $0.theme == .mars })
            ?? planets.first
            ?? PlanetaryBody.mockPlanets[0]
    }

    var hasPlanetFallback: Bool {
        planets.contains(where: { $0.dataSource == .mock })
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
        hasLoaded = true
    }

    func refresh() async {
        await fetchPlanets()
        await fetchAsteroidPreview()
    }

    private func fetchPlanets() async {
        isLoadingPlanets = true
        defer { isLoadingPlanets = false }

        do {
            let livePlanets = try await solarSystemService.fetchPlanets()
            planets = PlanetaryBody.mergedWithFallback(
                livePlanets: livePlanets,
                fallbackPlanets: PlanetaryBody.mockPlanets
            )
            planetError = nil
        } catch {
            planets = PlanetaryBody.mockPlanets
            planetError = error.localizedDescription
        }
    }

    private func fetchAsteroidPreview() async {
        isLoadingAsteroids = true
        defer { isLoadingAsteroids = false }

        do {
            asteroidPreview = Array(try await nasaService.fetchUpcomingAsteroids(daysAhead: 5).prefix(3))
            asteroidError = nil
        } catch {
            asteroidPreview = []
            asteroidError = "Near-Earth object data is unavailable right now."
        }
    }
}
