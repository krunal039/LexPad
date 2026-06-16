#!/usr/bin/env bash
# Copy Scintilla.framework + liblexilla.dylib beside the LexPad binary and fix load paths.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCINTILLA_FW_SRC="$ROOT/Vendor/scintilla/cocoa/Scintilla/build/Release/Scintilla.framework"
LEXILLA_SRC="$ROOT/Vendor/lexilla/bin/liblexilla.dylib"

if [[ ! -d "$SCINTILLA_FW_SRC" ]]; then
  echo "ERROR: Scintilla.framework not found. Run ./scripts/bootstrap.sh first." >&2
  exit 1
fi

if [[ ! -f "$LEXILLA_SRC" ]]; then
  echo "ERROR: liblexilla.dylib not found. Run ./scripts/bootstrap.sh first." >&2
  exit 1
fi

cd "$ROOT/LexPad"
BUILD_CONFIG="${LEXPAD_BUILD_CONFIG:-debug}"
BIN_DIR="$(swift build -c "$BUILD_CONFIG" --show-bin-path 2>/dev/null)"
LEXPAD_BIN="$BIN_DIR/LexPad"

if [[ ! -f "$LEXPAD_BIN" ]]; then
  echo "ERROR: LexPad binary not found at $LEXPAD_BIN — run swift build first." >&2
  exit 1
fi

# Stage every time so rebuilds always get fresh paths.
echo "==> Staging Scintilla + Lexilla next to LexPad ($BIN_DIR)"

rm -rf "$BIN_DIR/Scintilla.framework"
cp -R "$SCINTILLA_FW_SRC" "$BIN_DIR/"
cp -f "$LEXILLA_SRC" "$BIN_DIR/liblexilla.dylib"
chmod +x "$BIN_DIR/liblexilla.dylib"

# @rpath/Scintilla.framework — resolve via @loader_path (same folder as LexPad).
if ! otool -l "$LEXPAD_BIN" | grep -q '@loader_path'; then
  install_name_tool -add_rpath '@loader_path' "$LEXPAD_BIN" 2>/dev/null || true
fi

# liblexilla was linked as ../bin/liblexilla.dylib — point at staged copy.
if otool -L "$LEXPAD_BIN" | grep -q 'liblexilla'; then
  install_name_tool -change '../bin/liblexilla.dylib' '@loader_path/liblexilla.dylib' "$LEXPAD_BIN" 2>/dev/null || \
  install_name_tool -change "$LEXILLA_SRC" '@loader_path/liblexilla.dylib' "$LEXPAD_BIN" 2>/dev/null || true
fi

# Ensure Scintilla.framework internal id uses @rpath (xcodebuild Release usually does).
SCINTILLA_BIN="$BIN_DIR/Scintilla.framework/Versions/A/Scintilla"
if [[ -f "$SCINTILLA_BIN" ]]; then
  install_name_tool -id '@rpath/Scintilla.framework/Versions/A/Scintilla' "$SCINTILLA_BIN" 2>/dev/null || true
fi

# install_name_tool invalidates code signatures; re-sign ad hoc so dyld will load them.
echo "==> Re-signing staged binaries"
codesign --force --sign - "$BIN_DIR/liblexilla.dylib"
if [[ -f "$SCINTILLA_BIN" ]]; then
  codesign --force --sign - "$SCINTILLA_BIN"
  codesign --force --sign - "$BIN_DIR/Scintilla.framework"
fi
codesign --force --sign - "$LEXPAD_BIN"

echo "==> Runtime libraries staged"
