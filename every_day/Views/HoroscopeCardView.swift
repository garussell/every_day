//
//  HoroscopeCardView.swift
//  every_day
//

import SwiftUI

struct HoroscopeCardView: View {
    let viewModel: DashboardViewModel
    let appeared: Bool
    let onChangeStar: () -> Void

    var body: some View {
        OrbitCard(delay: 0.4, appeared: appeared) {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader
                signSelector

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
        }
    }

    // MARK: - Subviews

    private var cardHeader: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.title3)
                .foregroundStyle(Color.orbitGold)
            Text("Daily Horoscope")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
        }
    }

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
