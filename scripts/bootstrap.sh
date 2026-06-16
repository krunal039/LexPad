#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VENDOR="$ROOT/Vendor"
SCINTILLA="$VENDOR/scintilla/cocoa/Scintilla"
LEXILLA="$VENDOR/lexilla/src"

echo "==> LexPad bootstrap"
echo "    Project: $ROOT"

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "ERROR: xcodebuild not available."
  echo "  Install Xcode from the App Store, then run:"
  echo "    sudo xcodebuild -license accept"
  echo "    sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

if [[ ! -d "$VENDOR/scintilla" || ! -d "$VENDOR/lexilla" ]]; then
  echo "Cloning Scintilla and Lexilla..."
  mkdir -p "$VENDOR"
  git clone --depth 1 https://github.com/jrsoftware/scintilla.git "$VENDOR/scintilla"
  git clone --depth 1 https://github.com/ScintillaOrg/lexilla.git "$VENDOR/lexilla"
fi

echo "==> Building Lexilla"
(cd "$LEXILLA" && make)

if xcodebuild -version >/dev/null 2>&1; then
  echo "==> Building Scintilla Cocoa framework"
  (cd "$SCINTILLA" && xcodebuild -configuration Release build) || {
    echo "WARN: Scintilla build failed. LexPad still runs via: cd LexPad && swift run"
  }
  echo "Scintilla framework ready."
  echo "==> Building LexPad"
  (cd "$ROOT/LexPad" && swift build --product LexPad)
  "$ROOT/scripts/stage-runtime-libs.sh"
else
  echo "WARN: Full Xcode not detected. Install Xcode to build Scintilla Cocoa framework."
  echo "      LexPad shell still runs via: cd LexPad && swift run"
fi

echo "==> Bootstrap complete"
echo "    Launch: ./scripts/run-lexpad.sh"
