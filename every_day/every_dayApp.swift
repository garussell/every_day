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
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [JournalEntry.self, MeditationSession.self])
    }
}
