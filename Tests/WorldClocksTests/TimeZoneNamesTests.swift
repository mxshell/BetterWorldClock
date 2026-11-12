import Foundation
import Testing
@testable import WorldClocks

struct TimeZoneNamesTests {
    @Test func offsetText() {
        let cases = [
            ("America/Los_Angeles", "UTC−8"),
            ("UTC", "UTC+0"),
            ("Asia/Kolkata", "UTC+5:30"),
            ("Asia/Kathmandu", "UTC+5:45"),
            ("Pacific/Auckland", "UTC+13"),
        ]
        for (zone, expected) in cases {
            #expect(TimeZone(identifier: zone)!.utcOffsetText(for: winter) == expected, "\(zone)")
        }
    }

    @Test func abbreviationFollowsDaylightSaving() {
        let pacific = TimeZone(identifier: "America/Los_Angeles")!
        #expect(pacific.shortName(for: winter) == "PST")
        #expect(pacific.shortName(for: summer) == "PDT")
        let london = TimeZone(identifier: "Europe/London")!
        #expect(london.shortName(for: winter) == "GMT")
        #expect(london.shortName(for: summer) == "BST")
    }

    @Test func noAbbreviationRatherThanAnOffset() {
        // Foundation only offers "GMT+4" here, which would repeat the offset column.
        #expect(TimeZone(identifier: "Asia/Tbilisi")!.shortName(for: winter) == nil)
    }

    @Test func fullName() {
        let cases = [
            ("America/Los_Angeles", winter, "Pacific Standard Time (PST)"),
            ("America/Los_Angeles", summer, "Pacific Daylight Time (PDT)"),
            ("Europe/London", winter, "Greenwich Mean Time (GMT)"),
            ("Europe/London", summer, "British Summer Time (BST)"),
            ("Asia/Singapore", summer, "Singapore Standard Time (SGT)"),
            ("Asia/Kathmandu", winter, "Nepal Time (NPT)"),
        ]
        for (zone, date, expected) in cases {
            #expect(TimeZone(identifier: zone)!.fullName(for: date, locale: english) == expected)
        }
    }
}
