import Foundation
@testable import WorldClocks

func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

/// Mid-January and mid-July, so northern zones are on standard time in one and summer time in the other.
let winter = date("2026-01-15T12:00:00Z")
let summer = date("2026-07-15T12:00:00Z")

let english = Locale(identifier: "en_US")

extension City {
    static let sanFrancisco = City(name: "San Francisco", region: "California", country: "United States",
                                   timeZoneID: "America/Los_Angeles", latitude: 37.7749, longitude: -122.4194)
    static let newYork = City(name: "New York City", region: "New York", country: "United States",
                              timeZoneID: "America/New_York", latitude: 40.7143, longitude: -74.0060)
    static let london = City(name: "London", region: "England", country: "United Kingdom",
                             timeZoneID: "Europe/London", latitude: 51.5085, longitude: -0.1257)
    static let singapore = City(name: "Singapore", country: "Singapore",
                                timeZoneID: "Asia/Singapore", latitude: 1.2897, longitude: 103.8501)
    static let longyearbyen = City(name: "Longyearbyen", country: "Svalbard and Jan Mayen",
                                   timeZoneID: "Arctic/Longyearbyen", latitude: 78.2232, longitude: 15.6267)
}
