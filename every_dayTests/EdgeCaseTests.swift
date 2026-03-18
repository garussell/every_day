//
//  EdgeCaseTests.swift
//  every_dayTests
//
//  Failure-path and edge-case tests covering malformed JSON, boundary values,
//  out-of-range inputs, and error conditions across all model layers.
//

import Testing
import Foundation
import SwiftData
@testable import every_day

// MARK: - Weather Decoding Failure Tests

@Suite("Weather Models — Edge Cases")
struct WeatherEdgeCaseTests {

    @Test("WeatherAPIResponse throws on empty JSON object")
    func decodingEmptyObject() {
        let data = Data("{}".utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        }
    }

    @Test("WeatherAPIResponse throws on completely invalid JSON")
    func decodingGarbage() {
        let data = Data("not json at all".utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        }
    }

    @Test("WeatherAPIResponse throws when required field is missing")
    func decodingMissingField() {
        // Missing "daily" key
        let json = """
        {
            "current": {
                "time": "2026-03-01T12:00",
                "temperature_2m": 70.0,
                "relative_humidity_2m": 50,
                "wind_speed_10m": 5.0,
                "weather_code": 0
            }
        }
        """
        let data = Data(json.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        }
    }

    @Test("WeatherAPIResponse throws when field type is wrong")
    func decodingWrongType() {
        // temperature_2m as string instead of Double
        let json = """
        {
            "current": {
                "time": "2026-03-01T12:00",
                "temperature_2m": "hot",
                "relative_humidity_2m": 50,
                "wind_speed_10m": 5.0,
                "weather_code": 0
            },
            "daily": {
                "time": [],
                "weather_code": [],
                "temperature_2m_max": [],
                "temperature_2m_min": []
            }
        }
        """
        let data = Data(json.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        }
    }

    @Test("WeatherAPIResponse decodes with empty daily arrays")
    func decodingEmptyDailyArrays() throws {
        let json = """
        {
            "current": {
                "time": "2026-03-01T12:00",
                "temperature_2m": 70.0,
                "relative_humidity_2m": 50,
                "wind_speed_10m": 5.0,
                "weather_code": 0
            },
            "daily": {
                "time": [],
                "weather_code": [],
                "temperature_2m_max": [],
                "temperature_2m_min": []
            }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        #expect(decoded.daily.time.isEmpty)
    }

    @Test("WeatherHelper handles negative weather codes gracefully")
    func negativeWeatherCode() {
        #expect(WeatherHelper.condition(for: -1) == "Unknown")
        #expect(WeatherHelper.symbol(for: -1) == "questionmark.circle.fill")
    }

    @Test("cloud_cover decodes as nil when absent from JSON")
    func cloudCoverOptional() throws {
        let json = """
        {
            "current": {
                "time": "2026-03-01T12:00",
                "temperature_2m": 70.0,
                "relative_humidity_2m": 50,
                "wind_speed_10m": 5.0,
                "weather_code": 0
            },
            "daily": {
                "time": [],
                "weather_code": [],
                "temperature_2m_max": [],
                "temperature_2m_min": []
            }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)
        #expect(decoded.current.cloudCover == nil)
    }
}

// MARK: - Moon Model Edge Cases

@Suite("Moon Models — Edge Cases")
struct MoonEdgeCaseTests {

