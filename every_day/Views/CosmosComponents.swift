//
//  CosmosComponents.swift
//  every_day
//

import SwiftUI
import UIKit

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
                    .accessibilityHidden(true)

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
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 18) {
                        heading

                        Spacer(minLength: 16)

                        PlanetArtworkView(planet: planet, style: .featured)
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        heading
                        PlanetArtworkView(planet: planet, style: .featured)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
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

    private var heading: some View {
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

            Text("Selected from the planet gallery below.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.52))
        }
    }
}

struct FeaturedPlanetSkeletonView: View {
    let appeared: Bool

    var body: some View {
        OrbitCard(delay: 0.05, appeared: appeared) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .top, spacing: 18) {
                    VStack(alignment: .leading, spacing: 8) {
                        SkeletonLine(width: 118, height: 11)
                        SkeletonLine(width: 190, height: 32)
                        SkeletonLine(width: 220, height: 14)
                        SkeletonLine(width: 182, height: 10)
                    }

                    Spacer()

                    SkeletonBlock(width: 132, height: 132, cornerRadius: 32)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    alignment: .leading,
                    spacing: 12
                ) {
                    ForEach(0..<4, id: \.self) { _ in
                        skeletonFactPill
                    }
                }

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) {
                        skeletonMetricChip
                        skeletonMetricChip
                        skeletonMetricChip
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 10) {
                            skeletonMetricChip
                            skeletonMetricChip
                        }
                        skeletonMetricChip
                    }
                }

                HStack {
                    SkeletonLine(width: 124, height: 11)
                    Spacer()
                    SkeletonLine(width: 84, height: 10)
                }
            }
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.04))
            )
        }
    }

    private var skeletonFactPill: some View {
        VStack(alignment: .leading, spacing: 6) {
            SkeletonLine(width: 46, height: 9)
            SkeletonLine(width: nil, height: 14)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }

    private var skeletonMetricChip: some View {
        VStack(alignment: .leading, spacing: 4) {
            SkeletonLine(width: 38, height: 8)
            SkeletonLine(width: 56, height: 10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
        )
    }
}

struct PlanetCardView: View {
    let planet: PlanetaryBody
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            PlanetArtworkView(planet: planet, style: .card)
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Text("Featured")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.orbitGold.opacity(0.92), in: Capsule())
                            .padding(12)
                    }
                }

            VStack(alignment: .leading, spacing: 6) {
                Text(planet.displayName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)

                Text(planet.descriptor)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(3)
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
                    .foregroundStyle(isSelected ? Color.orbitGold : Color.orbitGold.opacity(0.85))
            }
        }
        .padding(18)
        .frame(width: 240, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(isSelected ? Color.orbitCard.opacity(0.98) : Color.orbitCard.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(isSelected ? selectedBorder : planet.theme.borderGradient, lineWidth: isSelected ? 1.4 : 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(isSelected ? planet.theme.backgroundGradient : planet.theme.softGradient)
                .frame(width: 90, height: 90)
                .blur(radius: 10)
                .offset(x: 20, y: -20)
        }
        .shadow(color: isSelected ? planet.theme.shadowColor.opacity(0.32) : .clear, radius: 18, x: 0, y: 10)
        .scaleEffect(isSelected ? 1.02 : 1)
        .animation(.spring(response: 0.28, dampingFraction: 0.82), value: isSelected)
    }

    private var selectedBorder: LinearGradient {
        LinearGradient(
            colors: [Color.orbitGold.opacity(0.95), .white.opacity(0.35)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct PlanetCardSkeletonView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SkeletonBlock(height: 114, cornerRadius: 18)

            VStack(alignment: .leading, spacing: 6) {
                SkeletonLine(width: 118, height: 16)
                SkeletonLine(width: 150, height: 10)
                SkeletonLine(width: 130, height: 10)
            }

            VStack(alignment: .leading, spacing: 10) {
                ForEach(0..<5, id: \.self) { index in
                    HStack {
                        SkeletonLine(width: 42, height: 9)
                        Spacer(minLength: 10)
                        SkeletonLine(width: index.isMultiple(of: 2) ? 72 : 56, height: 10)
                    }
                }
            }

            HStack {
                SkeletonLine(width: 48, height: 9)
                Spacer()
                SkeletonLine(width: 62, height: 9)
            }
        }
        .padding(18)
        .frame(width: 240, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.orbitCard.opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(Color.white.opacity(0.06))
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
        .accessibilityHidden(true)
    }
}

private struct PlanetArtworkView: View {
    enum Style {
        case featured
        case card

        var size: CGSize {
            switch self {
            case .featured:
                return CGSize(width: 132, height: 132)
            case .card:
                return CGSize(width: 204, height: 114)
            }
        }

        var cornerRadius: CGFloat {
            switch self {
            case .featured:
                return 32
            case .card:
                return 18
            }
        }

        var imagePadding: CGFloat {
            switch self {
            case .featured:
                return 14
            case .card:
                return 12
            }
        }

        var fallbackSymbolSize: CGFloat {
            switch self {
            case .featured:
                return 38
            case .card:
                return 24
            }
        }
    }

    let planet: PlanetaryBody
    let style: Style

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .fill(planet.theme.softGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .fill(Color.white.opacity(0.04))
                )

            if let image = assetImage {
                image
                    .resizable()
                    .scaledToFit()
                    .padding(style.imagePadding)
                    .transition(.opacity)
            } else {
                PlanetOrb(theme: planet.theme, symbolSize: style.fallbackSymbolSize)
            }
        }
        .frame(width: style.size.width, height: style.size.height)
        .overlay(
            RoundedRectangle(cornerRadius: style.cornerRadius)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var assetImage: Image? {
        guard let uiImage = UIImage(named: planet.imageAssetName) else {
            return nil
        }
        return Image(uiImage: uiImage)
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
