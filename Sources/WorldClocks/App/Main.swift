import AppKit

@main
enum Main {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)  // lives in the menu bar and on the desktop; no Dock icon
        app.run()
    }
}
