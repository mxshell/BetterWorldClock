import SwiftUI

/// Right-click menu shared by the desktop widget and the menu bar panel.
struct QuickActions: View {
    @ObservedObject var store: Store
    var openSettings: () -> Void

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
        Divider()
        Button("Quit Better World Clock") { NSApp.terminate(nil) }
    }
}
