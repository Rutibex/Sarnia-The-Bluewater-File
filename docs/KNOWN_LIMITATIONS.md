# Known limitations and preview status

The release is a **playable preview**, not a finished full-scale Sarnia simulator or a replacement for another commercial RPG.

- **Windows verification:** the bundled Windows Godot 4.4.1 runtime has not been independently run on Windows hardware during the supplied development/testing process. Linux engine tests do not prove Windows performance, controller support or compatibility with every GPU.
- **Controls:** keyboard/mouse controls are documented. Controller support and key rebinding are not currently established.
- **Performance:** population and traffic density can be demanding; lower density in Help on slower machines.
- **World fidelity:** streets, buildings and some landmarks derive from OpenStreetMap, but terrain/bridges are simplified, building heights can be estimates, and the atlas is not survey-grade. OSM data completeness is not guaranteed.
- **Interiors:** multi-floor layouts are generated fiction; they are not real-world architectural interiors. Not every conceivable building interaction is simulated.
- **Residents and vehicles:** characters and traffic are simulated near the player, not through a persistent city-wide social/transport model. Traffic has no crash physics or timetable.
- **Story/careers:** the Bluewater File is a short investigation with two endings; recurring faction jobs are a limited set of templates rather than a large authored quest library.
- **Combat/economy:** basic equipment slots, devices, loot and banking are implemented; more extensive combat, merchant stock, housing and boating systems are not.
- **Saves:** a single slot is available. Actor positions and interior combat health may reset between visits. Saving indoors records the exterior return point.

For bug reports, include Windows version, GPU/driver, exact steps, and whether the issue occurs before or after character creation. Avoid attaching private save files unless you have reviewed them.
