//
//  EarthTodayCardView.swift
//  every_day
//

import SwiftUI

struct EarthTodayCardView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

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
    }

    private var cardHeader: some View {
        HStack {
            Image(systemName: "globe.americas.fill")
                .font(.title3)
                .foregroundStyle(Color.orbitGold)
            Text("Earth Today")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
        }
    }

    private func earthContentView(_ image: EpicImage) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            if let imageURL = image.imageURL {
                AsyncImage(url: imageURL) { phase in
                    switch phase {
                    case let .success(loadedImage):
                        loadedImage
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: imageHeight)
                    case .failure:
                        imageFallback
                    case .empty:
                        imageLoadingState
                    @unknown default:
                        imageFallback
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: imageHeight)
                .background(imageBackground)
                .clipShape(RoundedRectangle(cornerRadius: 20))
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
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Color.orbitGold)
                .scaleEffect(1.1)
            Spacer()
        }
        .padding(.vertical, 18)
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

    private var imageHeight: CGFloat {
        isPhonePortrait ? 190 : 240
    }

    private var isPhonePortrait: Bool {
        horizontalSizeClass == .compact && verticalSizeClass != .compact
    }
}
