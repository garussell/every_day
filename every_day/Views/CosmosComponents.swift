//
//  CosmosComponents.swift
//  every_day
//

import SwiftUI

struct SpaceSectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SpaceStatusCard: View {
    let icon: String
    let message: String
    let appeared: Bool
    var delay: Double = 0

    var body: some View {
        OrbitCard(delay: delay, appeared: appeared) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundStyle(Color.orbitGold)

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}

struct FeaturedPlanetView: View {
    let planet: PlanetaryBody
    let appeared: Bool

    var body: some View {
        OrbitCard(delay: 0.05, appeared: appeared) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Featured Planet")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.orbitGold.opacity(0.9))
                            .textCase(.uppercase)

                        Text(planet.displayName)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)

                        Text(planet.descriptor)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Spacer()

                    PlanetOrb(theme: planet.theme, symbolSize: 26)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 12
                ) {
                    PlanetFactPill(title: "Radius", value: planet.radiusText)
                    PlanetFactPill(title: "Gravity", value: planet.gravityText)
                    PlanetFactPill(title: "Orbit", value: planet.orbitalPeriodText)
                    PlanetFactPill(title: "Rotation", value: planet.rotationText)
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        PlanetMetricChip(title: "Moons", value: planet.moonCountText)
                        PlanetMetricChip(title: "Avg Temp", value: planet.temperatureText)
                        PlanetMetricChip(title: "Density", value: planet.densityText)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            PlanetMetricChip(title: "Moons", value: planet.moonCountText)
                            PlanetMetricChip(title: "Avg Temp", value: planet.temperatureText)
                        }
                        PlanetMetricChip(title: "Density", value: planet.densityText)
                    }
                }

                HStack {
                    Label(planet.sourceBadgeText, systemImage: planet.dataSource == .live ? "waveform.path.ecg" : "sparkles")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white.opacity(0.72))

                    Spacer()

                    if let discoveryText = planet.discoveryText {
                        Text(discoveryText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.52))
                    }
                }
            }
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(planet.theme.softGradient)
            )
        }
    }
}

struct PlanetCardView: View {
    let planet: PlanetaryBody

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(planet.displayName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)

                    Text(planet.descriptor)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.62))
                        .lineLimit(3)
                }

                Spacer()

                PlanetOrb(theme: planet.theme, symbolSize: 18)
            }

            VStack(alignment: .leading, spacing: 10) {
                PlanetFactLine(label: "Radius", value: planet.radiusText)
                PlanetFactLine(label: "Gravity", value: planet.gravityText)
                PlanetFactLine(label: "Orbit", value: planet.orbitalPeriodText)
                PlanetFactLine(label: "Rotation", value: planet.rotationText)
                PlanetFactLine(label: "Moons", value: planet.moonCountText)
            }

            HStack {
                Text(planet.bodyType)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.white.opacity(0.68))

                Spacer()

                Text(planet.sourceBadgeText)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(Color.orbitGold.opacity(0.85))
            }
        }
        .padding(18)
        .frame(width: 240, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.orbitCard.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(planet.theme.borderGradient, lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(planet.theme.softGradient)
                .frame(width: 90, height: 90)
                .blur(radius: 10)
                .offset(x: 20, y: -20)
        }
    }
}

struct PlanetMetricChip: View {
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
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct PlanetFactPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.white.opacity(0.52))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct PlanetFactLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
            Spacer(minLength: 10)
            Text(value)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.84))
                .multilineTextAlignment(.trailing)
        }
    }
}

struct PlanetOrb: View {
    let theme: PlanetTheme
    let symbolSize: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(theme.backgroundGradient)
                .frame(width: 54, height: 54)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.22), lineWidth: 1)
                )

            Image(systemName: theme.symbolName)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
        }
        .shadow(color: theme.shadowColor, radius: 18, x: 0, y: 8)
    }
}

extension PlanetTheme {
    var symbolName: String {
        switch self {
        case .mercury:
            return "sparkles"
        case .venus:
            return "sun.haze.fill"
        case .earth:
            return "globe.americas.fill"
        case .mars:
            return "flame.fill"
        case .jupiter:
            return "hurricane"
        case .saturn:
            return "circle.hexagongrid.fill"
        case .uranus:
            return "wind"
        case .neptune:
            return "moon.stars.fill"
        }
    }

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var borderGradient: LinearGradient {
        LinearGradient(
            colors: [gradientColors.first?.opacity(0.8) ?? .white, gradientColors.last?.opacity(0.28) ?? .clear],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var softGradient: LinearGradient {
        LinearGradient(
            colors: gradientColors.map { $0.opacity(0.18) },
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var shadowColor: Color {
        gradientColors.last?.opacity(0.38) ?? .black.opacity(0.3)
    }

    private var gradientColors: [Color] {
        switch self {
        case .mercury:
            return [Color(red: 0.74, green: 0.72, blue: 0.76), Color(red: 0.42, green: 0.43, blue: 0.50)]
        case .venus:
            return [Color(red: 0.98, green: 0.77, blue: 0.45), Color(red: 0.80, green: 0.46, blue: 0.24)]
        case .earth:
            return [Color(red: 0.34, green: 0.83, blue: 0.76), Color(red: 0.17, green: 0.43, blue: 0.91)]
        case .mars:
            return [Color(red: 0.92, green: 0.46, blue: 0.35), Color(red: 0.60, green: 0.19, blue: 0.18)]
        case .jupiter:
            return [Color(red: 0.91, green: 0.69, blue: 0.52), Color(red: 0.67, green: 0.39, blue: 0.23)]
        case .saturn:
            return [Color(red: 0.94, green: 0.81, blue: 0.57), Color(red: 0.71, green: 0.58, blue: 0.32)]
        case .uranus:
            return [Color(red: 0.70, green: 0.95, blue: 0.92), Color(red: 0.38, green: 0.71, blue: 0.83)]
        case .neptune:
            return [Color(red: 0.43, green: 0.61, blue: 1.00), Color(red: 0.17, green: 0.27, blue: 0.66)]
        }
    }
}

#Preview("Planet Card") {
    ZStack {
        CelestialBackground()
        PlanetCardView(planet: PlanetaryBody.mockPlanets[3])
            .padding()
    }
}
