import Foundation
import Testing
@testable import BetterWorldClock

struct ReleaseTests {
    @Test func readsVersionPageAndArchive() throws {
        let json = """
        {"tag_name": "v1.2.0", "html_url": "https://github.com/mxshell/BetterWorldClock/releases/tag/v1.2.0",
         "body": "## Install", "draft": false, "prerelease": false,
         "assets": [{"name": "BetterWorldClock-1.2.0.dmg",
                     "browser_download_url": "https://github.com/mxshell/BetterWorldClock/releases/download/v1.2.0/BetterWorldClock-1.2.0.dmg"},
                    {"name": "BetterWorldClock-1.2.0.zip",
                     "browser_download_url": "https://github.com/mxshell/BetterWorldClock/releases/download/v1.2.0/BetterWorldClock-1.2.0.zip"}]}
        """
        let release = try Releases.parse(Data(json.utf8))
        #expect(release.version == "1.2.0")
        #expect(release.page.absoluteString == "https://github.com/mxshell/BetterWorldClock/releases/tag/v1.2.0")
        #expect(release.archive?.lastPathComponent == "BetterWorldClock-1.2.0.zip")
    }

    @Test func olderReleaseWithOnlyADiskImage() throws {
        let json = #"{"tag_name": "v1.1.2", "html_url": "https://example.com/r", "assets": [{"name": "BetterWorldClock-1.1.2.dmg", "browser_download_url": "https://example.com/a.dmg"}]}"#
        let release = try Releases.parse(Data(json.utf8))
        #expect(release.version == "1.1.2")
        #expect(release.archive == nil)
    }

    @Test func comparesVersionsByNumber() {
        #expect(Releases.isNewer("1.2.0", than: "1.1.2"))
        #expect(Releases.isNewer("1.10.0", than: "1.9.9"))
        #expect(Releases.isNewer("2", than: "1.99"))
        #expect(Releases.isNewer("1.1.3", than: "1.1"))
        #expect(!Releases.isNewer("1.1.2", than: "1.1.2"))
        #expect(!Releases.isNewer("1.2", than: "1.2.0"))
        #expect(!Releases.isNewer("1.1.1", than: "1.1.2"))
    }
}
