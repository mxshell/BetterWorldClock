#!/bin/bash
# Packs an app into a drag-to-install disk image: the app next to a shortcut to /Applications.
#
#   scripts/make-dmg.sh "build/Better World Clock.app" build/BetterWorldClock.dmg
#
# With SIGN_IDENTITY set (a Developer ID Application identity), the disk image is signed too.
set -euo pipefail

APP="$1"
DMG="$2"
NAME="$(basename "$APP" .app)"

staging="$(mktemp -d)"
trap 'rm -rf "$staging"' EXIT
cp -R "$APP" "$staging/"
ln -s /Applications "$staging/Applications"

rm -f "$DMG"
hdiutil create -volname "$NAME" -srcfolder "$staging" -fs HFS+ -format UDZO -imagekey zlib-level=9 -ov "$DMG" >/dev/null

if [ -n "${SIGN_IDENTITY:-}" ] && [ "$SIGN_IDENTITY" != "-" ]; then
    codesign --force --timestamp --sign "$SIGN_IDENTITY" "$DMG"
fi
echo "Made $DMG"
