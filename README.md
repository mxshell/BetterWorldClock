<img src="docs/icon.png" alt="" width="128" align="right">

# Better World Clock

A better world clock for the macOS desktop and menu bar, for keeping track of several time zones at a glance.

**Website:** [mxshell.dev/BetterWorldClock](https://mxshell.dev/BetterWorldClock/)

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/preview-dark.png">
  <img alt="Better World Clock showing San Francisco, New York City, London and Singapore, with the three cities where it is night shaded together" src="docs/preview-light.png" width="474">
</picture>

## Features

- **2–10 cities**, sorted west to east by UTC offset, with the offset running down the left edge.
- The **time** there (24- or 12-hour), the **weekday and date**, and how far ahead or behind you it is.
- The **time zone name** with its abbreviation, such as Pacific Standard Time (PST), and a **DST** badge while daylight saving time is on.
- **Current weather** and temperature, in °C or °F.
- A **countdown to the next sunrise or sunset**. Cities where it's night are shaded, and neighbouring night rows join into one band.
- A **UTC** row whenever none of your cities is on UTC+0.
- Two places to see it: a Liquid Glass **desktop widget** that sits behind your windows on every Space, and a dotted **globe** in the menu bar that drops down the same panel. The widget can be turned off.
- Starts at login.

## Install

1. Download the latest **BetterWorldClock-….dmg** from [Releases](https://github.com/mxshell/BetterWorldClock/releases/latest).
2. Open it and drag **World Clock+** onto **Applications**.
3. Open World Clock+ from Applications.

It needs macOS 26 or later, on Apple silicon or Intel, and it's signed and notarized by Apple. The app is called **World Clock+** because "Better World Clock" is too long to show in full under an app icon.

To update, download the new version and replace the app in Applications the same way. Your cities and settings carry over.

## Using it

- **Desktop widget:** drag it anywhere. It remembers the spot, and grows downward from its top-left corner as you add cities.
- **Menu bar:** click the globe to see the clocks over any window. ⌘-drag it to move it.
- **Right-click** the widget or the panel for quick options: show or hide the widget, weather, and sunrise and sunset; the time format; and the temperature unit.
- **Settings…** (in either menu, or open the app again from Finder or Spotlight): search for cities to add, remove cities, and change the same options, plus launch at login.

## Privacy

Better World Clock has no accounts, analytics or tracking, and your cities and settings stay on your Mac. It contacts two [Open-Meteo](https://open-meteo.com) services:

- the forecast API, which receives the coordinates of your cities, about every 2 hours;
- the geocoding API, which receives what you type into the city search.

Sunrise and sunset times are calculated on your Mac.

## Credits

Weather data by [Open-Meteo.com](https://open-meteo.com/), licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).

## Building it yourself

Building from source, how the app works, and how releases are made are covered in [DEVELOPMENT.md](DEVELOPMENT.md).

## License

MIT. See [LICENSE](LICENSE).
