#!/usr/bin/env bash
# Sign and notarize LexPad.app for distribution outside the Mac App Store.
#
# Prerequisites:
#   1. Apple Developer account
#   2. Developer ID Application certificate in Keychain
#   3. App-specific password for notarytool
#
# Usage:
#   export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
#   export APPLE_ID="you@example.com"
#   export APPLE_TEAM_ID="TEAMID"
#   export APPLE_APP_PASSWORD="xxxx-xxxx-xxxx-xxxx"
#   ./scripts/build-app-bundle.sh release
#   ./scripts/notarize-app.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/dist/LexPad.app"
ZIP="$ROOT/dist/LexPad.zip"

: "${CODESIGN_IDENTITY:?Set CODESIGN_IDENTITY to your Developer ID Application certificate}"
: "${APPLE_ID:?Set APPLE_ID}"
: "${APPLE_TEAM_ID:?Set APPLE_TEAM_ID}"
: "${APPLE_APP_PASSWORD:?Set APPLE_APP_PASSWORD (app-specific password)}"

if [[ ! -d "$APP" ]]; then
  echo "ERROR: $APP not found. Run ./scripts/build-app-bundle.sh first." >&2
  exit 1
fi

echo "==> Re-signing with Developer ID"
codesign --force --options runtime --sign "$CODESIGN_IDENTITY" "$APP/Contents/Frameworks/liblexilla.dylib"
codesign --force --options runtime --sign "$CODESIGN_IDENTITY" "$APP/Contents/Frameworks/Scintilla.framework"
codesign --force --deep --options runtime --sign "$CODESIGN_IDENTITY" "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"

echo "==> Creating zip for notarization"
ditto -c -k --keepParent "$APP" "$ZIP"

echo "==> Submitting to Apple notary service"
xcrun notarytool submit "$ZIP" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --team-id "$APPLE_TEAM_ID" \
  --wait

echo "==> Stapling ticket"
xcrun stapler staple "$APP"

echo "==> Done. Notarized app: $APP"
