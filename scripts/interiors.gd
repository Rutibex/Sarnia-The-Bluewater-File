extends RefCounted
const DIRS=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
const HEIGHT=4.4
const CELL=7.0
const THEMES=["Office","Archive","Classroom","Apartment","Dormitory","Medical","Washroom","Cafeteria","Lounge","Storage","Workshop","Mechanical"]
static func edge_key(a: Vector2i,b: Vector2i) -> String:
 return "%d,%d|%d,%d"%[a.x,a.y,b.x,b.y] if a.x<b.x or (a.x==b.x and a.y<b.y) else "%d,%d|%d,%d"%[b.x,b.y,a.x,a.y]
static func generate(identity: String,kind: String="building") -> Dictionary:
 var rng=RandomNumberGenerator.new();rng.seed=(identity+"/interior-v2").sha256_buffer().decode_s64(0)
 var dungeon=kind.contains("Fictional") or kind in ["industrial","warehouse","service"]
 var w=rng.randi_range(3,4) if dungeon else rng.randi_range(2,3)
 var depth=rng.randi_range(7,10) if dungeon else rng.randi_range(6,8)
 var floors=rng.randi_range(4,6) if dungeon else rng.randi_range(3,5)
 var result={"identity":identity,"floors":[],"floor_count":floors,"width":w,"depth":depth,"rooms":0,"seed":rng.seed}
 for f in range(floors):
  var cells={};var edges={};var themes={};var secret={}
  # A full rectangular maze with extra loops; all rooms have a guaranteed path.
  for x in range(-w,w+1):
   for z in range(depth):cells[Vector2i(x,z)]=true
  var visited={Vector2i.ZERO:true,Vector2i(0,1):true,Vector2i(0,2):true};var stack=[Vector2i.ZERO]
  while stack.size():
   var c=stack[-1];var candidates=[]
   for dir in DIRS:
    if cells.has(c+dir) and not visited.has(c+dir):candidates.append(c+dir)
   if candidates.is_empty():stack.pop_back();continue
   var next=candidates[rng.randi_range(0,candidates.size()-1)]
   edges[edge_key(c,next)]=true;visited[next]=true;stack.append(next)
  for c in cells:
   for dir in [Vector2i.RIGHT,Vector2i.DOWN]:
    if cells.has(c+dir) and rng.randf()<0.16:edges[edge_key(c,c+dir)]=true
   var theme=THEMES[rng.randi_range(0,THEMES.size()-1)]
   if kind in ["house","residential","apartments"]:theme=["Apartment","Lounge","Washroom","Storage"][rng.randi_range(0,3)]
   if dungeon:theme=["Mechanical","Workshop","Storage","Archive","Office"][rng.randi_range(0,4)]
   themes[c]=theme
  # Shared circulation around the stairwell; no floor can become isolated.
  for z in range(3):
   edges[edge_key(Vector2i(1,z),Vector2i(1,z+1))]=true
   edges[edge_key(Vector2i(0,z),Vector2i(0,z+1))]=true
  for z in [0,3]:edges[edge_key(Vector2i(0,z),Vector2i(1,z))]=true
  themes[Vector2i.ZERO]="Lobby";themes[Vector2i(0,1)]="Stairs";themes[Vector2i(0,2)]="Stairs"
  # Secret doors are optional shortcuts, never the only way to a required room.
  for c in cells:
   var next=c+Vector2i.RIGHT
   if cells.has(next) and not edges.has(edge_key(c,next)) and rng.randf()<0.05:secret[edge_key(c,next)]=[c,next]
  result.floors.append({"cells":cells,"edges":edges,"themes":themes,"secrets":secret,"locks":[],"floor":f})
  result.rooms+=cells.size()-2
 return result
static func reachable(floor: Dictionary) -> int:
 var queue=[Vector2i.ZERO];var seen={Vector2i.ZERO:true}
 while queue.size():
  var c=queue.pop_front()
  for dir in DIRS:
   var n=c+dir
   if floor.cells.has(n) and not seen.has(n) and floor.edges.has(edge_key(c,n)):seen[n]=true;queue.append(n)
 return seen.size()
static func path(floor: Dictionary,from: Vector2i,to: Vector2i) -> Array:
 if not floor.cells.has(from) or not floor.cells.has(to):return []
 var queue=[from];var prev={from:from}
 while queue.size():
  var c=queue.pop_front()
  if c==to:break
  for dir in DIRS:
   var n=c+dir
   if floor.cells.has(n) and floor.themes[n]!="Stairs" and not prev.has(n) and floor.edges.has(edge_key(c,n)):prev[n]=c;queue.append(n)
 if not prev.has(to):return []
 var route=[to];var c=to
 while c!=from:c=prev[c];route.push_front(c)
 return route
