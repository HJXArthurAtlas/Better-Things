#!/bin/bash
# 构建 Better Things（Release）并打包可分发的 dmg。
#
# 用法:
#   scripts/build-dmg.sh
#
# 分发（公证）路径——需要一次性配置：
#   1. Apple Developer Program 的 "Developer ID Application" 证书（钥匙串中）
#   2. 公证凭据档案:
#      xcrun notarytool store-credentials better-things-notary \
#        --apple-id <apple-id> --team-id <team-id> --password <app-specific-password>
# 配置后脚本自动走 签名 → 公证 → 装订 流程；
# 未配置时使用 ad-hoc 签名产出本机可用的 dmg（不可对外分发）。
set -euo pipefail
cd "$(dirname "$0")/.."

APP_NAME="Better Things"
CONFIG=Release
VERSION=$(grep -o 'CFBundleShortVersionString: "[^"]*"' project.yml | head -1 | sed 's/.*"\([^"]*\)".*/\1/')

echo "==> 构建 $CONFIG"
xcodebuild -project Better-Things.xcodeproj -scheme "$APP_NAME" -configuration "$CONFIG" build >/dev/null

BUILD_DIR=$(xcodebuild -project Better-Things.xcodeproj -scheme "$APP_NAME" -configuration "$CONFIG" -showBuildSettings 2>/dev/null \
  | awk '/ BUILT_PRODUCTS_DIR/{print $3; exit}')
APP="$BUILD_DIR/$APP_NAME.app"
echo "==> 产物: $APP"

echo "==> 代码签名"
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null | grep "Developer ID Application" | head -1 | sed -E 's/.*"([^"]+)".*/\1/' || true)
if [ -n "${IDENTITY:-}" ]; then
  codesign --force --deep --options runtime --identity "$IDENTITY" "$APP"
  echo "    Developer ID 签名: $IDENTITY"
else
  codesign --force --deep -s - "$APP"
  echo "    未找到 Developer ID 证书，使用 ad-hoc 签名（仅本机可用，不可对外分发）"
fi

echo "==> 打包 dmg"
STAGING=$(mktemp -d)
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
DMG="Better-Things-$VERSION.dmg"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

if [ -n "${IDENTITY:-}" ]; then
  echo "==> 公证 (notarytool，可能需要数分钟)"
  xcrun notarytool submit "$DMG" --keychain-profile better-things-notary --wait
  xcrun stapler staple "$DMG"
  echo "    已公证并装订票据"
else
  echo "==> 跳过公证（未配置 better-things-notary 凭据档案）"
fi

echo "==> 完成: $DMG"
