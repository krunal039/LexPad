#!/usr/bin/env swift
import AppKit

let root = URL(fileURLWithPath: CommandLine.arguments[1])
let iconset = root.appendingPathComponent("packaging/AppIcon.iconset")
try? FileManager.default.removeItem(at: iconset)
try FileManager.default.createDirectory(at: iconset, withIntermediateDirectories: true)

let sizes: [(Int, String)] = [
    (16, "icon_16x16.png"), (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"), (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"), (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"), (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"), (1024, "icon_512x512@2x.png"),
]

func color(_ r: CGFloat, _ g: CGFloat, _ b: CGFloat, _ a: CGFloat = 1) -> NSColor {
    NSColor(calibratedRed: r, green: g, blue: b, alpha: a)
}

func lerp(_ a: CGFloat, _ b: CGFloat, _ t: CGFloat) -> CGFloat { a + (b - a) * t }

func drawSquircle(in rect: NSRect, radius: CGFloat) -> NSBezierPath {
    NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
}

func drawRibbon(
    from start: NSPoint,
    cp1: NSPoint, cp2: NSPoint,
    to end: NSPoint,
    width: CGFloat,
    fill: NSColor,
    shadow: Bool = true
) {
    let path = NSBezierPath()
    path.move(to: start)
    path.curve(to: end, controlPoint1: cp1, controlPoint2: cp2)
    path.lineWidth = width
    path.lineCapStyle = .round
    if shadow {
        NSGraphicsContext.saveGraphicsState()
        let shadowColor = fill.withAlphaComponent(0.45)
        let shadow = NSShadow()
        shadow.shadowColor = shadowColor
        shadow.shadowBlurRadius = width * 0.35
        shadow.shadowOffset = NSSize(width: 0, height: -width * 0.08)
        shadow.set()
        fill.withAlphaComponent(0.92).setStroke()
        path.stroke()
        NSGraphicsContext.restoreGraphicsState()
    }
    fill.setStroke()
    path.stroke()
}

