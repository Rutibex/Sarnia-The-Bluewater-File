extends Node3D
const Interiors=preload("res://scripts/interiors.gd")
const Decor=preload("res://scripts/decor.gd")
const Population=preload("res://scripts/population.gd")
const Society=preload("res://scripts/society.gd")
const Actor=preload("res://scripts/actor.gd")
var data: Dictionary
var population
var blueprint={}
var interior_key=""
var current_floor=0
var floor_roots: Array=[]
var doors: Array=[]
var nav_cache={}
var signs: Array=[]
var building_lookup={}
var interior_state={}

var chunks={}
var loaded={}
var mats={}
var actors: Array=[]
var markers: Array=[]
var interior=false
var indoor: Node3D
var outdoor: Node3D
var interior_type=""
var last_out=Vector3.ZERO
var last_yaw=0.0
var chunk_queue: Array=[]
var ground: StaticBody3D
var generated=0
var points: Array=[]
var faction_points: Array=[]
var indoors_loot: Array=[]
var indoor_cells={}
var nav: AStarGrid2D
var water_polys: Array=[]
# The visual base is below gameplay floor height. Layers have real separation
# rather than relying on a few millimetres of depth-buffer precision.
const BASE_Y=-0.20
const PARK_Y=-0.14
const BEACH_Y=-0.08
const WATER_Y=-0.03
const ROAD_Y=0.025
const MARKING_Y=0.055
var atlas_meta={}
var atlas_tiles={}
var atlas_tile_lru: Array=[]
var last_stream_key=Vector2i(2147483647,2147483647)
var stream_wanted={}

func setup():
 data=JSON.parse_string(FileAccess.get_file_as_string("res://data/sarnia.json"))
 atlas_meta=JSON.parse_string(FileAccess.get_file_as_string("res://data/atlas.json"))
 for k in ["brick","concrete","house","industrial","roof","asphalt","grass"]:
  var m=StandardMaterial3D.new();m.albedo_texture=load("res://assets/"+k+".png");m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS_ANISOTROPIC;m.roughness=1.0;m.cull_mode=BaseMaterial3D.CULL_DISABLED;mats[k]=m
 for pair in [["water",Color("385e69")],["park",Color("60744e")],["sand",Color("b6aa7c")],["line",Color("d6c69a")],["dark",Color("293137")],["door",Color("a17b42")]]:
  var m=StandardMaterial3D.new();m.albedo_color=pair[1];m.roughness=1;m.cull_mode=BaseMaterial3D.CULL_DISABLED;mats[pair[0]]=m
 outdoor=Node3D.new();add_child(outdoor)
 ground=StaticBody3D.new();var collision=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(100000,2,100000);collision.shape=box;collision.position.y=-1;ground.add_child(collision);outdoor.add_child(ground)
 var plane=MeshInstance3D.new();var pm=PlaneMesh.new();pm.size=Vector2(100000,100000);plane.mesh=pm;plane.position.y=BASE_Y;plane.material_override=mats.grass;outdoor.add_child(plane)
 for a in data.areas:
  if a.kind=="water":
   var poly=PackedVector2Array()
   for p in a.p:poly.append(Vector2(p[0],p[1]))
   water_polys.append(poly)
 index_data()
 points=data.pois.duplicate(true)
 var anchors=["Sarnia City Hall","Lambton College","Lambton County Library - Sarnia","Sarnia Farmers' Market","Lambton Mall","Sarnia Police"]
 var titles=["Civic Liaison Office","Lambton Field Institute","Neighbourhood Aid","Waterfront Couriers","Bluewater Trades Council","Night Shift Collective"]
 for n in range(anchors.size()):
  var p=find_poi(anchors[n]);var pos=street_position(v3(p.p));var npc=Actor.new();outdoor.add_child(npc);npc.setup(titles[n],"worker" if n!=2 else "medic",pos);actors.append(npc)
  faction_points.append({"name":titles[n],"p":[pos.x,pos.z],"real":anchors[n]})
  marker(pos,anchors[n]+"\nE • "+titles[n],Color("e8c991"))
 # Fictional entrances placed by public roads; not claimed to be real infrastructure.
 for entry in [["Fictional service complex",Vector3(190,0,350)],["Fictional pumping station",Vector3(1600,0,2100)],["Fictional research annex",Vector3(4600,0,-200)]]:
  var p=street_position(entry[1]);points.append({"name":entry[0],"p":[p.x,p.z],"kind":"dungeon"});marker(p,entry[0]+"\nE • enter",Color("a4c9bd"))
 population=Population.new();population.setup(self)
