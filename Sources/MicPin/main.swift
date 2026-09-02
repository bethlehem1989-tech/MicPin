import AppKit
import CoreAudio

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    let engine = Engine()
    var statusItem: NSStatusItem!

    func applicationDidFinishLaunching(_ note: Notification) {
        // 防止开机自启和手动打开各起一个实例
        let me = ProcessInfo.processInfo.processIdentifier
        let others = NSRunningApplication.runningApplications(
            withBundleIdentifier: Bundle.main.bundleIdentifier ?? "com.william.micpin")
            .filter { $0.processIdentifier != me }
        if !others.isEmpty { NSApp.terminate(nil); return }

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu

        engine.onChange = { [weak self] switched in
            guard let self else { return }
            self.refreshStatusItem()
            if let d = switched, self.engine.config.showHUD {
                HUD.shared.show(title: d.name,
                                subtitle: L10n.hudLocked(d.transportName),
                                symbol: "mic.fill")
            }
        }
        engine.start()
        refreshStatusItem()
    }

    // MARK: - 菜单栏图标

    func refreshStatusItem() {
        guard let button = statusItem.button else { return }
        let cfg = engine.config
        let cur = engine.currentInput
        let tgt = engine.target

        let symbol: String
        if !cfg.enabled { symbol = "mic.slash" }
        else if let tgt, cur?.id == tgt.id { symbol = "mic.fill" }
        else { symbol = "mic" }

        button.image = NSImage(systemSymbolName: symbol, accessibilityDescription: "MicPin")
        button.image?.isTemplate = true
        button.title = cfg.showNameInMenuBar ? " " + short(cur?.name ?? L10n.menuBarNoInput) : ""
        button.font = .systemFont(ofSize: 12)
        button.toolTip = L10n.tooltip + (cur?.name ?? L10n.none)
    }

    private func short(_ s: String) -> String {
        s.count <= 14 ? s : String(s.prefix(13)) + "…"
    }

    // MARK: - 菜单

    func menuWillOpen(_ menu: NSMenu) {
        engine.reconcile()
        rebuild(menu)
    }

    private func rebuild(_ menu: NSMenu) {
        menu.removeAllItems()
        let cfg = engine.config

        // 当前状态
        let cur = engine.currentInput
        let head = NSMenuItem(title: L10n.currentInput(cur?.name ?? L10n.none), action: nil, keyEquivalent: "")
        head.isEnabled = false
        head.image = NSImage(systemSymbolName: cfg.enabled ? "checkmark.seal.fill" : "pause.circle",
                             accessibilityDescription: nil)
        menu.addItem(head)

        let stateText: String
        if !cfg.enabled { stateText = L10n.paused }
        else if cfg.mode == "pinned" {
            let name = cfg.pinnedName ?? L10n.none
            stateText = engine.target == nil ? L10n.pinnedOffline(name) : L10n.pinned(name)
        } else if let t = engine.target {
            stateText = L10n.autoPreferring(t.name, t.transportName)
        } else {
            stateText = L10n.autoNoUSB
        }
        let sub = NSMenuItem(title: stateText, action: nil, keyEquivalent: "")
        sub.isEnabled = false
        sub.attributedTitle = NSAttributedString(string: stateText, attributes: [
            .font: NSFont.systemFont(ofSize: 11),
            .foregroundColor: NSColor.secondaryLabelColor])
        menu.addItem(sub)

        menu.addItem(.separator())
        menu.addItem(section(L10n.sectionPick))

        let auto = NSMenuItem(title: L10n.autoItem,
                              action: #selector(chooseAuto), keyEquivalent: "")
        auto.target = self
        auto.state = cfg.mode == "auto" ? .on : .off
        menu.addItem(auto)

        for d in engine.devices where !d.isVirtual {
            let item = NSMenuItem(title: d.name, action: #selector(choosePinned(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = d.uid
            item.state = (cfg.mode == "pinned" && cfg.pinnedUID == d.uid) ? .on : .off
            item.attributedTitle = NSAttributedString(string: "\(d.name)  ·  \(d.transportName)",
                attributes: [.font: NSFont.systemFont(ofSize: 13)])
            if d.id == engine.currentInput?.id {
                item.image = NSImage(systemSymbolName: "waveform", accessibilityDescription: nil)
            }
            menu.addItem(item)
        }
        // 固定的设备当前不在线时，也要能看到并取消
        if cfg.mode == "pinned", let uid = cfg.pinnedUID,
           !engine.devices.contains(where: { $0.uid == uid }) {
            let item = NSMenuItem(title: L10n.offlineSuffix(cfg.pinnedName ?? uid),
                                  action: #selector(choosePinned(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = uid
            item.state = .on
            menu.addItem(item)
        }

        menu.addItem(.separator())
        menu.addItem(toggle(L10n.toggleEnabled, #selector(toggleEnabled), cfg.enabled))
        menu.addItem(toggle(L10n.toggleHUD, #selector(toggleHUD), cfg.showHUD))
        menu.addItem(toggle(L10n.toggleName, #selector(toggleName), cfg.showNameInMenuBar))
        menu.addItem(toggle(L10n.toggleLogin, #selector(toggleLogin), LoginItem.isEnabled))

        menu.addItem(.separator())
        let check = NSMenuItem(title: L10n.recheck, action: #selector(recheck), keyEquivalent: "r")
        check.target = self
        menu.addItem(check)
        let sound = NSMenuItem(title: L10n.openSound, action: #selector(openSound), keyEquivalent: "")
        sound.target = self
        menu.addItem(sound)
        let quit = NSMenuItem(title: L10n.quit, action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    private func section(_ t: String) -> NSMenuItem {
        let i = NSMenuItem(title: t, action: nil, keyEquivalent: "")
        i.isEnabled = false
        i.attributedTitle = NSAttributedString(string: t, attributes: [
            .font: NSFont.systemFont(ofSize: 11, weight: .semibold),
            .foregroundColor: NSColor.secondaryLabelColor])
        return i
    }

    private func toggle(_ title: String, _ action: Selector, _ on: Bool) -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: "")
        i.target = self
        i.state = on ? .on : .off
        return i
    }

    // MARK: - 动作

    @objc private func chooseAuto() {
        engine.config.mode = "auto"
        engine.config.pinnedUID = nil
        engine.config.pinnedName = nil
        engine.reconcile()
    }

    @objc private func choosePinned(_ sender: NSMenuItem) {
        guard let uid = sender.representedObject as? String else { return }
        if engine.config.mode == "pinned" && engine.config.pinnedUID == uid {
            chooseAuto(); return          // 再点一次 = 取消固定
        }
        engine.config.mode = "pinned"
        engine.config.pinnedUID = uid
        engine.config.pinnedName = engine.devices.first { $0.uid == uid }?.name
        engine.reconcile()
    }

    @objc private func toggleEnabled() {
        engine.config.enabled.toggle()
        engine.reconcile()
        refreshStatusItem()
    }

    @objc private func toggleHUD() {
        engine.config.showHUD.toggle()
        if engine.config.showHUD {
            HUD.shared.show(title: engine.currentInput?.name ?? L10n.hudNoDeviceTitle,
                            subtitle: L10n.hudEnabled,
                            symbol: "mic.fill")
        }
    }

    @objc private func toggleName() {
        engine.config.showNameInMenuBar.toggle()
        refreshStatusItem()
    }

    @objc private func toggleLogin() { LoginItem.set(!LoginItem.isEnabled) }

    @objc private func recheck() {
        engine.reconcile()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self else { return }
            let d = self.engine.currentInput
            HUD.shared.show(title: d?.name ?? L10n.hudNoDeviceTitle,
                            subtitle: d.map { L10n.hudCurrent($0.transportName) } ?? L10n.hudNoDevice,
                            symbol: "mic.fill")
        }
    }

    @objc private func openSound() {
        if let u = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") {
            NSWorkspace.shared.open(u)
        }
    }

    @objc private func quit() { NSApp.terminate(nil) }
}

// MARK: - 开机自启（LaunchAgent）

enum LoginItem {
    static let label = "com.william.micpin"
    static var plistURL: URL {
        URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/LaunchAgents/\(label).plist")
    }

    static var isEnabled: Bool { FileManager.default.fileExists(atPath: plistURL.path) }

    static func set(_ on: Bool) {
        let fm = FileManager.default
        let uid = getuid()
        // 先卸载旧的 launchd 任务，避免残留的 KeepAlive 版本继续把 App 复活
        let unload = Process()
        unload.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        unload.arguments = ["bootout", "gui/\(uid)/\(label)"]
        try? unload.run(); unload.waitUntilExit()

        if on {
            let exec = Bundle.main.executablePath ?? CommandLine.arguments[0]
            let plist = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key><string>\(label)</string>
                <key>ProgramArguments</key><array><string>\(exec)</string></array>
                <key>RunAtLoad</key><true/>
                <key>ProcessType</key><string>Interactive</string>
            </dict>
            </plist>
            """
            try? fm.createDirectory(at: plistURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? plist.write(to: plistURL, atomically: true, encoding: .utf8)
            let load = Process()
            load.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            load.arguments = ["bootstrap", "gui/\(uid)", plistURL.path]
            try? load.run(); load.waitUntilExit()
        } else {
            try? fm.removeItem(at: plistURL)
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)     // 只在菜单栏，不进 Dock
app.run()