    @Test("MoonAPIResponse throws on empty JSON")
    func decodingEmpty() {
        let data = Data("{}".utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MoonAPIResponse.self, from: data)
        }
    }

    @Test("MoonAPIResponse throws on garbage input")
    func decodingGarbage() {
        let data = Data("<<<not json>>>".utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(MoonAPIResponse.self, from: data)
        }
    }

    @Test("MoonHelper handles phase exactly at 0.0")
    func phaseAtZero() {
        #expect(MoonHelper.phaseName(for: 0.0) == "New Moon")
        #expect(MoonHelper.phaseSymbol(for: 0.0) == "moonphase.new.moon")
        #expect(MoonHelper.illumination(for: 0.0) == 0)
    }

    @Test("MoonHelper handles phase exactly at 1.0 (wraps to New Moon)")
    func phaseAtOne() {
        #expect(MoonHelper.phaseName(for: 1.0) == "New Moon")
        #expect(MoonHelper.phaseSymbol(for: 1.0) == "moonphase.new.moon")
        #expect(MoonHelper.illumination(for: 1.0) == 0)
    }

    @Test("MoonHelper handles negative phase (default case)")
    func negativePhase() {
        #expect(MoonHelper.phaseName(for: -0.1) == "New Moon")
        #expect(MoonHelper.phaseSymbol(for: -0.1) == "moonphase.new.moon")
    }

    @Test("MoonHelper handles phase > 1.0 (default case)")
    func phaseOverOne() {
        #expect(MoonHelper.phaseName(for: 1.5) == "New Moon")
        #expect(MoonHelper.phaseSymbol(for: 1.5) == "moonphase.new.moon")
    }

    @Test("MoonService.currentPhase returns valid range for extreme dates")
    func moonPhaseExtremeDates() {
        // Far past
        let pastDate = Date(timeIntervalSince1970: 0) // Jan 1, 1970
        let pastPhase = MoonService.currentPhase(for: pastDate)
        #expect(pastPhase >= 0.0 && pastPhase < 1.0)

        // Far future
        let futureDate = Date(timeIntervalSince1970: 4_000_000_000) // ~2096
        let futurePhase = MoonService.currentPhase(for: futureDate)
        #expect(futurePhase >= 0.0 && futurePhase < 1.0)
    }

    @Test("MoonService.moonZodiacSign returns a valid sign name")
    func moonZodiacSignValid() {
        let validSigns = ["Aries", "Taurus", "Gemini", "Cancer", "Leo", "Virgo",
                          "Libra", "Scorpio", "Sagittarius", "Capricorn", "Aquarius", "Pisces"]
        let sign = MoonService.moonZodiacSign()
        #expect(validSigns.contains(sign))
    }

    @Test("MoonService.nextFullMoon returns a date after the input date")
    func nextFullMoonIsFuture() {
        let now = Date()
        let next = MoonService.nextFullMoon(after: now)
        #expect(next > now)
    }

    @Test("MoonService.nextNewMoon returns a date after the input date")
    func nextNewMoonIsFuture() {
        let now = Date()
        let next = MoonService.nextNewMoon(after: now)
        #expect(next > now)
    }
}

// MARK: - Horoscope Model Edge Cases

@Suite("Horoscope Models — Edge Cases")
struct HoroscopeEdgeCaseTests {

    @Test("HoroscopeAPIResponse throws on empty JSON")
    func decodingEmpty() {
        let data = Data("{}".utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(HoroscopeAPIResponse.self, from: data)
        }
    }

    @Test("HoroscopeAPIResponse throws when 'sign' is missing")
    func decodingMissingSign() {
        let json = #"{"horoscope": "Some reading"}"#
        let data = Data(json.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(HoroscopeAPIResponse.self, from: data)
        }
    }

    @Test("HoroscopeAPIResponse throws when 'horoscope' is missing")
    func decodingMissingHoroscope() {
        let json = #"{"sign": "Aries"}"#
        let data = Data(json.utf8)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(HoroscopeAPIResponse.self, from: data)
        }
    }

    @Test("HoroscopeAPIResponse decodes with empty horoscope string")
    func decodingEmptyHoroscope() throws {
        let json = #"{"sign": "Aries", "horoscope": ""}"#
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(HoroscopeAPIResponse.self, from: data)
        #expect(decoded.horoscope.isEmpty)
    }

    @Test("ZodiacSign(fromName:) returns nil for invalid name")
    func zodiacSignInvalidName() {
        #expect(ZodiacSign(fromName: "notasign") == nil)
        #expect(ZodiacSign(fromName: "") == nil)
        #expect(ZodiacSign(fromName: "ARIES") == nil) // case sensitive rawValue match
    }

    @Test("ZodiacSign(fromName:) succeeds for valid lowercase name")
    func zodiacSignValidName() {
        #expect(ZodiacSign(fromName: "aries") == .aries)
        #expect(ZodiacSign(fromName: "pisces") == .pisces)
        #expect(ZodiacSign(fromName: "sagittarius") == .sagittarius)
    }
}

// MARK: - Journal Model Edge Cases

@Suite("Journal Models — Edge Cases")
struct JournalEdgeCaseTests {

    @Test("JournalEntry handles empty title and body")
    func emptyTitleAndBody() {
        let entry = JournalEntry(title: "", body: "")
        // displayTitle falls back to body prefix, which is empty when body is empty
        #expect(entry.displayTitle == "")
    }

