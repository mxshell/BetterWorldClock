import Foundation

/// A published version of the app.
struct Release: Equatable {
    var version: String
    var page: URL
    /// A zip of the app, for updating in place. Releases before 1.2.0 have only the disk image.
    var archive: URL?
}

/// The app's releases on GitHub.
enum Releases {
    static let latestURL = URL(string: "https://api.github.com/repos/mxshell/BetterWorldClock/releases/latest")!

    static func latest() async throws -> Release {
        var request = URLRequest(url: latestURL)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard (response as? HTTPURLResponse)?.statusCode == 200 else { throw URLError(.badServerResponse) }
        return try parse(data)
    }

    static func parse(_ data: Data) throws -> Release {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let response = try decoder.decode(Response.self, from: data)
        let version = response.tagName.hasPrefix("v") ? String(response.tagName.dropFirst()) : response.tagName
        let archive = response.assets.first { $0.name.hasSuffix(".zip") }?.browserDownloadUrl
        return Release(version: version, page: response.htmlUrl, archive: archive)
    }

    /// Compares dotted version numbers part by part, so 1.10 is newer than 1.9 and 1.2 equals 1.2.0.
    static func isNewer(_ version: String, than current: String) -> Bool {
        let new = version.split(separator: ".").map { Int($0) ?? 0 }
        let old = current.split(separator: ".").map { Int($0) ?? 0 }
        for index in 0..<max(new.count, old.count) {
            let a = index < new.count ? new[index] : 0, b = index < old.count ? old[index] : 0
            if a != b { return a > b }
        }
        return false
    }

    private struct Response: Decodable {
        struct Asset: Decodable {
            let name: String
            let browserDownloadUrl: URL
        }
        let tagName: String
        let htmlUrl: URL
        let assets: [Asset]
    }
}
