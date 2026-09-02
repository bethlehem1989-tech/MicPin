import AppKit

// 小红书图文卡片生成器 1080x1440
let W: CGFloat = 1080, H: CGFloat = 1440

let brandDeep = NSColor(srgbRed: 0.16, green: 0.28, blue: 0.86, alpha: 1)
let brandLite = NSColor(srgbRed: 0.36, green: 0.66, blue: 1.00, alpha: 1)
let ink       = NSColor(srgbRed: 0.09, green: 0.11, blue: 0.16, alpha: 1)
let inkSub    = NSColor(srgbRed: 0.42, green: 0.45, blue: 0.52, alpha: 1)
let paper     = NSColor(srgbRed: 0.965, green: 0.969, blue: 0.98, alpha: 1)

func font(_ size: CGFloat, _ weight: String = "Semibold") -> NSFont {
    NSFont(name: "PingFangSC-\(weight)", size: size) ?? .systemFont(ofSize: size)
}

func attr(_ s: String, _ f: NSFont, _ c: NSColor, spacing: CGFloat = 0, align: NSTextAlignment = .left,
          lineHeight: CGFloat = 1.35) -> NSAttributedString {
    let p = NSMutableParagraphStyle()
    p.alignment = align
    p.lineHeightMultiple = lineHeight
    return NSAttributedString(string: s, attributes: [
        .font: f, .foregroundColor: c, .kern: spacing, .paragraphStyle: p])
}

/// 以左上角为原点绘制文本，返回占用高度
@discardableResult
func draw(_ a: NSAttributedString, x: CGFloat, top: CGFloat, width: CGFloat) -> CGFloat {
    let h = a.boundingRect(with: NSSize(width: width, height: 9999),
                           options: [.usesLineFragmentOrigin, .usesFontLeading]).height + 6
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
    sh.set()
    body()
    NSGraphicsContext.restoreGraphicsState()
}

func symbolImage(_ name: String, size: CGFloat, color: NSColor, weight: NSFont.Weight = .semibold) -> NSImage? {
    guard let base = NSImage(systemSymbolName: name, accessibilityDescription: nil)?
        .withSymbolConfiguration(.init(pointSize: size, weight: weight)) else { return nil }
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
    let g = NSGradient(starting: top, ending: bottom)!
    g.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -75)
}

func card(_ name: String, _ body: () -> Void) {
    let img = NSImage(size: NSSize(width: W, height: H))
    img.lockFocus()
    body()
    img.unlockFocus()
    guard let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
          let data = rep.representation(using: .png, properties: [:]) else { return }
    try? FileManager.default.createDirectory(atPath: "build/xhs", withIntermediateDirectories: true)
    try? data.write(to: URL(fileURLWithPath: "build/xhs/\(name).png"))
    print("build/xhs/\(name).png")
}

// MARK: - 复用组件

/// App 图标（简化版，与真实图标一致）
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

/// 页码标签
func pageTag(_ n: Int, _ total: Int, light: Bool = false) {
    let t = attr("\(n) / \(total)", font(30, "Medium"),
                 light ? NSColor(white: 1, alpha: 0.55) : inkSub, align: .right)
    draw(t, x: W - 380, top: H - 96, width: 300)
}

// MARK: - 1 封面

