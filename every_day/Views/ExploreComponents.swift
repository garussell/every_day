//
//  ExploreComponents.swift
//  every_day
//

import SwiftUI

struct APODHeroView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let apod: APODEntry

    var body: some View {
        VStack(alignment: .leading, spacing: contentSpacing) {
            heroMedia

            VStack(alignment: .leading, spacing: 10) {
                Text(apod.dateText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.orbitGold.opacity(0.92))
                    .textCase(.uppercase)

                Text(apod.title)
                    .font(titleFont)
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                if let creditText = apod.creditText {
                    Text("Credit: \(creditText)")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.52))
                }

                Text(apod.explanation)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.72))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)

                if apod.mediaType == .video, let linkURL = apod.linkURL {
                    Link(destination: linkURL) {
                        Label("Open video", systemImage: "play.rectangle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(Color.orbitGold)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var heroMedia: some View {
        if let heroURL = apod.heroURL {
            AsyncImage(url: heroURL) { phase in
                switch phase {
                case let .success(image):
                    heroMediaContainer {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: mediaHeight)
                    }
                case .failure:
                    fallbackMedia
                case .empty:
                    heroMediaContainer {
                        ProgressView()
                            .tint(Color.orbitGold)
                    }
                @unknown default:
                    fallbackMedia
                }
            }
        } else {
            fallbackMedia
        }
    }

    private var fallbackMedia: some View {
        heroMediaContainer(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: apod.mediaType == .video ? "play.rectangle.fill" : "sparkles")
                    .font(.system(size: isPhonePortraitLayout ? 28 : 34))
                    .foregroundStyle(Color.orbitGold)
                Text(apod.mediaType == .video ? "Video experience" : "Image unavailable")
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
            }
            .padding(isPhonePortraitLayout ? 18 : 22)
        }
    }

    private var mediaBadge: some View {
        Text(apod.mediaType == .video ? "NASA APOD Video" : "NASA APOD")
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
    }

    private func heroMediaContainer<Content: View>(
        alignment: Alignment = .center,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            RoundedRectangle(cornerRadius: 26)
                .fill(
                    LinearGradient(
                        colors: [Color.orbitCard, Color.orbitBackground],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            content()
                .padding(isPhonePortraitLayout ? 12 : 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: mediaHeight)
        .clipShape(RoundedRectangle(cornerRadius: 26))
        .overlay(alignment: .bottomLeading) {
            mediaBadge
                .padding(isPhonePortraitLayout ? 12 : 16)
        }
    }

    private var isPhonePortraitLayout: Bool {
        horizontalSizeClass == .compact && verticalSizeClass != .compact
    }

    private var mediaHeight: CGFloat {
        isPhonePortraitLayout ? 210 : 280
    }

    private var titleFont: Font {
        isPhonePortraitLayout ? .title3.weight(.bold) : .title2.weight(.bold)
    }

    private var contentSpacing: CGFloat {
        isPhonePortraitLayout ? 12 : 14
    }
}

struct AsteroidCardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let asteroid: AsteroidApproach

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    asteroidHeaderText
                    Spacer(minLength: 12)
                    hazardBadge
                }

                VStack(alignment: .leading, spacing: 10) {
                    asteroidHeaderText
                    hazardBadge
                }
            }

            LazyVGrid(
                columns: infoColumns,
                alignment: .leading,
                spacing: 12
            ) {
                PlanetFactPill(title: "Estimated Size", value: asteroid.sizeText)
                PlanetFactPill(title: "Miss Distance", value: asteroid.missDistanceText)
                PlanetFactPill(title: "Relative Velocity", value: asteroid.velocityText)
                PlanetFactPill(title: "Approach", value: asteroid.approachDateText)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.orbitCard.opacity(0.94))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private var asteroidHeaderText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(asteroid.name)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(asteroid.approachDateText)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.58))
        }
    }

    private var hazardBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(asteroid.isPotentiallyHazardous ? Color.red.opacity(0.85) : Color.green.opacity(0.75))
                .frame(width: 8, height: 8)

            Text(asteroid.hazardText)
                .font(.caption.weight(.semibold))
                .foregroundStyle(asteroid.isPotentiallyHazardous ? Color.red.opacity(0.92) : Color.green.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var infoColumns: [GridItem] {
        if isPhonePortraitLayout {
            return [GridItem(.flexible())]
        }
        return [GridItem(.flexible()), GridItem(.flexible())]
    }

    private var isPhonePortraitLayout: Bool {
        horizontalSizeClass == .compact && verticalSizeClass != .compact
    }
}

#Preview("APOD Hero") {
    let sample = APODEntry(
        id: "2026-03-17",
        title: "Aurora Over Quiet Water",
        dateString: "2026-03-17",
        explanation: "A gentle curtain of light drifted over the horizon in tonight's celestial portrait.",
        mediaType: .image,
        url: URL(string: "https://example.com/apod.jpg"),
        hdURL: nil,
        thumbnailURL: nil,
        copyright: "NASA"
    )

    return ZStack {
        CelestialBackground()
        APODHeroView(apod: sample)
            .padding()
    }
}
