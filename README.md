# Ludo

Offline Ludo for Android and iOS by **Innovatex Technology Pvt. Ltd.** — play with 2–4 players on one device, against friends or the computer.

## How to play

Ludo uses one fixed, standard ruleset (no rule switches):

* **Roll** by tapping the dice in your player panel, then tap a **glowing pawn**. Only legal pawns glow; a single possible move is played for you.
* A pawn leaves its base only on a **6**, onto your colored start cell. Every **6 rolls again**.
* **Three 6s in a row**: the third is cancelled and the turn passes (moves from the first two stay).
* Land on an opponent outside a safe cell to **capture** it (back to base) and **roll again**. If several opponents share the cell, the top one is captured.
* **8 safe cells**, all marked with a star: the four colored start cells and the four star cells.
* **No blocks**: any number of pawns may share a cell.
* Reaching home needs the **exact roll**. First to bring all four pawns home wins; with 3–4 players play continues for the remaining places.

## Features

* **2–4 players**: *VS Computer* (Easy / Medium / Hard bots) or *Pass & Play*
* **Save & continue**: leaving a match keeps it; continue it from the home screen
* **Records**: statistics and achievements
* **Sound, vibration, game speed and board themes**
* Portrait-only, responsive layout for small to large phones
* Fully **offline** — no accounts, no network, no data collection

## Architecture

```
lib/
├── app/            MaterialApp, launcher (home), splash, settings
├── core/           theme (design tokens), audio + haptics, settings, l10n, navigation
├── shared/         reusable widgets (buttons, cards, scaffold) and dialogs
└── games/
    ├── game_definition.dart   how a game plugs into the launcher
    ├── game_catalog.dart      Ludo + "coming soon" entries
    └── ludo/
        ├── engine/      pure rules + engine (state, action) → next state + events, bot
        ├── models/      immutable match state and config
        ├── controller/  drives the engine: pacing, animation, audio, saving, bot turns
        ├── data/        save store, records, achievements, preferences
        ├── screens/     setup, game, result, how to play, records
        └── widgets/     board painter, animated board, pawns, dice, panels
```

The engine has no Flutter, timer, storage or audio dependencies, so a future
online mode can run the same rules elsewhere. Adding a game means adding a
`games/<name>/` folder and one catalog entry.

All sound effects are synthesized by `dart run tool/generate_sounds.dart`.

## Development

```sh
flutter pub get
flutter analyze   # must report no issues
flutter test      # unit + widget tests
```

CI runs `flutter analyze`, `flutter test` and a web build on every push
(`.github/workflows/ci.yaml`). Pushes to `main` also publish the web build to
GitHub Pages — in the repo settings, set **Settings → Pages → Source** to
*GitHub Actions* once so the deploy job can run.

## TODO
* Online multiplayer
* More games: Snakes & Ladders, Chess, Carrom

## Developer

Innovatex Technology Pvt. Ltd., Jaipur, Rajasthan, India  
https://innovatex-technology.com · info@innovatex-technology.com

## License

Copyright © 2026 Innovatex Technology Pvt. Ltd. All rights reserved.

Third-party packages keep their own licenses; the app lists them under
*About → Open-source licenses*.
