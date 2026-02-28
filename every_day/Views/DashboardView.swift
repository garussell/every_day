//
//  DashboardView.swift
//  every_day
//

import SwiftUI

struct DashboardView: View {
    var viewModel: DashboardViewModel

    @State private var showZodiacPicker = false
    @State private var appeared = false

    var body: some View {
        ZStack {
            CelestialBackground()

            ScrollView {
                VStack(spacing: 20) {
                    headerView
                    WeatherCardView(viewModel: viewModel, appeared: appeared)
                    MoonCardView(viewModel: viewModel, appeared: appeared)
                    HoroscopeCardView(viewModel: viewModel, appeared: appeared, onChangeStar: {
                        showZodiacPicker = true
                    })
                    Spacer(minLength: 30)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }
            .refreshable {
                await viewModel.refreshAll()
            }
        }
        .preferredColorScheme(.dark)
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
        .onAppear {
            viewModel.initialize()
            // Trigger card animations after a brief pause
            withAnimation(.spring(dampingFraction: 0.8).delay(0.2)) {
                appeared = true
            }
            // Show zodiac picker on first launch
            if !viewModel.hasSelectedSign {
                showZodiacPicker = true
            }
        }
        // React when location becomes available for the first time
        .onChange(of: viewModel.locationService.location) { _, newLocation in
            guard let loc = newLocation else { return }
            Task { await viewModel.onLocationAvailable(loc) }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
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
            Image(systemName: "sparkle")
                .font(.title)
                .foregroundStyle(Color.orbitGold)
                .rotationEffect(.degrees(appeared ? 0 : -180))
                .animation(.spring(dampingFraction: 0.6).delay(0.15), value: appeared)
        }
        .opacity(appeared ? 1 : 0)
        .animation(.easeOut(duration: 0.4), value: appeared)
        .padding(.top, 12)
    }

    private var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }
}
