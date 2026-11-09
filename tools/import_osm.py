"""Import the supplied PBF. Re-run with Python + osmium. Coordinates are metres."""
import osmium,json,math,sys,collections
from pathlib import Path
ORIGIN=(-82.4075,42.9745)
def xy(lon,lat): return [round((lon-ORIGIN[0])*111320*math.cos(math.radians(ORIGIN[1])),2),round(-(lat-ORIGIN[1])*111320,2)]
class Import(osmium.SimpleHandler):
 def __init__(self):
  super().__init__(); self.roads=[];self.buildings=[];self.areas=[];self.pois=[];self.trees=[];self.counts=collections.Counter();self.bounds=[1e9,1e9,-1e9,-1e9]
 def node(self,n):
  p=xy(n.location.lon,n.location.lat)
  self.bounds=[min(self.bounds[0],p[0]),min(self.bounds[1],p[1]),max(self.bounds[2],p[0]),max(self.bounds[3],p[1])]
  t=dict(n.tags)
  if t.get("natural")=="tree":self.trees.append(p)
  if t.get('name') and any(k in t for k in ['shop','amenity','tourism','leisure','historic']): self.pois.append({'id':n.id,'name':t['name'],'p':p,'kind':t.get('shop',t.get('amenity',t.get('leisure',t.get('tourism','landmark'))))})
 def area(self,a):
  if a.from_way():return
  t=dict(a.tags)
  if t.get("natural") not in ["water","wood"] and t.get("landuse") not in ["forest","grass"] and t.get("leisure")!="park":return
  for ring in a.outer_rings():
   p=[xy(n.lon,n.lat) for n in ring]
   if len(p)>3:self.areas.append({"id":a.id,"kind":t.get("natural",t.get("landuse",t.get("leisure"))),"p":p})
 def way(self,w):
  t=dict(w.tags)
  try:p=[xy(n.lon,n.lat) for n in w.nodes]
  except osmium.InvalidLocationError:return
  if len(p)<2:return
  if 'highway' in t:self.roads.append({'id':w.id,'name':t.get('name',t['highway'].replace('_',' ').title()),'kind':t['highway'],'p':p})
  if 'building' in t and len(p)>3:
   try:h=float(t.get('height',float(t.get('building:levels',2))*3.2))
   except:h=6.4
   self.buildings.append({'id':w.id,'name':t.get('name',t.get('addr:street','')),'kind':t.get('building'),'height':min(90,max(3,h)),'height_known':'height' in t or 'building:levels' in t,'p':p})
  if len(p)>3 and (t.get('natural') in ['water','wood','beach'] or t.get('landuse') in ['forest','grass','recreation_ground','industrial'] or t.get('leisure') in ['park','pitch','golf_course']):self.areas.append({'id':w.id,'kind':t.get('natural',t.get('landuse',t.get('leisure'))),'p':p})
  if t.get('name') and any(k in t for k in ['shop','amenity','tourism']):self.pois.append({'id':w.id,'name':t['name'],'p':[round(sum(a[0] for a in p)/len(p),2),round(sum(a[1] for a in p)/len(p),2)],'kind':t.get('shop',t.get('amenity',t.get('tourism')))})
h=Import();h.apply_file(sys.argv[1],locations=True)
out={'origin_lonlat':ORIGIN,'bounds':[-2200,-6500,18500,9500],'roads':h.roads,'buildings':h.buildings,'areas':h.areas,'pois':h.pois,'trees':h.trees,'attribution':'© OpenStreetMap contributors · ODbL 1.0','source':'User-supplied sarnia.osm.pbf; positions and footprints retained; missing heights estimated.'}
Path(sys.argv[2]).write_text(json.dumps(out,separators=(',',':')))
print(json.dumps({k:len(out[k]) for k in ['roads','buildings','areas','pois']}));print('bounds metres',h.bounds)
print('POIs:', [(p['name'],p['kind'],p['p']) for p in h.pois[:45]])
