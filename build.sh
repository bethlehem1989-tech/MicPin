#!/bin/bash
# 构建 MicPin.app —— 只需系统自带的 Swift 工具链，无第三方依赖
set -e
cd "$(dirname "$0")"
APP="build/MicPin.app"
rm -rf build && mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

# 1. 生成图标
swiftc -O -o build/makeicon Tools/MakeIcon.swift -framework AppKit
./build/makeicon build/icon.iconset >/dev/null
iconutil -c icns build/icon.iconset -o "$APP/Contents/Resources/MicPin.icns"

# 2. 编译主程序（默认通用二进制：Apple Silicon + Intel，UNIVERSAL=0 可只编本机架构）
SRC="Sources/MicPin/Audio.swift Sources/MicPin/Config.swift Sources/MicPin/L10n.swift
     Sources/MicPin/Engine.swift Sources/MicPin/HUD.swift Sources/MicPin/main.swift"
if [ "${UNIVERSAL:-1}" = "1" ]; then
  for arch in arm64 x86_64; do
    swiftc -O -target $arch-apple-macos13.0 -o "build/MicPin-$arch" $SRC \
      -framework AppKit -framework CoreAudio
  done
  lipo -create build/MicPin-arm64 build/MicPin-x86_64 -output "$APP/Contents/MacOS/MicPin"
  rm -f build/MicPin-arm64 build/MicPin-x86_64
else
  swiftc -O -o "$APP/Contents/MacOS/MicPin" $SRC -framework AppKit -framework CoreAudio
fi

# 3. Info.plist
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>MicPin</string>
    <key>CFBundleDisplayName</key><string>MicPin</string>
    <key>CFBundleIdentifier</key><string>com.william.micpin</string>
    <key>CFBundleExecutable</key><string>MicPin</string>
    <key>CFBundleIconFile</key><string>MicPin</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>LSUIElement</key><true/>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key><array><string>en</string><string>zh-Hans</string></array>
</dict>
</plist>
PLIST

codesign --force --deep --sign - "$APP" 2>/dev/null || true
rm -f build/makeicon
echo "Built: $APP"
