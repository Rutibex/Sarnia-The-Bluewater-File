# Building and running from source

**Engine:** Godot **4.4.1** (the source uses Godot 4.x GDScript and the Compatibility renderer).

1. Download and extract the source archive or clone the repository.
2. Open `project.godot` in the Godot 4.4.1 editor.
3. Allow Godot to import assets on first open. The checked-in `*.import` sidecars preserve texture/font import settings and resource UIDs; `.godot/` itself is an ignored local cache.
4. Run the project with F5 (main scene: `main.tscn`).

The source contains no required third-party game addons. Internet access is not needed for ordinary play once the source is present.

## Tests (with `godot` on PATH)

```bash
godot --headless --path . --script tests/rules_test.gd
godot --headless --path . --script tests/integration_test.gd
godot --headless --path . --script tests/life_test.gd
godot --headless --path . --script tests/stairs_test.gd
godot --headless --path . --script tests/atlas_benchmark.gd
godot --headless --path . -- --smoke
```

The original test evidence is summarized in [Testing notes](TESTING.md). These commands are documented, **not** claimed as freshly executed by the release repackaging process.

## Exporting

To build a game pack with a correctly installed export preset:

```bash
godot --headless --path . --export-pack "Windows Desktop" Sarnia.pck
```

A conventional standalone `.exe` export requires matching official Godot Windows export templates and an appropriate preset; use Godot's Project → Export workflow. The supplied Windows release instead uses an unmodified official Windows Godot 4.4.1 executable launched with `--main-pack Sarnia.pck` and the Compatibility renderer. Do not assume a Godot editor/runtime EXE is the same as a standalone export template.

## Regenerating source-derived map/audio assets (optional)

Python 3.10+ and extra packages are used **only** for data/art generation. For geographic preprocessing:

```bash
python -m pip install osmium shapely Pillow
python tools/import_osm.py data/source/sarnia.osm.pbf data/sarnia.json
python tools/reconstruct_water.py data/source/sarnia.osm.pbf data/sarnia.json
python tools/bake_atlas.py
```

The input `.pbf` is an OpenStreetMap extract, covered by ODbL 1.0 along with derived databases and map tile graphics. See [DATA-LICENSE.md](../DATA-LICENSE.md). The audio-generation utility is `tools/make_audio.py`; do not run it unless you intend to regenerate shipped audio.
