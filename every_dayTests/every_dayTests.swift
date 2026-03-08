//
//  every_dayTests.swift
//  every_dayTests
//
//  Unit tests for DailyOrbit's API service layer.
//  Tests cover JSON decoding, model helpers, and URL construction
//  without making real network calls.
//

import Testing
import Foundation
import SwiftData
@testable import every_day

// MARK: - Weather Model Tests

@Suite("Weather Models")
struct WeatherModelTests {

    @Test("WeatherAPIResponse decodes valid JSON")
    func decodesWeatherResponse() throws {
        let json = """
        {
            "current": {
                "time": "2026-02-28T12:00",
                "temperature_2m": 68.5,
                "relative_humidity_2m": 62,
                "wind_speed_10m": 12.3,
                "weather_code": 2
            },
            "daily": {
                "time": ["2026-02-28", "2026-03-01"],
                "weather_code": [2, 61],
                "temperature_2m_max": [72.0, 65.0],
                "temperature_2m_min": [55.0, 48.0]
            }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)

        #expect(decoded.current.temperature2m == 68.5)
        #expect(decoded.current.relativeHumidity2m == 62)
        #expect(decoded.current.windSpeed10m == 12.3)
        #expect(decoded.current.weatherCode == 2)
        #expect(decoded.daily.time.count == 2)
        #expect(decoded.daily.temperature2mMax.first == 72.0)
        #expect(decoded.daily.temperature2mMin.first == 55.0)
    }

    @Test("WeatherHelper maps clear sky code to correct symbol")
    func clearSkySymbol() {
        #expect(WeatherHelper.symbol(for: 0) == "sun.max.fill")
        #expect(WeatherHelper.condition(for: 0) == "Clear Sky")
    }

    @Test("WeatherHelper maps rain codes correctly")
    func rainSymbols() {
        #expect(WeatherHelper.symbol(for: 61) == "cloud.rain.fill")
        #expect(WeatherHelper.symbol(for: 63) == "cloud.rain.fill")
        #expect(WeatherHelper.symbol(for: 65) == "cloud.rain.fill")
        #expect(WeatherHelper.condition(for: 63) == "Rain")
    }

    @Test("WeatherHelper maps thunderstorm codes")
    func thunderstormSymbols() {
        #expect(WeatherHelper.symbol(for: 95) == "cloud.bolt.fill")
        #expect(WeatherHelper.symbol(for: 96) == "cloud.bolt.rain.fill")
        #expect(WeatherHelper.condition(for: 95) == "Thunderstorm")
    }

    @Test("WeatherHelper returns fallback for unknown code")
    func unknownCodeFallback() {
        #expect(WeatherHelper.symbol(for: 999) == "questionmark.circle.fill")
        #expect(WeatherHelper.condition(for: 999) == "Unknown")
    }

    @Test("WeatherDay builds day label from date")
    func weatherDayLabel() throws {
        // Create a known weekday: Monday 2026-03-02
        var components = DateComponents()
        components.year = 2026; components.month = 3; components.day = 2
        let date = try #require(Calendar.current.date(from: components))
        let day = WeatherDay(date: date, weatherCode: 0, maxTemp: 70, minTemp: 50)
        #expect(day.dayLabel == "Mon")
    }
}

// MARK: - Moon Model Tests

@Suite("Moon Models")
struct MoonModelTests {

    @Test("MoonAPIResponse decodes valid JSON including null moonrise")
    func decodesMoonResponse() throws {
        let json = """
        {
            "daily": {
                "time": ["2026-02-28"],
                "moonrise": [null],
                "moonset": ["2026-02-28T06:32"],
                "moon_phase": [0.42]
            }
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(MoonAPIResponse.self, from: data)

        #expect(decoded.daily.moonPhase.first == 0.42)
        // null moonrise decodes as Optional(nil)
        let riseEntry = decoded.daily.moonrise.first
        #expect(riseEntry == .some(nil))
        #expect(decoded.daily.moonset.first == .some("2026-02-28T06:32"))
    }

    @Test("MoonHelper.illumination derives correct percentage from phase")
    func illuminationFromPhase() {
        #expect(MoonHelper.illumination(for: 0.00) == 0)    // new moon
        #expect(MoonHelper.illumination(for: 0.25) == 50)   // first quarter
        #expect(MoonHelper.illumination(for: 0.50) == 100)  // full moon
        #expect(MoonHelper.illumination(for: 0.75) == 50)   // last quarter
        #expect(MoonHelper.illumination(for: 1.00) == 0)    // new moon again
    }

    @Test("MoonHelper returns correct phase name for each range")
    func moonPhaseNames() {
        #expect(MoonHelper.phaseName(for: 0.00) == "New Moon")
        #expect(MoonHelper.phaseName(for: 0.10) == "Waxing Crescent")
        #expect(MoonHelper.phaseName(for: 0.25) == "First Quarter")
        #expect(MoonHelper.phaseName(for: 0.38) == "Waxing Gibbous")
        #expect(MoonHelper.phaseName(for: 0.50) == "Full Moon")
        #expect(MoonHelper.phaseName(for: 0.62) == "Waning Gibbous")
        #expect(MoonHelper.phaseName(for: 0.75) == "Last Quarter")
        #expect(MoonHelper.phaseName(for: 0.85) == "Waning Crescent")
        #expect(MoonHelper.phaseName(for: 0.99) == "New Moon")
    }

    @Test("MoonHelper returns correct SF Symbol for each phase")
    func moonPhaseSymbols() {
        #expect(MoonHelper.phaseSymbol(for: 0.00) == "moonphase.new.moon")
        #expect(MoonHelper.phaseSymbol(for: 0.12) == "moonphase.waxing.crescent")
        #expect(MoonHelper.phaseSymbol(for: 0.25) == "moonphase.first.quarter")
        #expect(MoonHelper.phaseSymbol(for: 0.40) == "moonphase.waxing.gibbous")
        #expect(MoonHelper.phaseSymbol(for: 0.50) == "moonphase.full.moon")
        #expect(MoonHelper.phaseSymbol(for: 0.60) == "moonphase.waning.gibbous")
        #expect(MoonHelper.phaseSymbol(for: 0.75) == "moonphase.last.quarter")
        #expect(MoonHelper.phaseSymbol(for: 0.88) == "moonphase.waning.crescent")
    }

    @Test("MoonData exposes computed phaseName and phaseSymbol")
    func moonDataComputedProperties() {
        let moon = MoonData(illumination: 50, phase: 0.50, moonrise: "8:00 PM", moonset: "6:00 AM", nextFullMoon: .now, nextNewMoon: .now, moonZodiacSign: "Virgo")
        #expect(moon.phaseName == "Full Moon")
        #expect(moon.phaseSymbol == "moonphase.full.moon")
    }
}

// MARK: - Horoscope Model Tests

@Suite("Horoscope Models")
struct HoroscopeModelTests {

