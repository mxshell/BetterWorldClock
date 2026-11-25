# Developing Better World Clock

Notes for building the app, finding your way around the code, and publishing releases. For what the app does and how to install it, see the [README](README.md).

## Names

| Where | Name |
|---|---|
| The project, website and release titles | Better World Clock |
| The app in Finder, the Dock and menus | World Clock+ (`CFBundleName`; "Better World Clock" is too long to show in full under an app icon) |
| The Swift package, executable and disk image | BetterWorldClock |
| The bundle identifier | `com.markhuang.WorldClocks`, kept from the app's first name so existing settings carry over |

## Build from source

You need macOS 26 or later and the Xcode Command Line Tools (`xcode-select --install`). Xcode itself isn't needed.

```bash
./build.sh            # builds build/World Clock+.app
./build.sh --install  # also copies it to /Applications and launches it
./build.sh --test     # runs the unit tests (swift test)
```

The app is signed ad hoc, which is enough to run it on the Mac that built it. `build.sh` lists its other settings (architectures, version, signing identity) at the top.

`Package.swift` also lets you open the project in Xcode or any editor with SwiftPM support.

## Project layout

| Part | Folder |
|---|---|
| Entry point, desktop widget window, menu bar item | `Sources/BetterWorldClock/App` |
| Cities, clocks, time zone names, settings | `Sources/BetterWorldClock/Model` |
| Weather, city search, sunrise and sunset | `Sources/BetterWorldClock/Services` |
| SwiftUI views | `Sources/BetterWorldClock/Views` |
| Unit tests (Swift Testing) | `Tests/BetterWorldClockTests` |
| `Info.plist` and the script that draws the app icon | `Resources` |
| Disk image packaging | `scripts` |
| Hand-written release notes | `release-notes` |
| Website (one page, no build step) | `site` |
| App icon and screenshots for the README and website | `docs` |
| Release and website workflows | `.github/workflows` |

## How it works

- The desktop widget is a borderless window one level above the desktop icons, so app windows always cover it.
- Weather for all cities comes from a single [Open-Meteo](https://open-meteo.com) request. The app checks every 15 minutes and when the Mac wakes, and fetches once the weather is 2 hours old (`Weather.refreshInterval`). Weather that's an hour overdue is shown faded.
- The weather icon's day or night look follows the local sunrise and sunset calculation rather than the forecast, so it changes on time between updates.
- Sunrise and sunset come from the standard sunrise equation, accurate to a minute or two.
- Foundation often has no abbreviation for a time zone (it says "GMT+8"), so common ones come from a small built-in table.
- Settings and the last weather are stored in user defaults under `com.markhuang.WorldClocks`.
- Open-Meteo's free API is for non-commercial use, and its data is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), so the app and website credit it.

## Releases

Every push to `main` runs [the release workflow](.github/workflows/release.yml) on GitHub Actions, which runs the tests. To publish a release, raise `CFBundleShortVersionString` in `Resources/Info.plist` (for example from 1.1.1 to 1.1.2) and push. When that version has no release yet, the workflow builds a universal app for Apple silicon and Intel, packs it into a disk image with `scripts/make-dmg.sh`, and publishes it as release v1.1.2.

The release page gets install steps and the list of commits since the last release. To add your own notes for a version, write them in `release-notes/<version>.md` (for example `release-notes/1.1.2.md`) before you push.

Releases are signed with a Developer ID and notarized by Apple when these repository secrets are set (Settings › Secrets and variables › Actions). Without them, for example in a fork, the app is signed ad hoc and the release notes explain how to open it anyway.

| Secret | What it is |
|---|---|
| `MACOS_CERTIFICATE_P12` | Your **Developer ID Application** certificate and its private key, exported from Keychain Access as a .p12 file, then base64-encoded: `base64 -i certificate.p12 \| pbcopy` |
| `MACOS_CERTIFICATE_PASSWORD` | The password you gave the .p12 file |
| `NOTARY_APPLE_ID` | The Apple Account email of your developer account |
| `NOTARY_PASSWORD` | An app-specific password for it, from [account.apple.com](https://account.apple.com) |
| `NOTARY_TEAM_ID` | Your 10-character Team ID, from the Apple Developer website |

## Website

[The website workflow](.github/workflows/pages.yml) publishes `site/`, plus the icon and screenshots from `docs/`, to GitHub Pages whenever they change on `main`. The download button asks the GitHub API for the latest release, so the page needs no update when a new version comes out.
