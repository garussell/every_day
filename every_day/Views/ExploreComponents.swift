//
//  ExploreComponents.swift
//  every_day
//

import SwiftUI

struct APODHeroView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var expandedAPOD: APODEntry?

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
        .sheet(item: $expandedAPOD) { apod in
            APODImageDetailView(apod: apod)
                .presentationDragIndicator(.visible)
                .presentationBackground(.black)
        }
    }

    @ViewBuilder
    private var heroMedia: some View {
        switch apod.mediaType {
        case .image:
            imageMedia
        case .video:
            videoMedia
        case .unknown:
            unknownMedia
        }
    }

    private var fallbackMedia: some View {
        heroMediaContainer(alignment: .bottomLeading, height: mediaHeight) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: apod.mediaType == .video ? "play.rectangle.fill" : "sparkles")
                    .font(.system(size: isPhonePortraitLayout ? 28 : 34))
                    .foregroundStyle(Color.orbitGold)
                    .accessibilityHidden(true)
                Text(fallbackTitle)
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
        height: CGFloat,
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
        .frame(height: height)
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
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        if isPhonePortraitLayout {
            return min(max(screenWidth * 0.92, 340), 380)
        }

        if horizontalSizeClass == .regular {
            return min(max(screenHeight * 0.34, 340), 460)
        }

        return min(max(screenHeight * 0.30, 260), 320)
    }

    private var titleFont: Font {
        isPhonePortraitLayout ? .title3.weight(.bold) : .title2.weight(.bold)
    }

    private var contentSpacing: CGFloat {
        isPhonePortraitLayout ? 12 : 14
    }

    private var fallbackTitle: String {
        switch apod.mediaType {
        case .video:
            return "Today's APOD is a video"
        case .image:
            return "Image couldn't load"
        case .unknown:
            return "Media unavailable"
        }
    }

    @ViewBuilder
    private var imageMedia: some View {
        if let heroURL = apod.heroURL {
            #if DEBUG
            let _ = debugLogSelectedURL(heroURL)
            #endif
            Button {
                expandedAPOD = apod
            } label: {
                AsyncImage(url: heroURL) { phase in
                    switch phase {
                    case let .success(image):
                        heroMediaContainer(height: mediaHeight) {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: mediaHeight)
                        }
                        .overlay(alignment: .topTrailing) {
                            Label("Expand", systemImage: "arrow.up.left.and.arrow.down.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(isPhonePortraitLayout ? 12 : 14)
                        }
                    case .failure:
                        #if DEBUG
                        let _ = debugLogFallback("AsyncImage failed for \(heroURL.absoluteString)")
                        #endif
                        fallbackMedia
                    case .empty:
                        heroMediaContainer(height: mediaHeight) {
                            ProgressView()
                                .tint(Color.orbitGold)
                        }
                    @unknown default:
                        #if DEBUG
                        let _ = debugLogFallback("Unknown AsyncImage phase for \(heroURL.absoluteString)")
                        #endif
                        fallbackMedia
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Expand Astronomy Picture of the Day image")
        } else {
            #if DEBUG
            let _ = debugLogFallback("No usable image URL for mediaType=image")
            #endif
            fallbackMedia
        }
    }

    @ViewBuilder
    private var videoMedia: some View {
        if let thumbnailURL = apod.thumbnailURL, let linkURL = apod.linkURL {
            #if DEBUG
            let _ = debugLogSelectedURL(thumbnailURL)
            #endif
            Link(destination: linkURL) {
                AsyncImage(url: thumbnailURL) { phase in
                    switch phase {
                    case let .success(image):
                        heroMediaContainer(height: mediaHeight) {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: mediaHeight)
                        }
                        .overlay {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: isPhonePortraitLayout ? 64 : 72))
                                .foregroundStyle(.white.opacity(0.92))
                                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 6)
                        }
                    case .failure:
                        fallbackMedia
                    case .empty:
                        heroMediaContainer(height: mediaHeight) {
                            ProgressView()
                                .tint(Color.orbitGold)
                        }
                    @unknown default:
                        fallbackMedia
                    }
                }
            }
            .accessibilityLabel("Open today's APOD video")
        } else {
            #if DEBUG
            let _ = debugLogFallback("Video APOD has no usable thumbnail")
            #endif
            fallbackMedia
        }
    }

    @ViewBuilder
    private var unknownMedia: some View {
        #if DEBUG
        let _ = debugLogFallback("Unknown media type with no dedicated renderer")
        #endif
        if let heroURL = apod.heroURL {
            AsyncImage(url: heroURL) { phase in
                switch phase {
                case let .success(image):
                    heroMediaContainer(height: mediaHeight) {
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: mediaHeight)
                    }
                default:
                    fallbackMedia
                }
            }
        } else {
            fallbackMedia
        }
    }

    private func debugLogSelectedURL(_ url: URL) {
        print("[APODHeroView] mediaType=\(apod.mediaType.rawValue) selectedURL=\(url.absoluteString)")
    }

    private func debugLogFallback(_ reason: String) {
        print("[APODHeroView] fallback reason=\(reason)")
    }
}

private struct APODImageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var zoomScale: CGFloat = 1
    @State private var committedZoomScale: CGFloat = 1

    let apod: APODEntry

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let imageURL = apod.displayImageURL {
                        ScrollView([.horizontal, .vertical], showsIndicators: false) {
                            AsyncImage(url: imageURL) { phase in
                                switch phase {
                                case let .success(image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(
                                            width: baseImageSize(for: proxy.size) * zoomScale,
                                            height: baseImageSize(for: proxy.size) * zoomScale
                                        )
                                        .frame(
                                            minWidth: proxy.size.width,
                                            minHeight: proxy.size.height - 40
                                        )
                                case .failure:
                                    detailFallback
                                case .empty:
                                    ProgressView()
                                        .tint(Color.orbitGold)
                                        .frame(
                                            maxWidth: .infinity,
                                            minHeight: proxy.size.height - 40
                                        )
                                @unknown default:
                                    detailFallback
                                }
                            }
                        }
                        .gesture(magnificationGesture)
                    } else {
                        detailFallback
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(apod.title)
                            .font(.headline)
                            .foregroundStyle(.white)
                            .lineLimit(1)
                        Text(apod.dateText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(Color.orbitGold)
                }
            }
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
    }

    private var magnificationGesture: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                zoomScale = min(max(committedZoomScale * value.magnification, 1), 4)
            }
            .onEnded { _ in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                    committedZoomScale = zoomScale
                }
            }
    }

    private var detailFallback: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 42))
                .foregroundStyle(Color.orbitGold.opacity(0.85))
                .accessibilityHidden(true)
            Text("APOD image unavailable")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func baseImageSize(for size: CGSize) -> CGFloat {
        min(size.width - 24, size.height - 80)
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
