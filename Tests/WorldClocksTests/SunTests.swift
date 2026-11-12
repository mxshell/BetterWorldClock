import Foundation
import Testing
@testable import WorldClocks

struct SunTests {
    /// San Francisco on the June solstice: sunrise 5:48 PDT (12:48 UTC), sunset 20:35 PDT (03:35 UTC next day).
    @Test func sanFranciscoSolstice() throws {
        let city = City.sanFrancisco
        guard case .sunrise(let rise) = Sun.next(after: date("2026-06-21T10:00:00Z"),
                                                 latitude: city.latitude, longitude: city.longitude) else {
            Issue.record("expected a sunrise next"); return
        }
        #expect(abs(rise.timeIntervalSince(date("2026-06-21T12:48:00Z"))) < 3 * 60)

        guard case .sunset(let set) = Sun.next(after: date("2026-06-21T20:00:00Z"),
                                               latitude: city.latitude, longitude: city.longitude) else {
            Issue.record("expected a sunset next"); return
        }
        #expect(abs(set.timeIntervalSince(date("2026-06-22T03:35:00Z"))) < 3 * 60)
    }

    @Test func polarNightAndDay() {
        let city = City.longyearbyen
        #expect(Sun.next(after: date("2026-12-21T12:00:00Z"), latitude: city.latitude, longitude: city.longitude) == .polarNight)
        #expect(Sun.next(after: date("2026-06-21T12:00:00Z"), latitude: city.latitude, longitude: city.longitude) == .polarDay)
    }

    @Test func nightMeansTheSunRisesNext() {
        let now = Date()
        #expect(SunEvent.sunrise(now).isNight)
        #expect(SunEvent.polarNight.isNight)
        #expect(!SunEvent.sunset(now).isNight)
        #expect(!SunEvent.polarDay.isNight)
    }

    @Test func utcFollowsGreenwich() {
        // 03:00 UTC in July is before sunrise in Greenwich; 12:00 UTC is broad daylight.
        #expect(Clock.utc.nextSunEvent(after: date("2026-07-01T03:00:00Z")).isNight)
        #expect(!Clock.utc.nextSunEvent(after: date("2026-07-01T12:00:00Z")).isNight)
    }
}
