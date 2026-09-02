import AppKit

// Instagram 轮播图 1080x1350（4:5）
let W: CGFloat = 1080, H: CGFloat = 1350

let brandDeep = NSColor(srgbRed: 0.16, green: 0.28, blue: 0.86, alpha: 1)
let brandLite = NSColor(srgbRed: 0.36, green: 0.66, blue: 1.00, alpha: 1)
let gold      = NSColor(srgbRed: 1, green: 0.83, blue: 0.35, alpha: 1)
let ink       = NSColor(srgbRed: 0.09, green: 0.11, blue: 0.16, alpha: 1)
let inkSub    = NSColor(srgbRed: 0.42, green: 0.45, blue: 0.52, alpha: 1)
let paper     = NSColor(srgbRed: 0.965, green: 0.969, blue: 0.98, alpha: 1)

func font(_ size: CGFloat, _ w: NSFont.Weight = .semibold) -> NSFont {
    NSFont.systemFont(ofSize: size, weight: w)
}

func attr(_ s: String, _ f: NSFont, _ c: NSColor, spacing: CGFloat = 0,
          align: NSTextAlignment = .left, lineHeight: CGFloat = 1.2) -> NSAttributedString {
    let p = NSMutableParagraphStyle()
    p.alignment = align
    p.lineHeightMultiple = lineHeight
    return NSAttributedString(string: s, attributes: [
        .font: f, .foregroundColor: c, .kern: spacing, .paragraphStyle: p])
}

@discardableResult
func draw(_ a: NSAttributedString, x: CGFloat, top: CGFloat, width: CGFloat) -> CGFloat {
    let h = a.boundingRect(with: NSSize(width: width, height: 9999),
                           options: [.usesLineFragmentOrigin, .usesFontLeading]).height + 8
    a.draw(with: NSRect(x: x, y: H - top - h, width: width, height: h),
           options: [.usesLineFragmentOrigin, .usesFontLeading])
    return h
}

func roundRect(_ r: NSRect, _ radius: CGFloat, fill: NSColor?, stroke: NSColor? = nil, lw: CGFloat = 2) {
    let p = NSBezierPath(roundedRect: r, xRadius: radius, yRadius: radius)
    if let f = fill { f.setFill(); p.fill() }
    if let s = stroke { s.setStroke(); p.lineWidth = lw; p.stroke() }
}

func shadowed(_ blur: CGFloat, _ alpha: CGFloat, _ body: () -> Void) {
    NSGraphicsContext.saveGraphicsState()
    let sh = NSShadow()
    sh.shadowBlurRadius = blur
    sh.shadowOffset = NSSize(width: 0, height: -blur * 0.25)
    sh.shadowColor = NSColor(white: 0.35, alpha: alpha)
    sh.set(); body()
    NSGraphicsContext.restoreGraphicsState()
}

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

func drawSymbol(_ name: String, cx: CGFloat, cyTop: CGFloat, size: CGFloat, color: NSColor) {
    guard let img = symbolImage(name, size: size, color: color) else { return }
    let s = img.size
    img.draw(in: NSRect(x: cx - s.width / 2, y: H - cyTop - s.height / 2, width: s.width, height: s.height))
}

func gradientBG(_ top: NSColor, _ bottom: NSColor) {
    NSGradient(starting: top, ending: bottom)!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -75)
}

func card(_ name: String, _ body: () -> Void) {
    let img = NSImage(size: NSSize(width: W, height: H))
    img.lockFocus(); body(); img.unlockFocus()
    guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else { return }
    try? FileManager.default.createDirectory(atPath: "build/ig", withIntermediateDirectories: true)
    try? data.write(to: URL(fileURLWithPath: "build/ig/\(name).png"))
    print("build/ig/\(name).png")
}