func renderIcon(size: Int) -> NSImage {
    let s = CGFloat(size)
    let image = NSImage(size: NSSize(width: s, height: s))
    image.lockFocus()

    let canvas = NSRect(x: 0, y: 0, width: s, height: s)
    let inset = s * 0.06
    let body = canvas.insetBy(dx: inset, dy: inset)
    let radius = s * 0.215

    // Deep base
    color(0.07, 0.09, 0.18).setFill()
    drawSquircle(in: body, radius: radius).fill()

    // Vibrant mesh gradient background
    let bg = NSGradient(colors: [
        color(0.42, 0.18, 0.92),
        color(0.12, 0.42, 0.96),
        color(0.05, 0.72, 0.88),
        color(0.10, 0.14, 0.28),
    ])
    NSGraphicsContext.saveGraphicsState()
    drawSquircle(in: body, radius: radius).addClip()
    bg?.draw(in: body, angle: 135)

    // Warm accent orb (top-right)
    let orb = NSGradient(colors: [
        color(1.0, 0.35, 0.55, 0.55),
        color(1.0, 0.55, 0.15, 0.0),
    ])
    let orbRect = NSRect(x: body.midX, y: body.midY, width: body.width * 0.72, height: body.height * 0.72)
    orb?.draw(fromCenter: NSPoint(x: orbRect.maxX - s * 0.08, y: orbRect.maxY - s * 0.06),
              radius: body.width * 0.42,
              toCenter: NSPoint(x: orbRect.maxX - s * 0.08, y: orbRect.maxY - s * 0.06),
              radius: 0)

    // Cool accent orb (bottom-left)
    let orb2 = NSGradient(colors: [
        color(0.20, 0.95, 0.75, 0.45),
        color(0.05, 0.55, 0.95, 0.0),
    ])
    orb2?.draw(fromCenter: NSPoint(x: body.minX + s * 0.12, y: body.minY + s * 0.10),
               radius: body.width * 0.38,
               toCenter: NSPoint(x: body.minX + s * 0.12, y: body.minY + s * 0.10),
               radius: 0)

    NSGraphicsContext.restoreGraphicsState()

    // Glass highlight (top edge)
    NSGraphicsContext.saveGraphicsState()
    drawSquircle(in: body, radius: radius).addClip()
    let shine = NSGradient(colors: [
        color(1, 1, 1, 0.28),
        color(1, 1, 1, 0.0),
    ])
    shine?.draw(in: NSRect(x: body.minX, y: body.midY, width: body.width, height: body.height * 0.55), angle: 90)
    NSGraphicsContext.restoreGraphicsState()

    let cx = body.midX
    let cy = body.midY
    let w = body.width
    let h = body.height
    let stroke = max(s * 0.085, 2.5)

    // Abstract flowing "L" — three luminous ribbons (original mark, not VS Code)
    drawRibbon(
        from: NSPoint(x: cx - w * 0.28, y: cy + h * 0.30),
        cp1: NSPoint(x: cx - w * 0.05, y: cy + h * 0.42),
        cp2: NSPoint(x: cx + w * 0.18, y: cy + h * 0.18),
        to: NSPoint(x: cx + w * 0.30, y: cy - h * 0.08),
        width: stroke,
        fill: color(1.0, 0.45, 0.65)
    )
    drawRibbon(
        from: NSPoint(x: cx - w * 0.32, y: cy + h * 0.08),
        cp1: NSPoint(x: cx - w * 0.10, y: cy + h * 0.22),
        cp2: NSPoint(x: cx + w * 0.08, y: cy - h * 0.02),
        to: NSPoint(x: cx + w * 0.28, y: cy - h * 0.28),
        width: stroke * 0.92,
        fill: color(0.35, 0.82, 1.0)
    )
    drawRibbon(
        from: NSPoint(x: cx - w * 0.22, y: cy - h * 0.32),
        cp1: NSPoint(x: cx - w * 0.18, y: cy - h * 0.08),
        cp2: NSPoint(x: cx - w * 0.02, y: cy + h * 0.02),
        to: NSPoint(x: cx + w * 0.26, y: cy + h * 0.22),
        width: stroke * 0.88,
        fill: color(0.55, 1.0, 0.45)
    )

    // Syntax accent dots (readable at small sizes)
    if s >= 32 {
        let dots: [(CGFloat, CGFloat, NSColor)] = [
            (cx - w * 0.34, cy - h * 0.18, color(1.0, 0.85, 0.25)),
            (cx - w * 0.26, cy - h * 0.26, color(0.95, 0.55, 1.0)),
            (cx - w * 0.18, cy - h * 0.20, color(0.45, 0.95, 1.0)),
        ]
        for (dx, dy, c) in dots {
            c.setFill()
            NSBezierPath(ovalIn: NSRect(x: dx - s * 0.018, y: dy - s * 0.018, width: s * 0.036, height: s * 0.036)).fill()
        }
    }

    // Subtle bracket hint at large sizes
    if s >= 128 {
        let bracketAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: s * 0.14, weight: .bold),
            .foregroundColor: color(1, 1, 1, 0.12),
        ]
        ("{" as NSString).draw(at: NSPoint(x: cx - w * 0.38, y: cy - s * 0.06), withAttributes: bracketAttrs)
        ("}" as NSString).draw(at: NSPoint(x: cx + w * 0.28, y: cy - s * 0.06), withAttributes: bracketAttrs)
    }

    // Outer rim
    color(1, 1, 1, 0.14).setStroke()
    let rim = drawSquircle(in: body.insetBy(dx: s * 0.008, dy: s * 0.008), radius: radius * 0.98)
    rim.lineWidth = max(0.5, s * 0.008)
    rim.stroke()

    image.unlockFocus()
    return image
}

for (size, name) in sizes {
    guard let tiff = renderIcon(size: size).tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else { continue }
    try png.write(to: iconset.appendingPathComponent(name))
}

let icns = root.appendingPathComponent("packaging/LexPad.icns")
let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconset.path, "-o", icns.path]
try task.run()
task.waitUntilExit()
guard task.terminationStatus == 0 else {
    fputs("iconutil failed\n", stderr)
    exit(1)
}
print("Created \(icns.path)")
