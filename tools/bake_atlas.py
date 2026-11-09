"""Bake an offline tiled atlas pyramid from the unchanged geographic database.
Requires Pillow. Only a few visible tiles are drawn by the game, regardless
of the number of OSM features. Re-run after rebuilding data/sarnia.json.
"""
import json,math
from pathlib import Path
from PIL import Image,ImageDraw
root=Path(__file__).resolve().parents[1]
data=json.loads((root/'data/sarnia.json').read_text())
out=root/'assets/map';out.mkdir(parents=True,exist_ok=True)
px=512;world_tile=1024;bounds=data['bounds']
origin=[math.floor(bounds[0]/world_tile)*world_tile,math.floor(bounds[1]/world_tile)*world_tile]
cols=math.ceil((bounds[2]-origin[0])/world_tile);rows=math.ceil((bounds[3]-origin[1])/world_tile)
image=Image.new('RGB',(cols*px,rows*px),'#182c30');d=ImageDraw.Draw(image)
def points(p):return [((x-origin[0])/2,(y-origin[1])/2) for x,y in p]
for area in data['areas']:
 if len(area['p'])>=3:d.polygon(points(area['p']),fill='#264c5d' if area['kind']=='water' else '#334b39')
for building in data['buildings']:
 if len(building['p'])>=3:d.polygon(points(building['p']),fill='#54695f')
for road in data['roads']:
 if len(road['p'])<2:continue
 kind=road['kind'];width=5 if kind in ['motorway','trunk'] else 3 if kind in ['primary','secondary'] else 2 if kind in ['tertiary','residential','unclassified'] else 1
 d.line(points(road['p']),fill='#b59b67' if kind in ['motorway','trunk'] else '#879080',width=width)
levels=[]
for level in range(4):
 folder=out/str(level);folder.mkdir(exist_ok=True)
 ncols=math.ceil(image.width/px);nrows=math.ceil(image.height/px)
 for y in range(nrows):
  for x in range(ncols):
   tile=Image.new('RGB',(px,px),'#182c30');tile.paste(image.crop((x*px,y*px,min((x+1)*px,image.width),min((y+1)*px,image.height))),(0,0));tile.save(folder/f'{x}_{y}.png',optimize=True)
 levels.append({'cols':ncols,'rows':nrows,'world_size':world_tile*(2**level)})
 if level<3:image=image.resize((math.ceil(image.width/2),math.ceil(image.height/2)),Image.Resampling.LANCZOS)
meta={'origin':origin,'tile_pixels':px,'levels':levels,'attribution':'© OpenStreetMap contributors · ODbL 1.0'}
(root/'data/atlas.json').write_text(json.dumps(meta,separators=(',',':')))
print('Baked atlas:',levels)