func appIcon(cx: CGFloat, cyTop: CGFloat, size s: CGFloat) {
    let r = NSRect(x: cx - s / 2, y: H - cyTop - s / 2, width: s, height: s)
    shadowed(s * 0.12, 0.35) { roundRect(r, s * 0.224, fill: brandDeep) }
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: r, xRadius: s * 0.224, yRadius: s * 0.224).addClip()
    NSGradient(starting: NSColor(srgbRed: 0.36, green: 0.44, blue: 0.97, alpha: 1), ending: brandLite)!
        .draw(in: r, angle: -60)
    NSGraphicsContext.restoreGraphicsState()
    if let mic = symbolImage("mic.fill", size: s * 0.46, color: .white) {
        let m = mic.size
        mic.draw(in: NSRect(x: cx - m.width / 2, y: H - cyTop - m.height / 2 + s * 0.045,
                            width: m.width, height: m.height))
    }
    let bR = s * 0.155
    let bC = NSPoint(x: cx + s * 0.255, y: H - cyTop - s * 0.225)
    NSColor.white.setFill()
    NSBezierPath(ovalIn: NSRect(x: bC.x - bR, y: bC.y - bR, width: bR * 2, height: bR * 2)).fill()
    if let pin = symbolImage("pin.fill", size: bR * 1.15, color: brandDeep) {
        let p = pin.size
        pin.draw(in: NSRect(x: bC.x - p.width / 2, y: bC.y - p.height / 2, width: p.width, height: p.height))
    }
}

func pageTag(_ n: Int, _ total: Int, light: Bool = false) {
    draw(attr("\(n)/\(total)", font(28, .medium),
              light ? NSColor(white: 1, alpha: 0.5) : inkSub, align: .right),
         x: W - 380, top: H - 90, width: 300)
}

func swipeHint() {
    draw(attr("swipe →", font(28, .medium), NSColor(white: 1, alpha: 0.55)), x: 80, top: H - 90, width: 300)
}

// MARK: - 1 Cover

card("01-cover") {
    gradientBG(NSColor(srgbRed: 0.10, green: 0.15, blue: 0.40, alpha: 1),
               NSColor(srgbRed: 0.22, green: 0.45, blue: 0.92, alpha: 1))

    let pill = NSRect(x: 80, y: H - 172, width: 372, height: 72)
    roundRect(pill, 36, fill: NSColor(white: 1, alpha: 0.16))
    draw(attr("I built a Mac app", font(32, .medium), .white, align: .center), x: 80, top: 121, width: 372)

    let badge = NSRect(x: 474, y: H - 172, width: 356, height: 72)
    roundRect(badge, 36, fill: gold)
    drawSymbol("chevron.left.forwardslash.chevron.right", cx: 528, cyTop: 136, size: 28,
               color: NSColor(srgbRed: 0.12, green: 0.16, blue: 0.34, alpha: 1))
    draw(attr("OPEN SOURCE", font(29, .bold),
              NSColor(srgbRed: 0.12, green: 0.16, blue: 0.34, alpha: 1), spacing: 1),
         x: 566, top: 122, width: 260)

    draw(attr("PIN", font(190, .heavy), .white, spacing: -2), x: 78, top: 250, width: 960)
    draw(attr("YOUR MIC.", font(120, .heavy), .white, spacing: -1), x: 78, top: 448, width: 960)
    draw(attr("FOR GOOD.", font(120, .heavy), gold, spacing: -1), x: 78, top: 578, width: 960)

    draw(attr("Plug in a USB mic — macOS still records\nfrom the built-in one. Put on your AirPods,\nand your input jumps to the headset mic.",
              font(34, .regular), NSColor(white: 1, alpha: 0.76), lineHeight: 1.45),
         x: 80, top: 762, width: 960)

    appIcon(cx: 176, cyTop: 1148, size: 176)
    draw(attr("MicPin", font(58, .bold), .white), x: 300, top: 1082, width: 620)
    draw(attr("Free · macOS 13+ · Universal", font(30, .regular),
              NSColor(white: 1, alpha: 0.7)), x: 300, top: 1156, width: 620)
    swipeHint()
}

// MARK: - 2 Pain

