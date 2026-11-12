# World Clocks

A world clock for the macOS desktop and menu bar, for keeping track of several time zones at a glance.

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/preview-dark.png">
  <img alt="World Clocks showing San Francisco, New York City, London and Singapore, with the three cities where it is night shaded together" src="docs/preview-light.png" width="464">
</picture>

## Features

- **2–10 cities**, sorted west to east by UTC offset, with the offset running down the left edge.
- The **time** there (24- or 12-hour), the **weekday and date**, and how far ahead or behind you it is.
- The **time zone name** with its abbreviation, such as Pacific Standard Time (PST), and a **DST** badge while daylight saving time is on.
- **Current weather** and temperature, in °C or °F.
- A **countdown to the next sunrise or sunset**, calculated on your Mac. Cities where it's night are shaded, and neighbouring night rows join into one band.
- A **UTC** row whenever none of your cities is on UTC+0.
- Two places to see it: a Liquid Glass **desktop widget** that sits behind your windows on every Space, and a **menu bar** globe that drops down the same panel. The widget can be turned off.
- Starts at login.

## Requirements

- macOS 26 or later
- The Xcode Command Line Tools (`xcode-select --install`). Xcode itself isn't needed.

## Build and install

```bash
./build.sh            # builds build/World Clocks.app
./build.sh --install  # also copies it to /Applications and launches it
./build.sh --test     # runs the unit tests (swift test)
```

The app is signed ad hoc, which is enough to run it on the Mac that built it. To hand it to someone else, sign it with a Developer ID and notarize it.

`Package.swift` also lets you open the project in Xcode or any editor with SwiftPM support.

## Using it

- **Desktop widget:** drag it anywhere. It remembers the spot, and grows downward from its top-left corner as you add cities.
- **Menu bar:** click the globe to see the clocks over any window. ⌘-drag the globe to move it.
- **Right-click** the widget or the panel for quick options: show or hide the widget, weather, and sunrise and sunset; the time format; and the temperature unit.
- **Settings…** (in either menu, or open the app again from Finder or Spotlight): search for cities to add, remove cities, and change the same options, plus launch at login.

## How it works

| Part | Folder |
|---|---|
| Entry point, desktop widget window, menu bar item | `Sources/WorldClocks/App` |
| Cities, clocks, time zone names, settings | `Sources/WorldClocks/Model` |
| Weather, city search, sunrise and sunset | `Sources/WorldClocks/Services` |
| SwiftUI views | `Sources/WorldClocks/Views` |
| Unit tests (Swift Testing) | `Tests/WorldClocksTests` |
| `Info.plist` and the script that draws the icon | `Resources` |

- The desktop widget is a borderless window one level above the desktop icons, so app windows always cover it.
- Weather for all cities comes from a single Open-Meteo request every 15 minutes, and again after the Mac wakes.
- Sunrise and sunset come from the standard sunrise equation, accurate to a minute or two.
- Foundation often has no abbreviation for a time zone (it says "GMT+8"), so common ones come from a small built-in table.

## Privacy

World Clocks has no accounts, analytics or tracking. It contacts two [Open-Meteo](https://open-meteo.com) services:

- the forecast API, which receives the coordinates of your cities;
- the geocoding API, which receives what you type into the city search.

Settings are stored in your user defaults under `com.markhuang.WorldClocks`.

## Credits

Weather data by [Open-Meteo.com](https://open-meteo.com/), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Open-Meteo's free API is for non-commercial use.

## License

MIT. See [LICENSE](LICENSE).
