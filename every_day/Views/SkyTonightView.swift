//
//  SkyTonightView.swift
//  every_day
//

import SwiftUI

struct SkyTonightView: View {
    let viewModel: SkyTonightViewModel
    let appeared: Bool

    var body: some View {
        OrbitCard(delay: 0.24, appeared: appeared) {
            VStack(alignment: .leading, spacing: 16) {
                SpaceSectionHeader(
                    title: "Sky Tonight",
                    subtitle: "What’s visible from your location tonight"
                )

                locationHeader

                if viewModel.isLoading {
                    loadingState
                } else {
                    summaryCard
                    conditionsCard
                    objectsSection

                    if let errorMessage = viewModel.errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.65))
                    }

                    Text("Planet positions depend on your location and time.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
        }
    }

    private var locationHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "location.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orbitGold)
                    .accessibilityHidden(true)

                Text(viewModel.locationLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }

            if let locationMessage = viewModel.locationMessage {
                Text(locationMessage)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
    }

    private var loadingState: some View {
        HStack(spacing: 12) {
            ProgressView()
                .tint(Color.orbitGold)

            Text("Checking the sky above you")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.vertical, 10)
    }

    private var summaryCard: some View {
        SkyPanelCard(title: "Tonight Summary", icon: "sparkles") {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.summaryTitle)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(viewModel.summaryMessage)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var conditionsCard: some View {
        SkyPanelCard(title: "Viewing Conditions", icon: "cloud.moon.fill") {
            if let conditions = viewModel.viewingConditions {
                VStack(alignment: .leading, spacing: 12) {
                    Text(conditions.viewingNote)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .fixedSize(horizontal: false, vertical: true)

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            SkyMetricPill(title: "Condition", value: conditions.condition ?? "Unavailable")
                            SkyMetricPill(title: "Cloud Cover", value: conditions.cloudCoverText)
                            SkyMetricPill(title: "Temp", value: conditions.temperatureText)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 10) {
                                SkyMetricPill(title: "Condition", value: conditions.condition ?? "Unavailable")
                                SkyMetricPill(title: "Cloud Cover", value: conditions.cloudCoverText)
                            }
                            SkyMetricPill(title: "Temp", value: conditions.temperatureText)
                        }
                    }

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            SkyMetricPill(title: "Wind", value: conditions.windText)
                            SkyMetricPill(title: "Humidity", value: conditions.humidityText)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            SkyMetricPill(title: "Wind", value: conditions.windText)
                            SkyMetricPill(title: "Humidity", value: conditions.humidityText)
                        }
                    }
                }
            } else {
                Text("Sky conditions unavailable")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
            }
        }
    }

    private var objectsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Tonight’s Objects")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text("\(viewModel.objects.filter { $0.isAboveHorizon }.count) above horizon")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(Color.orbitGold.opacity(0.88))
            }

            if viewModel.objects.isEmpty {
                Text("Object visibility will appear here once your location and position data are ready.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.68))
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.objects) { object in
                        SkyObjectRowView(object: object)
                    }
                }
            }
        }
    }
}

private struct SkyPanelCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.orbitGold.opacity(0.9))
                .textCase(.uppercase)

            content()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct SkyMetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.5))

            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.88))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
        )
    }
}

private struct SkyObjectRowView: View {
    let object: SkyObject

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: object.symbolName)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                    .frame(width: 22)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(object.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(object.note)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 12)

                Text(object.viewingQuality.label)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(accentColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(accentColor.opacity(0.15))
                    )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    SkyMetricPill(title: "Above Horizon", value: object.aboveHorizonText)
                    SkyMetricPill(title: "Altitude", value: object.altitudeText)
                    SkyMetricPill(title: "Direction", value: object.azimuthText)
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        SkyMetricPill(title: "Above Horizon", value: object.aboveHorizonText)
                        SkyMetricPill(title: "Altitude", value: object.altitudeText)
                    }
                    SkyMetricPill(title: "Direction", value: object.azimuthText)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.orbitCard.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var accentColor: Color {
        switch object.viewingQuality {
        case .excellent:
            return Color.orbitGold
        case .moderate:
            return Color.moonSilver
        case .poor:
            return Color.orange.opacity(0.85)
        case .notVisible:
            return .white.opacity(0.65)
        case .unavailable:
            return .white.opacity(0.5)
        }
    }
}

#Preview {
    SkyTonightView(viewModel: SkyTonightViewModel(), appeared: true)
        .preferredColorScheme(.dark)
        .padding()
        .background(Color.orbitBackground)
}
