import SwiftUI

/// The drop-down from the menu bar icon: the same clocks as the desktop widget, plus a couple of actions.
struct MenuPanel: View {
    @ObservedObject var store: Store
    var openSettings: () -> Void
    @ObservedObject private var updater = Updater.shared

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.everyMinute) { context in
                ClockList(store: store, now: context.date)
            }
            divider
            // A new version shows up here until it's installed.
            if let release = updater.available {
                footerRow {
                    Text("Version \(release.version) is available").foregroundStyle(.secondary)
                    Spacer()
                    Button(updater.canInstall(release) ? "Update" : "Download") { updater.install() }
                        .fontWeight(.semibold)
                        .foregroundStyle(.tint)
                }
                divider
            } else if case .installing(let release) = updater.status {
                footerRow {
                    ProgressView().controlSize(.mini)
                    Text("Updating to \(release.version)…").foregroundStyle(.secondary)
                    Spacer()
                }
                divider
            }
            footerRow {
                Button("Settings…", action: openSettings)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
        }
        .fixedSize()
        .contextMenu { QuickActions(store: store, openSettings: openSettings) }
    }

    private var divider: some View {
        Divider().padding(.horizontal, 18)
    }

    private func footerRow(@ViewBuilder _ content: () -> some View) -> some View {
        HStack(spacing: 6, content: content)
            .buttonStyle(.borderless)
            .font(.system(size: 12))
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
    }
}
