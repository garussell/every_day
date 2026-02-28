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
            Text("Weather Forecast")
                .font(.headline)
                .foregroundStyle(.white)
            Spacer()
            if let locationError = viewModel.locationService.locationError {
                Image(systemName: "location.slash.fill")
                    .foregroundStyle(.orange)
                    .help(locationError)
            }
        }
    }

    private func currentWeatherView(_ weather: CurrentWeather) -> some View {
        HStack(alignment: .top, spacing: 20) {
            Image(systemName: weather.symbolName)
                .font(.system(size: 56))
                .symbolRenderingMode(.multicolor)
                .shadow(color: Color.orbitGold.opacity(0.4), radius: 12)

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
                    Text("\(Int(day.maxTemp))°")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("\(Int(day.minTemp))°")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var loadingView: some View {
        HStack {
            Spacer()
            ProgressView()
                .tint(Color.orbitGold)
                .scaleEffect(1.2)
            Spacer()
        }
        .padding(.vertical, 20)
    }

    private func errorView(message: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
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
