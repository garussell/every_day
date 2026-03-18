//
//  CosmosView.swift
//  every_day
//

import SwiftUI

struct CosmosView: View {
    @AppStorage("cosmos.selectedPlanetTheme") private var selectedPlanetThemeRaw = PlanetTheme.earth.rawValue
    @State private var viewModel = CosmosViewModel()
    @State private var skyTonightViewModel = SkyTonightViewModel()
    @State private var appeared = false

    let openExplore: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                CelestialBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        header

                        if let planetError {
                            SpaceStatusCard(
                                icon: "sparkles",
                                message: planetError,
                                appeared: appeared,
                                delay: 0.02
                            )
                        }

                        if shouldShowPlanetSkeleton {
                            FeaturedPlanetSkeletonView(appeared: appeared)
                        } else {
                            FeaturedPlanetView(planet: featuredPlanet, appeared: appeared)
                                .id(featuredPlanet.id)
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }

                        OrbitCard(delay: 0.12, appeared: appeared) {
                            VStack(alignment: .leading, spacing: 16) {
                                SpaceSectionHeader(
                                    title: "Planets",
                                    subtitle: "Tap a world below to bring it into focus."
                                )

                                if shouldShowPlanetSkeleton {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(0..<3, id: \.self) { _ in
                                                PlanetCardSkeletonView()
                                            }
                                        }
                                    }
                                    .padding(.vertical, 2)
                                } else {
                                    if viewModel.isLoadingPlanets {
                                        HStack(spacing: 10) {
                                            ProgressView()
                                                .tint(Color.orbitGold)
                                            Text("Refreshing live planet data")
                                                .font(.subheadline)
                                                .foregroundStyle(.white.opacity(0.7))
                                        }
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 16) {
                                            ForEach(viewModel.planets) { planet in
                                                Button {
                                                    selectPlanet(planet)
                                                } label: {
                                                    PlanetCardView(
                                                        planet: planet,
                                                        isSelected: planet.theme == featuredPlanet.theme
                                                    )
                                                }
                                                .buttonStyle(.plain)
                                                .hoverEffect(.lift)
                                                .accessibilityLabel("Feature \(planet.displayName)")
                                            }
                                        }
                                        .padding(.vertical, 2)
                                    }
                                }
                            }
                        }

                        OrbitCard(delay: 0.18, appeared: appeared) {
                            VStack(alignment: .leading, spacing: 16) {
                                SpaceSectionHeader(
                                    title: "Near-Earth Objects Preview",
                                    subtitle: "A quick look at upcoming close approaches, with the full feed in Explore."
                                )

                                if viewModel.isLoadingAsteroids {
                                    ProgressView("Gathering asteroid data")
                                        .tint(Color.orbitGold)
                                        .foregroundStyle(.white.opacity(0.7))
                                } else if !viewModel.asteroidPreview.isEmpty {
                                    VStack(spacing: 12) {
                                        ForEach(viewModel.asteroidPreview) { asteroid in
                                            previewRow(for: asteroid)
                                        }
                                    }
                                } else {
                                    Text(viewModel.asteroidError ?? "Asteroid preview will appear here soon.")
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.65))
                                }

                                Button {
                                    openExplore()
                                } label: {
                                    Label("See the full asteroid feed", systemImage: "arrow.right.circle.fill")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.orbitGold)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        SkyTonightView(viewModel: skyTonightViewModel, appeared: appeared)

                        Spacer(minLength: 28)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                }
                .refreshable {
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask { await viewModel.refresh() }
                        group.addTask { await skyTonightViewModel.refresh() }
                    }
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await viewModel.loadIfNeeded() }
                group.addTask { await skyTonightViewModel.loadIfNeeded() }
            }
            syncSelectedPlanetIfNeeded(with: availablePlanets)
            withAnimation(.spring(dampingFraction: 0.8)) {
                appeared = true
            }
        }
        .onChange(of: viewModel.planets) { _, planets in
            syncSelectedPlanetIfNeeded(with: planets)
        }
    }

    private var planetError: String? {
        viewModel.planetError
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cosmos")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orbitGold, .white],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

            Text("A slower orbit through planets, close approaches, and the quiet architecture of the night sky.")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.65))
        }
        .padding(.top, 10)
    }

    private var shouldShowPlanetSkeleton: Bool {
        viewModel.isLoadingPlanets && !viewModel.hasLoaded
    }

    private var availablePlanets: [PlanetaryBody] {
        viewModel.planets.isEmpty ? PlanetaryBody.mockPlanets : viewModel.planets
    }

    private var selectedPlanetTheme: PlanetTheme? {
        PlanetTheme(rawValue: selectedPlanetThemeRaw)
    }

    private var featuredPlanet: PlanetaryBody {
        if let selectedPlanetTheme,
           let selectedPlanet = availablePlanets.first(where: { $0.theme == selectedPlanetTheme }) {
            return selectedPlanet
        }

        if let earth = availablePlanets.first(where: { $0.theme == .earth }) {
            return earth
        }

        return availablePlanets.first ?? PlanetaryBody.mockPlanets[0]
    }

    private func selectPlanet(_ planet: PlanetaryBody) {
        withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
            selectedPlanetThemeRaw = planet.theme.rawValue
        }
    }

    private func syncSelectedPlanetIfNeeded(with planets: [PlanetaryBody]) {
        guard !planets.isEmpty else { return }

        if let selectedPlanetTheme,
           planets.contains(where: { $0.theme == selectedPlanetTheme }) {
            return
        }

        selectedPlanetThemeRaw = planets.first(where: { $0.theme == .earth })?.theme.rawValue
            ?? planets[0].theme.rawValue
    }

    private func previewRow(for asteroid: AsteroidApproach) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(asteroid.isPotentiallyHazardous ? Color.red.opacity(0.8) : Color.orbitGold.opacity(0.85))
                .frame(width: 10, height: 10)
                .padding(.top, 5)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(asteroid.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)

                Text("\(asteroid.approachDateText) • \(asteroid.sizeText)")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }

            Spacer()

            Text(asteroid.velocityText)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.72))
        }
        .padding(.vertical, 2)
    }

}

#Preview {
    CosmosView(openExplore: {})
}
