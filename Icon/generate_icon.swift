import AppKit

// Renders the app icon at every size macOS's iconutil expects, as a
// standalone .iconset folder. Run with:
//   swift generate_icon.swift <output-iconset-dir>

guard CommandLine.arguments.count > 1 else {
    print("usage: swift generate_icon.swift <output-iconset-dir>")
    exit(1)
}

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

let sizes: [(name: String, pixels: Int)] = [
    ("icon_16x16", 16),
    ("icon_16x16@2x", 32),
    ("icon_32x32", 32),
    ("icon_32x32@2x", 64),
    ("icon_128x128", 128),
    ("icon_128x128@2x", 256),
    ("icon_256x256", 256),
    ("icon_256x256@2x", 512),
    ("icon_512x512", 512),
    ("icon_512x512@2x", 1024),
]

func drawIcon(size: Int) -> NSImage {
    let canvas = NSImage(size: NSSize(width: size, height: size))
    canvas.lockFocus()

    let rect = NSRect(x: 0, y: 0, width: size, height: size)
    let cornerRadius = CGFloat(size) * 0.2237 // matches macOS "squircle" corner ratio
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    path.addClip()

    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.36, green: 0.42, blue: 0.98, alpha: 1.0),
        NSColor(calibratedRed: 0.58, green: 0.28, blue: 0.90, alpha: 1.0),
    ])
    gradient?.draw(in: path, angle: -45)

    let config = NSImage.SymbolConfiguration(pointSize: CGFloat(size) * 0.5, weight: .medium)
        .applying(.init(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let symbolSize = symbol.size
        let drawRect = NSRect(
            x: (CGFloat(size) - symbolSize.width) / 2,
            y: (CGFloat(size) - symbolSize.height) / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        symbol.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }

    canvas.unlockFocus()
    return canvas
}

for entry in sizes {
    let image = drawIcon(size: entry.pixels)
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("failed to render \(entry.name)")
        continue
    }
    let fileURL = outputDir.appendingPathComponent("\(entry.name).png")
    do {
        try png.write(to: fileURL)
    } catch {
        print("failed to write \(entry.name): \(error)")
    }
}

print("Wrote \(sizes.count) images to \(outputDir.path)")
