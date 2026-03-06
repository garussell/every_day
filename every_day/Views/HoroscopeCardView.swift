//
//  HoroscopeCardView.swift
//  every_day
//

import SwiftUI

struct HoroscopeCardView: View {
    let viewModel: DashboardViewModel
    let settingsVM: SettingsViewModel
    let appeared: Bool
    let onChangeStar: () -> Void

    /// Whether the user has a calculated birth chart
    private var hasBirthChart: Bool {
        settingsVM.birthChart != nil
    }

    /// The birth chart (if available)
    private var birthChart: BirthChart? {
        settingsVM.birthChart
    }

    /// Available horoscope types based on birth chart
    private var availableTypes: [HoroscopeType] {
        guard let chart = birthChart else { return [] }
        var types: [HoroscopeType] = [.sun, .moon]
        if chart.risingSign != nil {
            types.append(.rising)
        }
        return types
    }

    var body: some View {
        OrbitCard(delay: 0.4, appeared: appeared) {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader

                if hasBirthChart {
                    // Birth chart mode: show horoscope type selector
                    horoscopeTypeSelector
                    birthChartSignDisplay
                    birthChartHoroscopeContent
                } else {
                    // Legacy mode: show sign selector
                    signSelector
                    legacyHoroscopeContent
                    birthChartPrompt
                }
            }
        }
    }

    // MARK: - Card Header

    private var cardHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.orbitGold)
            Text(hasBirthChart ? "Your Horoscopes" : "Daily Horoscope")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
        }
    }

    // MARK: - Birth Chart Mode

    private var horoscopeTypeSelector: some View {
        HStack(spacing: 0) {
            ForEach(availableTypes) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.selectedHoroscopeType = type
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: type.icon)
                            .font(.caption)
                        Text(type.rawValue)
                            .font(.subheadline.weight(.medium))
                    }
                    .foregroundStyle(
                        viewModel.selectedHoroscopeType == type
                            ? Color.orbitGold
                            : .white.opacity(0.5)
                    )
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        viewModel.selectedHoroscopeType == type
                            ? Color.orbitGold.opacity(0.15)
                            : Color.clear
                    )
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orbitGold.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var birthChartSignDisplay: some View {
        Group {
            if let chart = birthChart,
               let sign = viewModel.signForType(viewModel.selectedHoroscopeType, birthChart: chart) {
                HStack(spacing: 10) {
                    Text(sign.glyph)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(viewModel.selectedHoroscopeType.rawValue) in \(sign.displayName)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(sign.dateRange)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white.opacity(0.07))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.orbitGold.opacity(0.25), lineWidth: 1)
                        )
                )
            }
        }
    }

    @ViewBuilder
    private var birthChartHoroscopeContent: some View {
        if viewModel.isLoadingCurrentHoroscope {
            loadingView
        } else if let error = viewModel.currentHoroscopeError {
            errorView(message: error)
        } else if let h = viewModel.currentHoroscope {
            horoscopeContent(h)
        } else {
            emptyView
        }
    }

    // MARK: - Legacy Mode (No Birth Chart)

    private var signSelector: some View {
        Button {
            onChangeStar()
        } label: {
            HStack(spacing: 10) {
                Text(viewModel.selectedSign.glyph)
                    .font(.title2)
                Text(viewModel.selectedSign.displayName)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                Text(viewModel.selectedSign.dateRange)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Color.orbitGold.opacity(0.7))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orbitGold.opacity(0.25), lineWidth: 1)
                    )
            )
        }
    }

    @ViewBuilder
    private var legacyHoroscopeContent: some View {
        if viewModel.isLoadingHoroscope {
            loadingView
        } else if let error = viewModel.horoscopeError {
            errorView(message: error)
        } else if let h = viewModel.horoscopeData {
            horoscopeContent(h)
        } else {
            emptyView
        }
    }

    private var birthChartPrompt: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()
                .background(Color.orbitGold.opacity(0.2))
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                Image(systemName: "star.circle")
                    .font(.title3)
                    .foregroundStyle(Color.orbitGold.opacity(0.7))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Unlock Your Full Chart")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Add your birth details in Settings to see Sun, Moon & Rising horoscopes.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Shared Content Views

    private func horoscopeContent(_ h: HoroscopeData) -> some View {
        Text(h.horoscope)
            .font(.body)
            .foregroundStyle(.white.opacity(0.88))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView().tint(Color.orbitGold).scaleEffect(1.2)
            Spacer()
        }
        .padding(.vertical, 20)
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
            Text(message).font(.footnote).foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }

    private var emptyView: some View {
        Text("Fetching your reading…")
            .font(.footnote).foregroundStyle(.white.opacity(0.5))
            .padding(.vertical, 8)
    }
}
