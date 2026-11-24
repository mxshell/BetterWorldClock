import AppKit

/// The menu bar mark: the app icon's globe of dots, half in daylight, at menu bar size.
/// Day dots use the menu bar's text colour, so the mark works on light and dark menu bars;
/// night dots are the same colour, faint; the sunrise line between them is orange.
enum DotMatrix {
    private enum Dot { case day, sunrise, night }

    static let orange = NSColor(srgbRed: 1.0, green: 0.60, blue: 0.18, alpha: 1)

    /// The dots of an n×n globe, keyed by [column, row] from the top-left (same shape as Resources/make_icon.swift).
    private static func globe(_ n: Int) -> [[Int]: Dot] {
        let centre = Double(n - 1) / 2, radius = Double(n) / 2 - 0.25
        var dots: [[Int]: Dot] = [:]
        for row in 0..<n {
            for column in 0..<n {
                let dx = Double(column) - centre, dy = Double(row) - centre
                guard (dx * dx + dy * dy).squareRoot() <= radius else { continue }
                dots[[column, row]] = dx <= 0.22 * (radius * radius - dy * dy).squareRoot() ? .day : .night
            }
        }
        for (cell, dot) in dots where dot == .day && dots[[cell[0] + 1, cell[1]]] == .night {
            dots[cell] = .sunrise
        }
        return dots
    }

    /// `pitch` is the distance between dot centres in points; 2.4 makes the 7×7 globe about 17 pt across.
    static func menuBarImage(pitch: CGFloat = 2.4) -> NSImage {
        let size = 7
        let dots = globe(size)
        let side = CGFloat(size) * pitch
        let image = NSImage(size: NSSize(width: side, height: side), flipped: true) { _ in
            for (cell, dot) in dots {
                switch dot {
                case .day: NSColor.labelColor.setFill()
                case .sunrise: orange.setFill()
                case .night: NSColor.labelColor.withAlphaComponent(0.28).setFill()
                }
                let diameter = pitch * 0.8
                NSBezierPath(ovalIn: NSRect(x: (CGFloat(cell[0]) + 0.5) * pitch - diameter / 2,
                                            y: (CGFloat(cell[1]) + 0.5) * pitch - diameter / 2,
                                            width: diameter, height: diameter)).fill()
            }
            return true
        }
        image.accessibilityDescription = "World Clocks"
        return image
    }
}