card("02-pain") {
    paper.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
    draw(attr("Sound familiar?", font(60, .bold), ink), x: 80, top: 110, width: 940)
    draw(attr("macOS keeps falling back to the built-in mic",
              font(32, .regular), inkSub), x: 80, top: 194, width: 940)

    let items: [(String, String, String)] = [
        ("headphones", "You put on Bluetooth headphones",
         "You only wanted to listen. Now you're recording\nthrough the headset mic and you sound underwater."),
        ("cable.connector", "You plug in a USB mic",
         "macOS doesn't care. Still the MacBook mic."),
        ("hand.tap", "Every time before you dictate",
         "You open Sound settings just to check\nwhich mic is actually live right now."),
    ]
    var top: CGFloat = 290
    for (sym, title, body) in items {
        let r = NSRect(x: 70, y: H - top - 260, width: W - 140, height: 242)
        shadowed(24, 0.15) { roundRect(r, 32, fill: .white) }
        let badge = NSRect(x: 116, y: H - top - 128, width: 88, height: 88)
        roundRect(badge, 26, fill: NSColor(srgbRed: 0.93, green: 0.95, blue: 1, alpha: 1))
        drawSymbol(sym, cx: badge.midX, cyTop: top + 84, size: 44, color: brandDeep)
        draw(attr(title, font(38, .bold), ink), x: 238, top: top + 46, width: 720)
        draw(attr(body, font(28, .regular), inkSub, lineHeight: 1.4), x: 238, top: top + 112, width: 720)
        top += 280
    }
    draw(attr("Once a day is fine. Ten times a day is not.", font(34, .semibold),
              NSColor(srgbRed: 0.90, green: 0.28, blue: 0.35, alpha: 1), align: .center),
         x: 0, top: 1170, width: W)
    pageTag(2, 6)
}

// MARK: - 3 Menu

card("03-menu") {
    gradientBG(NSColor(srgbRed: 0.13, green: 0.15, blue: 0.22, alpha: 1),
               NSColor(srgbRed: 0.20, green: 0.24, blue: 0.36, alpha: 1))
    draw(attr("It lives in your menu bar", font(56, .bold), .white), x: 80, top: 100, width: 940)
    draw(attr("One glance tells you which mic is live", font(32, .regular),
              NSColor(white: 1, alpha: 0.6)), x: 80, top: 180, width: 940)

    let bar = NSRect(x: 70, y: H - 320, width: W - 140, height: 70)
    roundRect(bar, 18, fill: NSColor(white: 1, alpha: 0.10))
    drawSymbol("mic.fill", cx: 560, cyTop: 285, size: 28, color: .white)
    draw(attr("NEOM USB", font(28, .medium), .white), x: 588, top: 268, width: 240)
    for (i, s) in ["wifi", "battery.100", "magnifyingglass"].enumerated() {
        drawSymbol(s, cx: 836 + CGFloat(i) * 60, cyTop: 285, size: 24, color: NSColor(white: 1, alpha: 0.5))
    }
    roundRect(NSRect(x: 534, y: H - 314, width: 254, height: 58), 15, fill: nil, stroke: gold, lw: 4)

    let menu = NSRect(x: 150, y: H - 1180, width: 780, height: 820)
    shadowed(38, 0.5) { roundRect(menu, 28, fill: NSColor(srgbRed: 0.19, green: 0.20, blue: 0.24, alpha: 1)) }

    var y: CGFloat = 392
    draw(attr("Current input: NEOM USB", font(36, .bold), .white), x: 198, top: y, width: 690)
    y += 54
    draw(attr("Auto: NEOM USB (USB)", font(26, .regular), NSColor(white: 1, alpha: 0.5)),
         x: 198, top: y, width: 690)
    y += 70
    roundRect(NSRect(x: 176, y: H - y - 2, width: 728, height: 2), 1, fill: NSColor(white: 1, alpha: 0.12))
    y += 28
    draw(attr("WHICH MICROPHONE TO LOCK", font(23, .semibold),
              NSColor(white: 1, alpha: 0.45), spacing: 1.5), x: 198, top: y, width: 690)
    y += 52

    let devices: [(String, String, Bool)] = [
        ("Automatic (prefer USB mic)", "", true),
        ("NEOM USB", "USB", false),
        ("MacBook Pro Microphone", "Built-in", false),
        ("AirPods Pro", "Bluetooth", false),
        ("Studio Display Microphone", "USB", false),
    ]
    for (name, tag, checked) in devices {
        if checked {
            roundRect(NSRect(x: 176, y: H - y - 52, width: 728, height: 62), 14,
                      fill: NSColor(srgbRed: 0.24, green: 0.42, blue: 0.95, alpha: 1))
            drawSymbol("checkmark", cx: 210, cyTop: y + 20, size: 24, color: .white)
        }
        draw(attr(name, font(29, .regular), checked ? .white : NSColor(white: 1, alpha: 0.9)),
             x: 244, top: y, width: 480)
        if !tag.isEmpty {
            let tw: CGFloat = tag == "Bluetooth" ? 156 : (tag == "Built-in" ? 138 : 96)
            roundRect(NSRect(x: 892 - tw, y: H - y - 40, width: tw, height: 42), 12,
                      fill: NSColor(white: 1, alpha: 0.13))
            draw(attr(tag, font(22, .medium), NSColor(white: 1, alpha: 0.75), align: .center),
                 x: 892 - tw, top: y + 8, width: tw)
        }
        y += 72
    }
    y += 12
    roundRect(NSRect(x: 176, y: H - y - 2, width: 728, height: 2), 1, fill: NSColor(white: 1, alpha: 0.12))
    y += 24
    for t in ["Enable auto-lock", "Show HUD when switching", "Launch at login"] {
        drawSymbol("checkmark", cx: 210, cyTop: y + 18, size: 22, color: .white)
        draw(attr(t, font(28, .regular), NSColor(white: 1, alpha: 0.85)), x: 244, top: y, width: 600)
        y += 58
    }

    draw(attr("Click a device to pin it. Click again for automatic.",
              font(30, .semibold), gold, align: .center), x: 0, top: 1225, width: W)
    pageTag(3, 6, light: true)
}

