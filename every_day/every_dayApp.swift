//
//  every_dayApp.swift
//  every_day
//

import SwiftUI
import SwiftData

@main
struct every_dayApp: App {
    init() {
        Secrets.bootstrap()
        SettingsViewModel.migrateBirthDataToKeychainIfNeeded()
        URLCache.shared = URLCache(
            memoryCapacity: 32 * 1_024 * 1_024,
            diskCapacity: 256 * 1_024 * 1_024,
            diskPath: nil
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [JournalEntry.self, MeditationSession.self])
    }
}
