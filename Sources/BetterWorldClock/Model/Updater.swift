import AppKit

/// Looks for a new release once a day, and installs it when asked.
@MainActor
final class Updater: ObservableObject {
    static let shared = Updater()

    enum Status: Equatable {
        case unknown
        case checking
        case upToDate
        case available(Release)
        case installing(Release)
        case failed(String)
    }

    @Published var status: Status = .unknown
    @Published var checksAutomatically: Bool {
        didSet {
            defaults.set(checksAutomatically, forKey: Key.automatic)
            checkIfDue()
        }
    }

    let currentVersion = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0"
    /// Whether this copy can replace itself; a build from source, for one, can't.
    private let canReplaceItself = SelfUpdate.canInstall(at: Bundle.main.bundleURL)

    private enum Key {
        static let automatic = "checkForUpdates"
        static let lastCheck = "lastUpdateCheck"
    }

    private let defaults = UserDefaults.standard
    private var timer: Timer?
    private var task: Task<Void, Never>?

    private init() {
        checksAutomatically = defaults.object(forKey: Key.automatic) as? Bool ?? true
    }

    var available: Release? {
        if case .available(let release) = status { release } else { nil }
    }

    /// Whether `release` can be installed from the app. If not, updating opens its release page instead.
    func canInstall(_ release: Release) -> Bool {
        canReplaceItself && release.archive != nil
    }

    var isBusy: Bool {
        switch status {
        case .checking, .installing: true
        default: false
        }
    }

    func start() {
        // Checks hourly whether a day has passed since the last check, so time asleep counts too.
        timer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.checkIfDue() }
        }
        Task {
            try? await Task.sleep(for: .seconds(15))  // after launch at login, give the network a moment
            checkIfDue()
        }
    }

    func checkIfDue() {
        guard checksAutomatically, !isBusy else { return }
        let last = defaults.object(forKey: Key.lastCheck) as? Date ?? .distantPast
        if Date().timeIntervalSince(last) >= 24 * 3600 { check(quietly: true) }
    }

    /// A quiet check (the daily one) shows nothing unless it finds an update.
    func check(quietly: Bool = false) {
        if case .installing = status { return }
        task?.cancel()
        if !quietly { status = .checking }
        task = Task {
            do {
                let release = try await Releases.latest()
                guard !Task.isCancelled else { return }
                defaults.set(Date(), forKey: Key.lastCheck)
                status = Releases.isNewer(release.version, than: currentVersion) ? .available(release) : .upToDate
            } catch {
                guard !Task.isCancelled else { return }
                if !quietly { status = .failed("Couldn't check for updates. \(error.localizedDescription)") }
            }
        }
    }

    func install() {
        guard let release = available else { return }
        guard canInstall(release) else {
            NSWorkspace.shared.open(release.page)
            return
        }
        status = .installing(release)
        task = Task {
            do {
                try await SelfUpdate.install(release, replacing: Bundle.main.bundleURL)
                try SelfUpdate.relaunch(Bundle.main.bundleURL)
            } catch {
                status = .failed("Couldn't install version \(release.version). \(error.localizedDescription)")
            }
        }
    }
}
