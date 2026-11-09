# Sarnia: The Bluewater File

**A first-person, open-ended RPG set in a fictionalized Sarnia, Ontario.**

*By Michael Robinson · Built with Godot 4.4.1 · Windows x64 · Offline single-player*

[![Godot 4.4.1](https://img.shields.io/badge/Godot-4.4.1-478CBF?logo=godotengine&logoColor=white)](https://godotengine.org/)
![Windows 10/11](https://img.shields.io/badge/Windows-10%20%2F%2011%20x64-555555)
![Licence: MIT + ODbL](https://img.shields.io/badge/Licences-MIT%20%2B%20ODbL-555555)

Explore a recognizable Ontario city through a retro-inspired 3D world. Create a resident, develop practical skills, take on work for rival local organizations, explore fictional multi-floor complexes, and investigate the mysterious **Bluewater File**. The map is based on OpenStreetMap data; the game's people, premises, organizations, and story are fictional.

> **Release status: playable preview.** This is a complete playable foundation with a short investigation and two outcomes, not a finished large-scale life simulator. Windows packaging is provided, but the included Windows runtime has not yet been independently playtested on Windows.

## Download and play

1. Open the [GitHub Releases page](../../releases/latest) and download **`Sarnia-The-Bluewater-File-Windows-x64.zip`**.
2. Extract the entire ZIP to a folder you can write to. **Do not launch from inside the ZIP viewer.**
3. Open the extracted folder and double-click **`Start Sarnia.cmd`**.
4. Choose a resident preset or make a custom character, then select **Begin**.

**Requirements:** Windows 10/11 (64-bit), mouse and keyboard, and an OpenGL 3.3-capable graphics driver. No installer, Godot editor, compiler, account, or internet access is required. If performance is low, reduce population density from the in-game Help settings.

## What you can do

- **Make your resident:** 18 presets or a custom profession, eight attributes, 35 skills, practice-based advancement, and training.
- **Investigate the Bluewater File:** follow a short main case with two resolutions, then continue exploring.
- **Explore Sarnia:** offline street and landmark data, a zoomable tiled atlas, transit shortcuts, pedestrians, and simulated road traffic.
- **Enter fictional interiors:** reproducibly generated multi-floor complexes, conversations, clues, lockers, shortcuts, and floor maps.
- **Develop a career:** six fictional organizations, repeatable assignments, reputation, ranks, and rewards.
- **Manage your resources:** buy and repair gear, use battery-powered field devices, handle money and debt, acquire property records, and save your progress.

## Controls

| Key / input | Action |
| --- | --- |
| WASD / mouse | Move / look |
| Shift / Ctrl / Space | Sprint / sneak / jump |
| E | Talk, interact, enter, exit, lockpick, loot |
| Hold E against a wall | Climb |
| Left / right mouse | Equipped weapon or tool / selected field device |
| 1–8 | Choose field device |
| Tab / I / J | Character / inventory / journal |
| M / F / T / R | Atlas / factions / devices / rest |
| B | Cycle owned walking, bicycle, and van movement modes |
| F5 / F9 | Save / load |
| Esc | Pause, open/close menus, release mouse |

After creating your character, **find the Civic Liaison near City Hall** (gold label), or use the atlas stop selector and Transit button. Press **E** nearby to begin the case. See [Player Guide](docs/PLAYER_GUIDE.md) for details.

## A few things to know

- Saves use **one local slot**. F5 overwrites the previous save; F9 loads it.
- The street map uses real geographic data, but building interiors, residents, quest events and institutions used in the story are fictional. Generated interiors do **not** depict real premises.
- Property deeds for an apartment and marina currently record ownership, not fully usable housing or boating features.
- Controller support, Windows hardware compatibility and long-running performance have not been verified. See [Known Limitations](docs/KNOWN_LIMITATIONS.md).

## Source and development

This repository contains the **Godot 4.4.1** source project, original assets, an ODbL-licensed map dataset, tests, and optional asset-generation tools. To play, download the Windows release instead of the source ZIP.

- [Build from source](docs/BUILDING.md)
- [Project layout](docs/ARCHITECTURE.md)
- [Known limitations](docs/KNOWN_LIMITATIONS.md)
- [Contributing](CONTRIBUTING.md)
- [Changelog](CHANGELOG.md)

## Licences and credits

Game code, original documentation and original artwork/audio are **MIT** licensed; see [LICENSE](LICENSE). Geographic data and derived map tiles are based on **OpenStreetMap** and licensed **ODbL 1.0**; see [DATA-LICENSE.md](DATA-LICENSE.md). The distributed engine and bundled font have their own included licences. See [CREDITS.md](CREDITS.md) and [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

**Sarnia: The Bluewater File** is an independent fictional game. Real location names provide geographical context, not endorsement.
