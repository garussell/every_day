//
//  ExploreView.swift
//  every_day
//

import SwiftUI

struct ExploreView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    @State private var viewModel = ExploreViewModel()
    @State private var appeared = false

    var body: some View {
        NavigationStack {
            ZStack {
                CelestialBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: contentSpacing) {
                        header

                        OrbitCard(delay: 0.04, appeared: appeared) {
                            VStack(alignment: .leading, spacing: 16) {
                                SpaceSectionHeader(
                                    title: "Astronomy Picture of the Day",
                                    subtitle: "NASA's daily window into the wider universe."
                                )

                                if viewModel.isLoadingAPOD && viewModel.apod == nil {
                                    ProgressView("Loading today's APOD")
                                        .tint(Color.orbitGold)
                                        .foregroundStyle(.white.opacity(0.72))
                                } else if let apod = viewModel.apod {
                                    APODHeroView(apod: apod)
                                } else if let apodError = viewModel.apodError {
                                    Text(apodError)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                } else {
                                    Text("Today's APOD will appear here soon.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                        }

                        if let apodError = viewModel.apodError, viewModel.apod == nil {
                            SpaceStatusCard(
                                icon: "photo.on.rectangle.angled",
                                message: apodError,
                                appeared: appeared,
                                delay: 0.08
                            )
                        }

                        OrbitCard(delay: 0.14, appeared: appeared) {
                            VStack(alignment: .leading, spacing: 16) {
                                SpaceSectionHeader(
                                    title: "Near-Earth Objects",
                                    subtitle: "Upcoming close approaches, formatted for a quick human scan."
                                )

                                if viewModel.isLoadingAsteroids && viewModel.asteroids.isEmpty {
                                    ProgressView("Loading asteroid feed")
                                        .tint(Color.orbitGold)
                                        .foregroundStyle(.white.opacity(0.72))
                                } else if !viewModel.asteroids.isEmpty {
                                    VStack(spacing: 14) {
                                        ForEach(viewModel.asteroids) { asteroid in
                                            AsteroidCardView(asteroid: asteroid)
                                        }
                                    }
                                } else if let asteroidError = viewModel.asteroidError {
                                    Text(asteroidError)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                } else {
                                    Text("Asteroid data will appear here soon.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                            }
                        }

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await viewModel.loadIfNeeded()
            withAnimation(.spring(dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Explore")
                .font(headerFont)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orbitGold, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("Images, close approaches, and a little room for wonder.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.top, 10)
    }

    private var isPhonePortraitLayout: Bool {
        horizontalSizeClass == .compact && verticalSizeClass != .compact
    }

    private var headerFont: Font {
        isPhonePortraitLayout ? .title.weight(.bold) : .largeTitle.weight(.bold)
    }

    private var contentSpacing: CGFloat {
        isPhonePortraitLayout ? 18 : 22
    }
}

#Preview {
    ExploreView()
}
