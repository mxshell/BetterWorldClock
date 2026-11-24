import Foundation
import Testing
@testable import BetterWorldClock

struct ClockTests {
    private let defaults: [City] = [.newYork, .sanFrancisco, .singapore, .london]

    @Test func sortedWestToEast() {
        let ids = Clock.visible(defaults, at: winter).map(\.id)
        #expect(ids == [City.sanFrancisco, .newYork, .london, .singapore].map(\.id))
    }

    @Test func utcHiddenWhileACityIsOnUTC() {
        // London is on GMT (UTC+0) in winter.
        #expect(!Clock.visible(defaults, at: winter).contains { $0.city == nil })
    }

    @Test func utcShownOtherwise() {
        // London is on BST (UTC+1) in summer, so UTC slots in between New York and London.
        let ids = Clock.visible(defaults, at: summer).map(\.id)
        #expect(ids == [City.sanFrancisco.id, City.newYork.id, "UTC", City.london.id, City.singapore.id])
    }

    @Test func tiesKeepTheOrderCitiesWereAdded() {
        let oakland = City(name: "Oakland", country: "United States", timeZoneID: "America/Los_Angeles",
                           latitude: 37.8, longitude: -122.27)
        let ids = Clock.sorted([.city(oakland), .city(.sanFrancisco)], at: winter).map(\.id)
        #expect(ids == [oakland.id, City.sanFrancisco.id])
    }
}

struct CityTests {
    @Test func subtitleSkipsRepeats() {
        #expect(City.singapore.subtitle == "")
        #expect(City(name: "Taipei", region: "Taiwan", country: "Taiwan", timeZoneID: "Asia/Taipei",
                     latitude: 25.05, longitude: 121.53).subtitle == "Taiwan")
        #expect(City.sanFrancisco.subtitle == "California, United States")
    }

    @Test func idIncludesRoundedCoordinates() {
        #expect(City.singapore.id == "Singapore|1.290|103.850")
    }
}