// MARK: - 4 HUD

card("04-hud") {
    gradientBG(NSColor(srgbRed: 0.10, green: 0.13, blue: 0.30, alpha: 1),
               NSColor(srgbRed: 0.17, green: 0.35, blue: 0.72, alpha: 1))
    draw(attr("Before you talk,", font(62, .bold), .white), x: 80, top: 110, width: 940)
    draw(attr("it tells you which mic", font(62, .bold), .white), x: 80, top: 190, width: 940)
    draw(attr("No more talking into the void and hoping",
              font(32, .regular), NSColor(white: 1, alpha: 0.7)), x: 80, top: 292, width: 940)

    let hud = NSRect(x: 130, y: H - 690, width: 820, height: 200)
    shadowed(46, 0.55) {
        roundRect(hud, 40, fill: NSColor(srgbRed: 0.16, green: 0.17, blue: 0.21, alpha: 0.97))
    }
    roundRect(hud, 40, fill: nil, stroke: NSColor(white: 1, alpha: 0.12), lw: 2)
    let ic = NSRect(x: 188, y: H - 636, width: 96, height: 96)
    roundRect(ic, 28, fill: NSColor(srgbRed: 0.24, green: 0.42, blue: 0.95, alpha: 1))
    drawSymbol("mic.fill", cx: ic.midX, cyTop: 588, size: 48, color: .white)
    draw(attr("NEOM USB", font(46, .bold), .white), x: 320, top: 546, width: 560)
    draw(attr("Locked as input · USB", font(28, .regular),
              NSColor(white: 1, alpha: 0.6)), x: 320, top: 612, width: 560)

    draw(attr("Fades in when the mic changes, gone in 2 seconds.\nWant to check anytime? Hit “Re-check now”.",
              font(31, .regular), NSColor(white: 1, alpha: 0.8), align: .center, lineHeight: 1.5),
         x: 90, top: 770, width: 900)

    let states: [(String, String)] = [("mic.fill", "Locked"), ("mic", "No USB mic"), ("mic.slash", "Paused")]
    for (i, (sym, label)) in states.enumerated() {
        let cx = 240 + CGFloat(i) * 300
        roundRect(NSRect(x: cx - 84, y: H - 1120, width: 168, height: 168), 38,
                  fill: NSColor(white: 1, alpha: 0.12))
        drawSymbol(sym, cx: cx, cyTop: 1018, size: 56, color: .white)
        draw(attr(label, font(26, .medium), NSColor(white: 1, alpha: 0.75), align: .center),
             x: cx - 150, top: 1146, width: 300)
    }
    pageTag(4, 6, light: true)
}

// MARK: - 5 Features

