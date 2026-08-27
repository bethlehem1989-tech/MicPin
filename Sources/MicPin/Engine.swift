import Foundation
import CoreAudio

/// 负责「该用哪个麦克风」以及把系统默认输入切过去
final class Engine {
    var config = Config.load() { didSet { config.save() } }

    private(set) var devices: [Device] = []
    private(set) var currentInput: Device?
    private(set) var target: Device?

    /// 每次状态刷新后回调（主线程）
    var onChange: ((_ switched: Device?) -> Void)?

    private let queue = DispatchQueue(label: "micpin.engine")
    private var timer: DispatchSourceTimer?

    func start() {
        installListeners()
        let t = DispatchSource.makeTimerSource(queue: queue)
        // 兜底巡检：蓝牙 HFP 切换等场景不一定发通知
        t.schedule(deadline: .now() + 3, repeating: 3)
        t.setEventHandler { [weak self] in self?.reconcile() }
        t.resume()
        timer = t
        reconcile()
    }

    private func installListeners() {
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            // 设备刚插入时通道信息可能还没就绪，稍等一拍
            self?.queue.asyncAfter(deadline: .now() + 0.5) { self?.reconcile() }
        }
        var addrs = [CA.addr(kAudioHardwarePropertyDevices),
                     CA.addr(kAudioHardwarePropertyDefaultInputDevice)]
        for i in addrs.indices {
            AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject),
                                               &addrs[i], queue, block)
        }
    }

    /// 候选设备：有输入通道、非虚拟、不在黑名单
    private func candidates(_ all: [Device]) -> [Device] {
        all.filter { d in
            !d.isVirtual && !config.blocked.contains {
                !$0.isEmpty && d.name.range(of: $0, options: .caseInsensitive) != nil
            }
        }
    }

    func pickTarget(_ all: [Device]) -> Device? {
        let cands = candidates(all)
        if config.mode == "pinned", let uid = config.pinnedUID {
            // 固定设备不在线时不退而求其次，保持系统原样
            return cands.first { $0.uid == uid }
        }
        for key in config.preferred where !key.isEmpty {
            if let d = cands.first(where: { $0.name.range(of: key, options: .caseInsensitive) != nil }) {
                return d
            }
        }
        if config.autoPickUSB, let d = cands.first(where: { $0.isUSB }) { return d }
        return nil
    }

    private var applying = false

    func reconcile() {
        queue.async { [weak self] in
            guard let self, !self.applying else { return }
            self.applying = true
            defer { self.applying = false }

            let all = CA.inputDevices()
            let curID = CA.defaultInputID()
            let tgt = self.pickTarget(all)
            var switched: Device? = nil

            if self.config.enabled, let tgt, tgt.id != curID {
                if CA.setDefaultInput(tgt.id) { switched = tgt }
            }

            let nowID = CA.defaultInputID()
            let cur = all.first { $0.id == nowID }
            DispatchQueue.main.async {
                self.devices = all
                self.currentInput = cur
                self.target = tgt
                self.onChange?(switched)
            }
        }
    }
}