func v3(p: Array) -> Vector3:return Vector3(float(p[0]),0,float(p[1]))
func find_poi(n: String) -> Dictionary:
 for p in data.pois:
  if p.name==n:return p
 return {"name":n,"p":[0,0],"kind":"landmark"}
func street_position(p: Vector3) -> Vector3:
 var best=INF;var result=p
 for r in data.roads:
  if r.kind in ["motorway","motorway_link"]:continue
  for i in range(r.p.size()-1):
   var a=v3(r.p[i]);var b=v3(r.p[i+1]);var ab=b-a
   var t=clampf((p-a).dot(ab)/maxf(0.001,ab.length_squared()),0,1);var q=a+t*ab;var dist=q.distance_squared_to(p)
   if dist<best:
    best=dist
    # Center of road gives a reliable accessible spawn; NPC offset comes later.
    result=q
 return result
func index_data():
 for p in data.get("trees",[]):bucket(Vector2i(floori(p[0]/256),floori(p[1]/256))).trees.append(p)
 for b in data.buildings:
  if b.p.size()<4:continue
  b._poly=PackedVector2Array()
  for p in b.p:b._poly.append(Vector2(p[0],p[1]))
  b._rect=Rect2(b._poly[0],Vector2.ZERO)
  for p in b._poly:b._rect=b._rect.expand(p)
  building_lookup[str(int(b.id))]=b
  var centre=Vector2.ZERO
  for p in b.p:centre+=Vector2(p[0],p[1])
  centre/=b.p.size();var key=Vector2i(floori(centre.x/256),floori(centre.y/256));bucket(key).buildings.append(b)
 for r in data.roads:
  var width=9.0
  match r.kind:
   "motorway","trunk":width=20
   "primary","secondary":width=12
   "tertiary":width=10
   "footway","path","cycleway","steps":width=2.4
   "service","track":width=5
  for i in range(r.p.size()-1):
   var a=v3(r.p[i]);var b=v3(r.p[i+1]);var mid=(a+b)*0.5
   if a.distance_to(b)>3000:continue
   var key=Vector2i(floori(mid.x/256),floori(mid.z/256));bucket(key).roads.append([a,b,width,r.name])
 for a in data.areas:
  if a.p.size()<4:continue
  var rect=Rect2(Vector2(a.p[0][0],a.p[0][1]),Vector2.ZERO)
  for p in a.p:rect=rect.expand(Vector2(p[0],p[1]))
  var keys=[]
  # Large water polygons stay in a shared layer; small surfaces are chunked.
  if rect.size.x>1800 or rect.size.y>1800:
   surface(a,outdoor);continue
  var c=rect.get_center();bucket(Vector2i(floori(c.x/256),floori(c.y/256))).areas.append(a)
func bucket(key: Vector2i) -> Dictionary:
 if not chunks.has(key):chunks[key]={"buildings":[],"roads":[],"areas":[],"trees":[]}
 return chunks[key]
func update_chunks(pos: Vector3):
 if interior:return
 var key=Vector2i(floori(pos.x/256),floori(pos.z/256))
 if key!=last_stream_key:
  last_stream_key=key;stream_wanted.clear();chunk_queue.clear()
  for x in range(-3,4):
   for y in range(-3,4):
    var k=key+Vector2i(x,y);stream_wanted[k]=true
    if chunks.has(k) and not loaded.has(k):chunk_queue.append(k)
  chunk_queue.sort_custom(func(a,b):return (a-key).length_squared()<(b-key).length_squared())
  for k in loaded.keys():
   if not stream_wanted.has(k):loaded[k].queue_free();loaded.erase(k)
 var count=0
 while chunk_queue.size()>0 and count<2:
  var k=chunk_queue.pop_front()
  if stream_wanted.has(k) and not loaded.has(k):build_chunk(k);count+=1
