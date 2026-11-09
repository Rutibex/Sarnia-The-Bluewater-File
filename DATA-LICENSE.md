# Open map attribution and data licence

© OpenStreetMap contributors. OpenStreetMap data is available under the
Open Database Licence (ODbL) 1.0:
https://www.openstreetmap.org/copyright
https://opendatacommons.org/licenses/odbl/1-0/

The supplied `data/source/sarnia.osm.pbf` is the original user-provided extract.
`data/sarnia.json` is the derived game database, distributed under ODbL 1.0.
The map database is separate from the MIT-licensed application and assets.
If distributing an adapted database, comply with the ODbL attribution,
share-alike and access requirements. Attribution also appears in the game.

Projection: local equirectangular approximation, origin longitude -82.4075,
latitude 42.9745. X points east and Z points south. One game unit is one metre.
This is adequate for this prototype's city scale, not survey-grade geodesy.

Positions, road centre lines, building outlines and mapped trees are retained.
Road widths are inferred by highway classification; bridges and terrain are
flattened. Heights tagged in OSM are used, with other heights estimated.
Facade textures, interiors, people, vehicles, quests and organizations are
fictional. Real POI names are location references, not endorsements or claims
about their operation. Full multipolygon holes are not yet supported.

The extract lacks most members of the large Lake Huron and Saint Clair River
relations. `tools/reconstruct_water.py` polygonizes the available relation
shoreline members against the stated regional boundary. It retains the
available shoreline, closes open paths at the extract extent and selects the
river/lake water cells. The closure is a documented approximation. It does not
infer underwater terrain, surveyed banks or inaccessible relation members.

Rebuild with Python 3.10+, osmium and shapely:

    python -m pip install osmium shapely
    python tools/import_osm.py data/source/sarnia.osm.pbf data/sarnia.json
    python tools/reconstruct_water.py data/source/sarnia.osm.pbf data/sarnia.json

Included database: 7,530 road ways; 11,278 building footprints; 781 named POIs;
4,101 mapped trees. Polygon counts differ after shoreline reconstruction.

Offline atlas tiles in `assets/map/` are rendered from the same OSM-derived
database and carry OpenStreetMap attribution in the game. They are map data
renderings, not part of the original MIT art set. Rebuild the tile pyramid after
changing the geographic database:

    python -m pip install Pillow
    python tools/bake_atlas.py
