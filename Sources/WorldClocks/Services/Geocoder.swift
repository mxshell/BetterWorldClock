import Foundation

/// City search via Open-Meteo's geocoding API, which also returns each place's time zone.
enum Geocoder {
    static func search(_ query: String) async throws -> [City] {
        var components = URLComponents(string: "https://geocoding-api.open-meteo.com/v1/search")!
        components.queryItems = [
            URLQueryItem(name: "name", value: query),
            URLQueryItem(name: "count", value: "8"),
            URLQueryItem(name: "language", value: "en"),
            URLQueryItem(name: "format", value: "json"),
        ]
        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try parse(data)
    }

    /// Populated places (feature codes PPL…) with a known time zone; airports, parks and the like are dropped.
    static func parse(_ data: Data) throws -> [City] {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return (try decoder.decode(Response.self, from: data).results ?? []).compactMap { place in
            guard let zone = place.timezone, TimeZone(identifier: zone) != nil,
                  place.featureCode?.hasPrefix("PPL") ?? true else { return nil }
            return City(name: place.name, region: place.admin1, country: place.country ?? "", timeZoneID: zone,
                        latitude: place.latitude, longitude: place.longitude)
        }
    }

    private struct Response: Decodable {
        struct Place: Decodable {
            let name: String
            let latitude: Double
            let longitude: Double
            let timezone: String?
            let country: String?
            let admin1: String?
            let featureCode: String?
        }
        let results: [Place]?
    }
}