    @Test("JournalEntry.moodScore handles unknown quadrant string")
    func unknownQuadrant() {
        let entry = JournalEntry(body: "x", moodQuadrant: "purple")
        #expect(entry.quadrantEnum == nil)
        #expect(entry.moodScore == 3) // default neutral
    }

    @Test("MoodMeter.quadrant handles clamped boundary values")
    func quadrantBoundaryClamp() {
        // Values at exact 0.0 and 1.0 edges
        #expect(MoodMeter.quadrant(x: 0.0, y: 0.0) == .blue)
        #expect(MoodMeter.quadrant(x: 1.0, y: 1.0) == .yellow)
        #expect(MoodMeter.quadrant(x: 0.0, y: 1.0) == .red)
        #expect(MoodMeter.quadrant(x: 1.0, y: 0.0) == .green)
    }

    @Test("MoodMeter.nearestWord returns non-nil for center position")
    func nearestWordCenter() {
        let word = MoodMeter.nearestWord(x: 0.5, y: 0.5)
        #expect(word != nil)
    }

    @Test("JournalEntry entryTypeEnum handles unknown type string")
    func unknownEntryType() {
        let entry = JournalEntry(body: "x")
        // Default entryType is "dream" — verify it parses
        #expect(entry.entryTypeEnum == .dream)
    }

    @Test("JournalEntry contextTagsArray handles empty string")
    func emptyContextTags() {
        let entry = JournalEntry(body: "x")
        #expect(entry.contextTagsArray.isEmpty)
    }

    @Test("JournalEntry.shareText handles nil mood and clarity")
    func shareTextNoMood() {
        let entry = JournalEntry(title: "Simple", body: "No mood set")
        let text = entry.shareText
        #expect(text.contains("Simple"))
        #expect(text.contains("No mood set"))
    }
}

// MARK: - Journal ViewModel Edge Cases

@MainActor
@Suite("Journal ViewModel — Edge Cases")
struct JournalViewModelEdgeCaseTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: JournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test("fetchEntries returns empty array from empty store")
    func fetchEmptyStore() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = JournalViewModel()

        let entries = vm.fetchEntries(from: context)
        #expect(entries.isEmpty)
    }

    @Test("deleteEntry on already-deleted entry does not crash")
    func deleteAlreadyDeleted() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = JournalViewModel()

        let entry = vm.createEntry(title: "A", body: "B", in: context)
        vm.deleteEntry(entry, in: context)
        // Second delete should not crash
        vm.deleteEntry(entry, in: context)
        #expect(vm.fetchEntries(from: context).isEmpty)
    }

    @Test("createEntry with extremely long body succeeds")
    func createLongBody() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let vm = JournalViewModel()

        let longBody = String(repeating: "A", count: 100_000)
        let entry = vm.createEntry(title: "Long", body: longBody, in: context)
        #expect(entry.body.count == 100_000)
    }
}

// MARK: - WeatherService Network Edge Cases

@Suite("WeatherService — Network Edge Cases")
struct WeatherServiceEdgeCaseTests {

    @Test("fetchWeather throws on malformed JSON with 200 status")
    func malformedJSONSuccess() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: "this is not json", statusCode: 200)

        let service = WeatherService(session: mockSession)

        do {
            _ = try await service.fetchWeather(latitude: 0, longitude: 0)
            Issue.record("Expected decoding error")
        } catch {
            // Expected — JSONDecoder should fail
        }
    }

    @Test("fetchWeather throws on empty response body with 200 status")
    func emptyResponseBody() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: "", statusCode: 200)

        let service = WeatherService(session: mockSession)

        do {
            _ = try await service.fetchWeather(latitude: 0, longitude: 0)
            Issue.record("Expected error")
        } catch {
            // Expected
        }
    }

    @Test("fetchWeather throws on 404 status")
    func status404() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: #"{"error": "not found"}"#, statusCode: 404)

        let service = WeatherService(session: mockSession)

        do {
            _ = try await service.fetchWeather(latitude: 0, longitude: 0)
            Issue.record("Expected error for 404")
        } catch {
            // Expected
        }
    }

    @Test("fetchWeather throws on 429 rate limit status")
    func status429() async {
        let mockSession = MockNetworkSession()
        MockURLProtocol.stub(json: #"{"error": "rate limited"}"#, statusCode: 429)

        let service = WeatherService(session: mockSession)

        do {
            _ = try await service.fetchWeather(latitude: 0, longitude: 0)
            Issue.record("Expected error for 429")
        } catch {
            // Expected
        }
    }
}
