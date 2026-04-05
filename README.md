# SE4X Companion (Unofficial)

[![CI](https://github.com/Fabulu/SE4xCompanion/actions/workflows/ci.yml/badge.svg)](https://github.com/Fabulu/SE4xCompanion/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)

Unofficial Flutter companion app for the board game **Space Empires 4X** by Jim Krohn, published by GMT Games, LLC.

> This is an unofficial, fan-made companion app. It is not affiliated with, endorsed by, sponsored by, or associated with GMT Games, LLC or Jim Krohn. "Space Empires 4X" is a trademark of GMT Games, LLC. All rights reserved by their respective owners. You must own a copy of the physical game to use this app as intended.

## Screenshots

*(coming soon — see [docs/screenshots/](docs/screenshots/))*

| Home | Production | Map | Ship & Tech | Settings |
|------|------------|-----|-------------|----------|
| ![Home](docs/screenshots/home.png) | ![Production](docs/screenshots/production.png) | ![Map](docs/screenshots/map.png) | ![Ship & Tech](docs/screenshots/shiptech.png) | ![Settings](docs/screenshots/settings.png) |

## Features

- **Production sheet** — track CP, maintenance, pipelines, mineral income, ship purchases
- **Hex map** — base 4-player + pentagonal 5-player layouts with fleet stacks, worlds, pipelines
- **Ship & tech tracker** — per-counter attack/defense/tactics/move levels, upgrade helpers
- **Combat calculator** — with dice service
- **Replicator tracker** — player-controlled replicator mode (Replicators expansion)
- **Alien economy tracker** — solitaire alien player management
- **Empire Advantage picker** — all 37 EA cards from Base + Close Encounters + Replicators + All Good Things
- **Rules reference browser** — in-app rulebook section search
- **Configurable expansions** — Facilities, Logistics, Temporal, Advanced Construction, Replicators, Ship Experience, Alternate Empire, Unpredictable Research
- **Local save slots** — multi-game support, all stored on-device

## Supported Expansions

- Base game
- Close Encounters
- Replicators
- All Good Things

## Installation

- **Android** — download APK/AAB from [Releases](https://github.com/Fabulu/SE4xCompanion/releases) (TBD) or Google Play (TBD)
- **iOS** — TestFlight (TBD)
- **From source** — see below

## Build from Source

Requires Flutter 3.x, Dart SDK ^3.11.1.

```bash
git clone https://github.com/Fabulu/SE4xCompanion.git
cd SE4xCompanion
flutter pub get
flutter run            # run on connected device/emulator
flutter build apk --release   # Android release APK
```

## Project Structure

```
lib/
  data/        game rules, card manifests, tech costs, ship definitions
  models/      game state, production state, map state, technology, etc.
  pages/       top-level screens (home, production, map, ship/tech, settings, ...)
  services/    persistence, dice
  widgets/     reusable widgets, dialogs, trackers
test/          widget tests, model tests, invariant tests
```

## Testing

```bash
flutter analyze    # static analysis (must be clean)
flutter test       # full test suite (500+ tests)
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). Bug reports and feature requests welcome via GitHub Issues.

## Privacy

SE4X Companion collects nothing, transmits nothing, has no analytics, no accounts, and no network access. All game state is stored locally via `path_provider`. See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).

## Credits

- **Game design:** Jim Krohn — published by [GMT Games, LLC](https://www.gmtgames.com/)
- **App author:** Fabian Trunz ([@Fabulu](https://github.com/Fabulu))
- **Contributors:** see [GitHub contributors](https://github.com/Fabulu/SE4xCompanion/graphs/contributors)
- **AI assistance:** portions of this codebase were developed with help from [Claude Code](https://claude.com/claude-code) (Anthropic)

## License

MIT — see [LICENSE](LICENSE). Copyright © 2026 Fabian Trunz.

## Trademark Acknowledgement

"Space Empires 4X" is a trademark of GMT Games, LLC. This project is an independent, unofficial companion app and makes no claim of affiliation with or endorsement by GMT Games or Jim Krohn.
