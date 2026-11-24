import AppKit
import Combine
import SwiftUI

/// The clock panel on the desktop: above the wallpaper and icons, below every app window, on all Spaces.
/// Drag it anywhere; it remembers where, and grows or shrinks from its top-left corner.
@MainActor
final class DesktopWidget: NSObject, NSWindowDelegate {
    private static let topLeftKey = "widgetTopLeft"

    private let window = WidgetWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
    private var cancellables = Set<AnyCancellable>()

    init(store: Store, openSettings: @escaping () -> Void) {
        super.init()

        let content = WidgetView(store: store, openSettings: openSettings, onSizeChange: { [weak self] size in
            DispatchQueue.main.async { self?.resize(to: size) }  // not in the middle of a layout pass
        })
        let hosting = DraggableHostingView(rootView: content)
        hosting.sizingOptions = []  // the window size is managed here instead

        window.contentView = hosting
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)) + 1)
        window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        window.isReleasedWhenClosed = false
        window.setContentSize(hosting.fittingSize)
        place(topLeft: savedTopLeft() ?? defaultTopLeft())
        window.delegate = self

        // Publishes the current value right away, so this also does the initial show or hide.
        store.$showOnDesktop
            .sink { [weak self] show in
                MainActor.assumeIsolated {
                    if show { self?.window.orderFrontRegardless() } else { self?.window.orderOut(nil) }
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.keepOnScreen() }
        }
    }

    func windowDidMove(_ notification: Notification) {
        UserDefaults.standard.set([window.frame.minX, window.frame.maxY], forKey: Self.topLeftKey)
    }

    private func place(topLeft: NSPoint) {
        let size = window.frame.size
        window.setFrame(NSRect(x: topLeft.x, y: topLeft.y - size.height, width: size.width, height: size.height),
                        display: true)
    }

    /// Cities were added or removed, or a name got longer: keep the top-left corner where it is.
    private func resize(to size: CGSize) {
        guard size.width > 0, size.height > 0, window.frame.size != size else { return }
        let frame = window.frame
        window.setFrame(NSRect(x: frame.minX, y: frame.maxY - size.height, width: size.width, height: size.height),
                        display: true)
    }

    private func savedTopLeft() -> NSPoint? {
        guard let saved = UserDefaults.standard.array(forKey: Self.topLeftKey) as? [Double], saved.count == 2 else {
            return nil
        }
        let point = NSPoint(x: saved[0], y: saved[1])
        let size = window.frame.size
        let frame = NSRect(x: point.x, y: point.y - size.height, width: size.width, height: size.height)
        return NSScreen.screens.contains { $0.visibleFrame.intersects(frame) } ? point : nil
    }

    /// Top-right corner of the main display.
    private func defaultTopLeft() -> NSPoint {
        let visible = (NSScreen.screens.first ?? NSScreen.main)?.visibleFrame ?? .zero
        return NSPoint(x: visible.maxX - window.frame.width - 24, y: visible.maxY - 24)
    }

    /// After a display is unplugged, bring the widget back if it ended up off every screen.
    private func keepOnScreen() {
        if !NSScreen.screens.contains(where: { $0.visibleFrame.intersects(window.frame) }) {
            place(topLeft: defaultTopLeft())
        }
    }
}

private final class WidgetWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

/// Dragging anywhere on the widget moves it. Right-click (or Control-click) still opens the context menu.
private final class DraggableHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            super.mouseDown(with: event)
        } else {
            window?.performDrag(with: event)
        }
    }
}
