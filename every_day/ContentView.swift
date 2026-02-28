//
//  ContentView.swift
//  every_day
//

import SwiftUI

struct ContentView: View {
    @State private var dashboardVM = DashboardViewModel()

    var body: some View {
        TabView {
            DashboardView(viewModel: dashboardVM)
                .tabItem {
                    Label("Today", systemImage: "sparkles")
                }

            JournalListView()
                .tabItem {
                    Label("Journal", systemImage: "book.fill")
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
