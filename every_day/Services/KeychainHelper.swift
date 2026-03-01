//
//  KeychainHelper.swift
//  every_day
//
//  Generic Keychain wrapper for securely storing string values.
//  Uses kSecClassGenericPassword scoped to the app's bundle identifier.
//

import Foundation
import Security

enum KeychainHelper {

    private static var service: String {
        Bundle.main.bundleIdentifier ?? "com.dailyorbit"
    }

    /// Writes (or overwrites) a UTF-8 string value for the given account key.
    @discardableResult
    static func save(_ value: String, for account: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item so the add always succeeds.
        delete(for: account)

        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrService:      service,
            kSecAttrAccount:      account,
            kSecValueData:        data,
            // Accessible whenever the device is unlocked; not migrated to other devices.
            kSecAttrAccessible:   kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]
        return SecItemAdd(query as CFDictionary, nil) == errSecSuccess
    }

    /// Returns the stored string for the given account key, or nil if not found.
    static func load(for account: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
            kSecReturnData:  true,
            kSecMatchLimit:  kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    /// Deletes the stored item for the given account key.
    @discardableResult
    static func delete(for account: String) -> Bool {
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrService: service,
            kSecAttrAccount: account,
        ]
        return SecItemDelete(query as CFDictionary) == errSecSuccess
    }
}
