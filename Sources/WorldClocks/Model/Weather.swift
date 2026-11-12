import Foundation

struct Weather: Codable {
    var temperature: Double  // always stored in °C
    var code: Int            // WMO weather code
    var isDay: Bool
    var fetched: Date

    var isStale: Bool { Date().timeIntervalSince(fetched) > 2 * 3600 }

    var symbolName: String {
        switch code {
        case 0: return isDay ? "sun.max.fill" : "moon.stars.fill"
        case 1, 2: return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case 3: return "cloud.fill"
        case 45, 48: return "cloud.fog.fill"
        case 51...57: return "cloud.drizzle.fill"
        case 61, 63, 66, 80, 81: return "cloud.rain.fill"
        case 65, 67, 82: return "cloud.heavyrain.fill"
        case 71...77, 85, 86: return "cloud.snow.fill"
        case 95...99: return "cloud.bolt.rain.fill"
        default: return "thermometer.medium"
        }
    }
}

enum TemperatureUnit: String, CaseIterable, Identifiable {
    case celsius, fahrenheit

    var id: String { rawValue }
    var label: String { self == .celsius ? "°C" : "°F" }

    func format(_ celsius: Double) -> String {
        let value = self == .celsius ? celsius : celsius * 9 / 5 + 32
        return "\(Int(value.rounded()))\(label)"
    }
}
