//
//  DashboardViewModel.swift
//  every_day
//

import Foundation
import CoreLocation

/// The type of horoscope to display (based on birth chart placement)
enum HoroscopeType: String, CaseIterable, Identifiable {
    case sun   = "Sun"
    case moon  = "Moon"
    case rising = "Rising"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .sun:    return "sun.max.fill"
        case .moon:   return "moon.fill"
        case .rising: return "arrow.up.circle.fill"
        }
    }
}

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

    // MARK: - Horoscope State (Single sign - legacy)
    var horoscopeData: HoroscopeData?
    var isLoadingHoroscope = false
    var horoscopeError: String?

    // MARK: - Multi-Horoscope State (Birth Chart)

    /// Currently selected horoscope type (Sun/Moon/Rising)
    var selectedHoroscopeType: HoroscopeType = .sun

    /// Horoscope data for each type
    var sunHoroscope: HoroscopeData?
    var moonHoroscope: HoroscopeData?
    var risingHoroscope: HoroscopeData?

    /// Loading states for each type
    var isLoadingSunHoroscope = false
    var isLoadingMoonHoroscope = false
    var isLoadingRisingHoroscope = false

    /// Error states for each type
    var sunHoroscopeError: String?
    var moonHoroscopeError: String?
    var risingHoroscopeError: String?

    /// Returns the currently selected horoscope based on type
    var currentHoroscope: HoroscopeData? {
        switch selectedHoroscopeType {
        case .sun:    return sunHoroscope
        case .moon:   return moonHoroscope
        case .rising: return risingHoroscope
        }
    }

    /// Returns loading state for currently selected type
    var isLoadingCurrentHoroscope: Bool {
        switch selectedHoroscopeType {
        case .sun:    return isLoadingSunHoroscope
        case .moon:   return isLoadingMoonHoroscope
        case .rising: return isLoadingRisingHoroscope
        }
    }

    /// Returns error for currently selected type
    var currentHoroscopeError: String? {
        switch selectedHoroscopeType {
        case .sun:    return sunHoroscopeError
        case .moon:   return moonHoroscopeError
        case .rising: return risingHoroscopeError
        }
    }

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

    // MARK: - Birth Chart Horoscope Fetching

    /// Fetches all three horoscopes (Sun, Moon, Rising) based on the user's birth chart.
    func fetchBirthChartHoroscopes(birthChart: BirthChart) async {
        await withTaskGroup(of: Void.self) { group in
            // Sun sign horoscope
            if let sunSign = ZodiacSign(fromName: birthChart.sunSign) {
                group.addTask { await self.fetchHoroscopeForType(.sun, sign: sunSign) }
            }

            // Moon sign horoscope
            if let moonSign = ZodiacSign(fromName: birthChart.moonSign) {
                group.addTask { await self.fetchHoroscopeForType(.moon, sign: moonSign) }
            }

            // Rising sign horoscope (only if available)
            if let risingName = birthChart.risingSign,
               let risingSign = ZodiacSign(fromName: risingName) {
                group.addTask { await self.fetchHoroscopeForType(.rising, sign: risingSign) }
            }
        }
    }

    /// Fetches a horoscope for a specific type (Sun/Moon/Rising)
    private func fetchHoroscopeForType(_ type: HoroscopeType, sign: ZodiacSign) async {
        // Set loading state
        switch type {
        case .sun:    isLoadingSunHoroscope = true; sunHoroscopeError = nil
        case .moon:   isLoadingMoonHoroscope = true; moonHoroscopeError = nil
        case .rising: isLoadingRisingHoroscope = true; risingHoroscopeError = nil
        }

        defer {
            switch type {
            case .sun:    isLoadingSunHoroscope = false
            case .moon:   isLoadingMoonHoroscope = false
            case .rising: isLoadingRisingHoroscope = false
            }
        }

        // Check cache first
        if let cached = HoroscopeCache.cachedToday(for: sign) {
            let data = HoroscopeData(sign: sign.displayName, horoscope: cached)
            setHoroscopeData(data, for: type)
            #if DEBUG
            print("✅ [BirthChart] Serving cached \(type.rawValue) horoscope for \(sign.displayName)")
            #endif
            return
        }

        // Fetch from API
        do {
            let data = try await horoscopeService.fetchHoroscope(for: sign)
            HoroscopeCache.store(data.horoscope, for: sign)
            setHoroscopeData(data, for: type)
        } catch {
            // Try stale cache
            if let stale = HoroscopeCache.staleCached(for: sign) {
                let data = HoroscopeData(sign: sign.displayName, horoscope: stale)
                setHoroscopeData(data, for: type)
            } else {
                setHoroscopeError("Unable to load \(type.rawValue.lowercased()) horoscope.", for: type)
            }
        }
    }

    private func setHoroscopeData(_ data: HoroscopeData, for type: HoroscopeType) {
        switch type {
        case .sun:    sunHoroscope = data
        case .moon:   moonHoroscope = data
        case .rising: risingHoroscope = data
        }
    }

    private func setHoroscopeError(_ error: String, for type: HoroscopeType) {
        switch type {
        case .sun:    sunHoroscopeError = error
        case .moon:   moonHoroscopeError = error
        case .rising: risingHoroscopeError = error
        }
    }

    /// Returns the zodiac sign for a given horoscope type based on birth chart
    func signForType(_ type: HoroscopeType, birthChart: BirthChart) -> ZodiacSign? {
        switch type {
        case .sun:    return ZodiacSign(fromName: birthChart.sunSign)
        case .moon:   return ZodiacSign(fromName: birthChart.moonSign)
        case .rising:
            guard let rising = birthChart.risingSign else { return nil }
            return ZodiacSign(fromName: rising)
        }
    }
}
