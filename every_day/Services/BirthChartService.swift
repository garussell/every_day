//
//  BirthChartService.swift
//  every_day
//
//  Uses the FreeAstroAPI to calculate natal charts (Sun, Moon, Rising signs,
//  full planet positions, house cusps).
//  Docs: https://freeastroapi.com/docs
//
//  API KEY SETUP
//  -------------
//  The key is stored exclusively in the iOS Keychain — it is never hardcoded
//  in source. Call BirthChartService.updateAPIKey("your-key") once at app
//  startup from Secrets.swift (which is gitignored).
//

import Foundation
import CoreLocation

// MARK: - Planet Data Model

/// Full planet position from the natal chart API response.
struct PlanetData: Codable, Equatable {
    let id: String          // "sun", "moon", "mercury", "venus", "mars", "jupiter",
                            // "saturn", "uranus", "neptune", "pluto", "mean_node"
    let name: String        // "Sun", "Moon", "Mercury", etc.
    let signId: String      // lowercase full sign name: "cancer", "sagittarius", etc.
    let pos: Double         // degrees within sign (0–29.99)
    let absPos: Double      // absolute ecliptic longitude
    let retrograde: Bool
    let house: Int          // 1–12 (0 if unavailable)
}

// MARK: - House Cusp Model

/// One house cusp from the natal chart API response.
struct HouseCusp: Codable, Equatable {
    let house: Int          // 1–12
    let signId: String      // lowercase full sign name
    let pos: Double         // cusp degree within sign (0–29.99)
}

// MARK: - Birth Chart Model

struct BirthChart: Codable, Equatable {
    let sunSign: String
    let moonSign: String
    let risingSign: String?
    let calculatedAt: Date

    // Full chart data — nil for charts calculated before this update.
    // All optional so existing cached charts continue to decode correctly.
    let planets: [PlanetData]?
    let houses: [HouseCusp]?
    let birthPlace: String?
    let birthDate: Date?

    /// User-friendly display for Rising when it may be nil
    var risingDisplayName: String {
        risingSign ?? "Unknown"
    }
}

// MARK: - Errors

enum BirthChartError: LocalizedError {
    case cityNotFound
    case apiKeyMissing
    case networkError(Error)
    case invalidResponse
    case serverError(Int)
    case decodingError(Error)
    case missingBirthTime

    var errorDescription: String? {
        switch self {
        case .cityNotFound:
            return "Could not find that city. Try entering it differently, e.g. 'London, UK'"
        case .apiKeyMissing:
            return "Birth chart API key not configured."
        case .networkError:
            return "Could not calculate your birth chart. Check your internet connection and try again."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .decodingError:
            return "Could not parse the birth chart data."
        case .missingBirthTime:
            return "Birth time is required for accurate Rising sign calculation."
        }
    }
}

// MARK: - Service

struct BirthChartService {

    // MARK: - API Key

    private static let keychainAccount = "freeastroapi_birth_chart_key"

    /// Reads the API key from the Keychain.
    private var apiKey: String {
        KeychainHelper.load(for: Self.keychainAccount) ?? ""
    }

    /// Seeds or updates the API key in the Keychain.
    static func updateAPIKey(_ key: String) {
        KeychainHelper.save(key, for: keychainAccount)
    }

    /// Checks if the API key is configured.
    static var hasAPIKey: Bool {
        let key = KeychainHelper.load(for: keychainAccount) ?? ""
        return !key.isEmpty
    }

    // MARK: - Geocoding

    /// Geocoding result with coordinates and timezone
    struct GeocodingResult {
        let latitude: Double
        let longitude: Double
        let timezone: String
    }