func atlas_texture(level: int,x: int,y: int) -> Texture2D:
 var path="res://assets/map/%d/%d_%d.png"%[level,x,y]
 if atlas_tiles.has(path):
  atlas_tile_lru.erase(path);atlas_tile_lru.append(path);return atlas_tiles[path]
 var texture=load(path) as Texture2D
 if texture:
  atlas_tiles[path]=texture;atlas_tile_lru.append(path)
  while atlas_tile_lru.size()>96:atlas_tiles.erase(atlas_tile_lru.pop_front())
 return texture
func vertex(st: SurfaceTool,p: Vector3,uv: Vector2):
 st.set_uv(uv);st.add_vertex(p)
func tri(st: SurfaceTool,a: Vector3,b: Vector3,c: Vector3,uvscale: float=0.15):
 if (b-a).cross(c-a).y<0:
  var swap=b;b=c;c=swap
 vertex(st,a,Vector2(a.x,a.z)*uvscale);vertex(st,b,Vector2(b.x,b.z)*uvscale);vertex(st,c,Vector2(c.x,c.z)*uvscale)
func build_chunk(k: Vector2i):
 var root=Node3D.new();outdoor.add_child(root);loaded[k]=root;var c=chunks[k]
 for a in c.areas:surface(a,root)
 var furniture=Decor.new();var prop_index=0
 for road in c.roads:
  if road[0].distance_to(road[1])<25 or prop_index>=14:continue
  var direction=(road[1]-road[0]).normalized();var side=direction.cross(Vector3.UP)*(road[2]*0.5+1.0)
  var place=road[0].lerp(road[1],0.45)+side
  if point_in_building(place):continue
  furniture.lamp(place)
  if prop_index%2==0:furniture.bench(place+direction*4,atan2(direction.x,direction.z))
  if prop_index%3==0:furniture.planter(place-direction*2.5)
  furniture.cube(place+direction*2+Vector3(0,0.4,0),Vector3(0.5,0.8,0.5),Color("4a655d"))
  prop_index+=1
 if furniture.transforms.size():furniture.finish(root)
 for p in c.trees:
  var tree=Sprite3D.new();tree.texture=load("res://assets/tree.png");tree.billboard=BaseMaterial3D.BILLBOARD_FIXED_Y;tree.pixel_size=0.08;tree.position=v3(p)+Vector3(0,3.8,0);tree.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;root.add_child(tree)
 var signed={}
 for r in c.roads:
  if signed.size()>=3:break
  if r[3] in ["Footway","Service","Path","Cycleway","Residential"] or signed.has(r[3]):continue
  signed[r[3]]=true
  var sign=Label3D.new();sign.text=r[3];sign.position=r[0]+Vector3(0,2.8,0);sign.font_size=22;sign.pixel_size=0.012;sign.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sign.modulate=Color("d9dac0");root.add_child(sign)
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var lines=SurfaceTool.new();lines.begin(Mesh.PRIMITIVE_TRIANGLES)
 for r in c.roads:
  var a=r[0]+Vector3.UP*ROAD_Y;var b=r[1]+Vector3.UP*ROAD_Y;var side=(b-a).cross(Vector3.UP).normalized()*r[2]*0.5
  tri(st,a-side,a+side,b+side);tri(st,a-side,b+side,b-side)
  if r[2]>=9:
   var dir=(b-a).normalized();var dash=(b-a).length();var off=0.0
   while off<dash:
    var d=a+dir*off+Vector3.UP*(MARKING_Y-ROAD_Y);var e=a+dir*minf(off+3,dash)+Vector3.UP*(MARKING_Y-ROAD_Y);var w=side.normalized()*0.07
    tri(lines,d-w,d+w,e+w);tri(lines,d-w,e+w,e-w);off+=8
 mesh_from(st,root,mats.asphalt);mesh_from(lines,root,mats.line)
 # One wall mesh and one roof mesh per chunk, instead of one draw call per building.
 var wall=SurfaceTool.new();wall.begin(Mesh.PRIMITIVE_TRIANGLES)
 var roof=SurfaceTool.new();roof.begin(Mesh.PRIMITIVE_TRIANGLES)
 for b in c.buildings:
  var poly=PackedVector2Array()
  for p in b.p:poly.append(Vector2(p[0],p[1]))
  if poly.size()>1 and poly[0]==poly[-1]:poly.remove_at(poly.size()-1)
  var height=float(b.height)
  for i in range(poly.size()):
   var p=poly[i];var q=poly[(i+1)%poly.size()];var a=Vector3(p.x,0,p.y);var d=Vector3(q.x,0,q.y);var u=p.distance_to(q)/8
   for pair in [[a,Vector2(0,1)],[d,Vector2(u,1)],[d+Vector3.UP*height,Vector2(u,1-height/7)],[a,Vector2(0,1)],[d+Vector3.UP*height,Vector2(u,1-height/7)],[a+Vector3.UP*height,Vector2(0,1-height/7)]]:vertex(wall,pair[0],pair[1])
  var ids=Geometry2D.triangulate_polygon(poly)
  for i in range(0,ids.size(),3):tri(roof,Vector3(poly[ids[i]].x,height,poly[ids[i]].y),Vector3(poly[ids[i+1]].x,height,poly[ids[i+1]].y),Vector3(poly[ids[i+2]].x,height,poly[ids[i+2]].y))
 var wm=mesh_from(wall,root,mats.brick)
 if wm:wm.create_trimesh_collision()
 mesh_from(roof,root,mats.roof);generated+=1
