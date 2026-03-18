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
    @State private var isHazardousExpanded = true
    @State private var isNonHazardousExpanded = false

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
                                    subtitle: "Upcoming close approaches at a glance."
                                )

                                if viewModel.isLoadingAsteroids && viewModel.asteroids.isEmpty {
                                    ProgressView("Loading asteroid feed")
                                        .tint(Color.orbitGold)
                                        .foregroundStyle(.white.opacity(0.72))
                                } else if !viewModel.asteroids.isEmpty {
                                    asteroidGroups
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
        .onChange(of: viewModel.asteroids) { _, asteroids in
            guard !asteroids.isEmpty else { return }

            if hazardousAsteroids.isEmpty {
                isHazardousExpanded = false
                isNonHazardousExpanded = true
            } else {
                isHazardousExpanded = true
                if nonHazardousAsteroids.isEmpty {
                    isNonHazardousExpanded = false
                }
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

    private var hazardousAsteroids: [AsteroidApproach] {
        viewModel.asteroids.filter(\.isPotentiallyHazardous)
    }

    private var nonHazardousAsteroids: [AsteroidApproach] {
        viewModel.asteroids.filter { !$0.isPotentiallyHazardous }
    }

    @ViewBuilder
    private var asteroidGroups: some View {
        VStack(spacing: 12) {
            if !hazardousAsteroids.isEmpty {
                asteroidGroup(
                    title: "Potentially Hazardous",
                    count: hazardousAsteroids.count,
                    tint: Color.red.opacity(0.9),
                    isExpanded: $isHazardousExpanded,
                    asteroids: hazardousAsteroids
                )
            }

            if !nonHazardousAsteroids.isEmpty {
                asteroidGroup(
                    title: "Not Currently Hazardous",
                    count: nonHazardousAsteroids.count,
                    tint: Color.orbitGold.opacity(0.9),
                    isExpanded: $isNonHazardousExpanded,
                    asteroids: nonHazardousAsteroids
                )
            }
        }
    }

    private func asteroidGroup(
        title: String,
        count: Int,
        tint: Color,
        isExpanded: Binding<Bool>,
        asteroids: [AsteroidApproach]
    ) -> some View {
        DisclosureGroup(isExpanded: isExpanded) {
            VStack(spacing: 12) {
                ForEach(asteroids) { asteroid in
                    AsteroidCardView(asteroid: asteroid)
                }
            }
            .padding(.top, 14)
        } label: {
            HStack(spacing: 10) {
                Circle()
                    .fill(tint)
                    .frame(width: 10, height: 10)
                    .accessibilityHidden(true)

                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Spacer(minLength: 12)

                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08), in: Capsule())
            }
            .contentShape(Rectangle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Color.orbitCard.opacity(0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .tint(.white.opacity(0.85))
    }
}

#Preview {
    ExploreView()
}
