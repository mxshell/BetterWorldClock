import Foundation

enum TimeFormat: String, CaseIterable, Identifiable {
    case h24, h12

    var id: String { rawValue }
    var label: String { self == .h24 ? "24-hour" : "12-hour" }
}

/// What each clock row shows, from the user's settings.
struct DisplayOptions {
    var unit: TemperatureUnit = .celsius
    var timeFormat: TimeFormat = .h24
    var showWeather = true
    var showSun = true
}
