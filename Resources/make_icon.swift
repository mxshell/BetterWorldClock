// Renders the app icon into an .iconset folder: swiftc make_icon.swift -o make_icon && ./make_icon <out.iconset>
import AppKit

let output = URL(fileURLWithPath: CommandLine.arguments[1])
try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)

func render(pixels: Int) -> Data {
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels, bitsPerSample: 8,
                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
                               bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let scale = CGFloat(pixels) / 1024
    let tile = NSRect(x: 100, y: 100, width: 824, height: 824).applying(.init(scaleX: scale, y: scale))
    let shape = NSBezierPath(roundedRect: tile, xRadius: 185 * scale, yRadius: 185 * scale)
    NSGradient(colors: [NSColor(srgbRed: 0.30, green: 0.20, blue: 0.78, alpha: 1),
                        NSColor(srgbRed: 0.13, green: 0.47, blue: 0.98, alpha: 1)])!.draw(in: shape, angle: 90)
    let config = NSImage.SymbolConfiguration(pointSize: 470 * scale, weight: .regular)
        .applying(.init(paletteColors: [.white]))
    if let globe = NSImage(systemSymbolName: "globe.americas.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let s = globe.size
        globe.draw(in: NSRect(x: tile.midX - s.width / 2, y: tile.midY - s.height / 2, width: s.width, height: s.height))
    }
    NSGraphicsContext.restoreGraphicsState()
    return rep.representation(using: .png, properties: [:])!
}

for points in [16, 32, 128, 256, 512] {
    try render(pixels: points).write(to: output.appendingPathComponent("icon_\(points)x\(points).png"))
    try render(pixels: points * 2).write(to: output.appendingPathComponent("icon_\(points)x\(points)@2x.png"))
}
