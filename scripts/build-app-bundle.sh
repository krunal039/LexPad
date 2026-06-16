#!/usr/bin/env bash
# Build LexPad.app bundle with embedded Scintilla + Lexilla for distribution.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="LexPad"
VERSION="0.3.0"
BUILD_NUMBER="3"
BUILD_CONFIG="${1:-release}"

cd "$ROOT/LexPad"
echo "==> Building LexPad ($BUILD_CONFIG)"
swift build -c "$BUILD_CONFIG" --product LexPad

LEXPAD_BUILD_CONFIG="$BUILD_CONFIG" "$ROOT/scripts/stage-runtime-libs.sh"

BIN_DIR="$(swift build -c "$BUILD_CONFIG" --show-bin-path)"
BIN="$BIN_DIR/LexPad"
APP_DIR="$ROOT/dist/${APP_NAME}.app"
CONTENTS="$APP_DIR/Contents"
MACOS="$CONTENTS/MacOS"
FRAMEWORKS="$CONTENTS/Frameworks"
RESOURCES="$CONTENTS/Resources"

echo "==> Generating app icon"
swift "$ROOT/scripts/generate-app-icon.swift" "$ROOT"

echo "==> Assembling $APP_DIR"
rm -rf "$APP_DIR"
mkdir -p "$MACOS" "$FRAMEWORKS" "$RESOURCES"

cp "$BIN" "$MACOS/$APP_NAME"
cp -R "$BIN_DIR/Scintilla.framework" "$FRAMEWORKS/"
cp "$BIN_DIR/liblexilla.dylib" "$FRAMEWORKS/"
cp "$ROOT/packaging/LexPad.icns" "$RESOURCES/AppIcon.icns"

echo "==> Bundling Help documentation"
mkdir -p "$RESOURCES/Help"
cp "$ROOT/docs/GETTING_STARTED.md" "$RESOURCES/Help/"
cp "$ROOT/docs/USER_GUIDE.md" "$RESOURCES/Help/"
cp "$ROOT/docs/SHORTCUTS.md" "$RESOURCES/Help/"
cp "$ROOT/docs/LICENSES.md" "$RESOURCES/Help/"
cp "$ROOT/CHANGELOG.md" "$RESOURCES/Help/CHANGELOG.md"
cp "$ROOT/README.md" "$RESOURCES/Help/README.md"

install_name_tool -change '@loader_path/liblexilla.dylib' '@executable_path/../Frameworks/liblexilla.dylib' "$MACOS/$APP_NAME" 2>/dev/null || true
install_name_tool -add_rpath '@executable_path/../Frameworks' "$MACOS/$APP_NAME" 2>/dev/null || true

cat > "$CONTENTS/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>LexPad</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.codetails.lexpad</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>LexPad</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeRole</key>
            <string>Editor</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.plain-text</string>
                <string>public.source-code</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST

SIGN_ID="${CODESIGN_IDENTITY:--}"
echo "==> Re-signing app bundle (identity: $SIGN_ID)"
codesign --force --sign "$SIGN_ID" "$FRAMEWORKS/liblexilla.dylib"
codesign --force --sign "$SIGN_ID" "$FRAMEWORKS/Scintilla.framework"
codesign --force --deep --sign "$SIGN_ID" "$APP_DIR"

echo "==> Done: $APP_DIR"
echo "    Open with: open \"$APP_DIR\""
echo "    Notarize:  ./scripts/notarize-app.sh"
