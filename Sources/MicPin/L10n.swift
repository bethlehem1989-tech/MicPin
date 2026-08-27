import Foundation
import CoreAudio

/// 极简本地化：跟随系统语言，中文以外一律英文
enum L10n {
    static let isChinese: Bool = {
        guard let lang = Locale.preferredLanguages.first else { return false }
        return lang.hasPrefix("zh")
    }()

    private static func t(_ zh: String, _ en: String) -> String { isChinese ? zh : en }

    // 菜单栏
    static var menuBarNoInput: String { t("无输入", "No input") }
    static var tooltip: String { t("MicPin · 当前输入：", "MicPin · Current input: ") }

    // 状态
    static func currentInput(_ name: String) -> String {
        t("当前输入：\(name)", "Current input: \(name)")
    }
    static var none: String { t("无", "none") }
    static var paused: String { t("自动锁定已暂停", "Auto-lock paused") }
    static func pinned(_ name: String) -> String { t("固定：\(name)", "Pinned: \(name)") }
    static func pinnedOffline(_ name: String) -> String {
        t("固定：\(name)（当前未连接）", "Pinned: \(name) (not connected)")
    }
    static func autoPreferring(_ name: String, _ transport: String) -> String {
        t("自动优先：\(name)（\(transport)）", "Auto: \(name) (\(transport))")
    }
    static var autoNoUSB: String {
        t("自动模式：未发现 USB 麦克风，保持系统设置",
          "Auto: no USB mic found — leaving system default alone")
    }

    // 菜单项
    static var sectionPick: String { t("锁定哪一个麦克风", "Which microphone to lock") }
    static var autoItem: String { t("自动（优先外接 USB 麦克风）", "Automatic (prefer USB mic)") }
    static func offlineSuffix(_ name: String) -> String {
        t("\(name)（未连接）", "\(name) (not connected)")
    }
    static var toggleEnabled: String { t("启用自动锁定", "Enable auto-lock") }
    static var toggleHUD: String { t("切换时显示提示条", "Show HUD when switching") }
    static var toggleName: String { t("菜单栏显示设备名", "Show device name in menu bar") }
    static var toggleLogin: String { t("开机自动启动", "Launch at login") }
    static var recheck: String { t("立即重新检测", "Re-check now") }
    static var openSound: String { t("打开「声音」设置…", "Open Sound Settings…") }
    static var quit: String { t("退出 MicPin", "Quit MicPin") }

    // 提示条
    static func hudLocked(_ transport: String) -> String {
        t("已锁定为输入麦克风 · \(transport)", "Locked as input · \(transport)")
    }
    static func hudCurrent(_ transport: String) -> String {
        t("当前输入麦克风 · \(transport)", "Current input · \(transport)")
    }
    static var hudNoDevice: String { t("未检测到可用麦克风", "No microphone available") }
    static var hudNoDeviceTitle: String { t("无输入设备", "No input device") }
    static var hudEnabled: String {
        t("提示条已开启 · 切换麦克风时会出现", "HUD enabled · shown when the mic switches")
    }

    // 传输类型
    static func transport(_ code: UInt32) -> String {
        switch code {
        case kAudioDeviceTransportTypeUSB: return "USB"
        case kAudioDeviceTransportTypeBuiltIn: return t("内置", "Built-in")
        case kAudioDeviceTransportTypeBluetooth, kAudioDeviceTransportTypeBluetoothLE:
            return t("蓝牙", "Bluetooth")
        case kAudioDeviceTransportTypeVirtual: return t("虚拟", "Virtual")
        case kAudioDeviceTransportTypeAggregate: return t("聚合", "Aggregate")
        case kAudioDeviceTransportTypeThunderbolt: return t("雷雳", "Thunderbolt")
        case kAudioDeviceTransportTypeDisplayPort: return "DisplayPort"
        case kAudioDeviceTransportTypeHDMI: return "HDMI"
        case kAudioDeviceTransportTypeContinuityCaptureWired,
             kAudioDeviceTransportTypeContinuityCaptureWireless:
            return t("接力相机", "Continuity Camera")
        default: return t("其他", "Other")
        }
    }
}
