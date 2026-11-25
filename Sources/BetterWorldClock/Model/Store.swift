import AppKit
import Foundation
import ServiceManagement

/// The user's cities and settings, saved in UserDefaults, plus the latest weather.
@MainActor
final class Store: ObservableObject {
    static let minCities = 2
    static let maxCities = 10

    private enum Key {
        static let cities = "cities"
        static let unit = "temperatureUnit"
        static let showOnDesktop = "showOnDesktop"
        static let showWeather = "showWeather"
        static let showSun = "showSun"
        static let timeFormat = "timeFormat"
        static let weather = "weatherCache"
        static let loginItemSetUp = "loginItemSetUp"
    }

    private let defaults = UserDefaults.standard
    private var weatherTask: Task<Void, Never>?
    private var refreshTimer: Timer?

    @Published var cities: [City] {
        didSet {
            if let data = try? JSONEncoder().encode(cities) { defaults.set(data, forKey: Key.cities) }
            if Set(oldValue.map(\.id)) != Set(cities.map(\.id)) { refreshWeather() }
        }
    }
    @Published var unit: TemperatureUnit {
        didSet { defaults.set(unit.rawValue, forKey: Key.unit) }
    }
    /// The clocks are always in the menu bar; this controls the desktop widget.
    @Published var showOnDesktop: Bool {
        didSet { defaults.set(showOnDesktop, forKey: Key.showOnDesktop) }
    }
    @Published var timeFormat: TimeFormat {
        didSet { defaults.set(timeFormat.rawValue, forKey: Key.timeFormat) }
    }
    @Published var showWeather: Bool {
        didSet {
            defaults.set(showWeather, forKey: Key.showWeather)
            if showWeather, !oldValue { refreshWeather() }
        }
    }
    @Published var showSun: Bool {
        didSet { defaults.set(showSun, forKey: Key.showSun) }
    }
    @Published private(set) var weather: [String: Weather] = [:]
    @Published private(set) var weatherError: String?
    @Published private(set) var loginItemError: String?

    init() {
        if let data = defaults.data(forKey: Key.cities),
           let saved = try? JSONDecoder().decode([City].self, from: data) {
            cities = saved
        } else {
            cities = City.defaults
        }
        showOnDesktop = defaults.object(forKey: Key.showOnDesktop) as? Bool ?? true
        showWeather = defaults.object(forKey: Key.showWeather) as? Bool ?? true
        showSun = defaults.object(forKey: Key.showSun) as? Bool ?? true
        timeFormat = TimeFormat(rawValue: defaults.string(forKey: Key.timeFormat) ?? "") ?? .h24
        unit = TemperatureUnit(rawValue: defaults.string(forKey: Key.unit) ?? "")
            ?? (Locale.current.measurementSystem == .us ? .fahrenheit : .celsius)
        if let data = defaults.data(forKey: Key.weather),
           let cached = try? JSONDecoder().decode([String: Weather].self, from: data) {
            weather = cached
        }
    }

    func start() {
        refreshWeatherIfDue()
        // Checks every 15 minutes and fetches only once the weather is old enough. Comparing dates, rather
        // than waiting on a 2-hour timer, also counts the time the Mac spent asleep.
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 15 * 60, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.refreshWeatherIfDue() }
        }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(10))  // give the network a moment after wake
                self?.refreshWeatherIfDue()
            }
        }
        if !defaults.bool(forKey: Key.loginItemSetUp) {
            defaults.set(true, forKey: Key.loginItemSetUp)
            launchAtLogin = true
        }
    }

    var lastWeatherUpdate: Date? { weather.values.map(\.fetched).max() }

    var display: DisplayOptions {
        DisplayOptions(unit: unit, timeFormat: timeFormat, showWeather: showWeather, showSun: showSun)
    }

    // MARK: Cities

    func canAdd(_ city: City) -> Bool {
        cities.count < Self.maxCities && !cities.contains { $0.id == city.id }
    }

    func add(_ city: City) {
        guard canAdd(city) else { return }
        cities.append(city)
    }

    var canRemove: Bool { cities.count > Self.minCities }

    func remove(_ city: City) {
        guard canRemove else { return }
        cities.removeAll { $0.id == city.id }
    }

    // MARK: Weather

    /// Fetches the weather when a city has none yet, or its weather is `Weather.refreshInterval` old.
    func refreshWeatherIfDue() {
        let due = cities.contains { city in
            guard let fetched = weather[city.id]?.fetched else { return true }
            return Date().timeIntervalSince(fetched) >= Weather.refreshInterval
        }
        if due { refreshWeather() }
    }

    /// Fetches the weather for all cities now, in one request.
    func refreshWeather() {
        weatherTask?.cancel()
        guard showWeather else { return }  // no network calls while weather is hidden
        let cities = self.cities
        weatherTask = Task { [weak self] in
            for attempt in 1...3 {
                do {
                    let result = try await WeatherService.current(for: cities)
                    guard let self, !Task.isCancelled else { return }
                    let ids = Set(cities.map(\.id))
                    self.weather = self.weather.filter { ids.contains($0.key) }.merging(result) { $1 }
                    self.weatherError = nil
                    if let data = try? JSONEncoder().encode(self.weather) {
                        self.defaults.set(data, forKey: Key.weather)
                    }
                    return
                } catch {
                    guard !Task.isCancelled else { return }
                    self?.weatherError = error.localizedDescription
                    try? await Task.sleep(for: .seconds(30 * attempt))
                }
            }
        }
    }

    // MARK: Login item

    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            objectWillChange.send()
            do {
                if newValue { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                loginItemError = nil
            } catch {
                loginItemError = error.localizedDescription
            }
        }
    }

    var loginItemNeedsApproval: Bool { SMAppService.mainApp.status == .requiresApproval }
}