card("05-features") {
    paper.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
    draw(attr("Why it's safe to leave running", font(52, .bold), ink), x: 80, top: 106, width: 940)
    draw(attr("It does exactly one thing: set the default input device",
              font(30, .regular), inkSub), x: 80, top: 182, width: 940)

    let feats: [(String, String, String)] = [
        ("lock.open", "No mic permission", "It never opens an audio\nstream, so macOS never asks"),
        ("bolt.fill", "A few MB of RAM", "~700 lines of Swift,\nsystem frameworks only"),
        ("arrow.triangle.2.circlepath", "Bluetooth-proof", "Listener + 3s safety poll,\ntakes the input right back"),
        ("globe", "English & 中文", "Follows your system\nlanguage automatically"),
        ("pin.fill", "Pin any device", "Two mics plugged in?\nPick one, it stays"),
        ("chevron.left.forwardslash.chevron.right", "MIT licensed", "Every line is on GitHub,\nfree forever"),
    ]
    for (i, (sym, title, body)) in feats.enumerated() {
        let col = CGFloat(i % 2), row = CGFloat(i / 2)
        let x = 70 + col * 480, top = 268 + row * 300
        let r = NSRect(x: x, y: H - top - 282, width: 470, height: 282)
        shadowed(22, 0.13) { roundRect(r, 30, fill: .white) }
        let badge = NSRect(x: x + 42, y: H - top - 116, width: 80, height: 80)
        roundRect(badge, 24, fill: NSColor(srgbRed: 0.93, green: 0.95, blue: 1, alpha: 1))
        drawSymbol(sym, cx: badge.midX, cyTop: top + 76, size: 38, color: brandDeep)
        draw(attr(title, font(34, .bold), ink), x: x + 42, top: top + 134, width: 400)
        draw(attr(body, font(25, .regular), inkSub, lineHeight: 1.4), x: x + 42, top: top + 186, width: 400)
    }
    draw(attr("Apple silicon + Intel · requires macOS 13 or later",
              font(28, .medium), inkSub, align: .center), x: 0, top: 1198, width: W)
    pageTag(5, 6)
}

// MARK: - 6 Get it

card("06-get") {
    gradientBG(NSColor(srgbRed: 0.10, green: 0.15, blue: 0.40, alpha: 1),
               NSColor(srgbRed: 0.22, green: 0.45, blue: 0.92, alpha: 1))
    appIcon(cx: W / 2, cyTop: 260, size: 200)
    draw(attr("MicPin", font(74, .bold), .white, spacing: 1, align: .center), x: 0, top: 396, width: W)
    draw(attr("Free and open source. Take it.", font(34, .regular),
              NSColor(white: 1, alpha: 0.8), align: .center), x: 0, top: 494, width: W)

    let steps = [("1", "Search MicPin on GitHub, grab the zip"),
                 ("2", "Drag MicPin.app into Applications"),
                 ("3", "Right-click → Open, enable Launch at login")]
    var top: CGFloat = 610
    for (n, t) in steps {
        roundRect(NSRect(x: 90, y: H - top - 118, width: W - 180, height: 118), 28,
                  fill: NSColor(white: 1, alpha: 0.13))
        let c = NSRect(x: 128, y: H - top - 88, width: 58, height: 58)
        roundRect(c, 29, fill: gold)
        draw(attr(n, font(30, .bold), NSColor(srgbRed: 0.15, green: 0.18, blue: 0.35, alpha: 1),
                  align: .center), x: 128, top: top + 38, width: 58)
        draw(attr(t, font(30, .regular), .white), x: 218, top: top + 40, width: 720)
        top += 140
    }

    roundRect(NSRect(x: 90, y: H - 1200, width: W - 180, height: 124), 28, fill: nil,
              stroke: NSColor(white: 1, alpha: 0.35), lw: 3)
    drawSymbol("chevron.left.forwardslash.chevron.right", cx: 168, cyTop: 1138, size: 36, color: .white)
    draw(attr("github.com/bethlehem1989-tech/MicPin", font(29, .medium), .white),
         x: 218, top: 1096, width: 760)
    draw(attr("Questions? Drop them in the comments", font(24, .regular),
              NSColor(white: 1, alpha: 0.6)), x: 218, top: 1146, width: 760)
    pageTag(6, 6, light: true)
}