func mesh_from(st: SurfaceTool,parent: Node3D,mat: Material):
 var arrays=st.commit_to_arrays()
 if arrays.is_empty() or arrays[Mesh.ARRAY_VERTEX]==null or arrays[Mesh.ARRAY_VERTEX].is_empty():return null
 st.generate_normals()
 var mesh=st.commit()
 if mesh==null:return null
 var mi=MeshInstance3D.new();mi.mesh=mesh;mi.material_override=mat;parent.add_child(mi);return mi
func surface(a: Dictionary,parent: Node3D):
 var poly=PackedVector2Array()
 for p in a.p:poly.append(Vector2(p[0],p[1]))
 if poly.size()>1 and poly[0]==poly[-1]:poly.remove_at(poly.size()-1)
 if poly.size()>7000:return
 var ids=Geometry2D.triangulate_polygon(poly)
 if ids.is_empty():return
 var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
 var y=WATER_Y if a.kind=="water" else BEACH_Y if a.kind=="beach" else PARK_Y
 for i in range(0,ids.size(),3):tri(st,Vector3(poly[ids[i]].x,y,poly[ids[i]].y),Vector3(poly[ids[i+1]].x,y,poly[ids[i+1]].y),Vector3(poly[ids[i+2]].x,y,poly[ids[i+2]].y))
 mesh_from(st,parent,mats.water if a.kind=="water" else mats.sand if a.kind=="beach" else mats.park)
func marker(p: Vector3,text: String,color: Color):
 var label=Label3D.new();label.text=text;label.position=p+Vector3(0,5,0);label.font_size=28;label.pixel_size=0.015;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=color;outdoor.add_child(label);markers.append(label)
func nearest_road(pos: Vector3) -> String:
 var best=INF;var n="Sarnia"
 var key=Vector2i(floori(pos.x/256),floori(pos.z/256))
 for dx in [-1,0,1]:
  for dz in [-1,0,1]:
   var k=key+Vector2i(dx,dz)
   if not chunks.has(k):continue
   for r in chunks[k].roads:
    var ab=r[1]-r[0];var q=r[0]+ab*clampf((pos-r[0]).dot(ab)/maxf(0.01,ab.length_squared()),0,1);var dist=pos.distance_squared_to(q)
    if dist<best:best=dist;n=r[3]
 return n
func water_at(pos: Vector3) -> bool:
 for poly in water_polys:
  if Geometry2D.is_point_in_polygon(Vector2(pos.x,pos.z),poly):return true
 return false
