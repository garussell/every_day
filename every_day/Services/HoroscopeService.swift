//
//  HoroscopeService.swift
//  every_day
//
//  Uses the API Ninjas Horoscope endpoint.
//  Docs: https://api-ninjas.com/api/horoscope
//

import Foundation

struct HoroscopeService {

    // MARK: - API Key
    // Your API Ninjas key. Every time this constant changes it is automatically
    // re-synced to the iOS Keychain, so stale Keychain values can never hide a
    // key update.
    private static let keyPlaceholder  = "E6vaMkcY6LuS4vm7oHG42Q==0mxjBNmM78DC4kYT"
    private static let keychainAccount = "apininjas_horoscope_key"

    /// Always writes the current hardcoded key to Keychain so updates are
    /// never silently ignored by a stale cached value.
    private var apiKey: String {
        let key = Self.keyPlaceholder
        KeychainHelper.save(key, for: Self.keychainAccount)
        return key
    }

    /// Call this to overwrite the stored key (e.g. from a settings screen).
    static func updateAPIKey(_ key: String) {
        KeychainHelper.save(key, for: keychainAccount)
    }

    // MARK: - Fetch

    func fetchHoroscope(for sign: ZodiacSign) async throws -> HoroscopeData {

        // ── Build request ────────────────────────────────────────────────────
        var components = URLComponents(string: "https://api.api-ninjas.com/v1/horoscope")!
        components.queryItems = [
            URLQueryItem(name: "zodiac", value: sign.rawValue),
        ]
        guard let url = components.url else { throw URLError(.badURL) }

        let key = apiKey
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(key, forHTTPHeaderField: "X-Api-Key")

        // ── Debug: print full request ────────────────────────────────────────
        let keyTrimmed     = key.trimmingCharacters(in: .whitespacesAndNewlines)
        let keyPreview     = key.count > 8 ? String(key.prefix(8)) + "..." : key
        let zodiacValue    = sign.rawValue
        let isLowercase    = zodiacValue == zodiacValue.lowercased()

        print("""

        ╔══════════════════════════════════════════════════════════
        ║  🌟 HoroscopeService — REQUEST
        ╠══════════════════════════════════════════════════════════
        ║  URL       : \(url.absoluteString)
        ║  Method    : GET
        ║  Zodiac    : \(zodiacValue)  (lowercase: \(isLowercase))
        ╠═══════════════════════════════════════════════════════════
        ║  HEADERS
        ║  X-Api-Key : \(keyPreview)  (length: \(key.count) chars)
        ║  Key trimmed == original: \(key == keyTrimmed)
        ║  No old RapidAPI headers (X-RapidAPI-Key): confirmed ✓
        ╚══════════════════════════════════════════════════════════
        """)

        // ── Network call ─────────────────────────────────────────────────────
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            print("❌ [HoroscopeService] Network error: \(error)")
            throw error
        }

        // ── Debug: print full response ───────────────────────────────────────
        let http       = response as? HTTPURLResponse
        let statusCode = http?.statusCode ?? -1
        let rawBody    = String(data: data, encoding: .utf8) ?? "<binary / unreadable>"

        print("""

        ╔══════════════════════════════════════════════════════════
        ║  📡 HoroscopeService — RESPONSE
        ╠══════════════════════════════════════════════════════════
        ║  Status : \(statusCode)  \(statusCode == 200 ? "✅" : "❌")
        ╠══════════════════════════════════════════════════════════
        ║  Body   : \(rawBody)
        ╚══════════════════════════════════════════════════════════
        """)

        guard statusCode == 200 else {
            print("❌ [HoroscopeService] Non-200 status \(statusCode). Check API key and quota at api-ninjas.com.")
            throw URLError(.badServerResponse)
        }

        // ── Decode ───────────────────────────────────────────────────────────
        do {
            let decoded = try JSONDecoder().decode(HoroscopeAPIResponse.self, from: data)
            print("✅ [HoroscopeService] Decoded successfully — sign: \(decoded.sign)")
            return HoroscopeData(sign: decoded.sign, horoscope: decoded.horoscope)
        } catch {
            print("❌ [HoroscopeService] Decoding error: \(error)")
            throw error
        }
    }
}
