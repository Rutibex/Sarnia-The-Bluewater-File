import osmium,sys

from shapely.geometry import LineString,box,Point
from shapely.ops import polygonize,unary_union
import math,json
origin=(-82.4075,42.9745)
def xy(n):return [(n.lon-origin[0])*111320*math.cos(math.radians(origin[1])),-(n.lat-origin[1])*111320]
class H(osmium.SimpleHandler):
 def __init__(self):super().__init__();self.ids=set();self.ways={}
 def relation(self,r):
  if r.id in [1205151,4229750,9171413]:self.ids.update(m.ref for m in r.members if m.type=='w' and m.role=='outer')
 def way(self,w):
  try:self.ways[w.id]=[xy(n) for n in w.nodes]
  except:pass
h=H();h.apply_file(sys.argv[1],locations=True)
bounds=box(-2200,-6500,18500,9500)
lines=[LineString(h.ways[i]).intersection(bounds) for i in h.ids if i in h.ways and len(h.ways[i])>1]
print('members available',len(lines),'of',len(h.ids))
polys=list(polygonize(unary_union(lines+[bounds.boundary])))
print([(round(p.area),p.contains(Point(-500,0)),p.contains(Point(5000,-6000))) for p in polys])
j=json.load(open(sys.argv[2]))
j['areas']=[a for a in j['areas'] if not str(a['id']).startswith('clipped_water_')]
for i,p in enumerate(polys):
 if any(p.contains(Point(*seed)) for seed in [(-500,0),(5000,-6000),(-900,-900)]):
  j['areas'].append({'id':'clipped_water_'+str(i),'kind':'water','p':[[round(x,2),round(y,2)] for x,y in p.exterior.coords],'boundary_closed_at_extract_extent':True})
json.dump(j,open(sys.argv[2],'w'),separators=(',',':'))
