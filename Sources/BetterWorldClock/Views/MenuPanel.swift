import SwiftUI

/// The drop-down from the menu bar icon: the same clocks as the desktop widget, plus a couple of actions.
struct MenuPanel: View {
    @ObservedObject var store: Store
    var openSettings: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            TimelineView(.everyMinute) { context in
                ClockList(store: store, now: context.date)
            }
            Divider()
                .padding(.horizontal, 18)
            HStack {
                Button("Settings…", action: openSettings)
                Spacer()
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
            .font(.system(size: 12))
            .padding(.horizontal, 18)
            .padding(.vertical, 9)
        }
        .fixedSize()
        .contextMenu { QuickActions(store: store, openSettings: openSettings) }
    }
}