card("01-cover") {
    gradientBG(NSColor(srgbRed: 0.10, green: 0.15, blue: 0.40, alpha: 1),
               NSColor(srgbRed: 0.22, green: 0.45, blue: 0.92, alpha: 1))
    let gold = NSColor(srgbRed: 1, green: 0.83, blue: 0.35, alpha: 1)

    // 顶部：我写了一个 Mac 小工具 + 开源徽章
    let pill = NSRect(x: 80, y: H - 186, width: 452, height: 76)
    roundRect(pill, 38, fill: NSColor(white: 1, alpha: 0.16))
    draw(attr("我写了一个 Mac 小工具", font(34, "Medium"), .white, align: .center),
         x: 80, top: 128, width: 452)

    let badge = NSRect(x: 556, y: H - 186, width: 236, height: 76)
    roundRect(badge, 38, fill: gold)
    drawSymbol("chevron.left.forwardslash.chevron.right", cx: 608, cyTop: 148, size: 30,
               color: NSColor(srgbRed: 0.12, green: 0.16, blue: 0.34, alpha: 1))
    draw(attr("开源", font(38), NSColor(srgbRed: 0.12, green: 0.16, blue: 0.34, alpha: 1)),
         x: 646, top: 128, width: 120)

    // 主标题：最大的一行
    draw(attr("把麦克风", font(168), .white, spacing: 4), x: 80, top: 268, width: 960)
    let hero = NSMutableAttributedString(attributedString:
        attr("彻底", font(168), .white, spacing: 4))
    hero.append(attr("钉死", font(168), gold, spacing: 4))
    draw(hero, x: 80, top: 470, width: 960)

    draw(attr("插上 USB 麦克风，系统还在用内置的？\n戴上蓝牙耳机它又自己跳走",
              font(38, "Regular"), NSColor(white: 1, alpha: 0.78), lineHeight: 1.5),
         x: 80, top: 792, width: 960)

    appIcon(cx: W / 2, cyTop: 1090, size: 226)

    draw(attr("MicPin", font(60), .white, spacing: 2, align: .center), x: 0, top: 1232, width: W)
    draw(attr("插上就自动用它 · 也能手动固定某一个", font(32, "Regular"),
              NSColor(white: 1, alpha: 0.75), align: .center), x: 0, top: 1326, width: W)
}

// MARK: - 2 痛点

card("02-pain") {
    paper.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
    draw(attr("这三件事，你是不是也天天在做", font(58), ink), x: 80, top: 130, width: 940)
    draw(attr("macOS 的默认输入设备，永远在往内置麦克风退",
              font(34, "Regular"), inkSub), x: 80, top: 224, width: 940)

    let items: [(String, String, String)] = [
        ("headphones", "戴上蓝牙耳机", "只想用它听歌，输入却被拖去了耳机麦克风，说话像隔了一层棉被"),
        ("cable.connector", "插上 USB 麦克风", "系统纹丝不动，还在用 MacBook 自带的那个"),
        ("hand.tap", "每次语音输入前", "都要点开设置确认一遍：现在到底在用哪个麦克风？"),
    ]
    var top: CGFloat = 320
    for (sym, title, body) in items {
        let r = NSRect(x: 70, y: H - top - 268, width: W - 140, height: 250)
        shadowed(26, 0.16) { roundRect(r, 34, fill: .white) }
        let badge = NSRect(x: 118, y: H - top - 132, width: 92, height: 92)
        roundRect(badge, 26, fill: NSColor(srgbRed: 0.93, green: 0.95, blue: 1, alpha: 1))
        drawSymbol(sym, cx: badge.midX, cyTop: top + 86, size: 46, color: brandDeep)
        draw(attr(title, font(46), ink), x: 244, top: top + 46, width: 700)
        draw(attr(body, font(32, "Regular"), inkSub, lineHeight: 1.45), x: 244, top: top + 116, width: 700)
        top += 288
    }
    draw(attr("一次两次还行，一天十次就想砸电脑", font(38, "Medium"),
              NSColor(srgbRed: 0.90, green: 0.28, blue: 0.35, alpha: 1), align: .center),
         x: 0, top: 1234, width: W)
    pageTag(2, 6)
}

// MARK: - 3 解法：菜单栏

