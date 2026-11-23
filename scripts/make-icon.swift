// Draws the app icon: a white "M↓" on a blue rounded square. Usage: swift make-icon.swift out.png
import AppKit

let size = 1024.0
let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
    let tile = rect.insetBy(dx: 100, dy: 100)
    NSGradient(starting: NSColor(red: 0.20, green: 0.45, blue: 0.95, alpha: 1),
               ending: NSColor(red: 0.10, green: 0.22, blue: 0.60, alpha: 1))!
        .draw(in: NSBezierPath(roundedRect: tile, xRadius: 185, yRadius: 185), angle: -90)
    let text = NSAttributedString(string: "M↓", attributes: [
        .font: NSFont.systemFont(ofSize: 380, weight: .bold),
        .foregroundColor: NSColor.white,
    ])
    let box = text.size()
    text.draw(at: NSPoint(x: rect.midX - box.width / 2, y: rect.midY - box.height / 2))
    return true
}
let rep = NSBitmapImageRep(data: image.tiffRepresentation!)!
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
