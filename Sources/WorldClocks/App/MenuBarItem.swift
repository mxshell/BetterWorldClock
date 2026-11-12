import AppKit
import SwiftUI

/// The globe in the menu bar. Clicking it drops down the same clocks as the desktop widget.
@MainActor
final class MenuBarItem: NSObject {
    private let statusItem: NSStatusItem
    private let popover = NSPopover()

    init(store: Store, openSettings: @escaping () -> Void) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        statusItem.autosaveName = "WorldClocksStatusItem"  // remembers its place if ⌘-dragged
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "World Clocks")
            button.image?.isTemplate = true
            button.target = self
            button.action = #selector(togglePanel(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        let panel = MenuPanel(store: store, openSettings: { [weak self] in
            self?.popover.performClose(nil)
            openSettings()
        })
        let controller = NSHostingController(rootView: panel)
        controller.sizingOptions = [.preferredContentSize]  // the popover follows the number of cities
        popover.contentViewController = controller
        popover.behavior = .transient  // closes on any click outside
    }

    @objc private func togglePanel(_ sender: NSStatusBarButton) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            NSApp.activate()
            popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        }
    }
}
