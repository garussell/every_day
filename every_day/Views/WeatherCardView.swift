//
//  WeatherCardView.swift
//  every_day
//

import SwiftUI

struct WeatherCardView: View {
    let viewModel: DashboardViewModel
    let appeared: Bool

    var body: some View {
        OrbitCard(delay: 0.1, appeared: appeared) {
            VStack(alignment: .leading, spacing: 16) {
                cardHeader

                if viewModel.isLoadingWeather {
                    loadingView
                } else if let error = viewModel.weatherError {
                    errorView(message: error)
                } else if let weather = viewModel.currentWeather {
                    currentWeatherView(weather)
                    if !viewModel.weatherForecast.isEmpty {
                        Divider().background(Color.orbitGold.opacity(0.3))
                        forecastRow
                    }
                } else {
                    emptyView
                }
            }
        }
    }

    // MARK: - Subviews

    private var cardHeader: some View {
        HStack {
            Image(systemName: "sun.and.horizon.fill")
                .font(.title3)
                .foregroundStyle(Color.orbitGold)
                .accessibilityHidden(true)
            Text("Weather Forecast")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            if let locationError = viewModel.locationService.locationError {
                Image(systemName: "location.slash.fill")
                    .foregroundStyle(.orange)
                    .help(locationError)
                    .accessibilityLabel("Location unavailable: \(locationError)")
            }
        }
    }

    private func currentWeatherView(_ weather: CurrentWeather) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: weather.symbolName)
                .font(.system(size: 56))
                .symbolRenderingMode(.multicolor)
                .shadow(color: Color.orbitGold.opacity(0.4), radius: 12)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text("\(Int(weather.temperature))°F")
                    .font(.system(size: 44, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                Text(weather.condition)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                Spacer().frame(height: 4)
                HStack(spacing: 16) {
                    statBadge(icon: "humidity.fill",      value: "\(weather.humidity)%",         label: "Humidity")
                    statBadge(icon: "wind",               value: "\(Int(weather.windSpeed)) mph", label: "Wind")
                }
            }
            Spacer()
        }
    }

    private func statBadge(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(Color.orbitGold.opacity(0.8))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 0) {
                Text(value)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white)
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.5))
            }
        }
    }

    private var forecastRow: some View {
        HStack(spacing: 0) {
            ForEach(viewModel.weatherForecast) { day in
                VStack(spacing: 6) {
                    Text(day.dayLabel)
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(.white.opacity(0.6))
                    Image(systemName: day.symbolName)
                        .font(.system(size: 18))
                        .symbolRenderingMode(.multicolor)
                        .accessibilityHidden(true)
                    Text("\(Int(day.maxTemp))°")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(Int(day.minTemp))°")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("\(day.dayLabel): high \(Int(day.maxTemp)) degrees, low \(Int(day.minTemp)) degrees")
            }
        }
    }

    private var loadingView: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 20) {
                SkeletonBlock(width: 68, height: 68, cornerRadius: 20)

                VStack(alignment: .leading, spacing: 10) {
                    SkeletonLine(width: 110, height: 42)
                    SkeletonLine(width: 140, height: 14)
                    SkeletonLine(width: 84, height: 10)

                    HStack(spacing: 16) {
                        weatherStatSkeleton
                        weatherStatSkeleton
                    }
                }

                Spacer()
            }

            Divider().background(Color.orbitGold.opacity(0.18))

            HStack(spacing: 0) {
                ForEach(0..<5, id: \.self) { _ in
                    VStack(spacing: 8) {
                        SkeletonLine(width: 24, height: 10)
                        SkeletonBlock(width: 28, height: 28, cornerRadius: 14)
                        SkeletonLine(width: 26, height: 11)
                        SkeletonLine(width: 20, height: 9)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var weatherStatSkeleton: some View {
        HStack(spacing: 6) {
            SkeletonBlock(width: 12, height: 12, cornerRadius: 6)

            VStack(alignment: .leading, spacing: 4) {
                SkeletonLine(width: 54, height: 10)
                SkeletonLine(width: 38, height: 8)
            }
        }
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            Text(message)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
        }
        .padding(.vertical, 8)
    }

    private var emptyView: some View {
        Text("Fetching weather…")
            .font(.footnote)
            .foregroundStyle(.white.opacity(0.5))
            .padding(.vertical, 8)
    }
}
