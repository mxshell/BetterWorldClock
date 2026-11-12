// Draws the app icon into an .iconset folder: swiftc make_icon.swift -o make_icon && ./make_icon <out.iconset>
//
// "TIME" in a dot matrix, stacked TI over ME on an 11×11 grid of dots, with a red status dot in the corner.
// The letters match the horizontal menu bar mark in Sources/WorldClocks/Views/DotMatrix.swift.
import AppKit

let glyphs: [Character: [String]] = [
    "T": ["XXXXX", "..X..", "..X..", "..X..", "..X.."],
    "I": ["XXX", ".X.", ".X.", ".X.", "XXX"],
    "M": ["X...X", "XX.XX", "X.X.X", "X...X", "X...X"],
    "E": ["XXXX", "X...", "XXX.", "X...", "XXXX"],
]

/// Lit cells as (column, row) from the top-left.
func stamp(_ word: String, row: Int, into lit: inout Set<[Int]>) {
    var x = 0
    for character in word {
        let glyph = glyphs[character]!
        for (r, line) in glyph.enumerated() {
            for (c, cell) in line.enumerated() where cell == "X" { lit.insert([x + c, row + r]) }
        }
        x += glyph[0].count + 1
    }
}

let gridSize = 11
var lit = Set<[Int]>()
stamp("TI", row: 0, into: &lit)
stamp("ME", row: 6, into: &lit)
let accent = [gridSize - 1, 0]

let ink = NSColor(srgbRed: 0.96, green: 0.96, blue: 0.94, alpha: 1)
let red = NSColor(srgbRed: 1.0, green: 0.27, blue: 0.20, alpha: 1)

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: pixels, height: pixels).fill(using: .copy)

    // Tiny sizes get a pixel-aligned version: a larger tile, one solid square per lit dot, no unlit dots.
    let tiny = pixels <= 32
    let n = CGFloat(pixels)
    let tile = tiny ? NSRect(x: 1, y: 1, width: n - 2, height: n - 2)
                    : NSRect(x: n * 100 / 1024, y: n * 100 / 1024, width: n * 824 / 1024, height: n * 824 / 1024)
    let shape = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    NSGradient(colors: [NSColor(srgbRed: 0.045, green: 0.045, blue: 0.05, alpha: 1),
                        NSColor(srgbRed: 0.13, green: 0.13, blue: 0.145, alpha: 1)])!.draw(in: shape, angle: 90)

    if tiny {
        let pitch = floor(tile.width * 0.8 / CGFloat(gridSize))
        let origin = ((n - pitch * CGFloat(gridSize)) / 2).rounded()
        for cell in lit.union([accent]) {
            (cell == accent ? red : ink).setFill()
            NSRect(x: origin + CGFloat(cell[0]) * pitch, y: n - origin - CGFloat(cell[1] + 1) * pitch,
                   width: pitch, height: pitch).fill()
        }
    } else {
        // A faint rim so the dark tile still has an edge on a dark Dock or desktop.
        NSColor(white: 1, alpha: 0.10).setStroke()
        let rim = NSBezierPath(roundedRect: tile.insetBy(dx: n * 1.5 / 1024, dy: n * 1.5 / 1024),
                               xRadius: tile.width * 0.223, yRadius: tile.width * 0.223)
        rim.lineWidth = n * 3 / 1024
        rim.stroke()

        let grid = tile.insetBy(dx: n * 132 / 1024, dy: n * 132 / 1024)
        var pitch = grid.width / CGFloat(gridSize)
        // Below a few pixels per dot, round dots blur into each other: snap square dots to whole pixels instead.
        let snapped = pitch < 6
        if snapped { pitch = floor(pitch) }
        let left = snapped ? ((n - pitch * CGFloat(gridSize)) / 2).rounded() : grid.minX
        let top = snapped ? n - left : grid.maxY
        for row in 0..<gridSize {
            for column in 0..<gridSize {
                let cell = [column, row]
                let isLit = lit.contains(cell) || cell == accent
                (cell == accent ? red : isLit ? ink : ink.withAlphaComponent(0.13)).setFill()
                let x = left + CGFloat(column) * pitch, y = top - CGFloat(row + 1) * pitch
                if snapped {
                    NSRect(x: x, y: y, width: pitch - 1, height: pitch - 1).fill()
                } else {
                    let diameter = pitch * (isLit ? 0.74 : 0.62)
                    NSBezierPath(ovalIn: NSRect(x: x + (pitch - diameter) / 2, y: y + (pitch - diameter) / 2,
                                                width: diameter, height: diameter)).fill()
                }
            }
        }
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
for points in [16, 32, 128, 256, 512] {
    try render(pixels: points).write(to: output.appendingPathComponent("icon_\(points)x\(points).png"))
    try render(pixels: points * 2).write(to: output.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
