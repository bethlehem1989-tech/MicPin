import AppKit


/// 取 SF Symbol 并染色
func symbol(_ name: String, size: CGFloat, color: NSColor) -> NSImage? {
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

/// 保持宽高比，居中放进给定方框
func fit(_ image: NSImage, in box: CGRect) -> CGRect {
    let s = min(box.width / image.size.width, box.height / image.size.height)
    let w = image.size.width * s, h = image.size.height * s
    return CGRect(x: box.midX - w / 2, y: box.midY - h / 2, width: w, height: h)
}

// 生成 MicPin 图标：macOS 风格圆角方块 + 麦克风 + 图钉角标
func drawIcon(size: CGFloat) -> NSImage {
    let img = NSImage(size: NSSize(width: size, height: size))
    img.lockFocus()
    let ctx = NSGraphicsContext.current!.cgContext
    let s = size

    // 底板：连续圆角（squircle 近似）
    let inset = s * 0.055
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let radius = rect.width * 0.2237
    let plate = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)
    ctx.saveGState()
    plate.addClip()
    // 渐变：靛蓝 → 亮蓝
    let colors = [NSColor(srgbRed: 0.20, green: 0.36, blue: 0.95, alpha: 1).cgColor,
                  NSColor(srgbRed: 0.36, green: 0.66, blue: 1.00, alpha: 1).cgColor]
    let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                          colors: colors as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(grad, start: CGPoint(x: rect.minX, y: rect.maxY),
                           end: CGPoint(x: rect.maxX, y: rect.minY), options: [])
    // 顶部高光
    let hi = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                        colors: [NSColor(white: 1, alpha: 0.28).cgColor,
                                 NSColor(white: 1, alpha: 0).cgColor] as CFArray,
                        locations: [0, 1])!
    ctx.drawLinearGradient(hi, start: CGPoint(x: rect.midX, y: rect.maxY),
                           end: CGPoint(x: rect.midX, y: rect.midY), options: [])
    ctx.restoreGState()

    // 麦克风：直接用系统 SF Symbol，保证字形正确、与 macOS 一致
    if let mic = symbol("mic.fill", size: s * 0.52, color: .white) {
        let r = fit(mic, in: CGRect(x: s * 0.5 - s * 0.30, y: s * 0.5 - s * 0.29 + s * 0.075,
                                    width: s * 0.58, height: s * 0.58))
        mic.draw(in: r)
    }

    // 图钉角标：白色圆底 + 蓝色 pin.fill，表示「已锁定」
    let bR = s * 0.155
    let bC = CGPoint(x: s * 0.755, y: s * 0.275)
    ctx.setShadow(offset: CGSize(width: 0, height: -s * 0.006),
                  blur: s * 0.035, color: NSColor(white: 0, alpha: 0.30).cgColor)
    NSColor.white.setFill()
    NSBezierPath(ovalIn: CGRect(x: bC.x - bR, y: bC.y - bR, width: bR * 2, height: bR * 2)).fill()
    ctx.setShadow(offset: .zero, blur: 0, color: nil)

    let pinColor = NSColor(srgbRed: 0.16, green: 0.33, blue: 0.92, alpha: 1)
    if let pin = symbol("pin.fill", size: bR * 1.15, color: pinColor) {
        let box = CGRect(x: bC.x - bR * 0.72, y: bC.y - bR * 0.72, width: bR * 1.44, height: bR * 1.44)
        pin.draw(in: fit(pin, in: box))
    }

    img.unlockFocus()
    return img
}

func png(_ image: NSImage, _ path: String) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else { return }
    try? data.write(to: URL(fileURLWithPath: path))
}

let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "build/icon.iconset"
try? FileManager.default.createDirectory(atPath: out, withIntermediateDirectories: true)
for (px, name) in [(16, "icon_16x16"), (32, "icon_16x16@2x"), (32, "icon_32x32"),
                   (64, "icon_32x32@2x"), (128, "icon_128x128"), (256, "icon_128x128@2x"),
                   (256, "icon_256x256"), (512, "icon_256x256@2x"), (512, "icon_512x512"),
                   (1024, "icon_512x512@2x")] {
    png(drawIcon(size: CGFloat(px)), "\(out)/\(name).png")
}
png(drawIcon(size: 1024), "\(out)/../icon-preview.png")
print("iconset -> \(out)")
