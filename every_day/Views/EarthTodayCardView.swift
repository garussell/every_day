//
//  EarthTodayCardView.swift
//  every_day
//

import SwiftUI
import Combine
import UIKit

struct EarthTodayCardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var expandedImage: EpicImage?

    let viewModel: DashboardViewModel
    let appeared: Bool

    var body: some View {
        OrbitCard(delay: 0.17, appeared: appeared) {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader

                if viewModel.isLoadingEarthToday {
                    loadingView
                } else if let error = viewModel.earthTodayError {
                    errorView(message: error)
                } else if let image = viewModel.earthTodayImage {
                    earthContentView(image)
                }
            }
        }
        .sheet(item: $expandedImage) { image in
            EarthImageDetailView(image: image)
                .presentationDragIndicator(.visible)
                .presentationBackground(.black)
        }
    }

    private var cardHeader: some View {
        HStack {
            Image(systemName: "globe.americas.fill")
                .font(.title3)
                .foregroundStyle(Color.orbitGold)
                .accessibilityHidden(true)
            Text("Earth Today")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private func earthContentView(_ image: EpicImage) -> some View {
        GeometryReader { proxy in
            let imageHeight = inlineImageHeight(for: proxy.size.width)

            VStack(alignment: .leading, spacing: 14) {
                if let imageURL = image.imageURL {
                    Button {
                        expandedImage = image
                    } label: {
                        EarthTodayRemoteImageView(url: imageURL) { loadedImage in
                            loadedImage
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity, maxHeight: imageHeight)
                        } placeholder: {
                            imageLoadingState
                        } failure: {
                            imageFallback
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: imageHeight)
                        .background(imageBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 22))
                        .overlay(alignment: .topTrailing) {
                            Label("Expand", systemImage: "arrow.up.left.and.arrow.down.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(14)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Expand Earth image")
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(image.formattedDate)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Color.orbitGold.opacity(0.88))
                        .textCase(.uppercase)

                    if let caption = image.shortCaption {
                        Text(caption)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                            .lineLimit(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: cardContentHeight)
    }

    private var loadingView: some View {
        GeometryReader { proxy in
            let imageHeight = inlineImageHeight(for: proxy.size.width)

            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .topTrailing) {
                    SkeletonBlock(height: imageHeight, cornerRadius: 22)

                    SkeletonLine(width: 78, height: 28)
                        .padding(14)
                }

                VStack(alignment: .leading, spacing: 8) {
                    SkeletonLine(width: 132, height: 11)
                    SkeletonLine(width: nil, height: 14)
                    SkeletonLine(width: nil, height: 14)
                    SkeletonLine(width: 188, height: 14)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(height: cardContentHeight)
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "globe.badge.chevron.backward")
                .foregroundStyle(Color.orbitGold.opacity(0.8))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.68))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 6)
    }

    private var imageLoadingState: some View {
        ZStack {
            imageBackground
            ProgressView()
                .tint(Color.orbitGold)
        }
    }

    private var imageFallback: some View {
        ZStack {
            imageBackground

            VStack(spacing: 8) {
                Image(systemName: "globe.americas")
                    .font(.system(size: 30))
                    .foregroundStyle(Color.orbitGold.opacity(0.8))
                    .accessibilityHidden(true)
                Text("Earth image unavailable")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
    }

    private var imageBackground: some View {
        LinearGradient(
            colors: [Color.orbitCard.opacity(0.95), Color.orbitBackground],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var cardContentHeight: CGFloat {
        if isPhonePortrait {
            return 410
        }
        return horizontalSizeClass == .regular ? 470 : 360
    }

    private func inlineImageHeight(for availableWidth: CGFloat) -> CGFloat {
        if isPhonePortrait {
            return min(max(availableWidth * 1.08, 305), 340)
        }
        if horizontalSizeClass == .regular {
            return min(availableWidth * 0.82, 440)
        }
        return min(max(availableWidth * 0.78, 260), 320)
    }

    private var isPhonePortrait: Bool {
        horizontalSizeClass == .compact && verticalSizeClass != .compact
    }
}

private struct EarthImageDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var zoomScale: CGFloat = 1
    @State private var committedZoomScale: CGFloat = 1

    let image: EpicImage

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ZStack {
                    Color.black.ignoresSafeArea()

                    if let imageURL = image.imageURL {
                        ScrollView([.horizontal, .vertical], showsIndicators: false) {
                            EarthTodayRemoteImageView(url: imageURL) { loadedImage in
                                loadedImage
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
                            } placeholder: {
                                ProgressView()
                                    .tint(Color.orbitGold)
                                    .frame(
                                        maxWidth: .infinity,
                                        minHeight: proxy.size.height - 40
                                    )
                            } failure: {
                                detailFallback
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
                        Text("Earth Today")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Text(image.formattedDate)
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
            Image(systemName: "globe.americas")
                .font(.system(size: 42))
                .foregroundStyle(Color.orbitGold.opacity(0.85))
                .accessibilityHidden(true)
            Text("Earth image unavailable")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.82))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func baseImageSize(for size: CGSize) -> CGFloat {
        min(size.width - 24, size.height - 80)
    }
}

@MainActor
private final class EarthTodayImageLoader: ObservableObject {
    @Published private(set) var image: UIImage?
    @Published private(set) var didFail = false

    private var currentURL: URL?

    func displayedImage(for url: URL) -> UIImage? {
        if currentURL == url, let image {
            return image
        }
        return EarthTodayImageMemoryCache.image(for: url)
    }

    func load(url: URL) async {
        if currentURL != url {
            currentURL = url
            didFail = false
            if let cachedImage = EarthTodayImageMemoryCache.image(for: url) {
                EarthTodayImageLogger.log("image memory cache hit")
                image = cachedImage
            } else {
                EarthTodayImageLogger.log("image memory cache miss")
                image = nil
            }
        }

        guard image == nil else { return }

        do {
            let imageData = try await EarthTodayImagePipeline.shared.loadImageData(for: url)
            guard currentURL == url, let loadedImage = UIImage(data: imageData) else {
                didFail = true
                return
            }
            EarthTodayImageMemoryCache.insert(loadedImage, for: url)
            image = loadedImage
            didFail = false
        } catch {
            guard currentURL == url else { return }
            didFail = true
        }
    }
}

private struct EarthTodayRemoteImageView<Content: View, Placeholder: View, Failure: View>: View {
    let url: URL
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    let failure: () -> Failure

    @StateObject private var loader = EarthTodayImageLoader()

    init(
        url: URL,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder,
        @ViewBuilder failure: @escaping () -> Failure
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
        self.failure = failure
    }

    var body: some View {
        Group {
            if let uiImage = loader.displayedImage(for: url) {
                content(Image(uiImage: uiImage))
            } else if loader.didFail {
                failure()
            } else {
                placeholder()
            }
        }
        .task(id: url) {
            await loader.load(url: url)
        }
    }
}
