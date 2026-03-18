//
//  DashboardView.swift
//  every_day
//

import SwiftUI

struct DashboardView: View {
    var viewModel:  DashboardViewModel
    var settingsVM: SettingsViewModel

    @State private var showZodiacPicker  = false
    @State private var showSettings      = false
    @State private var showBirthChart    = false
    @State private var appeared          = false
    @State private var sparkleScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            CelestialBackground()

            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    WeatherCardView(viewModel: viewModel, appeared: appeared)
                    if viewModel.shouldShowEarthTodayCard {
                        EarthTodayCardView(viewModel: viewModel, appeared: appeared)
                    }
                    MoonCardView(viewModel: viewModel, appeared: appeared)
                    HoroscopeCardView(
                        viewModel: viewModel,
                        settingsVM: settingsVM,
                        appeared: appeared,
                        onChangeStar: { showZodiacPicker = true }
                    )
                    if settingsVM.hasBirthChart {
                        birthChartLink
                    }
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .refreshable {
                await viewModel.refreshAll()
            }
        }
        .sheet(isPresented: $showZodiacPicker) {
            ZodiacPickerView(
                selectedSign: Binding(
                    get: { viewModel.selectedSign },
                    set: { viewModel.selectedSign = $0 }
                ),
                onDismiss: { showZodiacPicker = false }
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(settingsVM: settingsVM, dashboardVM: viewModel)
                .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showBirthChart) {
            if let chart = settingsVM.birthChart {
                NavigationStack {
                    BirthChartDetailView(chart: chart, isSheet: true)
                }
                .presentationDragIndicator(.visible)
            }
        }
        .onAppear {
            viewModel.initialize()
            withAnimation(.spring(dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
            if !viewModel.hasSelectedSign {
                showZodiacPicker = true
            }
        }
        .onChange(of: viewModel.locationService.location) { _, newLocation in
            guard let loc = newLocation else { return }
            Task {
                await viewModel.onLocationAvailable(loc)
                // Fetch birth chart horoscopes if available
                if let chart = settingsVM.birthChart {
                    await viewModel.fetchBirthChartHoroscopes(birthChart: chart)
                }
            }
        }
        .onChange(of: settingsVM.birthChart) { _, newChart in
            // When birth chart is calculated, fetch all three horoscopes
            if let chart = newChart {
                Task { await viewModel.fetchBirthChartHoroscopes(birthChart: chart) }
            }
        }
    }

    // MARK: - Birth Chart Link

    private var birthChartLink: some View {
        Button {
            showBirthChart = true
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .medium))
                    .accessibilityHidden(true)
                Text("View Full Birth Chart")
                    .font(.footnote)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .medium))
                    .accessibilityHidden(true)
            }
            .foregroundStyle(Color.orbitGold.opacity(0.8))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("View Full Birth Chart")
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                // Greeting appears when the user has set a display name
                let greet = greeting
                if !greet.isEmpty {
                    Text(greet)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.65))
                }

                Text("DailyOrbit")
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.orbitGold, .white],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )

                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.55))
            }

            Spacer()

            // ── Settings entry point ───────────────────────────────────────
            // Tap: light haptic → scale bounce → open Settings sheet.
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                sparkleScale = 1.35
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                    sparkleScale  = 1.0
                    showSettings  = true
                }
            } label: {
                Image(systemName: "sparkle")
                    .font(.title)
                    .foregroundStyle(Color.orbitGold)
                    .rotationEffect(.degrees(appeared ? 0 : -180))
                    .animation(.spring(dampingFraction: 0.6).delay(0.15), value: appeared)
                    .scaleEffect(sparkleScale)
                    .animation(.spring(response: 0.22, dampingFraction: 0.45), value: sparkleScale)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: appeared)
        .padding(.top, 12)
    }

    // MARK: - Computed

    private var greeting: String {
        let name = settingsVM.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return "" }
        let hour = Calendar.current.component(.hour, from: .now)
        let tod: String
        switch hour {
        case 5..<12:  tod = "Good morning"
        case 12..<17: tod = "Good afternoon"
        default:      tod = "Good evening"
        }
        return "\(tod), \(name)"
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }
}
