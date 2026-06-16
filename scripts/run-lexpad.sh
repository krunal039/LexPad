#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -d "$ROOT/Vendor/scintilla/cocoa/Scintilla/build/Release/Scintilla.framework" ]]; then
  echo "Scintilla not built. Running bootstrap..."
  "$ROOT/scripts/bootstrap.sh"
fi

cd "$ROOT/LexPad"
swift build --product LexPad
"$ROOT/scripts/stage-runtime-libs.sh"

BIN="$(swift build --show-bin-path)/LexPad"
exec "$BIN" "$@"
