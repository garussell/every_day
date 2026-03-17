//
//  WeatherModels.swift
//  every_day
//

import Foundation

// MARK: - API Response Models

struct WeatherAPIResponse: Codable {
    let current: CurrentWeatherData
    let daily: DailyWeatherData
}

struct CurrentWeatherData: Codable {
    let time: String
    let temperature2m: Double
    let relativeHumidity2m: Int
    let windSpeed10m: Double
    let weatherCode: Int
    let cloudCover: Int?

    enum CodingKeys: String, CodingKey {
        case time
        case temperature2m = "temperature_2m"
        case relativeHumidity2m = "relative_humidity_2m"
        case windSpeed10m = "wind_speed_10m"
        case weatherCode = "weather_code"
        case cloudCover = "cloud_cover"
    }
}

struct DailyWeatherData: Codable {
    let time: [String]
    let weatherCode: [Int]
    let temperature2mMax: [Double]
    let temperature2mMin: [Double]

    enum CodingKeys: String, CodingKey {
        case time
        case weatherCode = "weather_code"
        case temperature2mMax = "temperature_2m_max"
        case temperature2mMin = "temperature_2m_min"
    }
}

// MARK: - View-friendly Models

struct CurrentWeather {
    let temperature: Double
    let humidity: Int
    let windSpeed: Double
    let weatherCode: Int
    let cloudCover: Int?

    var condition: String { WeatherHelper.condition(for: weatherCode) }
    var symbolName: String { WeatherHelper.symbol(for: weatherCode) }
}

struct WeatherDay: Identifiable {
    let id = UUID()
    let date: Date
    let weatherCode: Int
    let maxTemp: Double
    let minTemp: Double

    var dayLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    var symbolName: String { WeatherHelper.symbol(for: weatherCode) }
    var condition: String { WeatherHelper.condition(for: weatherCode) }
}

// MARK: - Weather Code Helpers

enum WeatherHelper {
    static func condition(for code: Int) -> String {
        switch code {
        case 0:           return "Clear Sky"
        case 1:           return "Mostly Clear"
        case 2:           return "Partly Cloudy"
        case 3:           return "Overcast"
        case 45, 48:      return "Foggy"
        case 51, 53, 55:  return "Drizzle"
        case 56, 57:      return "Freezing Drizzle"
        case 61, 63, 65:  return "Rain"
        case 66, 67:      return "Freezing Rain"
        case 71, 73, 75:  return "Snow"
        case 77:          return "Snow Grains"
        case 80, 81, 82:  return "Rain Showers"
        case 85, 86:      return "Snow Showers"
        case 95:          return "Thunderstorm"
        case 96, 99:      return "Thunderstorm & Hail"
        default:          return "Unknown"
        }
    }

    static func symbol(for code: Int) -> String {
        switch code {
        case 0:           return "sun.max.fill"
        case 1:           return "sun.min.fill"
        case 2:           return "cloud.sun.fill"
        case 3:           return "cloud.fill"
        case 45, 48:      return "cloud.fog.fill"
        case 51, 53, 55:  return "cloud.drizzle.fill"
        case 56, 57:      return "cloud.sleet.fill"
        case 61, 63, 65:  return "cloud.rain.fill"
        case 66, 67:      return "cloud.sleet.fill"
        case 71, 73, 75:  return "cloud.snow.fill"
        case 77:          return "cloud.snow.fill"
        case 80, 81, 82:  return "cloud.heavyrain.fill"
        case 85, 86:      return "cloud.snow.fill"
        case 95:          return "cloud.bolt.fill"
        case 96, 99:      return "cloud.bolt.rain.fill"
        default:          return "questionmark.circle.fill"
        }
    }
}
