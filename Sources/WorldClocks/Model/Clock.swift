import Foundation

/// A row on the widget: one of the user's cities, or the UTC reference clock.
enum Clock: Identifiable {
    case utc
    case city(City)

    var id: String { city?.id ?? "UTC" }

    var city: City? {
        if case .city(let city) = self { return city }
        return nil
    }

    var timeZone: TimeZone { city?.timeZone ?? TimeZone(identifier: "UTC")! }

    /// West to east by current UTC offset; ties keep their original order.
    static func sorted(_ clocks: [Clock], at date: Date) -> [Clock] {
        clocks.enumerated().sorted { a, b in
            let offsetA = a.element.timeZone.secondsFromGMT(for: date)
            let offsetB = b.element.timeZone.secondsFromGMT(for: date)
            return offsetA != offsetB ? offsetA < offsetB : a.offset < b.offset
        }.map(\.element)
    }

    /// The rows to show, west to east. UTC is added only when no city is currently on UTC+0.
    static func visible(_ cities: [City], at date: Date) -> [Clock] {
        let hasUTCCity = cities.contains { $0.timeZone.secondsFromGMT(for: date) == 0 }
        return sorted((hasUTCCity ? [] : [.utc]) + cities.map(Clock.city), at: date)
    }

    /// The next sunrise or sunset there. UTC follows Greenwich, where it started out as GMT.
    func nextSunEvent(after date: Date) -> SunEvent {
        Sun.next(after: date, latitude: city?.latitude ?? 51.4779, longitude: city?.longitude ?? 0)
    }
}
