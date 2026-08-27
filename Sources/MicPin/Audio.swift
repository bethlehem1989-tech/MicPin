import Foundation
import CoreAudio

// MARK: - 设备模型

struct Device: Equatable {
    let id: AudioDeviceID
    let uid: String
    let name: String
    let transport: UInt32
    let inputChannels: Int

    var isUSB: Bool { transport == kAudioDeviceTransportTypeUSB }
    var isBuiltIn: Bool { transport == kAudioDeviceTransportTypeBuiltIn }
    var isBluetooth: Bool {
        transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE
    }
    var isVirtual: Bool { transport == kAudioDeviceTransportTypeVirtual }

    var transportName: String { L10n.transport(transport) }
}

// MARK: - CoreAudio 薄封装

enum CA {
    static func addr(_ selector: AudioObjectPropertySelector,
                     _ scope: AudioObjectPropertyScope = kAudioObjectPropertyScopeGlobal)
        -> AudioObjectPropertyAddress {
        AudioObjectPropertyAddress(mSelector: selector, mScope: scope,
                                   mElement: kAudioObjectPropertyElementMain)
    }

    private static func allDeviceIDs() -> [AudioDeviceID] {
        var a = addr(kAudioHardwarePropertyDevices)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject),
                                             &a, 0, nil, &size) == noErr, size > 0 else { return [] }
        var ids = [AudioDeviceID](repeating: 0, count: Int(size) / MemoryLayout<AudioDeviceID>.size)
        guard AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject),
                                         &a, 0, nil, &size, &ids) == noErr else { return [] }
        return ids
    }

    private static func string(_ id: AudioDeviceID, _ selector: AudioObjectPropertySelector) -> String? {
        var a = addr(selector)
        var size = UInt32(MemoryLayout<CFString?>.size)
        var cf: Unmanaged<CFString>? = nil
        guard AudioObjectGetPropertyData(id, &a, 0, nil, &size, &cf) == noErr,
              let value = cf?.takeUnretainedValue() else { return nil }
        return value as String
    }

    private static func transport(_ id: AudioDeviceID) -> UInt32 {
        var a = addr(kAudioDevicePropertyTransportType)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var t: UInt32 = 0
        AudioObjectGetPropertyData(id, &a, 0, nil, &size, &t)
        return t
    }

    private static func inputChannels(_ id: AudioDeviceID) -> Int {
        var a = addr(kAudioDevicePropertyStreamConfiguration, kAudioObjectPropertyScopeInput)
        var size: UInt32 = 0
        guard AudioObjectGetPropertyDataSize(id, &a, 0, nil, &size) == noErr, size > 0 else { return 0 }
        let ptr = UnsafeMutableRawPointer.allocate(byteCount: Int(size), alignment: 16)
        defer { ptr.deallocate() }
        guard AudioObjectGetPropertyData(id, &a, 0, nil, &size, ptr) == noErr else { return 0 }
        let list = ptr.assumingMemoryBound(to: AudioBufferList.self)
        return UnsafeMutableAudioBufferListPointer(list).reduce(0) { $0 + Int($1.mNumberChannels) }
    }

    /// 所有具备输入通道的设备
    static func inputDevices() -> [Device] {
        allDeviceIDs().compactMap { id in
            let ch = inputChannels(id)
            guard ch > 0 else { return nil }
            let name = string(id, kAudioObjectPropertyName) ?? "未知设备 \(id)"
            let uid = string(id, kAudioDevicePropertyDeviceUID) ?? "id:\(id)"
            return Device(id: id, uid: uid, name: name, transport: transport(id), inputChannels: ch)
        }
    }

    static func defaultInputID() -> AudioDeviceID {
        var a = addr(kAudioHardwarePropertyDefaultInputDevice)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var id: AudioDeviceID = 0
        AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil, &size, &id)
        return id
    }

    @discardableResult
    static func setDefaultInput(_ id: AudioDeviceID) -> Bool {
        var dev = id
        var a = addr(kAudioHardwarePropertyDefaultInputDevice)
        return AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &a, 0, nil,
                                          UInt32(MemoryLayout<AudioDeviceID>.size), &dev) == noErr
    }
}