func point_in_building(p: Vector3) -> bool:
 var point=Vector2(p.x,p.z);var key=Vector2i(floori(p.x/256),floori(p.z/256))
 for dx in [-1,0,1]:
  for dz in [-1,0,1]:
   var chunk=chunks.get(key+Vector2i(dx,dz),{})
   for building in chunk.get("buildings",[]):
    if building._rect.has_point(point) and Geometry2D.is_point_in_polygon(point,building._poly):return true
 return false
func floor_at(p: Vector3) -> int:return clampi(int(floor((p.y+0.35)/Interiors.HEIGHT)),0,maxi(0,int(blueprint.get("floor_count",1))-1))
func navigate(from: Vector3,to: Vector3) -> Vector3:
 if not interior or blueprint.is_empty():return to
 var f=floor_at(from)
 if floor_at(to)!=f:return from
 var a=Vector2i(roundi(from.x/7),roundi(from.z/7));var b=Vector2i(roundi(to.x/7),roundi(to.z/7))
 var key="%d/%s/%s"%[f,str(a),str(b)]
 if not nav_cache.has(key):nav_cache[key]=Interiors.path(blueprint.floors[f],a,b)
 var route=nav_cache[key]
 if route.size()>1:return Vector3(route[1].x*7,f*Interiors.HEIGHT,route[1].y*7)
 return to if route.size() else from
func identify_building(name: String,p: Vector3) -> Dictionary:
 var best=INF;var selected={}
 for b in data.buildings:
  var d=b._rect.get_center().distance_squared_to(Vector2(p.x,p.z))
  if b.name==name:d*=0.1
  if d<best:best=d;selected=b
 return selected
func box(parent: Node3D,p: Vector3,size: Vector3,mat: Material,solid: bool=true):
 var mi=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=size;mi.mesh=mesh;mi.position=p;mi.material_override=mat;parent.add_child(mi)
 if solid:mi.create_trimesh_collision()
 return mi
func enter(kind: String,outpos: Vector3,yaw: float,identity: String="",building_kind: String=""):
 interior=true;interior_type=kind;last_out=outpos;last_yaw=yaw;outdoor.hide();ground.process_mode=Node.PROCESS_MODE_DISABLED
 for root in loaded.values():root.process_mode=Node.PROCESS_MODE_DISABLED
 interior_key=identity if not identity.is_empty() else "place/"+kind
 if building_lookup.has(interior_key):building_kind=building_lookup[interior_key].kind
 blueprint=Interiors.generate(interior_key,kind if kind.contains("Fictional") else building_kind)
 indoor=Node3D.new();add_child(indoor);indoors_loot=[];floor_roots=[];doors=[];signs=[];nav_cache.clear();current_floor=0
 var rng=RandomNumberGenerator.new();rng.seed=blueprint.seed
 for floor in blueprint.floors:build_floor(floor,rng,kind.contains("Fictional"))
 indoor_cells=blueprint.floors[0].cells
 # A permanent roof seals the stairwell even while distant floors are culled.
 box(indoor,Vector3(0,blueprint.floor_count*Interiors.HEIGHT+0.25,(blueprint.depth-1)*3.5),Vector3((blueprint.width*2+1)*7,0.2,blueprint.depth*7),mats.roof)
 # Guaranteed lobby locker keeps investigation records accessible on revisits.
 var chest=box(floor_roots[0],Vector3(2,0.5,2),Vector3(1,1,1),mats.door)
 indoors_loot.append({"node":chest,"pos":Vector3(2,0,2),"locked":false,"taken":false})
 box(floor_roots[0],Vector3(0,1.4,-3.35),Vector3(2,2.8,0.2),mats.door,false)
 make_sign(floor_roots[0],Vector3(0,2.9,-3.1),"STREET EXIT / E")
func make_sign(parent: Node3D,p: Vector3,text: String):
 var l=Label3D.new();l.text=text;l.position=p;l.font_size=20;l.pixel_size=0.0035;l.billboard=BaseMaterial3D.BILLBOARD_ENABLED;l.modulate=Color("d0d5b5");l.visibility_range_end=22;parent.add_child(l);signs.append(l)
