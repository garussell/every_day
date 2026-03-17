//
//  CosmosView.swift
//  every_day
//

import SwiftUI

struct CosmosView: View {
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

                        FeaturedPlanetView(planet: viewModel.featuredPlanet, appeared: appeared)

                        OrbitCard(delay: 0.12, appeared: appeared) {
                            VStack(alignment: .leading, spacing: 16) {
                                SpaceSectionHeader(
                                    title: "Planets",
                                    subtitle: "A calm sweep across the solar system, with mock details ready when live data is quiet."
                                )

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
                                            PlanetCardView(planet: planet)
                                        }
                                    }
                                    .padding(.vertical, 2)
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
            withAnimation(.spring(dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private var planetError: String? {
        guard let planetError = viewModel.planetError else { return nil }
        return viewModel.hasPlanetFallback ? "\(planetError) Mock planet cards are still available." : planetError
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

            if viewModel.hasPlanetFallback {
                Label("Mock details remain available as a graceful fallback.", systemImage: "sparkles")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.58))
            }
        }
        .padding(.top, 10)
    }

    private func previewRow(for asteroid: AsteroidApproach) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(asteroid.isPotentiallyHazardous ? Color.red.opacity(0.8) : Color.orbitGold.opacity(0.85))
                .frame(width: 10, height: 10)
                .padding(.top, 5)

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
