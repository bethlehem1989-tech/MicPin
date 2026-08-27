import Foundation

struct Config: Codable {
    /// 总开关
    var enabled = true
    /// "auto"：按 preferred/USB 自动挑；"pinned"：固定用 pinnedUID 那一个
    var mode = "auto"
    var pinnedUID: String? = nil
    var pinnedName: String? = nil

    /// 自动模式下的优先级关键字（按顺序命中）
    var preferred: [String] = []
    /// 永不选用
    var blocked: [String] = ["LarkAudioDevice", "BlackHole", "Loopback", "Soundflower",
                             "ZoomAudioDevice", "Microsoft Teams Audio", "Krisp", "VB-Cable", "豆包"]
    /// preferred 未命中时，自动挑任意 USB 麦克风
    var autoPickUSB = true

    /// 切换时在屏幕右上角弹提示
    var showHUD = true
    /// 菜单栏图标旁显示设备名
    var showNameInMenuBar = true

    static let url = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent(".config/micpin/config.json")

    // 向前兼容：任何缺失字段都用默认值
    init() {}
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        func v<T: Decodable>(_ k: CodingKeys, _ d: T) -> T { (try? c.decode(T.self, forKey: k)) ?? d }
        enabled = v(.enabled, true)
        mode = v(.mode, "auto")
        pinnedUID = try? c.decode(String.self, forKey: .pinnedUID)
        pinnedName = try? c.decode(String.self, forKey: .pinnedName)
        preferred = v(.preferred, [])
        blocked = v(.blocked, Config().blocked)
        autoPickUSB = v(.autoPickUSB, true)
        showHUD = v(.showHUD, true)
        showNameInMenuBar = v(.showNameInMenuBar, true)
    }

    static func load() -> Config {
        guard let data = try? Data(contentsOf: url),
              let c = try? JSONDecoder().decode(Config.self, from: data) else {
            let c = Config(); c.save(); return c
        }
        return c
    }

    func save() {
        try? FileManager.default.createDirectory(at: Config.url.deletingLastPathComponent(),
                                                 withIntermediateDirectories: true)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        if let d = try? enc.encode(self) { try? d.write(to: Config.url) }
    }
}
