//
//  DashboardViewModel.swift
//  every_day
//

import Foundation
import CoreLocation

@Observable
final class DashboardViewModel {

    // MARK: - Weather State
    var currentWeather: CurrentWeather?
    var weatherForecast: [WeatherDay] = []
    var isLoadingWeather = false
    var weatherError: String?

    // MARK: - Moon State
    var moonData: MoonData?
    var isLoadingMoon = false
    var moonError: String?

    // MARK: - Horoscope State
    var horoscopeData: HoroscopeData?
    var isLoadingHoroscope = false
    var horoscopeError: String?

    // MARK: - User Preferences
    // Backed by a stored property so @Observable tracks changes
    private var _selectedSignRaw: String = UserDefaults.standard.string(forKey: "selectedZodiacSign") ?? ZodiacSign.aries.rawValue

    var selectedSign: ZodiacSign {
        get { ZodiacSign(rawValue: _selectedSignRaw) ?? .aries }
        set {
            _selectedSignRaw = newValue.rawValue
            UserDefaults.standard.set(newValue.rawValue, forKey: "selectedZodiacSign")
            Task { await fetchHoroscope(for: newValue) }
        }
    }

    var hasSelectedSign: Bool {
        UserDefaults.standard.string(forKey: "selectedZodiacSign") != nil
    }

    // MARK: - Animation
    var cardsAppeared = false

    // MARK: - Location (nested @Observable — views can observe .location directly)
    var locationService = LocationService()

    // MARK: - Services (stateless, no observation needed)
    @ObservationIgnored private let weatherService    = WeatherService()
    @ObservationIgnored private let moonService       = MoonService()
    @ObservationIgnored private let horoscopeService  = HoroscopeService()

    // MARK: - Lifecycle

    func initialize() {
        locationService.requestLocation()
    }

    /// Changes the zodiac sign from Settings, clearing the cache first so a
    /// fresh API call is always made regardless of any same-day cached reading.
    func changeSign(_ sign: ZodiacSign) {
        HoroscopeCache.clearCache(for: sign)
        _selectedSignRaw = sign.rawValue
        UserDefaults.standard.set(sign.rawValue, forKey: "selectedZodiacSign")
        horoscopeData  = nil
        horoscopeError = nil
        Task { await fetchHoroscope(for: sign) }
    }

    /// Called by the View whenever locationService.location becomes non-nil.
    func onLocationAvailable(_ location: CLLocation) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchWeather(location: location) }
            group.addTask { await self.fetchMoon(location: location) }
            group.addTask { await self.fetchHoroscope(for: self.selectedSign) }
        }
    }

    /// Pull-to-refresh: re-fetch everything.
    func refreshAll() async {
        guard let location = locationService.location else {
            locationService.requestLocation()
            return
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.fetchWeather(location: location) }
            group.addTask { await self.fetchMoon(location: location) }
            group.addTask { await self.fetchHoroscope(for: self.selectedSign) }
        }
    }

    // MARK: - Private Fetchers

    func fetchWeather(location: CLLocation) async {
        isLoadingWeather = true
        weatherError = nil
        defer { isLoadingWeather = false }
        do {
            let result = try await weatherService.fetchWeather(
                latitude:  location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
            currentWeather  = result.current
            weatherForecast = result.forecast
        } catch {
            weatherError = "Unable to load weather. Pull down to retry."
        }
    }

    func fetchMoon(location: CLLocation) async {
        isLoadingMoon = true
        moonError = nil
        defer { isLoadingMoon = false }
        do {
            moonData = try await moonService.fetchMoonData(
                latitude:  location.coordinate.latitude,
                longitude: location.coordinate.longitude
            )
        } catch {
            moonError = "Unable to load moon data. Pull down to retry."
        }
    }

    func fetchHoroscope(for sign: ZodiacSign) async {
        // ── 1. Fresh cache hit — skip network entirely ───────────────────────
        if let cached = HoroscopeCache.cachedToday(for: sign) {
            horoscopeData = HoroscopeData(sign: sign.displayName, horoscope: cached)
            #if DEBUG
            print("✅ [HoroscopeCache] Serving today's cached horoscope for \(sign.displayName)")
            #endif
            return
        }

        // ── 2. Cache miss — call the API ─────────────────────────────────────
        isLoadingHoroscope = true
        horoscopeError     = nil
        defer { isLoadingHoroscope = false }

        do {
            let data = try await horoscopeService.fetchHoroscope(for: sign)
            HoroscopeCache.store(data.horoscope, for: sign)
            horoscopeData = data
        } catch {
            // ── 3a. API failed — serve stale cache as fallback ───────────────
            if let stale = HoroscopeCache.staleCached(for: sign) {
                horoscopeData  = HoroscopeData(sign: sign.displayName, horoscope: stale)
                horoscopeError = nil
                #if DEBUG
                print("⚠️ [HoroscopeCache] API failed — serving stale horoscope for \(sign.displayName)")
                #endif
            } else {
                // ── 3b. No cache at all — surface an error ───────────────────
                horoscopeError = "Today's horoscope is unavailable. Pull down to retry."
                #if DEBUG
                print("❌ [HoroscopeCache] API failed and no cache exists for \(sign.displayName)")
                #endif
            }
        }
    }
}
