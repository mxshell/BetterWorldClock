import AppKit
import Security

/// Replaces the app with a new release: download its zip, check the app inside is signed by the same developer,
/// swap it in, and relaunch. (A zip rather than the disk image, which would have to be mounted, and macOS can
/// ask for permission before an app reads a mounted disk image.)
enum SelfUpdate {
    enum Failure: LocalizedError {
        case noArchive, noApp, untrusted, wrongVersion
        case tool(String)

        var errorDescription: String? {
            switch self {
            case .noArchive: "The release has no update archive."
            case .noApp: "The update archive has no app in it."
            case .untrusted: "The new version isn't signed by the same developer."
            case .wrongVersion: "The update archive holds a different version."
            case .tool(let message): message
            }
        }
    }

    /// Whether the app at `app` can replace itself: signed with a Developer ID (not ad hoc, like a build from
    /// source), not run from the disk image or a translocated copy, and in a folder this user can write to.
    static func canInstall(at app: URL) -> Bool {
        let files = FileManager.default
        return app.pathExtension == "app"
            && !app.path.contains("/AppTranslocation/")
            && files.isWritableFile(atPath: app.path)
            && files.isWritableFile(atPath: app.deletingLastPathComponent().path)
            && teamIdentifier(of: app) != nil
    }

    static func install(_ release: Release, replacing app: URL) async throws {
        guard let archive = release.archive else { throw Failure.noArchive }
        let files = FileManager.default
        // On the same volume as the app, so the final swap is a quick rename.
        let work = try files.url(for: .itemReplacementDirectory, in: .userDomainMask, appropriateFor: app, create: true)
        defer { try? files.removeItem(at: work) }

        let (download, response) = try await URLSession.shared.download(from: archive)
        if let http = response as? HTTPURLResponse, http.statusCode != 200 { throw URLError(.badServerResponse) }
        let zip = work.appendingPathComponent("update.zip")
        try files.moveItem(at: download, to: zip)

        let unpacked = work.appendingPathComponent("unpacked")
        try run("/usr/bin/ditto", "-x", "-k", zip.path, unpacked.path)
        guard let new = try files.contentsOfDirectory(at: unpacked, includingPropertiesForKeys: nil)
            .first(where: { $0.pathExtension == "app" }) else { throw Failure.noApp }

        try verify(new, replacing: app, version: release.version)
        _ = try files.replaceItemAt(app, withItemAt: new)
    }

    /// Quits, and opens `app` again once this process has exited.
    @MainActor static func relaunch(_ app: URL) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        let pid = ProcessInfo.processInfo.processIdentifier
        process.arguments = ["-c", "while kill -0 \(pid) 2>/dev/null; do sleep 0.2; done; /usr/bin/open \"$0\"", app.path]
        try process.run()
        NSApp.terminate(nil)
    }

    /// The new app must meet the current app's designated requirement (same bundle identifier, signed with a
    /// Developer ID by the same team) and be the version the release says it is.
    static func verify(_ new: URL, replacing current: URL, version: String) throws {
        var currentCode: SecStaticCode?, requirement: SecRequirement?, newCode: SecStaticCode?
        let flags = SecCSFlags(rawValue: kSecCSCheckAllArchitectures | kSecCSStrictValidate | kSecCSCheckNestedCode)
        guard SecStaticCodeCreateWithPath(current as CFURL, [], &currentCode) == errSecSuccess, let currentCode,
              SecCodeCopyDesignatedRequirement(currentCode, [], &requirement) == errSecSuccess, let requirement,
              SecStaticCodeCreateWithPath(new as CFURL, [], &newCode) == errSecSuccess, let newCode,
              SecStaticCodeCheckValidity(newCode, flags, requirement) == errSecSuccess
        else { throw Failure.untrusted }
        let info = NSDictionary(contentsOf: new.appendingPathComponent("Contents/Info.plist"))
        guard info?["CFBundleShortVersionString"] as? String == version else { throw Failure.wrongVersion }
    }

    static func teamIdentifier(of app: URL) -> String? {
        var code: SecStaticCode?, info: CFDictionary?
        guard SecStaticCodeCreateWithPath(app as CFURL, [], &code) == errSecSuccess, let code,
              SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess
        else { return nil }
        return (info as? [String: Any])?[kSecCodeInfoTeamIdentifier as String] as? String
    }

    private static func run(_ tool: String, _ arguments: String...) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: tool)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        let errors = Pipe()
        process.standardError = errors
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw Failure.tool("\(URL(fileURLWithPath: tool).lastPathComponent): "
                               + message.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}