func doorway(structure,root: Node3D,c: Vector2i,next: Vector2i,y: float,open: bool,secret: bool,floor: int):
 var dir=next-c;var centre=Vector3((c.x+next.x)*3.5,y,(c.y+next.y)*3.5);var along=Vector3(0,0,1) if dir.x else Vector3(1,0,0)
 var size=Vector3(0.18,Interiors.HEIGHT,7) if dir.x else Vector3(7,Interiors.HEIGHT,0.18)
 # Keep the complete stair axis free of cross-beams and door frames.
 if c.x==0 and next.x==0 and mini(c.y,next.y)<=2 and maxi(c.y,next.y)>=0:return
 var col=Color("7c8980") if floor%2==0 else Color("8b8676")
 if not open and not secret:structure.cube(centre+Vector3(0,Interiors.HEIGHT*0.5,0),size,col,true);return
 var panel_size=Vector3(0.18,Interiors.HEIGHT,2.6) if dir.x else Vector3(2.6,Interiors.HEIGHT,0.18)
 for side in [-1,1]:structure.cube(centre+along*2.2*side+Vector3(0,Interiors.HEIGHT*0.5,0),panel_size,col,true)
 structure.cube(centre+Vector3(0,3.6,0),Vector3(0.18,1.6,1.8) if dir.x else Vector3(1.8,1.6,0.18),col,true)
 if secret:
  var pivot=Node3D.new();pivot.position=centre+along*0.9;root.add_child(pivot)
  var panel=box(pivot,Vector3(0,1.35,0)-along*0.9,Vector3(0.2,2.7,1.75) if dir.x else Vector3(1.75,2.7,0.2),mats.house)
  var state_key="%s/%d/%s"%[interior_key,floor,Interiors.edge_key(c,next)]
  var opened=interior_state.get(state_key,false)
  doors.append({"node":pivot,"pos":centre,"floor":floor,"key":state_key,"open":opened,"secret":true,"a":c,"b":next})
  if opened:pivot.rotation.y=PI*0.5;blueprint.floors[floor].edges[Interiors.edge_key(c,next)]=true
