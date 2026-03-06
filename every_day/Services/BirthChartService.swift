//
//  BirthChartService.swift
//  every_day
//
//  Uses the FreeAstroAPI to calculate natal charts (Sun, Moon, Rising signs).
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

// MARK: - Birth Chart Model

struct BirthChart: Codable, Equatable {
    let sunSign: String
    let moonSign: String
    let risingSign: String?
    let calculatedAt: Date

    /// User-friendly display for Rising when it may be nil
    var risingDisplayName: String {
        risingSign ?? "Unknown"
    }
}

// MARK: - API Response Models

struct NatalChartResponse: Codable {
    let planets: [String: PlanetPosition]?
    let houses: HouseData?

    struct PlanetPosition: Codable {
        let sign: String?
        let signNum: Int?
        let position: Double?
        let retrograde: Bool?

        enum CodingKeys: String, CodingKey {
            case sign
            case signNum = "sign_num"
            case position
            case retrograde
        }
    }

    struct HouseData: Codable {
        let ascendant: HousePosition?

        struct HousePosition: Codable {
            let sign: String?
            let signNum: Int?
            let position: Double?

            enum CodingKeys: String, CodingKey {
                case sign
                case signNum = "sign_num"
                case position
            }
        }
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
    /// - Parameters:
    ///   - day: Birth day (1-31)
    ///   - month: Birth month (1-12)
    ///   - year: Birth year (e.g., 1990)
    ///   - hour: Birth hour (0-23), nil if unknown
    ///   - minute: Birth minute (0-59), nil if unknown
    ///   - city: Birth city name (will be geocoded)
    /// - Returns: A BirthChart with Sun, Moon, and Rising signs
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
        let birthHour = hour ?? 12
        let birthMinute = minute ?? 0
        let hasBirthTime = hour != nil

        // Geocode the city to get coordinates and timezone
        let geoResult = try await geocodeCity(city)

        // Build request — CORRECT ENDPOINT: /api/v1/natal/calculate
        let url = URL(string: "https://api.freeastroapi.com/api/v1/natal/calculate")!

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")

        // API requires: name, year, month, day, hour, minute, city, lat, lng, tz_str
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
        ║  Body   : \(rawBody.prefix(1500))
        ╚══════════════════════════════════════════════════════════
        """)
        #endif

        guard statusCode == 200 else {
            throw BirthChartError.serverError(statusCode)
        }

        // Parse response - the API returns planetary positions
        // We need to extract Sun sign, Moon sign, and Ascendant
        return try parseNatalChart(from: data, hasBirthTime: hasBirthTime)
    }

    // MARK: - Response Parsing

    private func parseNatalChart(from data: Data, hasBirthTime: Bool) throws -> BirthChart {
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

            var sunSign = "Unknown"
            var moonSign = "Unknown"
            var risingSign: String? = nil

            // Try to extract from planets — could be array or dictionary
            if let planetsArray = json?["planets"] as? [[String: Any]] {
                // Format: [{"name": "Sun", "sign": "Cancer", ...}, ...]
                for planet in planetsArray {
                    let name = planet["name"] as? String ?? ""
                    let sign = planet["sign"] as? String ?? ""

                    if name.lowercased() == "sun" {
                        sunSign = normalizeSignName(sign)
                    } else if name.lowercased() == "moon" {
                        moonSign = normalizeSignName(sign)
                    }
                }
            } else if let planetsDict = json?["planets"] as? [String: Any] {
                // Format: {"Sun": {"sign": "Cancer", ...}, "Moon": {...}}
                if let sunData = planetsDict["Sun"] as? [String: Any],
                   let sign = sunData["sign"] as? String {
                    sunSign = normalizeSignName(sign)
                }
                if let moonData = planetsDict["Moon"] as? [String: Any],
                   let sign = moonData["sign"] as? String {
                    moonSign = normalizeSignName(sign)
                }
            }

            // Extract Rising/Ascendant — only if birth time is known
            if hasBirthTime {
                // Try houses.ascendant format
                if let houses = json?["houses"] as? [String: Any] {
                    if let ascendant = houses["ascendant"] as? [String: Any],
                       let sign = ascendant["sign"] as? String {
                        risingSign = normalizeSignName(sign)
                    } else if let ascSign = houses["Ascendant"] as? String {
                        risingSign = normalizeSignName(ascSign)
                    }
                }

                // Try houses as array format
                if risingSign == nil, let housesArray = json?["houses"] as? [[String: Any]] {
                    for house in housesArray {
                        let name = house["name"] as? String ?? ""
                        if name.lowercased().contains("ascendant") || name == "1" || name == "I" {
                            if let sign = house["sign"] as? String {
                                risingSign = normalizeSignName(sign)
                                break
                            }
                        }
                    }
                }

                // Try first_house format
                if risingSign == nil, let firstHouse = json?["first_house"] as? [String: Any],
                   let sign = firstHouse["sign"] as? String {
                    risingSign = normalizeSignName(sign)
                }

                // Try direct ascendant field
                if risingSign == nil, let ascendant = json?["ascendant"] as? [String: Any],
                   let sign = ascendant["sign"] as? String {
                    risingSign = normalizeSignName(sign)
                }
            }

            #if DEBUG
            print("✅ [BirthChartService] Parsed — Sun: \(sunSign), Moon: \(moonSign), Rising: \(risingSign ?? "N/A")")
            #endif

            return BirthChart(
                sunSign: sunSign,
                moonSign: moonSign,
                risingSign: risingSign,
                calculatedAt: Date()
            )

        } catch {
            #if DEBUG
            print("❌ [BirthChartService] Decoding error: \(error)")
            #endif
            throw BirthChartError.decodingError(error)
        }
    }

    /// Normalizes sign names (handles abbreviations and capitalizes properly)
    private func normalizeSignName(_ sign: String) -> String {
        let trimmed = sign.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = trimmed.lowercased()

        // Map common abbreviations to full names
        let abbreviations: [String: String] = [
            "ari": "Aries",
            "tau": "Taurus",
            "gem": "Gemini",
            "can": "Cancer",
            "leo": "Leo",
            "vir": "Virgo",
            "lib": "Libra",
            "sco": "Scorpio",
            "sag": "Sagittarius",
            "cap": "Capricorn",
            "aqu": "Aquarius",
            "pis": "Pisces"
        ]

        // Check if it's an abbreviation
        if let fullName = abbreviations[lowercased] {
            return fullName
        }

        // Check if it starts with a known prefix (e.g., "Sag" for Sagittarius)
        for (abbr, fullName) in abbreviations {
            if lowercased.hasPrefix(abbr) {
                return fullName
            }
        }

        // If already a full name, just capitalize it properly
        let fullNames = ["aries", "taurus", "gemini", "cancer", "leo", "virgo",
                         "libra", "scorpio", "sagittarius", "capricorn", "aquarius", "pisces"]

        if fullNames.contains(lowercased) {
            return trimmed.capitalized
        }

        // Return as-is with first letter capitalized
        return trimmed.isEmpty ? "Unknown" : trimmed.prefix(1).uppercased() + trimmed.dropFirst().lowercased()
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
