//
//  ContentView.swift
//  every_day
//

import SwiftUI

private enum AppTab: Hashable {
    case today
    case journal
    case meditation
    case cosmos
    case explore
}

struct ContentView: View {
    @State private var dashboardVM  = DashboardViewModel()
    @State private var settingsVM   = SettingsViewModel()
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(viewModel: dashboardVM, settingsVM: settingsVM)
                .tag(AppTab.today)
                .tabItem {
                    Label("Today", systemImage: "sparkles")
                }

            JournalListView()
                .tag(AppTab.journal)
                .tabItem {
                    Label("Journal", systemImage: "book.closed.fill")
                }

            MeditationTimerView()
                .tag(AppTab.meditation)
                .tabItem {
                    Label("Meditation", systemImage: "figure.mind.and.body")
                }

            CosmosView {
                selectedTab = .explore
            }
                .tag(AppTab.cosmos)
                .tabItem {
                    Label("Cosmos", systemImage: "globe.americas.fill")
                }

            ExploreView()
                .tag(AppTab.explore)
                .tabItem {
                    Label("Explore", systemImage: "sparkles.rectangle.stack")
                }
        }
        .tint(Color.orbitGold)
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
