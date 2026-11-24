import Foundation

/// Current conditions from Open-Meteo (free, no API key). All cities go in one request.
enum WeatherService {
    static func current(for cities: [City]) async throws -> [String: Weather] {
        guard !cities.isEmpty else { return [:] }
        let (data, response) = try await URLSession.shared.data(from: url(for: cities))
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try parse(data, for: cities, fetched: Date())
    }

    static func url(for cities: [City]) -> URL {
        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: cities.map { String(format: "%.4f", $0.latitude) }.joined(separator: ",")),
            URLQueryItem(name: "longitude", value: cities.map { String(format: "%.4f", $0.longitude) }.joined(separator: ",")),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,is_day"),
        ]
        return components.url!
    }

    /// Weather keyed by city id. One location comes back as an object, several as an array in request order.
    static func parse(_ data: Data, for cities: [City], fetched: Date) throws -> [String: Weather] {
        let decoder = JSONDecoder()
        let items = try (try? decoder.decode([Response].self, from: data)) ?? [decoder.decode(Response.self, from: data)]
        var result: [String: Weather] = [:]
        for (city, item) in zip(cities, items) {
            result[city.id] = Weather(temperature: item.current.temperature2m, code: item.current.weatherCode,
                                      isDay: item.current.isDay == 1, fetched: fetched)
        }
        return result
    }

    private struct Response: Decodable {
        struct Current: Decodable {
            let temperature2m: Double
            let weatherCode: Int
            let isDay: Int

            // Spelled out: automatic snake_case conversion can't produce "temperature2m" from "temperature_2m".
            enum CodingKeys: String, CodingKey {
                case temperature2m = "temperature_2m"
                case weatherCode = "weather_code"
                case isDay = "is_day"
            }
        }
        let current: Current
    }
}