    /// Converts a city name to coordinates and timezone using Apple's CLGeocoder.
    func geocodeCity(_ city: String) async throws -> GeocodingResult {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.geocodeAddressString(city)
            guard let placemark = placemarks.first,
                  let location = placemark.location?.coordinate else {
                throw BirthChartError.cityNotFound
            }

            // Get timezone identifier from placemark or use UTC as fallback
            let timezoneStr = placemark.timeZone?.identifier ?? "UTC"

            return GeocodingResult(
                latitude: location.latitude,
                longitude: location.longitude,
                timezone: timezoneStr
            )
        } catch let error as BirthChartError {
            throw error
        } catch {
            throw BirthChartError.cityNotFound
        }
    }

    // MARK: - Birth Chart Calculation

    /// Calculates the birth chart using FreeAstroAPI.
    func calculateBirthChart(
        day: Int,
        month: Int,
        year: Int,
        hour: Int?,
        minute: Int?,
        city: String
    ) async throws -> BirthChart {

        let key = apiKey
        guard !key.isEmpty else {
            #if DEBUG
            print("❌ [BirthChartService] API key not configured")
            #endif
            throw BirthChartError.apiKeyMissing
        }

        // Use noon as default if birth time is unknown
        let birthHour   = hour ?? 12
        let birthMinute = minute ?? 0
        let hasBirthTime = hour != nil

        // Geocode the city to get coordinates and timezone
        let geoResult = try await geocodeCity(city)

        // Build request
        let url = URL(string: "https://api.freeastroapi.com/api/v1/natal/calculate")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")

        let body: [String: Any] = [
            "name": "User",
            "year": year,
            "month": month,
            "day": day,
            "hour": birthHour,
            "minute": birthMinute,
            "city": city,
            "lat": geoResult.latitude,
            "lng": geoResult.longitude,
            "tz_str": geoResult.timezone
        ]

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        #if DEBUG
        let keyPreview = key.count > 8 ? String(key.prefix(8)) + "..." : key
        print("""

        ╔══════════════════════════════════════════════════════════
        ║  🌟 BirthChartService — REQUEST
        ╠══════════════════════════════════════════════════════════
        ║  URL       : \(url.absoluteString)
        ║  Method    : POST
        ║  City      : \(city)
        ║  Lat/Lng   : \(geoResult.latitude), \(geoResult.longitude)
        ║  Timezone  : \(geoResult.timezone)
        ║  Date      : \(year)-\(month)-\(day) \(birthHour):\(birthMinute)
        ║  x-api-key : \(keyPreview)  (length: \(key.count) chars)
        ╚══════════════════════════════════════════════════════════
        """)
        #endif

        // Network call
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            #if DEBUG
            print("❌ [BirthChartService] Network error: \(error)")
            #endif
            throw BirthChartError.networkError(error)
        }

        // Validate response
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        #if DEBUG
        let rawBody = String(data: data, encoding: .utf8) ?? "<binary / unreadable>"
        print("""

        ╔══════════════════════════════════════════════════════════
        ║  📡 BirthChartService — RESPONSE
        ╠══════════════════════════════════════════════════════════
        ║  Status : \(statusCode)  \(statusCode == 200 ? "✅" : "❌")
        ║  Body   : \(rawBody.prefix(2000))
        ╚══════════════════════════════════════════════════════════
        """)
        #endif

        guard statusCode == 200 else {
            throw BirthChartError.serverError(statusCode)
        }

        // Build birth date from components (for display in detail view)
        var comps = DateComponents()
        comps.day = day; comps.month = month; comps.year = year
        let birthDateForStorage = Calendar.current.date(from: comps)

        return try parseNatalChart(
            from: data,
            hasBirthTime: hasBirthTime,
            birthPlace: city,
            birthDate: birthDateForStorage
        )
    }

    // MARK: - Response Parsing

    private func parseNatalChart(
        from data: Data,
        hasBirthTime: Bool,
        birthPlace: String,
        birthDate: Date?
    ) throws -> BirthChart {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            var sunSign    = "Unknown"
            var moonSign   = "Unknown"
            var risingSign: String? = nil
            var planets: [PlanetData] = []
            var houseCusps: [HouseCusp] = []

            // ── Parse planets (array format — FreeAstroAPI primary format) ───
            if let planetsArray = json?["planets"] as? [[String: Any]] {
                for p in planetsArray {
                    // id field ("sun", "moon", "mean_node", etc.)
                    let rawId   = p["id"] as? String ?? p["name"] as? String ?? ""
                    let id      = rawId.lowercased().replacingOccurrences(of: " ", with: "_")
                    let name    = p["name"] as? String ?? rawId.capitalized

                    // sign_id is the primary field; fall back to "sign"
                    let rawSign = p["sign_id"] as? String
                                  ?? p["sign"] as? String
                                  ?? ""
                    let signId  = normalizeSignId(rawSign)

                    let pos     = p["pos"] as? Double ?? 0
                    let absPos  = p["abs_pos"] as? Double ?? 0

                    let retrograde: Bool = {
                        if let b = p["retrograde"] as? Bool   { return b }
                        if let s = p["retrograde"] as? String { return s.lowercased() == "true" }
                        if let i = p["retrograde"] as? Int    { return i != 0 }
                        return false
                    }()

                    let house = p["house"] as? Int ?? 0

                    guard !id.isEmpty, !signId.isEmpty else { continue }

                    planets.append(PlanetData(
                        id: id, name: name, signId: signId,
                        pos: pos, absPos: absPos,
                        retrograde: retrograde, house: house
                    ))

                    // Derive basic sun/moon from the planet array
                    if id == "sun"  { sunSign  = normalizeSignName(signId) }
                    if id == "moon" { moonSign = normalizeSignName(signId) }
                }

            // ── Fallback: dict format {"Sun": {"sign": "Cancer", ...}} ──────
            } else if let planetsDict = json?["planets"] as? [String: Any] {
                if let sunData  = planetsDict["Sun"]  as? [String: Any],
                   let sign     = sunData["sign"] as? String {
                    sunSign = normalizeSignName(sign)
                }
                if let moonData = planetsDict["Moon"] as? [String: Any],
                   let sign     = moonData["sign"] as? String {
                    moonSign = normalizeSignName(sign)
                }
            }

            // ── Parse houses (array format) ──────────────────────────────────
            if let housesArray = json?["houses"] as? [[String: Any]] {
                for h in housesArray {
                    let houseNum = h["house"] as? Int ?? 0
                    let rawSign  = h["sign_id"] as? String ?? h["sign"] as? String ?? ""
                    let signId   = normalizeSignId(rawSign)
                    let pos      = h["pos"] as? Double ?? 0

                    guard houseNum > 0, !signId.isEmpty else { continue }
                    houseCusps.append(HouseCusp(house: houseNum, signId: signId, pos: pos))
                }
                // Rising from house 1 cusp
                if let house1 = houseCusps.first(where: { $0.house == 1 }) {
                    risingSign = normalizeSignName(house1.signId)
                }
            }

            // ── Rising fallbacks (dict / legacy formats) ─────────────────────
            if risingSign == nil, hasBirthTime {
                if let houses = json?["houses"] as? [String: Any] {
                    if let asc  = houses["ascendant"] as? [String: Any],
                       let sign = asc["sign"] as? String {
                        risingSign = normalizeSignName(sign)
                    } else if let ascSign = houses["Ascendant"] as? String {
                        risingSign = normalizeSignName(ascSign)
                    }
                }
                if risingSign == nil,
                   let firstHouse = json?["first_house"] as? [String: Any],
                   let sign = firstHouse["sign"] as? String {
                    risingSign = normalizeSignName(sign)
                }
                if risingSign == nil,
                   let ascendant = json?["ascendant"] as? [String: Any],
                   let sign = ascendant["sign"] as? String {
                    risingSign = normalizeSignName(sign)
                }
            }

            // Strip rising if birth time wasn't provided
            if !hasBirthTime { risingSign = nil }

            #if DEBUG
            print("""
            ✅ [BirthChartService] Parsed:
               Sun: \(sunSign) | Moon: \(moonSign) | Rising: \(risingSign ?? "N/A")
               Planets: \(planets.map { "\($0.name)(\($0.signId))" }.joined(separator: ", "))
               Houses:  \(houseCusps.map { "H\($0.house):\($0.signId)" }.joined(separator: ", "))
            """)
            #endif

            return BirthChart(
                sunSign:      sunSign,
                moonSign:     moonSign,
                risingSign:   risingSign,
                calculatedAt: Date(),
                planets:      planets.isEmpty ? nil : planets,
                houses:       houseCusps.isEmpty ? nil : houseCusps,
                birthPlace:   birthPlace.isEmpty ? nil : birthPlace,
                birthDate:    birthDate
            )

        } catch {
            #if DEBUG
            print("❌ [BirthChartService] Decoding error: \(error)")
            #endif
            throw BirthChartError.decodingError(error)
        }
    }

    // MARK: - Sign Helpers

    /// Normalizes a raw sign string to a capitalized full name ("Cancer", "Sagittarius", …)
    private func normalizeSignName(_ sign: String) -> String {
        normalizeSignId(sign).capitalized
    }

    /// Maps any sign string or abbreviation to a lowercase full name ("cancer", "sagittarius", …)
    private func normalizeSignId(_ raw: String) -> String {
        let lower = raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        let abbreviations: [String: String] = [
            "ari": "aries",   "tau": "taurus",      "gem": "gemini",
            "can": "cancer",  "leo": "leo",          "vir": "virgo",
            "lib": "libra",   "sco": "scorpio",      "sag": "sagittarius",
            "cap": "capricorn","aqu": "aquarius",    "pis": "pisces"
        ]

        let fullNames: Set<String> = [
            "aries","taurus","gemini","cancer","leo","virgo",
            "libra","scorpio","sagittarius","capricorn","aquarius","pisces"
        ]

        if fullNames.contains(lower) { return lower }
        if let full = abbreviations[lower] { return full }
        for (abbr, full) in abbreviations where lower.hasPrefix(abbr) { return full }

        // Return as-is lowercased if unrecognized
        return lower
    }
}

// MARK: - ZodiacSign Extension for Matching

extension ZodiacSign {
    /// Creates a ZodiacSign from a sign name string (case-insensitive).
    init?(fromName name: String) {
        let lowercased = name.lowercased()
        if let match = ZodiacSign.allCases.first(where: { $0.rawValue == lowercased }) {
            self = match
        } else {
            return nil
        }
    }
}
