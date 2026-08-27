<p align="center">
  <img src="docs/icon.png" width="128" alt="MicPin">
</p>

<h1 align="center">MicPin</h1>

<p align="center">
  让 macOS 一直用你想用的那个麦克风。<br>
  <a href="README.md">English</a>
</p>

---

macOS 特别喜欢退回内置麦克风：插上 USB 麦克风，它还在用 MacBook 自带的；戴上蓝牙耳机，
输入又跳到耳机麦克风上——哪怕你只是想用耳机听声音。

**MicPin** 是一个常驻菜单栏的小程序，专治这个问题。插上 USB 麦克风，它立刻成为系统输入设备，
每次都是。所有跟随「系统默认输入」的软件——听写、Typeless 这类语音输入 App、飞书、Zoom、腾讯会议——
自然就拿到了正确的麦克风。

- **零配置**：插上 USB 麦克风就赢。
- **不怕蓝牙**：戴 AirPods 听歌，输入不会被拖到耳机麦克风上。
- **可以固定某一个**：同时插两个麦克风时，指定用哪个，它就一直是哪个。
- **看得见**：菜单栏显示当前麦克风，切换时右上角弹提示条确认。
- **中英双语**，跟随系统语言。
- 不申请麦克风权限、不需要辅助功能授权、不联网，常驻内存几 MB。

## 菜单里有什么

| | |
|---|---|
| **当前输入：NEOM USB** | 下面一行状态：在自动优先谁、固定了谁、固定的设备是否未连接 |
| **锁定哪一个麦克风** | `自动（优先外接 USB 麦克风）`，以及所有在线输入设备，标注 USB / 内置 / 蓝牙。点一下固定用它，再点一下回到自动 |
| `启用自动锁定` | 临时就想用内置麦克风时关掉 |
| `切换时显示提示条` | 右上角的确认浮窗 |
| `菜单栏显示设备名` | 只留图标，或图标加名字 |
| `开机自动启动` | |
| `立即重新检测` | 同时弹一次提示条——开口说话前确认一下用的是哪个麦克风 |

菜单栏图标：**实心话筒** = 已锁定在目标设备 · **空心话筒** = 已启用但当前没有 USB 麦克风（保持系统原样） · **划线话筒** = 已暂停。

## 两种模式

- **自动**：按 `preferred` 关键字顺序匹配，都不在线就挑任意一个 USB 输入设备。
  内置、蓝牙、虚拟声卡（Teams、Krisp、BlackHole 等）永远不会被主动选中。
- **固定**：你指定了某个设备。它没连接时 MicPin 不会退而求其次，保持系统当前设置不动。

## 安装

从 [Releases](../../releases) 下载 `MicPin.app`，拖进 `/Applications`，打开即可。

没有做公证签名，首次打开需要执行下面任一操作：

```bash
xattr -dr com.apple.quarantine /Applications/MicPin.app
```

……或者右键点 App →**打开**→**打开**。

### 从源码编译

只需要 Xcode 命令行工具，没有任何第三方依赖，不用包管理器。

```bash
git clone https://github.com/bethlehem1989-tech/MicPin.git
cd MicPin && ./build.sh
cp -R build/MicPin.app /Applications/ && open -a /Applications/MicPin.app
```

## 配置

菜单里的每一次操作都会写入 `~/.config/micpin/config.json`。手动改这个文件也行，每次检测都会重新读取。

| 字段 | 含义 |
|---|---|
| `enabled` | 总开关 |
| `mode` | `auto` 或 `pinned` |
| `pinnedUID` / `pinnedName` | 固定模式下的目标设备 |
| `preferred` | 自动模式的优先级关键字，按顺序命中（包含匹配，不区分大小写） |
| `blocked` | 永不选用的关键字（虚拟声卡） |
| `autoPickUSB` | `preferred` 都不在线时，是否自动挑任意 USB 麦克风 |
| `showHUD` | 切换时弹提示条 |
| `showNameInMenuBar` | 菜单栏图标旁显示设备名 |

例子——优先 Shure，其次 Yeti，再不行任意 USB 麦克风：

```json
{
  "preferred": ["Shure", "Yeti"],
  "autoPickUSB": true
}
```

## 原理

在 `kAudioHardwarePropertyDevices` 和 `kAudioHardwarePropertyDefaultInputDevice` 上挂 CoreAudio
属性监听，再加 3 秒兜底巡检（蓝牙 HFP 切换不一定发通知）。发现目标设备不是当前默认输入，就写
`kAudioHardwarePropertyDefaultInputDevice`。全部机关就这一处——它从不打开音频流，所以 macOS
永远不会向你索要麦克风权限。

六个文件、约 700 行 Swift，只用 AppKit 和 CoreAudio。

## 许可证

MIT
