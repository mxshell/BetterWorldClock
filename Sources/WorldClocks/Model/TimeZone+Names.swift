import Foundation

extension TimeZone {
    /// Common abbreviations as (standard, daylight). Foundation only knows a handful and otherwise says "GMT+8".
    private static let abbreviations: [String: (String, String)] = {
        var table: [String: (String, String)] = [:]
        func add(_ standard: String, _ daylight: String, _ ids: String...) {
            for id in ids { table[id] = (standard, daylight) }
        }
        add("HST", "HDT", "Pacific/Honolulu")
        add("AKST", "AKDT", "America/Anchorage")
        add("PST", "PDT", "America/Los_Angeles", "America/Vancouver", "America/Tijuana")
        add("MST", "MDT", "America/Denver", "America/Edmonton", "America/Boise", "America/Phoenix")
        add("CST", "CDT", "America/Chicago", "America/Winnipeg", "America/Mexico_City")
        add("EST", "EDT", "America/New_York", "America/Toronto", "America/Detroit", "America/Montreal")
        add("AST", "ADT", "America/Halifax")
        add("NST", "NDT", "America/St_Johns")
        add("COT", "COST", "America/Bogota")
        add("PET", "PEST", "America/Lima")
        add("CLT", "CLST", "America/Santiago")
        add("ART", "ARST", "America/Argentina/Buenos_Aires", "America/Buenos_Aires")
        add("BRT", "BRST", "America/Sao_Paulo")
        add("GMT", "BST", "Europe/London")
        add("GMT", "IST", "Europe/Dublin")
        add("WET", "WEST", "Europe/Lisbon")
        add("CET", "CEST", "Europe/Paris", "Europe/Berlin", "Europe/Madrid", "Europe/Rome", "Europe/Amsterdam",
            "Europe/Brussels", "Europe/Vienna", "Europe/Zurich", "Europe/Stockholm", "Europe/Oslo",
            "Europe/Copenhagen", "Europe/Warsaw", "Europe/Prague", "Europe/Budapest", "Europe/Luxembourg",
            "Europe/Monaco", "Europe/Belgrade", "Europe/Zagreb", "Arctic/Longyearbyen")
        add("EET", "EEST", "Europe/Athens", "Europe/Helsinki", "Europe/Kyiv", "Europe/Kiev", "Europe/Bucharest",
            "Europe/Sofia", "Europe/Riga", "Europe/Tallinn", "Europe/Vilnius", "Africa/Cairo")
        add("MSK", "MSD", "Europe/Moscow")
        add("TRT", "TRT", "Europe/Istanbul")
        add("WAT", "WAT", "Africa/Lagos")
        add("SAST", "SAST", "Africa/Johannesburg")
        add("EAT", "EAT", "Africa/Nairobi")
        add("IST", "IDT", "Asia/Jerusalem")
        add("AST", "AST", "Asia/Riyadh", "Asia/Qatar")
        add("IRST", "IRDT", "Asia/Tehran")
        add("GST", "GST", "Asia/Dubai")
        add("PKT", "PKT", "Asia/Karachi")
        add("IST", "IST", "Asia/Kolkata", "Asia/Calcutta")
        add("NPT", "NPT", "Asia/Kathmandu")
        add("ICT", "ICT", "Asia/Bangkok", "Asia/Ho_Chi_Minh", "Asia/Saigon")
        add("WIB", "WIB", "Asia/Jakarta")
        add("SGT", "SGT", "Asia/Singapore")
        add("MYT", "MYT", "Asia/Kuala_Lumpur")
        add("PHT", "PHT", "Asia/Manila")
        add("HKT", "HKST", "Asia/Hong_Kong")
        add("CST", "CDT", "Asia/Shanghai", "Asia/Taipei")
        add("KST", "KDT", "Asia/Seoul")
        add("JST", "JDT", "Asia/Tokyo")
        add("AWST", "AWDT", "Australia/Perth")
        add("ACST", "ACDT", "Australia/Adelaide", "Australia/Darwin")
        add("AEST", "AEDT", "Australia/Sydney", "Australia/Melbourne", "Australia/Brisbane", "Australia/Hobart")
        add("NZST", "NZDT", "Pacific/Auckland")
        return table
    }()

    /// "PST" / "PDT", or nil when the zone has no well-known abbreviation (the UTC offset is shown instead).
    func shortName(for date: Date) -> String? {
        if let names = Self.abbreviations[identifier] {
            return isDaylightSavingTime(for: date) ? names.1 : names.0
        }
        guard let abbreviation = abbreviation(for: date),
              !abbreviation.hasPrefix("GMT+"), !abbreviation.hasPrefix("GMT-") else { return nil }
        return abbreviation
    }

    /// "Pacific Standard Time (PST)", or just the name when there's no well-known abbreviation.
    func fullName(for date: Date, locale: Locale = .current) -> String {
        let style: NameStyle = isDaylightSavingTime(for: date) ? .daylightSaving : .standard
        // Foundation falls back to "GMT+08:00" for some zones (even London in winter).
        func isOffset(_ name: String?) -> Bool { name.map { $0.hasPrefix("GMT+") || $0.hasPrefix("GMT-") } ?? true }
        var name = localizedName(for: style, locale: locale)
        if isOffset(name), secondsFromGMT(for: date) == 0, identifier.hasPrefix("Europe/") || identifier.hasPrefix("Atlantic/") {
            name = "Greenwich Mean Time"
        }
        if isOffset(name) { name = localizedName(for: .generic, locale: locale) }
        guard let name, !isOffset(name) else { return shortName(for: date) ?? utcOffsetText(for: date) }
        guard let short = shortName(for: date), !name.contains(short) else { return name }
        return "\(name) (\(short))"
    }

    /// "UTC−8", "UTC+5:30", "UTC+0"
    func utcOffsetText(for date: Date) -> String {
        let seconds = secondsFromGMT(for: date)
        let hours = abs(seconds) / 3600, minutes = abs(seconds) % 3600 / 60
        return "UTC\(seconds < 0 ? "−" : "+")\(hours)\(minutes == 0 ? "" : String(format: ":%02d", minutes))"
    }
}
