import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var store: Store
    @ObservedObject private var updater = Updater.shared
    @State private var query = ""
    @State private var results: [City] = []
    @State private var isSearching = false
    @State private var searchFailed = false
    @State private var confirmingReset = false

    var body: some View {
        Form {
            Section {
                ForEach(sortedCities) { city in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                            Text(city.detail(at: Date()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { store.remove(city) } label: {
                            Image(systemName: "minus.circle.fill").foregroundStyle(.red)
                        }
                        .disabled(!store.canRemove)
                        .opacity(store.canRemove ? 1 : 0.35)
                        .help(store.canRemove ? "Remove" : "Keep at least \(Store.minCities) cities")
                    }
                    .buttonStyle(.borderless)
                }
            } header: {
                Text("Cities (\(store.cities.count) of \(Store.maxCities))")
            } footer: {
                Text("Keep \(Store.minCities)–\(Store.maxCities) cities. Clocks are sorted by UTC offset, west to east. A UTC clock is added when none of your cities is on UTC+0.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Add a City") {
                HStack {
                    TextField("Search", text: $query, prompt: Text("Tokyo, Paris, Taipei…"))
                        .labelsHidden()
                    if isSearching { ProgressView().controlSize(.small) }
                }
                if searchFailed {
                    Text("Couldn't reach the city search. Check your connection.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ForEach(results) { city in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(city.name)
                            Text(city.detail(at: Date()))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button("Add") {
                            store.add(city)
                            query = ""
                        }
                        .disabled(!store.canAdd(city))
                    }
                }
                if store.cities.count >= Store.maxCities {
                    Text("Remove a city to add another (max \(Store.maxCities)).")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Display") {
                Toggle("Show widget on desktop", isOn: $store.showOnDesktop)
                Picker("Time format", selection: $store.timeFormat) {
                    ForEach(TimeFormat.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Show weather", isOn: $store.showWeather)
                Picker("Temperature", selection: $store.unit) {
                    ForEach(TemperatureUnit.allCases) { Text($0.label).tag($0) }
                }
                .pickerStyle(.segmented)
                .disabled(!store.showWeather)
                Toggle("Show sunrise and sunset", isOn: $store.showSun)
                Toggle("Launch at login", isOn: $store.launchAtLogin)
                if store.loginItemNeedsApproval {
                    HStack {
                        Text("Allow World Clock+ in Login Items to finish turning this on.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Open Settings") { SMAppService.openSystemSettingsLoginItems() }
                    }
                } else if let error = store.loginItemError {
                    Text(error).font(.caption).foregroundStyle(.secondary)
                }
            }

            Section("Updates") {
                HStack {
                    Text("World Clock+ \(updater.currentVersion)")
                    Spacer()
                    Button("Check Now") { updater.check() }
                        .disabled(updater.isBusy)
                }
                Toggle("Check for updates automatically", isOn: $updater.checksAutomatically)
                updateStatus
            }

            Section {
                HStack {
                    Text(weatherStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("Refresh") { store.refreshWeather() }
                        .disabled(!store.showWeather)
                }
                Text("Click the globe in the menu bar to see your clocks anytime. Drag the desktop widget to move it; right-click either one for quick options.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } footer: {
                HStack {
                    Button("Reset to Default Cities…") { confirmingReset = true }
                    Spacer()
                    Button("Quit World Clock+") { NSApp.terminate(nil) }
                }
            }
        }
        .confirmationDialog("Replace your cities with the defaults?", isPresented: $confirmingReset) {
            Button("Reset Cities", role: .destructive) { store.cities = City.defaults }
        } message: {
            Text(City.defaults.map(\.name).joined(separator: ", "))
        }
        .formStyle(.grouped)
        .frame(width: 460, height: 700)
        .task(id: query) { await search() }
    }

    @ViewBuilder private var updateStatus: some View {
        switch updater.status {
        case .unknown:
            EmptyView()
        case .checking:
            HStack {
                ProgressView().controlSize(.small)
                Text("Checking…").font(.caption).foregroundStyle(.secondary)
            }
        case .upToDate:
            Text("You're up to date.").font(.caption).foregroundStyle(.secondary)
        case .available(let release):
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Version \(release.version) is available.")
                    Link("What's new", destination: release.page).font(.caption)
                }
                Spacer()
                Button(updater.canInstall(release) ? "Install and Relaunch" : "Download") { updater.install() }
            }
            if !updater.canInstall(release) {
                Text("World Clock+ can't install this update itself, so Download opens the release page.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .installing(let release):
            HStack {
                ProgressView().controlSize(.small)
                Text("Downloading and installing version \(release.version)…").font(.caption).foregroundStyle(.secondary)
            }
        case .failed(let message):
            Text(message).font(.caption).foregroundStyle(.secondary)
        }
    }

    private var sortedCities: [City] {
        Clock.sorted(store.cities.map(Clock.city), at: Date()).compactMap(\.city)
    }

    private var weatherStatus: String {
        guard store.showWeather else { return "Weather is turned off." }
        if let error = store.weatherError { return "Weather unavailable: \(error)" }
        guard let updated = store.lastWeatherUpdate else { return "Weather: loading…" }
        return "Weather from Open-Meteo, updated \(updated.formatted(.relative(presentation: .named)))"
    }

    private func search() async {
        let text = query.trimmingCharacters(in: .whitespaces)
        guard text.count >= 2 else {
            results = []
            searchFailed = false
            return
        }
        try? await Task.sleep(for: .milliseconds(350))  // debounce typing
        guard !Task.isCancelled else { return }
        isSearching = true
        defer { isSearching = false }
        do {
            let found = try await Geocoder.search(text)
            guard !Task.isCancelled else { return }
            results = found
            searchFailed = false
        } catch {
            if !Task.isCancelled { searchFailed = true }
        }
    }
}
