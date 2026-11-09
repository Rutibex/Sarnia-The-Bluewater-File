# Changelog

## First public preview package — November 2026

This GitHub package organizes the existing playable game and source assets for distribution. It does **not** introduce gameplay changes or claim new Windows QA.

### Included gameplay milestones

**Bluewater File foundation**
- First-person exploration, custom residents and 18 profession presets.
- Eight attributes, 35 skills, skill advancement, gear, field devices, factions, commerce and saves.
- Offline mapped Sarnia street data and a short investigation with two endings.

**Ground and atlas improvements (Update 1)**
- Better separation of ground, road and water surfaces.
- Improved texture filtering and atlas map performance using cached tiles.
- Zoom and streaming refinements; older saves remain supported as documented.

**Citizens, traffic and interiors (Update 2)**
- Walking citizens with animated variants, local traffic and streetscape props.
- Generated multi-level interiors, physical stair ramps, room maps and optional shortcuts.
- Persistent indoor citizen identities and procedural conversation choices.

### Distribution cleanup
- Removed the unused Windows console executable and internal development reports from the player ZIP.
- Added player-focused guides, licence/credit notices and source repository documentation.

### Known limitations

This is a playable preview, not feature parity with any other RPG. Only one save slot is provided; Windows execution and hardware compatibility were not independently verified by this packaging pass. See `docs/KNOWN_LIMITATIONS.md` in the source repository.
