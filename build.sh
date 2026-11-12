#!/bin/bash
# Builds "World Clocks.app" into ./build using only the Xcode Command Line Tools (no Xcode project).
#
#   ./build.sh            build the app
#   ./build.sh --install  build, copy to /Applications and (re)launch it
#   ./build.sh --test     run the unit tests
#
# Optional settings (the release workflow uses them):
#   ARCHS="arm64 x86_64"   architectures to build; more than one makes a universal app (default: this Mac's)
#   VERSION=1.0.7          version shown in Finder (default: the one in Resources/Info.plist)
#   BUILD_NUMBER=7         build number (default: the one in Resources/Info.plist)
#   SIGN_IDENTITY="Developer ID Application: …"   sign for distribution (default: ad-hoc, for this Mac only)
set -euo pipefail
cd "$(dirname "$0")"

DEVELOPER_DIR="$(xcode-select -p)"
ARCHS="${ARCHS:-$(uname -m)}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"
SWIFT_FLAGS=(-swift-version 5 -parse-as-library)
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

# One compile per architecture, then lipo them into a single (universal) executable.
slices=()
for arch in $ARCHS; do
    swiftc -O "${SWIFT_FLAGS[@]}" -target "$arch-apple-macos26.0" -module-name WorldClocks \
        -o "build/WorldClocks-$arch" "${SOURCES[@]}"
    slices+=("build/WorldClocks-$arch")
done
lipo -create -output "$APP/Contents/MacOS/WorldClocks" "${slices[@]}"
rm -f "${slices[@]}"

# The icon is drawn by a small Swift script, again whenever the script changes.
if [ ! -f build/AppIcon.icns ] || [ Resources/make_icon.swift -nt build/AppIcon.icns ]; then
    swiftc -O Resources/make_icon.swift -o build/make_icon
    rm -rf build/AppIcon.iconset
    build/make_icon build/AppIcon.iconset
    iconutil -c icns build/AppIcon.iconset -o build/AppIcon.icns
fi

cp Resources/Info.plist "$APP/Contents/"
cp build/AppIcon.icns "$APP/Contents/Resources/"
if [ -n "${VERSION:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "$APP/Contents/Info.plist"
fi
if [ -n "${BUILD_NUMBER:-}" ]; then
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "$APP/Contents/Info.plist"
fi

if [ "$SIGN_IDENTITY" = "-" ]; then
    codesign --force --sign - "$APP"  # ad-hoc: enough to run on the Mac that built it
else
    # Hardened runtime and a secure timestamp are what notarization requires.
    codesign --force --options runtime --timestamp --sign "$SIGN_IDENTITY" "$APP"
fi
echo "Built $APP ($(lipo -archs "$APP/Contents/MacOS/WorldClocks"))"

if [ "${1:-}" = "--install" ]; then
    pkill -x WorldClocks && sleep 1 || true
    rm -rf "/Applications/World Clocks.app"
    cp -R "$APP" /Applications/
    touch "/Applications/World Clocks.app"  # nudges Finder to pick up a changed icon
    open "/Applications/World Clocks.app"
    echo "Installed and launched /Applications/World Clocks.app"
fi
