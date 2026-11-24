import Foundation

struct City: Codable, Hashable, Identifiable {
    var name: String
    var region: String?
    var country: String
    var timeZoneID: String
    var latitude: Double
    var longitude: Double

    var id: String { "\(name)|\(String(format: "%.3f", latitude))|\(String(format: "%.3f", longitude))" }
    var timeZone: TimeZone { TimeZone(identifier: timeZoneID) ?? .autoupdatingCurrent }
    var isLocal: Bool { timeZoneID == TimeZone.autoupdatingCurrent.identifier }

    var subtitle: String {
        var parts: [String] = []
        for part in [region, country].compactMap({ $0 }) where !part.isEmpty && part != name && !parts.contains(part) {
            parts.append(part)
        }
        return parts.joined(separator: ", ")
    }

    /// "California, United States · PST · UTC−8"
    func detail(at date: Date) -> String {
        [subtitle, timeZone.shortName(for: date) ?? "", timeZone.utcOffsetText(for: date)]
            .filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Starting cities for new users.
    static let defaults: [City] = [
        City(name: "New York City", region: "New York", country: "United States",
             timeZoneID: "America/New_York", latitude: 40.7143, longitude: -74.0060),
        City(name: "San Francisco", region: "California", country: "United States",
             timeZoneID: "America/Los_Angeles", latitude: 37.7749, longitude: -122.4194),
        City(name: "Singapore", region: nil, country: "Singapore",
             timeZoneID: "Asia/Singapore", latitude: 1.2897, longitude: 103.8501),
        City(name: "London", region: "England", country: "United Kingdom",
             timeZoneID: "Europe/London", latitude: 51.5085, longitude: -0.1257),
    ]
}