func build_floor(floor: Dictionary,rng: RandomNumberGenerator,dungeon: bool):
 var index=int(floor.floor);var y=index*Interiors.HEIGHT;var root=Node3D.new();indoor.add_child(root);floor_roots.append(root)
 var structure=Decor.new();var furnishings=Decor.new();var rooms=0
 for c in floor.cells:
  var p=Vector3(c.x*7,y,c.y*7);var theme=floor.themes[c];var stair=theme=="Stairs"
  if index==0 or not stair:structure.cube(p+Vector3(0,-0.12,0),Vector3(7,0.24,7),Color("a4aa98"),true)
  if index==blueprint.floor_count-1:structure.cube(p+Vector3(0,Interiors.HEIGHT,0),Vector3(7,0.18,7),Color("637470"),true)
  for dir in Interiors.DIRS:
   var next=c+dir
   if not floor.cells.has(next):
    var centre=p+Vector3(dir.x*3.5,Interiors.HEIGHT*0.5,dir.y*3.5)
    structure.cube(centre,Vector3(0.18,Interiors.HEIGHT,7) if dir.x else Vector3(7,Interiors.HEIGHT,0.18),Color("859080"),true)
   elif dir in [Vector2i.RIGHT,Vector2i.DOWN]:doorway(structure,root,c,next,y,floor.edges.has(Interiors.edge_key(c,next)),floor.secrets.has(Interiors.edge_key(c,next)),index)
  if stair:continue
  if theme!="Lobby":furnishings.room(p,theme,rng)
  if rooms%4==0:make_sign(root,p+Vector3(0,2.8,-2.8),"%d-%03d / %s"%[index+1,rooms+1,theme])
  if rooms%12==0:
   var light=OmniLight3D.new();light.position=p+Vector3(0,3.7,0);light.light_energy=0.75;light.omni_range=16;light.light_color=Color("bbc9ad");root.add_child(light)
  if rooms%9==4:
   var locker_pos=p+Vector3(2.7,0,-1.4);var chest=box(root,locker_pos+Vector3(0,0.65,0),Vector3(0.7,1.3,0.6),mats.door)
   indoors_loot.append({"node":chest,"pos":locker_pos,"locked":rng.randf()<0.45,"taken":false})
  if rooms%8==3 and theme!="Lobby":
   var actor=Actor.new();indoor.add_child(actor)
   var identity=interior_key+"/occupant/%d/%d"%[index,rooms];var profile=Society.person(identity,interior_type,job_for(theme))
   actor.setup(profile.name,"citizen",p);actor.set_profile(profile);actor.floor_index=index;actor.managed=true;actor.path_timer=rng.randf_range(2,8);actors.append(actor)
  if dungeon and rooms%21==15:
   var hostile=Actor.new();indoor.add_child(hostile);hostile.setup("Rogue maintenance unit","hostile",p,true);hostile.floor_index=index;actors.append(hostile)
  rooms+=1
 structure.finish(root);furnishings.finish(root)
 # Physical ramps connect every floor. They occupy a two-cell, open stairwell.
 if index<blueprint.floor_count-1:
  var angle=-atan(Interiors.HEIGHT/14.0);var length=sqrt(14.0*14.0+Interiors.HEIGHT*Interiors.HEIGHT)
  var ramp=box(root,Vector3(0,y+Interiors.HEIGHT*0.5,10.5),Vector3(3.2,0.18,length),mats.concrete)
  ramp.rotation.x=angle
  for side in [-1,1]:
   var rail=box(root,Vector3(side*1.65,y+Interiors.HEIGHT*0.5+0.9,10.5),Vector3(0.08,0.1,length),mats.dark)
   rail.rotation.x=angle
 make_sign(root,Vector3(2.6,y+2.1,1),"FLOOR %d / %d
STAIRS AHEAD"%[index+1,blueprint.floor_count])
 root.visible=index<=1
func job_for(theme: String) -> String:
 match theme:
  "Medical":return "nurse"
  "Archive":return "library assistant"
  "Classroom":return "student"
  "Workshop","Mechanical":return "maintenance supervisor"
  "Cafeteria":return "cook"
  _:return "office administrator"
func tick_life(dt: float,player: Vector3,minutes: float):
 if not interior:population.tick(dt,player,minutes);return
 var floor=floor_at(player)
 if floor!=current_floor:
  current_floor=floor;indoor_cells=blueprint.floors[floor].cells
  for i in range(floor_roots.size()):floor_roots[i].visible=absi(i-floor)<=1
 for actor in actors:
  if not is_instance_valid(actor) or actor.get_parent()!=indoor:continue
  actor.visible=absi(actor.floor_index-current_floor)<=1
  if actor.hostile or actor.dead or actor.floor_index!=current_floor:continue
  actor.path_timer-=dt
  if actor.path.is_empty() and actor.path_timer<=0:
   var data=blueprint.floors[current_floor];var choices=data.cells.keys();var target=choices[actor.rng.randi_range(0,choices.size()-1)]
   actor.path=Interiors.path(data,Vector2i(roundi(actor.position.x/7),roundi(actor.position.z/7)),target);actor.path_timer=actor.rng.randf_range(6,15)
  if actor.path.size() and actor.position.distance_to(player)>1.5:
   var cell=actor.path[0];var target=Vector3(cell.x*7,current_floor*Interiors.HEIGHT,cell.y*7);var delta=target-actor.position
   if delta.length()<0.2:actor.path.pop_front()
   else:actor.position+=delta.normalized()*minf(delta.length(),dt*actor.walk_speed)
  actor.animate(dt,player)
func toggle_door(door: Dictionary):
 door.open=not door.open;door.node.rotation.y=PI*0.5 if door.open else 0
 interior_state[door.key]=door.open
 var edge=Interiors.edge_key(door.a,door.b)
 if door.open:blueprint.floors[door.floor].edges[edge]=true
 else:blueprint.floors[door.floor].edges.erase(edge)
 nav_cache.clear()
func leave():
 for a in actors.duplicate():
  if is_instance_valid(a) and a.get_parent()==indoor:actors.erase(a)
 indoor.hide();indoor.process_mode=Node.PROCESS_MODE_DISABLED;indoor.queue_free();interior=false;outdoor.show();ground.process_mode=Node.PROCESS_MODE_INHERIT
 for root in loaded.values():root.process_mode=Node.PROCESS_MODE_INHERIT
