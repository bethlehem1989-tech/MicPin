import AppKit

// DMG 安装窗口背景图 660x400
let W: CGFloat = 660, H: CGFloat = 400

func symbolImage(_ name: String, size: CGFloat, color: NSColor) -> NSImage? {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: size, weight: .semibold)) else { return nil }
    let img = NSImage(size: base.size)
    img.lockFocus()
    base.draw(at: .zero, from: .zero, operation: .sourceOver, fraction: 1)
    color.set()
    NSRect(origin: .zero, size: base.size).fill(using: .sourceAtop)
    img.unlockFocus()
    return img
}

let img = NSImage(size: NSSize(width: W, height: H))
img.lockFocus()

NSGradient(starting: NSColor(srgbRed: 0.97, green: 0.975, blue: 0.985, alpha: 1),
          ending: NSColor(srgbRed: 0.91, green: 0.93, blue: 0.97, alpha: 1))!
    .draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)

let p = NSMutableParagraphStyle(); p.alignment = .center
let title = NSAttributedString(string: "拖到 Applications 即安装完成", attributes: [
    .font: NSFont.systemFont(ofSize: 17, weight: .semibold),
    .foregroundColor: NSColor(srgbRed: 0.2, green: 0.22, blue: 0.28, alpha: 1),
    .paragraphStyle: p])
title.draw(in: NSRect(x: 0, y: 40, width: W, height: 24))

// 箭头
if let arrow = symbolImage("arrow.right", size: 40, color: NSColor(srgbRed: 0.35, green: 0.4, blue: 0.5, alpha: 0.55)) {
    arrow.draw(in: NSRect(x: W/2 - 20, y: H/2 - 20, width: 40, height: 40))
}

img.unlockFocus()
guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
      let data = rep.representation(using: .png, properties: [:]) else { fatalError() }
try? data.write(to: URL(fileURLWithPath: "build/dmg-bg.png"))
print("build/dmg-bg.png")
