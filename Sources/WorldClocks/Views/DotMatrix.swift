import AppKit

/// The horizontal form of the app icon for the menu bar: "TIME" on one line of dots with the red status dot.
/// Lit dots use the menu bar's text colour, so the mark works on light and dark menu bars.
enum DotMatrix {
    /// Same letters as the app icon (Resources/make_icon.swift).
    private static let glyphs: [Character: [String]] = [
        "T": ["XXXXX", "..X..", "..X..", "..X..", "..X.."],
        "I": ["XXX", ".X.", ".X.", ".X.", "XXX"],
        "M": ["X...X", "XX.XX", "X.X.X", "X...X", "X...X"],
        "E": ["XXXX", "X...", "XXX.", "X...", "XXXX"],
    ]
    private static let rows = 5
    static let red = NSColor(srgbRed: 1.0, green: 0.27, blue: 0.20, alpha: 1)

    /// `pitch` is the distance between dot centres in points; 3 makes the mark 15 pt tall.
    static func menuBarImage(pitch: CGFloat = 3) -> NSImage {
        var lit = Set<[Int]>()
        var width = 0
        for character in "TIME" {
            let glyph = glyphs[character]!
            for (row, line) in glyph.enumerated() {
                for (column, cell) in line.enumerated() where cell == "X" { lit.insert([width + column, row]) }
            }
            width += glyph[0].count + 1
        }
        let accent = [width, 0]  // one blank column after the E, top row
        let columns = width + 1

        let size = NSSize(width: CGFloat(columns) * pitch, height: CGFloat(rows) * pitch)
        let image = NSImage(size: size, flipped: true) { _ in
            for row in 0..<rows {
                for column in 0..<columns {
                    let cell = [column, row]
                    let isLit = lit.contains(cell) || cell == accent
                    (cell == accent ? red : isLit ? NSColor.labelColor : NSColor.labelColor.withAlphaComponent(0.18)).setFill()
                    let diameter = pitch * (isLit ? 0.78 : 0.6)
                    NSBezierPath(ovalIn: NSRect(x: (CGFloat(column) + 0.5) * pitch - diameter / 2,
                                                y: (CGFloat(row) + 0.5) * pitch - diameter / 2,
                                                width: diameter, height: diameter)).fill()
                }
            }
            return true
        }
        image.accessibilityDescription = "World Clocks"
        return image
    }
}
