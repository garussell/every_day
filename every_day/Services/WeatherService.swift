//
//  WeatherService.swift
//  every_day
//

import Foundation

struct WeatherService {
    private let baseURL = "https://api.open-meteo.com/v1/forecast"

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    func fetchWeather(latitude: Double, longitude: Double) async throws -> (current: CurrentWeather, forecast: [WeatherDay]) {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "latitude",         value: String(format: "%.4f", latitude)),
            URLQueryItem(name: "longitude",        value: String(format: "%.4f", longitude)),
            URLQueryItem(name: "current",          value: "temperature_2m,relative_humidity_2m,wind_speed_10m,weather_code,cloud_cover"),
            URLQueryItem(name: "daily",            value: "weather_code,temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "temperature_unit", value: "fahrenheit"),
            URLQueryItem(name: "wind_speed_unit",  value: "mph"),
            URLQueryItem(name: "timezone",         value: "auto"),
            URLQueryItem(name: "forecast_days",    value: "5"),
        ]

        guard let url = components.url else { throw URLError(.badURL) }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let decoded = try JSONDecoder().decode(WeatherAPIResponse.self, from: data)

        let current = CurrentWeather(
            temperature: decoded.current.temperature2m,
            humidity:    decoded.current.relativeHumidity2m,
            windSpeed:   decoded.current.windSpeed10m,
            weatherCode: decoded.current.weatherCode,
            cloudCover:  decoded.current.cloudCover
        )

        let forecast = zip(
            decoded.daily.time,
            zip(decoded.daily.weatherCode,
                zip(decoded.daily.temperature2mMax,
                    decoded.daily.temperature2mMin))
        ).compactMap { (timeStr, rest) -> WeatherDay? in
            let (code, (maxTemp, minTemp)) = rest
            guard let date = Self.dateFormatter.date(from: timeStr) else { return nil }
            return WeatherDay(date: date, weatherCode: code, maxTemp: maxTemp, minTemp: minTemp)
        }

        return (current: current, forecast: forecast)
    }
}