card("03-menu") {
    gradientBG(NSColor(srgbRed: 0.13, green: 0.15, blue: 0.22, alpha: 1),
               NSColor(srgbRed: 0.20, green: 0.24, blue: 0.36, alpha: 1))
    draw(attr("现在它常驻在菜单栏", font(58), .white), x: 80, top: 120, width: 940)
    draw(attr("一眼看到当前用的是哪个麦克风", font(34, "Regular"),
              NSColor(white: 1, alpha: 0.62)), x: 80, top: 210, width: 940)

    // 仿菜单栏
    let bar = NSRect(x: 70, y: H - 358, width: W - 140, height: 74)
    roundRect(bar, 20, fill: NSColor(white: 1, alpha: 0.10))
    drawSymbol("mic.fill", cx: 560, cyTop: 321, size: 30, color: .white)
    draw(attr("NEOM USB", font(30, "Medium"), .white), x: 588, top: 302, width: 240)
    for (i, s) in ["wifi", "battery.100", "magnifyingglass"].enumerated() {
        drawSymbol(s, cx: 838 + CGFloat(i) * 62, cyTop: 321, size: 26, color: NSColor(white: 1, alpha: 0.5))
    }
    // 高亮指示
    roundRect(NSRect(x: 532, y: H - 352, width: 258, height: 62), 16, fill: nil,
              stroke: NSColor(srgbRed: 1, green: 0.83, blue: 0.35, alpha: 1), lw: 4)

    // 下拉菜单
    let menu = NSRect(x: 150, y: H - 1245, width: 780, height: 860)
    shadowed(40, 0.5) { roundRect(menu, 30, fill: NSColor(srgbRed: 0.19, green: 0.20, blue: 0.24, alpha: 1)) }

    var y: CGFloat = 420
    draw(attr("当前输入：NEOM USB", font(38), .white), x: 200, top: y, width: 680)
    y += 58
    draw(attr("自动优先：NEOM USB（USB）", font(28, "Regular"),
              NSColor(white: 1, alpha: 0.5)), x: 200, top: y, width: 680)
    y += 76
    roundRect(NSRect(x: 178, y: H - y - 2, width: 724, height: 2), 1, fill: NSColor(white: 1, alpha: 0.12))
    y += 30
    draw(attr("锁定哪一个麦克风", font(26, "Medium"), NSColor(white: 1, alpha: 0.45), spacing: 1),
         x: 200, top: y, width: 680)
    y += 58

    let devices: [(String, String, Bool)] = [
        ("自动（优先外接 USB 麦克风）", "", true),
        ("NEOM USB", "USB", false),
        ("MacBook Pro麦克风", "内置", false),
        ("AirPods Pro", "蓝牙", false),
        ("Studio Display麦克风", "USB", false),
    ]
    for (name, tag, checked) in devices {
        if checked {
            roundRect(NSRect(x: 178, y: H - y - 56, width: 724, height: 66), 14,
                      fill: NSColor(srgbRed: 0.24, green: 0.42, blue: 0.95, alpha: 1))
            drawSymbol("checkmark", cx: 212, cyTop: y + 22, size: 26, color: .white)
        }
        draw(attr(name, font(32, "Regular"), checked ? .white : NSColor(white: 1, alpha: 0.9)),
             x: 246, top: y, width: 500)
        if !tag.isEmpty {
            let tw: CGFloat = 108
            roundRect(NSRect(x: 780, y: H - y - 44, width: tw, height: 44), 12,
                      fill: NSColor(white: 1, alpha: 0.13))
            draw(attr(tag, font(24, "Medium"), NSColor(white: 1, alpha: 0.75), align: .center),
                 x: 780, top: y + 8, width: tw)
        }
        y += 76
    }
    y += 14
    roundRect(NSRect(x: 178, y: H - y - 2, width: 724, height: 2), 1, fill: NSColor(white: 1, alpha: 0.12))
    y += 26
    for (t, on) in [("启用自动锁定", true), ("切换时显示提示条", true), ("开机自动启动", true)] {
        if on { drawSymbol("checkmark", cx: 212, cyTop: y + 20, size: 24, color: .white) }
        draw(attr(t, font(30, "Regular"), NSColor(white: 1, alpha: 0.85)), x: 246, top: y, width: 600)
        y += 62
    }

    draw(attr("点一下就固定用它，再点一下回到自动", font(34, "Medium"),
              NSColor(srgbRed: 1, green: 0.83, blue: 0.35, alpha: 1), align: .center),
         x: 0, top: 1300, width: W)
    pageTag(3, 6, light: true)
}

