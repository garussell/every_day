//
//  ServiceNetworkTests.swift
//  every_dayTests
//
//  Mock-based network tests demonstrating the NetworkSession pattern.
//  These tests use MockURLProtocol to intercept requests and return
//  fixture data, verifying service behavior without hitting the network.
//

import Testing
import Foundation
@testable import every_day

// MARK: - WeatherService Network Tests

@Suite("WeatherService — Mock Network")
struct WeatherServiceNetworkTests {

    @Test("fetchWeather returns parsed weather from mock JSON")
    func fetchWeatherSuccess() async throws {
        let json = """
        {
            "current": {
                "time": "2026-03-01T12:00",
                "temperature_2m": 72.0,
                "relative_humidity_2m": 55,
                "wind_speed_10m": 8.5,
                "weather_code": 1,
                "cloud_cover": 25
            },
            "daily": {
                "time": ["2026-03-01", "2026-03-02"],
                "weather_code": [1, 3],
                "temperature_2m_max": [75.0, 68.0],
                "temperature_2m_min": [58.0, 52.0]
            }
        }
        """

        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: json, statusCode: 200)

        let service = WeatherService(session: mockSession)
        let result = try await service.fetchWeather(latitude: 37.7749, longitude: -122.4194)

        #expect(result.current.temperature == 72.0)
        #expect(result.current.humidity == 55)
        #expect(result.current.windSpeed == 8.5)
        #expect(result.current.weatherCode == 1)
        #expect(result.forecast.count == 2)
        #expect(result.forecast[0].maxTemp == 75.0)
        #expect(result.forecast[1].minTemp == 52.0)
    }

    @Test("fetchWeather throws on non-200 status code")
    func fetchWeatherServerError() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: "{}", statusCode: 500)

        let service = WeatherService(session: mockSession)

        do {
            _ = try await service.fetchWeather(latitude: 37.7749, longitude: -122.4194)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected — service should throw on non-200
        }
    }

    @Test("fetchWeather throws on network error")
    func fetchWeatherNetworkError() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stubError(URLError(.notConnectedToInternet))

        let service = WeatherService(session: mockSession)

        do {
            _ = try await service.fetchWeather(latitude: 37.7749, longitude: -122.4194)
            Issue.record("Expected error to be thrown")
        } catch let error as URLError {
            #expect(error.code == .notConnectedToInternet)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - HoroscopeService Network Tests

@Suite("HoroscopeService — Mock Network")
struct HoroscopeServiceNetworkTests {

    @Test("fetchHoroscope returns parsed data from mock JSON")
    func fetchHoroscopeSuccess() async throws {
        let json = """
        {
            "date": "2026-03-01",
            "sign": "Aries",
            "horoscope": "A wonderful day awaits you."
        }
        """

        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: json, statusCode: 200)

        let service = HoroscopeService(session: mockSession)
        let result = try await service.fetchHoroscope(for: .aries)

        #expect(result.sign == "Aries")
        #expect(result.horoscope == "A wonderful day awaits you.")
    }

    @Test("fetchHoroscope throws on 401 unauthorized")
    func fetchHoroscopeUnauthorized() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: #"{"error": "Invalid API key"}"#, statusCode: 401)

        let service = HoroscopeService(session: mockSession)

        do {
            _ = try await service.fetchHoroscope(for: .aries)
            Issue.record("Expected error to be thrown")
        } catch {
            // Expected — service should throw on non-200
        }
    }

    @Test("fetchHoroscope throws on malformed JSON")
    func fetchHoroscopeMalformedJSON() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: "not valid json {{{", statusCode: 200)

        let service = HoroscopeService(session: mockSession)

        do {
            _ = try await service.fetchHoroscope(for: .aries)
            Issue.record("Expected decoding error to be thrown")
        } catch {
            // Expected — JSONDecoder should fail
        }
    }

    @Test("fetchHoroscope throws on network timeout")
    func fetchHoroscopeTimeout() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stubError(URLError(.timedOut))

        let service = HoroscopeService(session: mockSession)

        do {
            _ = try await service.fetchHoroscope(for: .aries)
            Issue.record("Expected error to be thrown")
        } catch let error as URLError {
            #expect(error.code == .timedOut)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}
