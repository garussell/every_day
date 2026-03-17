//
//  SkyTonightViewModel.swift
//  every_day
//

import Foundation
import CoreLocation

@MainActor
@Observable
final class SkyTonightViewModel {
    var locationLabel = "Your location"
    var locationMessage: String?
    var summaryTitle = "Sky Tonight"
    var summaryMessage = "What’s visible from your location tonight"
    var viewingConditions: SkyViewingConditions?
    var objects: [SkyObject] = []
    var isLoading = false
    var errorMessage: String?

    private(set) var hasLoaded = false

    @ObservationIgnored private let solarSystemService: SolarSystemService
    @ObservationIgnored private let weatherService: WeatherService
    @ObservationIgnored private let locationService: LocationService
    @ObservationIgnored private let geocoder = CLGeocoder()

    init(
        solarSystemService: SolarSystemService = SolarSystemService(),
        weatherService: WeatherService = WeatherService(),
        locationService: LocationService = LocationService()
    ) {
        self.solarSystemService = solarSystemService
        self.weatherService = weatherService
        self.locationService = locationService
    }

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        await refresh()
        hasLoaded = true
    }

    func refresh() async {
        isLoading = true
        errorMessage = nil
        locationMessage = nil

        guard let location = await resolveLocation() else {
            applyLocationUnavailableState()
            isLoading = false
            return
        }

        locationMessage = normalizedMessage(locationService.locationError)
        locationLabel = await resolvedLocationLabel(for: location)

        let observer = SkyObserverContext(
            latitude: location.coordinate.latitude,
            longitude: location.coordinate.longitude,
            altitudeMeters: location.altitude,
            date: Date()
        )

        async let positionsTask = fetchPositionsResult(observer: observer)
        async let weatherTask = fetchWeatherResult(location: location)

        let positionsResult = await positionsTask
        let weatherResult = await weatherTask

        switch weatherResult {
        case let .success(currentWeather):
            viewingConditions = SkyViewingConditions(
                condition: currentWeather.condition,
                cloudCoverPercent: currentWeather.cloudCover,
                temperatureF: currentWeather.temperature,
                windSpeedMph: currentWeather.windSpeed,
                humidityPercent: currentWeather.humidity
            )
        case .failure:
            viewingConditions = nil
        }

        switch positionsResult {
        case let .success(observations):
            applyObservations(observations)
        case let .failure(error):
            applyPositionFailure(error)
        }

        isLoading = false
    }

    private func resolveLocation() async -> CLLocation? {
        if let location = locationService.location {
            return location
        }

        locationService.requestLocation()

        for _ in 0..<20 {
            if let location = locationService.location {
                return location
            }

            switch locationService.authorizationStatus {
            case .denied, .restricted:
                return locationService.location
            default:
                break
            }

            try? await Task.sleep(nanoseconds: 250_000_000)
        }

        return locationService.location
    }

    private func applyLocationUnavailableState() {
        locationLabel = "Location unavailable"
        summaryTitle = "Location needed"
        summaryMessage = "Allow location access to tailor tonight’s sky to you. The rest of Cosmos is still available while we wait."
        objects = []
        viewingConditions = nil
        errorMessage = nil
        locationMessage = normalizedMessage(locationService.locationError)
    }

    private func applyObservations(_ observations: [SkyPositionObservation]) {
        let positionsByKind: [SkyObjectKind: SkyPositionObservation] = Dictionary(
            uniqueKeysWithValues: observations.compactMap { observation -> (SkyObjectKind, SkyPositionObservation)? in
                guard let kind = observation.kind else { return nil }
                return (kind, observation)
            }
        )

        let sunAltitude = positionsByKind[SkyObjectKind.sun]?.altitudeDegrees

        let orderedObjects = SkyObjectKind.featuredOrder.map { kind in
            SkyObject(kind: kind, observation: positionsByKind[kind], sunAltitudeDegrees: sunAltitude)
        }

        let indexByKind = Dictionary(uniqueKeysWithValues: SkyObjectKind.featuredOrder.enumerated().map { ($0.element, $0.offset) })

        objects = orderedObjects.sorted { lhs, rhs in
            if lhs.isAboveHorizon != rhs.isAboveHorizon {
                return lhs.isAboveHorizon && !rhs.isAboveHorizon
            }

            let lhsAltitude = lhs.altitudeDegrees ?? -999
            let rhsAltitude = rhs.altitudeDegrees ?? -999
            if lhsAltitude != rhsAltitude {
                return lhsAltitude > rhsAltitude
            }

            return (indexByKind[lhs.kind] ?? 0) < (indexByKind[rhs.kind] ?? 0)
        }

        let summary = buildSummary(objects: objects, sunAltitude: sunAltitude, conditions: viewingConditions)
        summaryTitle = summary.title
        summaryMessage = summary.message
    }

    private func applyPositionFailure(_ error: Error) {
        objects = SkyObjectKind.featuredOrder.map { kind in
            SkyObject(kind: kind, observation: nil, sunAltitudeDegrees: nil)
        }
        summaryTitle = "Sky guidance is limited tonight"
        summaryMessage = "Live planetary positions are unavailable for \(locationLabel) right now. Weather context is still shown when available."
        errorMessage = error.localizedDescription
    }

    private func buildSummary(
        objects: [SkyObject],
        sunAltitude: Double?,
        conditions: SkyViewingConditions?
    ) -> (title: String, message: String) {
        let visibleObjects = objects.filter { $0.isAboveHorizon }
        let visibleNames = visibleObjects.map(\.name)
        let locationPhrase = "from \(locationLabel)"

        if let sunAltitude, sunAltitude > 0 {
            let daylightMessage: String
            if visibleNames.isEmpty {
                daylightMessage = "It’s still bright \(locationPhrase), so the planets will be easier to spot after sunset."
            } else {
                daylightMessage = "\(joinedList(visibleNames.prefix(2).map { $0 })) are above the horizon \(locationPhrase), but daylight will make them easier to catch later."
            }

            return ("Better after sunset", daylightMessage)
        }

        if let sunAltitude, sunAltitude > -6 {
            let twilightMessage: String
            if visibleNames.isEmpty {
                twilightMessage = "Twilight is settling in \(locationPhrase), but the brighter targets are still quiet right now."
            } else {
                twilightMessage = "\(joinedList(visibleNames.prefix(3).map { $0 })) are coming into view \(locationPhrase) as twilight deepens."
            }

            return ("Twilight is settling in", twilightMessage)
        }

        if visibleObjects.count >= 2 {
            var message = "\(joinedList(visibleNames.prefix(3).map { $0 })) are above the horizon \(locationPhrase) right now."
            if let conditions, let cloudCover = conditions.cloudCoverPercent, cloudCover >= 60 {
                message += " \(conditions.viewingNote)"
            }
            return (conditions?.cloudCoverPercent ?? 0 >= 60 ? "Some targets, softer skies" : "A promising sky tonight", message)
        }

        if let visibleObject = visibleObjects.first {
            return ("\(visibleObject.name) is your clearest target", "\(visibleObject.note) \(locationPhrase) right now.")
        }

        var message = "Most of the bright targets are below the horizon \(locationPhrase) right now."
        if let conditions, let cloudCover = conditions.cloudCoverPercent, cloudCover >= 60 {
            message += " \(conditions.viewingNote)"
        }
        return ("A quieter sky right now", message)
    }

    private func resolvedLocationLabel(for location: CLLocation) async -> String {
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                let parts = [
                    placemark.locality,
                    placemark.administrativeArea,
                ]
                .compactMap { normalizedMessage($0) }

                if !parts.isEmpty {
                    return parts.joined(separator: ", ")
                }

                if let name = normalizedMessage(placemark.name) {
                    return name
                }
            }
        } catch {
            #if DEBUG
            print("SkyTonight reverse geocode failed: \(error.localizedDescription)")
            #endif
        }

        return coordinateLabel(for: location.coordinate)
    }

    private func coordinateLabel(for coordinate: CLLocationCoordinate2D) -> String {
        let latitudeDirection = coordinate.latitude >= 0 ? "N" : "S"
        let longitudeDirection = coordinate.longitude >= 0 ? "E" : "W"
        return String(
            format: "%.2f°%@, %.2f°%@",
            abs(coordinate.latitude),
            latitudeDirection,
            abs(coordinate.longitude),
            longitudeDirection
        )
    }

    private func fetchPositionsResult(observer: SkyObserverContext) async -> Result<[SkyPositionObservation], Error> {
        do {
            return .success(try await solarSystemService.fetchSkyPositions(observer: observer))
        } catch {
            return .failure(error)
        }
    }

    private func fetchWeatherResult(location: CLLocation) async -> Result<CurrentWeather, Error> {
        do {
            let weather = try await weatherService.fetchWeather(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            return .success(weather.current)
        } catch {
            return .failure(error)
        }
    }

    private func joinedList(_ names: [String]) -> String {
        switch names.count {
        case 0:
            return "No major objects"
        case 1:
            return names[0]
        case 2:
            return "\(names[0]) and \(names[1])"
        default:
            let leading = names.dropLast().joined(separator: ", ")
            return "\(leading), and \(names.last!)"
        }
    }

    private func normalizedMessage(_ value: String?) -> String? {
        guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else {
            return nil
        }
        return trimmed
    }
}
