//
//  NASAAPIConfiguration.swift
//  every_day
//

import Foundation

enum NASAAPIConfiguration {
    private static let keychainAccount = "nasa_api_key"

    /// Returns the stored NASA API key, or falls back to NASA's public DEMO_KEY.
    /// DEMO_KEY is rate-limited to 30 requests/hour/IP — suitable only for development.
    static var apiKey: String {
        let stored = (KeychainHelper.load(for: keychainAccount) ?? "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if stored.isEmpty {
            #if DEBUG
            print("⚠️ [NASAAPIConfiguration] Using DEMO_KEY (rate-limited). Set a real key in Secrets.swift.")
            #endif
            return "DEMO_KEY"
        }
        return stored
    }

    static func updateAPIKey(_ key: String) {
        let trimmed = key.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            KeychainHelper.delete(for: keychainAccount)
        } else {
            KeychainHelper.save(trimmed, for: keychainAccount)
        }
    }
}
