//
//  LocationService.swift
//  every_day
//

import Foundation
import CoreLocation

// MARK: - LocationService

/// Observable wrapper around CLLocationManager.
/// Uses an inner NSObject delegate to avoid @Observable + NSObject conflicts.
@Observable
final class LocationService {
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var locationError: String?

    private let manager = CLLocationManager()
    // Keep delegate alive as a stored property
    private var _delegate: LocationDelegate?

    init() {
        let d = LocationDelegate(service: self)
        _delegate = d
        manager.delegate = d
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func requestLocation() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            locationError = "Location access denied. Showing data for San Francisco."
            location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        @unknown default:
            break
        }
    }
}

// MARK: - Inner CLLocationManagerDelegate

/// Separate NSObject subclass so LocationService doesn't need to inherit NSObject,
/// allowing @Observable to work cleanly.
private final class LocationDelegate: NSObject, CLLocationManagerDelegate {
    weak var service: LocationService?

    init(service: LocationService) {
        self.service = service
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        service?.location = locations.first
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        service?.locationError = error.localizedDescription
        if service?.location == nil {
            service?.location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        service?.authorizationStatus = manager.authorizationStatus
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.requestLocation()
        case .denied, .restricted:
            service?.locationError = "Location access denied. Showing data for San Francisco."
            service?.location = CLLocation(latitude: 37.7749, longitude: -122.4194)
        default:
            break
        }
    }
}
