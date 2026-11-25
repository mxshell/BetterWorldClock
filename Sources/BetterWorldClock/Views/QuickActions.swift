import SwiftUI

/// Right-click menu shared by the desktop widget and the menu bar panel.
struct QuickActions: View {
    @ObservedObject var store: Store
    var openSettings: () -> Void
    @ObservedObject private var updater = Updater.shared

    var body: some View {
        Button("Settings…", action: openSettings)
        Divider()
        Toggle("Show Widget on Desktop", isOn: $store.showOnDesktop)
        Toggle("Show Weather", isOn: $store.showWeather)
        Toggle("Show Sunrise & Sunset", isOn: $store.showSun)
        Picker("Time Format", selection: $store.timeFormat) {
            ForEach(TimeFormat.allCases) { Text($0.label).tag($0) }
        }
        Picker("Temperature", selection: $store.unit) {
            ForEach(TemperatureUnit.allCases) { Text($0.label).tag($0) }
        }
        .disabled(!store.showWeather)
        Divider()
        Button("Refresh Weather") { store.refreshWeather() }
            .disabled(!store.showWeather)
        if let release = updater.available {
            Button(updater.canInstall(release) ? "Update to \(release.version)" : "Download Version \(release.version)") {
                updater.install()
            }
        } else {
            Button("Check for Updates…") {
                updater.check()
                openSettings()
            }
            .disabled(updater.isBusy)
        }
        Divider()
        Button("Quit World Clock+") { NSApp.terminate(nil) }
    }
}
