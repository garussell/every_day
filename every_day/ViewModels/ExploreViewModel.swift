//
//  ExploreViewModel.swift
//  every_day
//

import Foundation

@MainActor
@Observable
final class ExploreViewModel {
    var apod: APODEntry?
    var asteroids: [AsteroidApproach] = []

    var isLoadingAPOD = false
    var isLoadingAsteroids = false

    var apodError: String?
    var asteroidError: String?

    private(set) var hasLoaded = false

    @ObservationIgnored private let nasaService: NASAService

    init(nasaService: NASAService = NASAService()) {
        self.nasaService = nasaService
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
        hasLoaded = true
    }

    func refresh() async {
        await fetchAPOD()
        await fetchAsteroids()
    }

    private func fetchAPOD() async {
        isLoadingAPOD = true
        defer { isLoadingAPOD = false }

        do {
            apod = try await nasaService.fetchAPOD()
            apodError = nil
        } catch {
            apod = nil
            apodError = "Astronomy Picture of the Day is unavailable right now."
        }
    }

    private func fetchAsteroids() async {
        isLoadingAsteroids = true
        defer { isLoadingAsteroids = false }

        do {
            asteroids = try await nasaService.fetchUpcomingAsteroids(daysAhead: 5)
            asteroidError = nil
        } catch {
            asteroids = []
            asteroidError = "Asteroid feed is unavailable right now."
        }
    }
}
