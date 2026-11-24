import Foundation
import Testing
@testable import BetterWorldClock

struct WeatherParsingTests {
    private let fetched = Date(timeIntervalSince1970: 0)

    @Test func severalCitiesComeBackAsAnArray() throws {
        let json = """
        [{"current": {"time": "2026-11-12T05:00", "temperature_2m": 9.4, "weather_code": 61, "is_day": 0}},
         {"current": {"time": "2026-11-12T13:00", "temperature_2m": 30.1, "weather_code": 2, "is_day": 1}}]
        """
        let weather = try WeatherService.parse(Data(json.utf8), for: [.london, .singapore], fetched: fetched)
        #expect(weather[City.london.id]?.temperature == 9.4)
        #expect(weather[City.london.id]?.code == 61)
        #expect(weather[City.london.id]?.isDay == false)
        #expect(weather[City.singapore.id]?.isDay == true)
    }

    @Test func oneCityComesBackAsAnObject() throws {
        let json = #"{"current": {"temperature_2m": -3.0, "weather_code": 71, "is_day": 1}}"#
        let weather = try WeatherService.parse(Data(json.utf8), for: [.newYork], fetched: fetched)
        #expect(weather[City.newYork.id]?.temperature == -3)
        #expect(weather[City.newYork.id]?.fetched == fetched)
    }

    @Test func requestListsEveryCity() {
        let query = WeatherService.url(for: [.london, .singapore]).query ?? ""
        #expect(query.contains("latitude=51.5085,1.2897"))
        #expect(query.contains("longitude=-0.1257,103.8501"))
    }
}

struct GeocoderParsingTests {
    @Test func keepsPopulatedPlacesOnly() throws {
        let json = """
        {"results": [
          {"name": "Taipei", "latitude": 25.05, "longitude": 121.53, "timezone": "Asia/Taipei",
           "country": "Taiwan", "admin1": "Taiwan", "feature_code": "PPLC"},
          {"name": "Taipei Songshan Airport", "latitude": 25.07, "longitude": 121.55, "timezone": "Asia/Taipei",
           "country": "Taiwan", "feature_code": "AIRP"},
          {"name": "Nowhere", "latitude": 0, "longitude": 0, "timezone": "Not/AZone", "feature_code": "PPL"}
        ]}
        """
        let cities = try Geocoder.parse(Data(json.utf8))
        #expect(cities.map(\.name) == ["Taipei"])
        #expect(cities.first?.timeZoneID == "Asia/Taipei")
        #expect(cities.first?.region == "Taiwan")
    }

    @Test func noResults() throws {
        let cities = try Geocoder.parse(Data("{}".utf8))
        #expect(cities.isEmpty)
    }
}
