#!/bin/bash
# Builds "World Clocks.app" into ./build using only the Xcode Command Line Tools (no Xcode project).
#
#   ./build.sh            build the app
#   ./build.sh --install  build, copy to /Applications and (re)launch it
#   ./build.sh --test     run the unit tests
set -euo pipefail
cd "$(dirname "$0")"

DEVELOPER_DIR="$(xcode-select -p)"
SWIFT_FLAGS=(-swift-version 5 -parse-as-library -target "$(uname -m)-apple-macos26.0")
SOURCES=()
while IFS= read -r file; do SOURCES+=("$file"); done < <(find Sources/WorldClocks -name '*.swift' | sort)

# A newer beta SDK can be the default while the compiler is older, which fails with "this SDK is not
# supported by the compiler". Fall back to an installed macOS 26 SDK in that case.
if [ -z "${SDKROOT:-}" ]; then
    probe="$(mktemp -d)"
    echo 'print(0)' > "$probe/probe.swift"
    if ! swiftc -typecheck "$probe/probe.swift" >/dev/null 2>&1; then
        for sdk in "$DEVELOPER_DIR"/SDKs/MacOSX26*.sdk \
                   "$DEVELOPER_DIR"/Platforms/MacOSX.platform/Developer/SDKs/MacOSX26*.sdk; do
            if [ -d "$sdk" ]; then export SDKROOT="$sdk"; break; fi
        done
    fi
    rm -rf "$probe"
fi

if [ "${1:-}" = "--test" ]; then
    exec swift test
fi

APP="build/World Clocks.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O "${SWIFT_FLAGS[@]}" -module-name WorldClocks -o "$APP/Contents/MacOS/WorldClocks" "${SOURCES[@]}"

# The icon is drawn by a small Swift script, again whenever the script changes.
if [ ! -f build/AppIcon.icns ] || [ Resources/make_icon.swift -nt build/AppIcon.icns ]; then
    swiftc -O Resources/make_icon.swift -o build/make_icon
    rm -rf build/AppIcon.iconset
    build/make_icon build/AppIcon.iconset
    iconutil -c icns build/AppIcon.iconset -o build/AppIcon.icns
fi

cp Resources/Info.plist "$APP/Contents/"
cp build/AppIcon.icns "$APP/Contents/Resources/"
codesign --force --sign - "$APP"  # ad-hoc signature: enough to run on the Mac that built it
echo "Built $APP"

if [ "${1:-}" = "--install" ]; then
    pkill -x WorldClocks && sleep 1 || true
    rm -rf "/Applications/World Clocks.app"
    cp -R "$APP" /Applications/
    touch "/Applications/World Clocks.app"  # nudges Finder to pick up a changed icon
    open "/Applications/World Clocks.app"
    echo "Installed and launched /Applications/World Clocks.app"
fi
