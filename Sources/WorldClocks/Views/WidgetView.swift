import SwiftUI

/// The desktop widget: the clocks on Liquid Glass. Reports its size so the window can follow.
struct WidgetView: View {
    @ObservedObject var store: Store
    var openSettings: () -> Void
    var onSizeChange: (CGSize) -> Void

    var body: some View {
        TimelineView(.everyMinute) { context in
            ClockList(store: store, now: context.date)
        }
        .glassEffect(.regular, in: .rect(cornerRadius: 24, style: .continuous))
        .contextMenu { QuickActions(store: store, openSettings: openSettings) }
        .fixedSize()
        .onGeometryChange(for: CGSize.self, of: { $0.size }, action: onSizeChange)
    }
}
