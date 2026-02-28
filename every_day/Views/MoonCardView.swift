//
//  MoonCardView.swift
//  every_day
//

import SwiftUI

struct MoonCardView: View {
    let viewModel: DashboardViewModel
    let appeared: Bool

    @State private var glowPulse = false

    var body: some View {
        OrbitCard(delay: 0.25, appeared: appeared) {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader

                if viewModel.isLoadingMoon {
                    loadingView
                } else if let error = viewModel.moonError {
                    errorView(message: error)
                } else if let moon = viewModel.moonData {
                    moonContentView(moon)
                } else {
                    emptyView
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    // MARK: - Subviews

    private var cardHeader: some View {
        HStack {
            Image(systemName: "moon.stars.fill")
                .font(.title3)
                .foregroundStyle(Color.moonSilver)
            Text("Moon Phase")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private func moonContentView(_ moon: MoonData) -> some View {
        HStack(alignment: .center, spacing: 24) {
            // Animated moon icon
            ZStack {
                Circle()
                    .fill(Color.moonSilver.opacity(0.08))
                    .frame(width: 90, height: 90)
                    .blur(radius: glowPulse ? 18 : 10)

                Image(systemName: moon.phaseSymbol)
                    .font(.system(size: 62))
                    .foregroundStyle(Color.moonSilver)
                    .shadow(color: Color.moonSilver.opacity(glowPulse ? 0.9 : 0.4),
                            radius: glowPulse ? 24 : 10)
                    .scaleEffect(appeared ? 1 : 0.4)
                    .animation(.spring(dampingFraction: 0.55).delay(0.35), value: appeared)
            }
            .frame(width: 90, height: 90)

            VStack(alignment: .leading, spacing: 8) {
                Text(moon.phaseName)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)

                illuminationBar(moon.illumination)

                HStack(spacing: 16) {
                    if let rise = moon.moonrise {
                        riseSetItem(icon: "moonrise.fill", label: "Rise", time: rise)
                    }
                    if let set = moon.moonset {
                        riseSetItem(icon: "moonset.fill",  label: "Set",  time: set)
                    }
                }
            }
            Spacer()
        }
    }

    private func illuminationBar(_ pct: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("Illumination \(pct)%")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.white.opacity(0.12))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.moonSilver)
                        .frame(width: geo.size.width * CGFloat(pct) / 100, height: 6)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: 160)
    }

    private func riseSetItem(icon: String, label: String, time: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.moonSilver.opacity(0.8))
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
                Text(time)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white)
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView().tint(Color.moonSilver).scaleEffect(1.2)
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
        Text("Fetching moon data…")
            .font(.footnote).foregroundStyle(.white.opacity(0.5))
            .padding(.vertical, 8)
    }
}
