# Testing notes

**Historical test evidence from the supplied project:** 25 October 2026 and its subsequent Update 1 / Update 2 test notes, executed on Godot 4.4.1 under Linux.

- Original foundation: **258 rules checks** and **38 integration checks** passed.
- Packed game smoke test: loaded the Sarnia map, entered a fictional complex and returned outside; menus opened.
- Native OpenGL Compatibility screenshots were inspected in Linux Xvfb/llvmpipe testing for title/creation, outdoor scenes, atlas and interiors.
- Update 1: atlas redraw/cache checks were reported as passing; existing 258 rules and 38 integration checks remained passing.
- Update 2: **20,883** life/layout/dialogue checks were reported as passing, including generated interior connectivity and multi-floor stairs; existing rules and integration tests remained passing.
- Supplied test report reported no unhandled script errors in the final integration and packed smoke logs.

**Important:** This is a reorganization of supplied files, not a new engine build or Windows playtest. The original development evidence does not establish Windows x64 execution, physical GPU compatibility, full geographic fidelity or long-duration balance. Run real Windows tests before marking the release stable. The [Build guide](BUILDING.md) lists repeatable commands for testing the source.
