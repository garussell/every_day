//
//  ContentView.swift
//  every_day
//

import SwiftUI

struct ContentView: View {
    @State private var dashboardVM  = DashboardViewModel()
    @State private var settingsVM   = SettingsViewModel()

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardVM, settingsVM: settingsVM)
                .tabItem {
                    Label("Today", systemImage: "sparkles")
                }

            JournalListView()
                .tabItem {
                    Label("Journal", systemImage: "book.closed.fill")
                }

            MeditationTimerView()
                .tabItem {
                    Label("Meditate", systemImage: "figure.mind.and.body")
                }
        }
        .tint(Color.orbitGold)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