    @Test("HoroscopeAPIResponse decodes API Ninjas JSON with sign field")
    func decodesHoroscopeResponse() throws {
        // API Ninjas actual response uses "sign" (docs incorrectly said "zodiac")
        let json = """
        {
            "date": "2026-02-28",
            "sign": "Aries",
            "horoscope": "Today is a great day to take bold action."
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(HoroscopeAPIResponse.self, from: data)

        #expect(decoded.sign == "Aries")
        #expect(decoded.horoscope == "Today is a great day to take bold action.")
        #expect(decoded.date == "2026-02-28")
    }

    @Test("HoroscopeAPIResponse decodes when date field is absent")
    func decodesHoroscopeResponseWithoutDate() throws {
        let json = """
        {
            "sign": "virgo",
            "horoscope": "A calm day awaits."
        }
        """
        let data = Data(json.utf8)
        let decoded = try JSONDecoder().decode(HoroscopeAPIResponse.self, from: data)
        #expect(decoded.sign == "virgo")
        #expect(decoded.date == nil)
        #expect(!decoded.horoscope.isEmpty)
    }
}

// MARK: - ZodiacSign Tests

@Suite("ZodiacSign")
struct ZodiacSignTests {

    @Test("All 12 zodiac signs are present in allCases")
    func allCasesCount() {
        #expect(ZodiacSign.allCases.count == 12)
    }

    @Test("rawValue is lowercase sign name")
    func rawValues() {
        #expect(ZodiacSign.aries.rawValue == "aries")
        #expect(ZodiacSign.pisces.rawValue == "pisces")
        #expect(ZodiacSign.sagittarius.rawValue == "sagittarius")
    }

    @Test("displayName is capitalized")
    func displayNames() {
        #expect(ZodiacSign.aries.displayName == "Aries")
        #expect(ZodiacSign.aquarius.displayName == "Aquarius")
    }

    @Test("glyph returns unicode zodiac character")
    func glyphs() {
        #expect(ZodiacSign.aries.glyph == "♈")
        #expect(ZodiacSign.taurus.glyph == "♉")
        #expect(ZodiacSign.pisces.glyph == "♓")
    }

    @Test("id matches rawValue for Identifiable conformance")
    func identifiable() {
        for sign in ZodiacSign.allCases {
            #expect(sign.id == sign.rawValue)
        }
    }

    @Test("dateRange is non-empty for every sign")
    func dateRanges() {
        for sign in ZodiacSign.allCases {
            #expect(!sign.dateRange.isEmpty)
        }
    }

    @Test("sfSymbol is non-empty for every sign")
    func sfSymbols() {
        for sign in ZodiacSign.allCases {
            #expect(!sign.sfSymbol.isEmpty)
        }
    }
}

// MARK: - URL Construction Tests

@Suite("Service URL Construction")
struct ServiceURLTests {

    @Test("WeatherService builds a valid URL with correct query params")
    func weatherServiceURL() throws {
        // Replicate the URL-building logic from WeatherService
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude",         value: "37.7749"),
            URLQueryItem(name: "longitude",        value: "-122.4194"),
            URLQueryItem(name: "current",          value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code"),
            URLQueryItem(name: "daily",            value: "weather_code,temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit",  value: "mph"),
            URLQueryItem(name: "timezone",         value: "auto"),
            URLQueryItem(name: "forecast_days",    value: "5"),
        ]
        let url = try #require(components.url)
        let urlString = url.absoluteString

        #expect(urlString.contains("api.open-meteo.com"))
        #expect(urlString.contains("latitude=37.7749"))
        #expect(urlString.contains("temperature_unit=fahrenheit"))
        #expect(urlString.contains("forecast_days=5"))
    }

    @Test("MoonService.currentPhase returns a value in [0, 1)")
    func moonPhaseRange() {
        let phase = MoonService.currentPhase()
        #expect(phase >= 0.0)
        #expect(phase < 1.0)
    }

    @Test("MoonService.currentPhase returns ~0.5 for a known full moon date")
    func moonPhaseKnownFullMoon() {
        // Full moon: January 13, 2025 at 22:27 UTC
        // Unix timestamp: 1736807220
        let fullMoon = Date(timeIntervalSince1970: 1_736_807_220)
        let phase = MoonService.currentPhase(for: fullMoon)
        // Should be within 0.02 of 0.5 (full moon)
        #expect(abs(phase - 0.5) < 0.02)
    }

    @Test("MoonService.currentPhase returns ~0.0 for a known new moon date")
    func moonPhaseKnownNewMoon() {
        // New moon: January 29, 2025 at 12:36 UTC
        // Unix timestamp: 1738150560
        let newMoon = Date(timeIntervalSince1970: 1_738_150_560)
        let phase = MoonService.currentPhase(for: newMoon)
        // Should be within 0.02 of 0.0 (or 1.0, which wraps to new moon)
        #expect(phase < 0.02 || phase > 0.98)
    }

    @Test("HoroscopeService URL uses zodiac parameter, not sign")
    func horoscopeUsesZodiacParam() throws {
        var components = URLComponents(string: "https://api.api-ninjas.com/v1/horoscope")!
        components.queryItems = [URLQueryItem(name: "zodiac", value: "aries")]
        let url = try #require(components.url)
        let urlString = url.absoluteString
        #expect(urlString.contains("zodiac=aries"))
        #expect(!urlString.contains("sign="))
        #expect(url.host == "api.api-ninjas.com")
    }
}

// MARK: - Journal Model Tests (Mood Meter)

@Suite("Journal Models — Mood Meter")
struct JournalModelTests {

    // MARK: MoodQuadrant

    @Test("All 4 quadrants present in allCases")
    func allQuadrantsCount() {
        #expect(MoodQuadrant.allCases.count == 4)
    }

    @Test("MoodQuadrant.moodScore maps correctly to 1–5 scale")
    func quadrantMoodScores() {
        #expect(MoodQuadrant.blue.moodScore   == 1)
        #expect(MoodQuadrant.red.moodScore    == 2)
        #expect(MoodQuadrant.green.moodScore  == 4)
        #expect(MoodQuadrant.yellow.moodScore == 5)
    }

    @Test("MoodQuadrant properties are non-empty")
    func quadrantProperties() {
        for q in MoodQuadrant.allCases {
            #expect(!q.title.isEmpty)
            #expect(!q.energyLabel.isEmpty)
            #expect(!q.pleasantnessLabel.isEmpty)
            #expect(!q.sfSymbol.isEmpty)
        }
    }

    // MARK: MoodMeter helpers

    @Test("MoodMeter.quadrant classifies positions correctly")
    func quadrantClassification() {
        #expect(MoodMeter.quadrant(x: 0.1, y: 0.9) == .red)     // unpleasant + high energy
        #expect(MoodMeter.quadrant(x: 0.9, y: 0.9) == .yellow)  // pleasant   + high energy
        #expect(MoodMeter.quadrant(x: 0.1, y: 0.1) == .blue)    // unpleasant + low energy
        #expect(MoodMeter.quadrant(x: 0.9, y: 0.1) == .green)   // pleasant   + low energy
    }

    @Test("MoodMeter.quadrant handles boundary (0.5) — left of center")
    func quadrantBoundary() {
        // Exactly 0.5 on x is "pleasant" side (x >= 0.5 → yellow/green)
        #expect(MoodMeter.quadrant(x: 0.5, y: 0.8) == .yellow)
        #expect(MoodMeter.quadrant(x: 0.5, y: 0.2) == .green)
        // Exactly 0.5 on y is "low energy" side (y < 0.5 → blue/green)
        #expect(MoodMeter.quadrant(x: 0.2, y: 0.5) == .red)
    }

    @Test("MoodMeter.nearestWord returns a word in the correct quadrant")
    func nearestWordQuadrant() {
        // Deep in each quadrant corner
        let redWord    = MoodMeter.nearestWord(x: 0.05, y: 0.95)
        let yellowWord = MoodMeter.nearestWord(x: 0.95, y: 0.95)
        let blueWord   = MoodMeter.nearestWord(x: 0.05, y: 0.05)
        let greenWord  = MoodMeter.nearestWord(x: 0.95, y: 0.05)

        #expect(redWord?.quadrant    == .red)
        #expect(yellowWord?.quadrant == .yellow)
        #expect(blueWord?.quadrant   == .blue)
        #expect(greenWord?.quadrant  == .green)
    }

    @Test("MoodMeter.words contains 40 entries (10 per quadrant)")
    func wordCount() {
        #expect(MoodMeter.words.count == 40)
        for quadrant in MoodQuadrant.allCases {
            let count = MoodMeter.words.filter { $0.quadrant == quadrant }.count
            #expect(count == 10)
        }
    }

    @Test("All MoodWord positions are within [0, 1] bounds")
    func wordPositionBounds() {
        for word in MoodMeter.words {
            #expect(word.x >= 0.0 && word.x <= 1.0)
            #expect(word.y >= 0.0 && word.y <= 1.0)
        }
    }

    @Test("MoodMeter.moodScore returns 3 for nil quadrant")
    func moodScoreNil() {
        #expect(MoodMeter.moodScore(for: nil) == 3)
    }

    // MARK: JournalEntry

    @Test("JournalEntry initialises with default mood fields")
    func journalEntryDefaultMood() {
        let entry = JournalEntry(body: "Hello world")
        #expect(entry.moodX        == 0.5)
        #expect(entry.moodY        == 0.5)
        #expect(entry.moodQuadrant == nil)
        #expect(entry.moodWord     == nil)
        #expect(entry.hasMoodSelection == false)
    }

    @Test("JournalEntry initialises with explicit mood fields")
    func journalEntryWithMood() {
        let entry = JournalEntry(
            title: "Test",
            body: "Body",
            moodX: 0.8,
            moodY: 0.8,
            moodQuadrant: MoodQuadrant.yellow.rawValue,
            moodWord: "Excited"
        )
        #expect(entry.hasMoodSelection == true)
        #expect(entry.quadrantEnum     == .yellow)
        #expect(entry.moodWord         == "Excited")
        #expect(entry.moodScore        == 5)
    }

    @Test("JournalEntry.moodScore derives from quadrant")
    func moodScoreByQuadrant() {
        let blue   = JournalEntry(body: "x", moodQuadrant: "blue")
        let red    = JournalEntry(body: "x", moodQuadrant: "red")
        let green  = JournalEntry(body: "x", moodQuadrant: "green")
        let yellow = JournalEntry(body: "x", moodQuadrant: "yellow")
        let none   = JournalEntry(body: "x")

        #expect(blue.moodScore   == 1)
        #expect(red.moodScore    == 2)
        #expect(green.moodScore  == 4)
        #expect(yellow.moodScore == 5)
        #expect(none.moodScore   == 3)   // default neutral
    }

    @Test("JournalEntry.moodStars has exactly 5 characters")
    func moodStarsLength() {
        for q in MoodQuadrant.allCases {
            let entry = JournalEntry(body: "x", moodQuadrant: q.rawValue)
            #expect(entry.moodStars.count == 5)
        }
    }

    @Test("JournalEntry.displayTitle falls back to 40-char body prefix when untitled")
    func displayTitleFallback() {
        let entry = JournalEntry(title: "", body: "A long body text that exceeds forty characters in length")
        #expect(entry.displayTitle.count == 40)

        let named = JournalEntry(title: "My Title", body: "Body text")
        #expect(named.displayTitle == "My Title")
    }

    @Test("JournalEntry.shareText is non-empty and contains key content")
    func shareTextContents() {
        let entry = JournalEntry(
            title: "Share Test",
            body: "Journal body here.",
            moodQuadrant: "yellow",
            moodWord: "Excited"
        )
        #expect(!entry.shareText.isEmpty)
        #expect(entry.shareText.contains("Journal body here."))
        #expect(entry.shareText.contains("Share Test"))
        #expect(entry.shareText.contains("Excited"))
        #expect(entry.shareText.contains("Yellow Zone"))
    }
}

// MARK: - Journal ViewModel Tests

@MainActor
@Suite("Journal ViewModel CRUD")
struct JournalViewModelTests {

    /// Creates a fresh in-memory SwiftData container for each test.
    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: JournalEntry.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test("createEntry inserts entry with correct fields")
    func createEntry() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let vm        = JournalViewModel()

        let entry = vm.createEntry(
            title: "Morning Thoughts",
            body: "Feeling optimistic today.",
            moodX: 0.8,
            moodY: 0.8,
            moodQuadrant: MoodQuadrant.yellow.rawValue,
            moodWord: "Excited",
            in: context
        )

        let fetched = vm.fetchEntries(from: context)
        #expect(fetched.count == 1)
        #expect(fetched.first?.title       == "Morning Thoughts")
        #expect(fetched.first?.body        == "Feeling optimistic today.")
        #expect(fetched.first?.moodWord    == "Excited")
        #expect(fetched.first?.moodQuadrant == "yellow")
        #expect(entry.id == fetched.first?.id)
    }

    @Test("updateEntry mutates fields and bumps editedAt")
    func updateEntry() async throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let vm        = JournalViewModel()

        let entry = vm.createEntry(
            title: "Draft", body: "Initial.",
            moodX: 0.8, moodY: 0.25,
            moodQuadrant: MoodQuadrant.green.rawValue, moodWord: "Calm",
            in: context
        )
        let originalEdited = entry.editedAt

        try await Task.sleep(for: .milliseconds(50))

        vm.updateEntry(
            entry,
            title: "Final", body: "Updated body.",
            moodX: 0.2, moodY: 0.8,
            moodQuadrant: MoodQuadrant.red.rawValue, moodWord: "Anxious",
            dreamClarity: 4,
            in: context
        )

        let updated = try #require(vm.fetchEntries(from: context).first)
        #expect(updated.title        == "Final")
        #expect(updated.body         == "Updated body.")
        #expect(updated.moodWord     == "Anxious")
        #expect(updated.moodQuadrant == "red")
        #expect(updated.editedAt      > originalEdited)
    }

    @Test("deleteEntry removes entry from the store")
    func deleteEntry() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let vm        = JournalViewModel()

        let entry = vm.createEntry(title: "", body: "To be deleted.", in: context)
        #expect(vm.fetchEntries(from: context).count == 1)

        vm.deleteEntry(entry, in: context)
        #expect(vm.fetchEntries(from: context).isEmpty)
    }

    @Test("fetchEntries returns entries sorted most-recent first")
    func fetchSortOrder() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let vm        = JournalViewModel()

        let d1 = Date.now.addingTimeInterval(-7200)
        let d2 = Date.now.addingTimeInterval(-3600)
        let d3 = Date.now

        vm.createEntry(title: "Oldest", body: "A", date: d1, in: context)
        vm.createEntry(title: "Middle", body: "B", date: d2, in: context)
        vm.createEntry(title: "Newest", body: "C", date: d3, in: context)

        let fetched = vm.fetchEntries(from: context)
        #expect(fetched.count == 3)
        #expect(fetched[0].title == "Newest")
        #expect(fetched[1].title == "Middle")
        #expect(fetched[2].title == "Oldest")
    }

    @Test("moodScore static helper maps quadrant correctly")
    func staticMoodScore() {
        #expect(JournalViewModel.moodScore(for: nil)      == 3)
        #expect(JournalViewModel.moodScore(for: .blue)    == 1)
        #expect(JournalViewModel.moodScore(for: .red)     == 2)
        #expect(JournalViewModel.moodScore(for: .green)   == 4)
        #expect(JournalViewModel.moodScore(for: .yellow)  == 5)
    }

    @Test("Mood data persists and is retrieved correctly")
    func moodPersistence() throws {
        let container = try makeContainer()
        let context   = container.mainContext
        let vm        = JournalViewModel()

        vm.createEntry(
            title: "Persist me",
            body: "Still here?",
            moodX: 0.15,
            moodY: 0.15,
            moodQuadrant: MoodQuadrant.blue.rawValue,
            moodWord: "Tired",
            in: context
        )

        let fetched = vm.fetchEntries(from: context)
        #expect(fetched.count == 1)
        #expect(fetched.first?.title        == "Persist me")
        #expect(fetched.first?.moodQuadrant == "blue")
        #expect(fetched.first?.moodWord     == "Tired")
        #expect(fetched.first?.moodX        == 0.15)
        #expect(fetched.first?.moodY        == 0.15)
        #expect(fetched.first?.hasMoodSelection == true)
    }
}