// MARK: - 4 提示条

card("04-hud") {
    gradientBG(NSColor(srgbRed: 0.10, green: 0.13, blue: 0.30, alpha: 1),
               NSColor(srgbRed: 0.17, green: 0.35, blue: 0.72, alpha: 1))
    draw(attr("语音输入前", font(64), .white), x: 80, top: 130, width: 940)
    draw(attr("右上角告诉你在用哪个麦克风", font(64), .white), x: 80, top: 224, width: 940)
    draw(attr("再也不用心里没底地开口说话", font(36, "Regular"),
              NSColor(white: 1, alpha: 0.72)), x: 80, top: 344, width: 940)

    // 提示条本体（放大）
    let hud = NSRect(x: 130, y: H - 760, width: 820, height: 210)
    shadowed(50, 0.55) {
        roundRect(hud, 42, fill: NSColor(srgbRed: 0.16, green: 0.17, blue: 0.21, alpha: 0.97))
    }
    roundRect(hud, 42, fill: nil, stroke: NSColor(white: 1, alpha: 0.12), lw: 2)
    let ic = NSRect(x: 190, y: H - 700, width: 100, height: 100)
    roundRect(ic, 30, fill: NSColor(srgbRed: 0.24, green: 0.42, blue: 0.95, alpha: 1))
    drawSymbol("mic.fill", cx: ic.midX, cyTop: 650, size: 52, color: .white)
    draw(attr("NEOM USB", font(48), .white), x: 326, top: 606, width: 560)
    draw(attr("已锁定为输入麦克风 · USB", font(30, "Regular"),
              NSColor(white: 1, alpha: 0.6)), x: 326, top: 676, width: 560)

    draw(attr("切换麦克风时自动淡入，2 秒后消失\n想随手确认，点菜单里的「立即重新检测」它就出现",
              font(34, "Regular"), NSColor(white: 1, alpha: 0.8), align: .center, lineHeight: 1.55),
         x: 90, top: 850, width: 900)

    // 三个状态图标说明
    let states: [(String, String)] = [
        ("mic.fill", "已锁定"), ("mic", "无USB设备"), ("mic.slash", "已暂停"),
    ]
    for (i, (sym, label)) in states.enumerated() {
        let cx = 240 + CGFloat(i) * 300
        let box = NSRect(x: cx - 90, y: H - 1230, width: 180, height: 180)
        roundRect(box, 40, fill: NSColor(white: 1, alpha: 0.12))
        drawSymbol(sym, cx: cx, cyTop: 1120, size: 60, color: .white)
        draw(attr(label, font(28, "Medium"), NSColor(white: 1, alpha: 0.75), align: .center),
             x: cx - 150, top: 1258, width: 300)
    }
    pageTag(4, 6, light: true)
}

// MARK: - 5 亮点

