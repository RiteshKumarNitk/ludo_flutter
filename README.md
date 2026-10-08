# NLudo Flutter

Ludo game made with Flutter — play with 2–4 players on one device, against friends or the computer.

[Play now!](https://nizwar.github.io/ludo_flutter/)

## How to play

* **Roll** the dice by tapping it on your turn.
* **Move** by tapping a highlighted pawn. Only legal moves are highlighted.
* A pawn leaves its base on a **6**. Rolling a 6 grants an extra roll (can be turned off).
* Landing on an opponent's pawn sends it back to its base — unless it sits on a **safe (star) cell**.
* Get all four pawns to the final cell to win. With the default rules you need the **exact roll** to finish.

## Features

* **2–4 players** hot-seat, with any seat assigned to the CPU
* **CPU difficulty**: Easy (random), Medium (races toward the finish), Hard (evaluates captures, safety, blocks and threats)
* **Configurable rules**: extra roll on 6, extra roll on capture, three 6s forfeit, exact finish, blocking
* **Undo** your last move (rewinds the CPU reply played after it too)
* **Save & resume**: a match survives closing the app — resume it from the main menu
* **Board themes** and a responsive board that fits any screen
* **Stacked pawns** with clear counts when several pawns share a cell
* **Statistics & achievements** tracked across sessions
* **Sound effects, haptics** and animation-speed control, each toggleable
* Fully **offline** — no network access required

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
* Multiplayer

## LICENSE
```license
Copyright 2022 - Mochamad Nizwar Syafuan

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

```
