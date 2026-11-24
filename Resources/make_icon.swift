// Draws the app icon into an .iconset folder: swiftc make_icon.swift -o make_icon && ./make_icon <out.iconset>
//
// A globe made of dots, half in daylight: bright dots on the day side, faint dots on the night side, and
// the sunrise line between them in orange. The menu bar mark is the same globe, smaller
// (Sources/BetterWorldClock/Views/DotMatrix.swift).
import AppKit

enum Dot { case day, sunrise, night }

/// The dots of an n×n globe, keyed by [column, row] from the top-left.
func globe(_ n: Int) -> [[Int]: Dot] {
    let centre = Double(n - 1) / 2, radius = Double(n) / 2 - 0.25
    var dots: [[Int]: Dot] = [:]
    for row in 0..<n {
        for column in 0..<n {
            let dx = Double(column) - centre, dy = Double(row) - centre
            guard (dx * dx + dy * dy).squareRoot() <= radius else { continue }
            // The day side bulges slightly past the middle, like a globe turned a little toward the sun.
            dots[[column, row]] = dx <= 0.22 * (radius * radius - dy * dy).squareRoot() ? .day : .night
        }
    }
    for (cell, dot) in dots where dot == .day && dots[[cell[0] + 1, cell[1]]] == .night {
        dots[cell] = .sunrise
    }
    return dots
}

let ink = NSColor(srgbRed: 0.96, green: 0.96, blue: 0.94, alpha: 1)
let orange = NSColor(srgbRed: 1.0, green: 0.60, blue: 0.18, alpha: 1)

func color(_ dot: Dot, nightAlpha: CGFloat) -> NSColor {
    switch dot {
    case .day: ink
    case .sunrise: orange
    case .night: ink.withAlphaComponent(nightAlpha)
    }
}

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    NSColor.clear.set()
    NSRect(x: 0, y: 0, width: pixels, height: pixels).fill(using: .copy)

    // Up to 32 px the tile fills the canvas, so there is room for the globe.
    let n = CGFloat(pixels)
    let tile = pixels <= 32 ? NSRect(x: 1, y: 1, width: n - 2, height: n - 2)
                            : NSRect(x: n * 100 / 1024, y: n * 100 / 1024, width: n * 824 / 1024, height: n * 824 / 1024)
    let shape = NSBezierPath(roundedRect: tile, xRadius: tile.width * 0.225, yRadius: tile.width * 0.225)
    NSGradient(colors: [NSColor(srgbRed: 0.045, green: 0.045, blue: 0.05, alpha: 1),
                        NSColor(srgbRed: 0.13, green: 0.13, blue: 0.145, alpha: 1)])!.draw(in: shape, angle: 90)

    if pixels <= 16 {
        // Too small for dots: a solid half-lit disc with a one-pixel sunrise line.
        let disc = NSRect(x: n / 2 - 5, y: n / 2 - 5, width: 10, height: 10)
        NSBezierPath(ovalIn: disc).addClip()
        color(.night, nightAlpha: 0.3).setFill()
        disc.fill()
        ink.setFill()
        NSRect(x: disc.minX, y: disc.minY, width: 5, height: 10).fill()
        orange.setFill()
        NSRect(x: disc.minX + 5, y: disc.minY, width: 1, height: 10).fill()
    } else if pixels <= 64 {
        // Small: square dots snapped to whole pixels (2 px with a 1 px gap) so they stay crisp;
        // a 7×7 globe at 32 px, the full 13×13 at 64 px.
        let size = pixels <= 32 ? 7 : 13
        let pitch: CGFloat = 3
        let origin = ((n - (pitch * CGFloat(size) - 1)) / 2).rounded()
        for (cell, dot) in globe(size) {
            color(dot, nightAlpha: 0.26).setFill()
            NSRect(x: origin + CGFloat(cell[0]) * pitch, y: n - origin - CGFloat(cell[1]) * pitch - (pitch - 1),
                   width: pitch - 1, height: pitch - 1).fill()
        }
    } else {
        // A faint rim so the dark tile still has an edge on a dark Dock or desktop.
        NSColor(white: 1, alpha: 0.10).setStroke()
        let rim = NSBezierPath(roundedRect: tile.insetBy(dx: n * 1.5 / 1024, dy: n * 1.5 / 1024),
                               xRadius: tile.width * 0.223, yRadius: tile.width * 0.223)
        rim.lineWidth = n * 3 / 1024
        rim.stroke()

        let size = 13
        let grid = tile.insetBy(dx: tile.width * 0.16, dy: tile.width * 0.16)
        let pitch = grid.width / CGFloat(size)
        for (cell, dot) in globe(size) {
            let diameter = pitch * (dot == .night ? 0.62 : 0.74)
            color(dot, nightAlpha: 0.16).setFill()
            NSBezierPath(ovalIn: NSRect(x: grid.minX + (CGFloat(cell[0]) + 0.5) * pitch - diameter / 2,
                                        y: grid.maxY - (CGFloat(cell[1]) + 0.5) * pitch - diameter / 2,
                                        width: diameter, height: diameter)).fill()
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
