import AppKit

// Renders a GitHub social-preview cover (1280x640) and a square thumbnail
// (1200x1200) for the ClipboardHistory app. Run with:
//   swift generate_marketing.swift <output-dir>

guard CommandLine.arguments.count > 1 else {
    print("usage: swift generate_marketing.swift <output-dir>")
    exit(1)
}

let outputDir = URL(fileURLWithPath: CommandLine.arguments[1])
try? FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)

// MARK: - Helpers

func roundedFont(size: CGFloat, weight: NSFont.Weight) -> NSFont {
    let base = NSFont.systemFont(ofSize: size, weight: weight)
    if let descriptor = base.fontDescriptor.withDesign(.rounded) {
        return NSFont(descriptor: descriptor, size: size) ?? base
    }
    return base
}

@discardableResult
func drawLeftText(_ text: String, font: NSFont, color: NSColor, x: CGFloat, y: CGFloat, tracking: CGFloat = 0) -> NSSize {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .kern: tracking]
    let attrString = NSAttributedString(string: text, attributes: attrs)
    let size = attrString.size()
    attrString.draw(at: NSPoint(x: x, y: y))
    return size
}

@discardableResult
func drawCenteredText(_ text: String, font: NSFont, color: NSColor, centerX: CGFloat, y: CGFloat, tracking: CGFloat = 0) -> NSSize {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .kern: tracking]
    let attrString = NSAttributedString(string: text, attributes: attrs)
    let size = attrString.size()
    attrString.draw(at: NSPoint(x: centerX - size.width / 2, y: y))
    return size
}

func drawBackground(rect: NSRect) {
    let gradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.30, green: 0.36, blue: 0.96, alpha: 1.0),
        NSColor(calibratedRed: 0.50, green: 0.24, blue: 0.86, alpha: 1.0),
    ])
    gradient?.draw(in: rect, angle: -55)

    // Subtle vignette for depth.
    let vignette = NSGradient(colors: [
        NSColor.black.withAlphaComponent(0.0),
        NSColor.black.withAlphaComponent(0.22),
    ])
    vignette?.draw(in: NSBezierPath(ovalIn: rect.insetBy(dx: -rect.width * 0.2, dy: -rect.height * 0.2)), relativeCenterPosition: .zero)
}

/// Draws the app's squircle icon (background + clipboard glyph) inside `rect`.
func drawAppIcon(in rect: NSRect) {
    NSGraphicsContext.saveGraphicsState()

    let shadow = NSShadow()
    shadow.shadowColor = NSColor.black.withAlphaComponent(0.35)
    shadow.shadowBlurRadius = rect.width * 0.08
    shadow.shadowOffset = NSSize(width: 0, height: -rect.height * 0.04)
    shadow.set()

    let cornerRadius = rect.width * 0.2237
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor.white.withAlphaComponent(0.001).setFill() // ensures shadow is cast by the fill below
    path.fill()

    NSGraphicsContext.restoreGraphicsState()

    NSGraphicsContext.saveGraphicsState()
    path.addClip()
    let iconGradient = NSGradient(colors: [
        NSColor(calibratedRed: 0.40, green: 0.46, blue: 0.98, alpha: 1.0),
        NSColor(calibratedRed: 0.62, green: 0.32, blue: 0.92, alpha: 1.0),
    ])
    iconGradient?.draw(in: path, angle: -45)

    let config = NSImage.SymbolConfiguration(pointSize: rect.width * 0.5, weight: .medium)
        .applying(.init(paletteColors: [.white]))
    if let symbol = NSImage(systemSymbolName: "doc.on.clipboard.fill", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let symbolSize = symbol.size
        let drawRect = NSRect(
            x: rect.midX - symbolSize.width / 2,
            y: rect.midY - symbolSize.height / 2,
            width: symbolSize.width,
            height: symbolSize.height
        )
        symbol.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
    }
    NSGraphicsContext.restoreGraphicsState()
}

