//
//  HoroscopeService.swift
//  every_day
//
//  Uses the API Ninjas Horoscope endpoint.
//  Docs: https://api-ninjas.com/api/horoscope
//
//  API KEY SETUP
//  -------------
//  The key is stored exclusively in the iOS Keychain — it is never hardcoded
//  in source. Call HoroscopeService.updateAPIKey("your-key") once at app
//  startup (e.g. from every_dayApp.init()) in a file that is excluded from
//  version control (e.g. add "Secrets.swift" to .gitignore).
//
//  Example Secrets.swift (gitignored):
//
//      import Foundation
//      enum Secrets {
//          static func bootstrap() {
//              HoroscopeService.updateAPIKey("your-api-ninjas-key-here")
//          }
//      }
//
//  Then in every_dayApp.init(): Secrets.bootstrap()
//

import Foundation

struct HoroscopeService {

    // MARK: - Dependency Injection

    private let session: NetworkSession

    init(session: NetworkSession = URLSession.shared) {
        self.session = session
    }

    // MARK: - API Key

    private static let keychainAccount = "apininjas_horoscope_key"

    /// Reads the API key from the Keychain. Returns an empty string if not set,
    /// which will cause the request to fail with a 401 — surfaced as a user-facing
    /// error via the existing error-handling path.
    private var apiKey: String {
        KeychainHelper.load(for: Self.keychainAccount) ?? ""
    }

    /// Seeds or updates the API key in the Keychain. Call once at app startup
    /// from a file that is excluded from version control.
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

        #if DEBUG
        print("""

        ╔══════════════════════════════════════════════════════════
        ║  🌟 HoroscopeService — REQUEST
        ╠══════════════════════════════════════════════════════════
        ║  URL       : \(url.absoluteString)
        ║  Method    : GET
        ║  Zodiac    : \(sign.rawValue)
        ║  X-Api-Key : [REDACTED] (length: \(key.count) chars)
        ╚══════════════════════════════════════════════════════════
        """)
        #endif

        // ── Network call ─────────────────────────────────────────────────────
        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch {
            #if DEBUG
            print("❌ [HoroscopeService] Network error: \(error)")
            #endif
            throw error
        }

        // ── Validate response ────────────────────────────────────────────────
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1

        #if DEBUG
        print("""

        ╔══════════════════════════════════════════════════════════
        ║  📡 HoroscopeService — RESPONSE
        ╠══════════════════════════════════════════════════════════
        ║  Status : \(statusCode)  \(statusCode == 200 ? "✅" : "❌")
        ║  Bytes  : \(data.count)
        ╚══════════════════════════════════════════════════════════
        """)
        #endif

        guard statusCode == 200 else {
            #if DEBUG
            print("❌ [HoroscopeService] Non-200 status \(statusCode). Check API key and quota at api-ninjas.com.")
            #endif
            throw URLError(.badServerResponse)
        }

        // ── Decode ───────────────────────────────────────────────────────────
        do {
            let decoded = try JSONDecoder().decode(HoroscopeAPIResponse.self, from: data)
            #if DEBUG
            print("✅ [HoroscopeService] Decoded successfully — sign: \(decoded.sign)")
            #endif
            return HoroscopeData(sign: decoded.sign, horoscope: decoded.horoscope)
        } catch {
            #if DEBUG
            print("❌ [HoroscopeService] Decoding error: \(error)")
            #endif
            throw error
        }
    }
}
