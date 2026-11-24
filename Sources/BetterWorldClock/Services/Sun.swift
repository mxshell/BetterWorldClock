import Foundation

enum SunEvent: Equatable {
    case sunrise(Date)
    case sunset(Date)
    case polarDay
    case polarNight

    /// Whether the sun is down now, judging by what it does next.
    var isNight: Bool {
        switch self {
        case .sunrise, .polarNight: true
        case .sunset, .polarDay: false
        }
    }
}

/// Sunrise and sunset from the sunrise equation, computed locally (good to a minute or two; no network needed).
enum Sun {
    private enum Day {
        case times(rise: Date, set: Date)
        case alwaysUp
        case alwaysDown
    }

    static func next(after now: Date, latitude: Double, longitude: Double) -> SunEvent {
        let julianNow = now.timeIntervalSince1970 / 86400 + 2440587.5
        let today = (julianNow - 2451545.0 + 0.0008).rounded(.up)
        var next: SunEvent?
        var nextDate = Date.distantFuture
        var todayIsPolarDay = false
        for dayNumber in [today - 1, today, today + 1, today + 2] {
            switch day(dayNumber, latitude: latitude, longitude: longitude) {
            case .times(let rise, let set):
                if rise > now, rise < nextDate { next = .sunrise(rise); nextDate = rise }
                if set > now, set < nextDate { next = .sunset(set); nextDate = set }
            case .alwaysUp:
                if dayNumber == today { todayIsPolarDay = true }
            case .alwaysDown:
                break
            }
        }
        return next ?? (todayIsPolarDay ? .polarDay : .polarNight)
    }

    /// `dayNumber` counts days since J2000 (2000-01-01 12:00 UTC).
    private static func day(_ dayNumber: Double, latitude: Double, longitude: Double) -> Day {
        let rad = Double.pi / 180
        let meanSolarTime = dayNumber - longitude / 360
        let anomaly = (357.5291 + 0.98560028 * meanSolarTime).truncatingRemainder(dividingBy: 360)
        let center = 1.9148 * sin(anomaly * rad) + 0.0200 * sin(2 * anomaly * rad) + 0.0003 * sin(3 * anomaly * rad)
        let eclipticLongitude = (anomaly + center + 180 + 102.9372).truncatingRemainder(dividingBy: 360)
        let transit = 2451545.0 + meanSolarTime + 0.0053 * sin(anomaly * rad) - 0.0069 * sin(2 * eclipticLongitude * rad)
        let sinDeclination = sin(eclipticLongitude * rad) * sin(23.4397 * rad)
        let cosDeclination = cos(asin(sinDeclination))
        // -0.833° accounts for refraction and the sun's radius.
        let cosHourAngle = (sin(-0.833 * rad) - sin(latitude * rad) * sinDeclination) / (cos(latitude * rad) * cosDeclination)
        if cosHourAngle < -1 { return .alwaysUp }
        if cosHourAngle > 1 { return .alwaysDown }
        let halfDay = acos(cosHourAngle) / rad / 360
        func date(_ julian: Double) -> Date { Date(timeIntervalSince1970: (julian - 2440587.5) * 86400) }
        return .times(rise: date(transit - halfDay), set: date(transit + halfDay))
    }
}