func drawKeycapPill(text: String, centerX: CGFloat, y: CGFloat, font: NSFont) -> NSSize {
    let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: NSColor.white, .kern: 2]
    let attrString = NSAttributedString(string: text, attributes: attrs)
    let textSize = attrString.size()

    let paddingX: CGFloat = 22
    let paddingY: CGFloat = 12
    let pillSize = NSSize(width: textSize.width + paddingX * 2, height: textSize.height + paddingY * 2)
    let pillRect = NSRect(x: centerX - pillSize.width / 2, y: y, width: pillSize.width, height: pillSize.height)

    let pillPath = NSBezierPath(roundedRect: pillRect, xRadius: pillSize.height / 2, yRadius: pillSize.height / 2)
    NSColor.white.withAlphaComponent(0.16).setFill()
    pillPath.fill()
    NSColor.white.withAlphaComponent(0.45).setStroke()
    pillPath.lineWidth = 1.5
    pillPath.stroke()

    attrString.draw(at: NSPoint(x: pillRect.midX - textSize.width / 2, y: pillRect.midY - textSize.height / 2 + 1))
    return pillSize
}

func writePNG(_ image: NSImage, to url: URL) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        print("failed to encode \(url.lastPathComponent)")
        return
    }
    do {
        try png.write(to: url)
        print("wrote \(url.lastPathComponent)")
    } catch {
        print("failed to write \(url.lastPathComponent): \(error)")
    }
}

// MARK: - Cover (1280x640, GitHub social preview size)

func renderCover() -> NSImage {
    let size = NSSize(width: 1280, height: 640)
    let image = NSImage(size: size)
    image.lockFocus()

    let full = NSRect(origin: .zero, size: size)
    drawBackground(rect: full)

    let iconSize: CGFloat = 280
    let iconRect = NSRect(x: 96, y: (size.height - iconSize) / 2, width: iconSize, height: iconSize)
    drawAppIcon(in: iconRect)

    let textX = iconRect.maxX + 56
    let titleFont = roundedFont(size: 60, weight: .bold)
    let subtitleFont = roundedFont(size: 24, weight: .medium)
    let keycapFont = roundedFont(size: 22, weight: .semibold)

    let titleY: CGFloat = 372
    drawLeftText("Clipboard History", font: titleFont, color: .white, x: textX, y: titleY)

    let subtitleY: CGFloat = 322
    drawLeftText("Every copy & screenshot, one hotkey away.", font: subtitleFont, color: NSColor.white.withAlphaComponent(0.85), x: textX, y: subtitleY)

    _ = drawKeycapPill(text: "\u{2318} \u{21E7} V", centerX: textX + 60, y: 236, font: keycapFont)

    let captionFont = roundedFont(size: 16, weight: .medium)
    let captionSize = NSAttributedString(string: "github.com/mithelan/mac-copy-clipboard", attributes: [.font: captionFont]).size()
    drawLeftText(
        "github.com/mithelan/mac-copy-clipboard",
        font: captionFont,
        color: NSColor.white.withAlphaComponent(0.55),
        x: size.width - captionSize.width - 40,
        y: 32
    )

    image.unlockFocus()
    return image
}

// MARK: - Thumbnail (1200x1200 square)

func renderThumbnail() -> NSImage {
    let size = NSSize(width: 1200, height: 1200)
    let image = NSImage(size: size)
    image.lockFocus()

    let full = NSRect(origin: .zero, size: size)
    drawBackground(rect: full)

    let iconSize: CGFloat = 440
    let iconRect = NSRect(x: (size.width - iconSize) / 2, y: 565, width: iconSize, height: iconSize)
    drawAppIcon(in: iconRect)

    let titleFont = roundedFont(size: 74, weight: .bold)
    let subtitleFont = roundedFont(size: 30, weight: .medium)
    let keycapFont = roundedFont(size: 28, weight: .semibold)

    drawCenteredText("Clipboard History", font: titleFont, color: .white, centerX: size.width / 2, y: 415)
    drawCenteredText("Every copy & screenshot,", font: subtitleFont, color: NSColor.white.withAlphaComponent(0.85), centerX: size.width / 2, y: 345)
    drawCenteredText("one hotkey away.", font: subtitleFont, color: NSColor.white.withAlphaComponent(0.85), centerX: size.width / 2, y: 303)

    _ = drawKeycapPill(text: "\u{2318} \u{21E7} V", centerX: size.width / 2, y: 195, font: keycapFont)

    image.unlockFocus()
    return image
}

let cover = renderCover()
writePNG(cover, to: outputDir.appendingPathComponent("cover.png"))

let thumbnail = renderThumbnail()
writePNG(thumbnail, to: outputDir.appendingPathComponent("thumbnail.png"))
