# Repository layout

| Path | Purpose |
| --- | --- |
| `project.godot`, `main.tscn` | Godot project configuration and entry scene |
| `scripts/main.gd` | Player control, world interactions, combat and campaign loop |
| `scripts/world.gd` | Map streaming, scene geometry and interiors |
| `scripts/rules.gd` | Character progression, commerce, factions and saves |
| `scripts/interface.gd`, `scripts/atlas.gd` | Menus, HUD and geographic/interior maps |
| `scripts/actor.gd`, `scripts/population.gd`, `scripts/vehicle.gd` | NPCs, citizens and traffic |
| `scripts/interiors.gd`, `scripts/decor.gd`, `scripts/society.gd` | Generated interiors, scenery and dialogue identities |
| `assets/` | Original audio/graphics/font and derived ODbL atlas tiles |
| `data/sarnia.json`, `data/atlas.json` | Derived offline geographic game data |
| `data/source/sarnia.osm.pbf` | Source OSM extract for reproducing the geographic database |
| `tools/` | Optional map/audio preprocessing scripts |
| `tests/` | Rules, integration, population, stairs and rendering-related checks |
| `docs/` | Player, build, QA and known-limitations documentation |
| `licenses/`, `LICENSE`, `DATA-LICENSE.md` | Licence details for the game and included dependencies |

The `*.import` files are **Godot source import metadata**, not disposable engine caches. The `.godot/` cache is excluded from the repository and should regenerate locally.