card("05-features") {
    paper.setFill(); NSRect(x: 0, y: 0, width: W, height: H).fill()
    draw(attr("为什么敢一直挂在后台", font(58), ink), x: 80, top: 130, width: 940)
    draw(attr("它做的事只有一件：改系统默认输入设备", font(34, "Regular"), inkSub),
         x: 80, top: 224, width: 940)

    let feats: [(String, String, String)] = [
        ("lock.open", "不要麦克风权限", "从不打开音频流，\nmacOS 根本不会向它索权"),
        ("bolt.fill", "几 MB 内存", "六个文件、约 700 行 Swift\n只用系统框架"),
        ("arrow.triangle.2.circlepath", "不怕蓝牙抢", "监听 + 3 秒兜底巡检\n被抢走也能自动抢回来"),
        ("globe", "中英双语", "跟随系统语言\n发给外国同事也能用"),
        ("pin.fill", "支持手动固定", "插两个麦克风时\n指定哪个就一直是哪个"),
        ("chevron.left.forwardslash.chevron.right", "完全开源免费", "MIT 协议\n代码全在 GitHub 上"),
    ]
    var i = 0
    for (sym, title, body) in feats {
        let col = CGFloat(i % 2), row = CGFloat(i / 2)
        let x = 70 + col * 480, top = 300 + row * 318
        let r = NSRect(x: x, y: H - top - 300, width: 470, height: 300)
        shadowed(24, 0.14) { roundRect(r, 32, fill: .white) }
        let badge = NSRect(x: x + 44, y: H - top - 122, width: 84, height: 84)
        roundRect(badge, 24, fill: NSColor(srgbRed: 0.93, green: 0.95, blue: 1, alpha: 1))
        drawSymbol(sym, cx: badge.midX, cyTop: top + 80, size: 40, color: brandDeep)
        draw(attr(title, font(38), ink), x: x + 44, top: top + 140, width: 400)
        draw(attr(body, font(27, "Regular"), inkSub, lineHeight: 1.45), x: x + 44, top: top + 200, width: 400)
        i += 1
    }
    draw(attr("Apple 芯片和 Intel 都能跑 · 需要 macOS 13 以上",
              font(30, "Medium"), inkSub, align: .center), x: 0, top: 1282, width: W)
    pageTag(5, 6)
}

// MARK: - 6 结尾

card("06-get") {
    gradientBG(NSColor(srgbRed: 0.11, green: 0.16, blue: 0.42, alpha: 1),
               NSColor(srgbRed: 0.22, green: 0.45, blue: 0.92, alpha: 1))
    appIcon(cx: W / 2, cyTop: 300, size: 220)
    draw(attr("MicPin", font(80), .white, spacing: 2, align: .center), x: 0, top: 442, width: W)
    draw(attr("已经开源，随便拿去用", font(38, "Regular"),
              NSColor(white: 1, alpha: 0.8), align: .center), x: 0, top: 548, width: W)

    let steps = [("1", "GitHub 搜 MicPin，下载 zip"),
                 ("2", "解压拖进「应用程序」"),
                 ("3", "右键打开，勾上「开机自动启动」")]
    var top: CGFloat = 680
    for (n, t) in steps {
        let r = NSRect(x: 90, y: H - top - 128, width: W - 180, height: 128)
        roundRect(r, 30, fill: NSColor(white: 1, alpha: 0.13))
        let c = NSRect(x: 130, y: H - top - 94, width: 62, height: 62)
        roundRect(c, 31, fill: NSColor(srgbRed: 1, green: 0.83, blue: 0.35, alpha: 1))
        draw(attr(n, font(34), NSColor(srgbRed: 0.15, green: 0.18, blue: 0.35, alpha: 1), align: .center),
             x: 130, top: top + 42, width: 62)
        draw(attr(t, font(34, "Regular"), .white), x: 226, top: top + 44, width: 700)
        top += 152
    }

    let box = NSRect(x: 90, y: H - 1290, width: W - 180, height: 130)
    roundRect(box, 30, fill: nil, stroke: NSColor(white: 1, alpha: 0.35), lw: 3)
    drawSymbol("chevron.left.forwardslash.chevron.right", cx: 170, cyTop: 1225, size: 40, color: .white)
    draw(attr("github.com/bethlehem1989-tech/MicPin", font(32, "Medium"), .white),
         x: 222, top: 1178, width: 760)
    draw(attr("不会用的评论区问我", font(26, "Regular"),
              NSColor(white: 1, alpha: 0.6)), x: 222, top: 1232, width: 760)
    pageTag(6, 6, light: true)
}
