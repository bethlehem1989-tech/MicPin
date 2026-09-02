#!/bin/bash
# 生成可拖拽安装的 MicPin.dmg
set -e
cd "$(dirname "$0")"

VOL="MicPin"
DMG_TMP="build/dmg-tmp"
DMG_OUT="build/MicPin-1.0.dmg"
APP="build/MicPin.app"

[ -d "$APP" ] || { echo "先运行 ./build.sh"; exit 1; }

# build.sh 每次都会清空 build/，背景图要在这里重新生成
swiftc -O -o build/makedmgbg Tools/MakeDMGBackground.swift -framework AppKit
build/makedmgbg
rm -f build/makedmgbg

rm -rf "$DMG_TMP" "$DMG_OUT"
mkdir -p "$DMG_TMP/.background"
cp -R "$APP" "$DMG_TMP/"
cp build/dmg-bg.png "$DMG_TMP/.background/bg.png"
ln -s /Applications "$DMG_TMP/Applications"

# 先造一个可写的临时 dmg 摆图标位置
hdiutil create -volname "$VOL" -srcfolder "$DMG_TMP" -ov -format UDRW "build/tmp.dmg" >/dev/null
MOUNT_DIR=$(hdiutil attach "build/tmp.dmg" -readwrite -noverify -noautoopen | grep -Eo '/Volumes/.+' | head -1)

osascript <<OSA
tell application "Finder"
  tell disk "$VOL"
    open
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {400, 200, 1060, 600}
    set viewOptions to the icon view options of container window
    set arrangement of viewOptions to not arranged
    set icon size of viewOptions to 108
    set background picture of viewOptions to file ".background:bg.png"
    set position of item "MicPin.app" of container window to {170, 220}
    set position of item "Applications" of container window to {490, 220}
    close
    open
    update without registering applications
    delay 1
  end tell
end tell
OSA

chmod -Rf go-w "$MOUNT_DIR" 2>/dev/null || true
sync
hdiutil detach "$MOUNT_DIR" >/dev/null
hdiutil convert "build/tmp.dmg" -format UDZO -imagekey zlib-level=9 -o "$DMG_OUT" >/dev/null
rm -f "build/tmp.dmg"
rm -rf "$DMG_TMP"

echo "Built: $DMG_OUT"
