extends Control
var game
var centre=Vector2(0,0)
var zoom=0.11
var drag=false
func _ready():
 mouse_filter=Control.MOUSE_FILTER_STOP;texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR;clip_contents=true;custom_minimum_size=Vector2(650,450)
var floor_view=-1
var last_draw_usec=0
var tiles_drawn=0
func _gui_input(e):
 if e is InputEventMouseButton:
  if e.pressed and e.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
   var at=centre+(e.position-size*0.5)/zoom
   var factor=1.25 if e.button_index==MOUSE_BUTTON_WHEEL_UP else 0.8
   zoom=clampf(zoom*factor,0.5 if game.world.interior else 0.025,24.0 if game.world.interior else 2.0)
   centre=at-(e.position-size*0.5)/zoom
  if e.button_index==MOUSE_BUTTON_LEFT:drag=e.pressed
  queue_redraw();accept_event()
 if e is InputEventMouseMotion and drag:centre-=e.relative/zoom;queue_redraw();accept_event()
func screen(p: Array) -> Vector2:return (Vector2(p[0],p[1])-centre)*zoom+size*0.5
func _draw():
 var began=Time.get_ticks_usec()
 tiles_drawn=0
 draw_rect(Rect2(Vector2.ZERO,size),Color("182c30"))
 if not game:return
 if game.world.interior:
  draw_interior();last_draw_usec=Time.get_ticks_usec()-began;return
 draw_tiles()
 for p in game.world.faction_points:
  var v=screen(p.p);draw_circle(v,5,Color("e1bc7b"));draw_string(ThemeDB.fallback_font,v+Vector2(8,-5),p.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e4d9bc"))
 if game.rules.s.has("rumor_mark"):
  var r=game.rules.s.rumor_mark;var v=screen(r.p);draw_circle(v,9,Color("85c9c1"),false,2);draw_string(ThemeDB.fallback_font,v+Vector2(12,-12),r.name,HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("9ed3c8"))
 for q in game.rules.s.quests:
  if q.status=="active" and not q.done:
   var v=screen(q.pos);draw_circle(v,7,Color("d47650"));draw_string(ThemeDB.fallback_font,v+Vector2(10,16),q.target,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("efbc8c"))
 var pos=game.world.last_out if game.world.interior else game.player.position
 var me=screen([pos.x,pos.z]);draw_circle(me,6,Color("e9e4ce"));draw_line(me,me+Vector2(sin(game.player.rotation.y),cos(game.player.rotation.y))*-18,Color.WHITE,2)
 draw_string(ThemeDB.fallback_font,Vector2(16,24),"SARNIA / OPENSTREETMAP     •     drag to pan · wheel to zoom",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e3d5b8"))
 draw_string(ThemeDB.fallback_font,Vector2(16,size.y-18),"© OpenStreetMap contributors · ODbL 1.0   |   Scale: %d m across"%int(size.x/zoom),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("b6bda9"))
 last_draw_usec=Time.get_ticks_usec()-began

func draw_tiles():
 var meta=game.world.atlas_meta
 if meta.is_empty():return
 var level=clampi(int(floor(log(1.0/(2.0*zoom))/log(2.0))),0,meta.levels.size()-1)
 var info=meta.levels[level];var span=float(info.world_size)
 var origin=Vector2(meta.origin[0],meta.origin[1])
 var low=centre-size*0.5/zoom;var high=centre+size*0.5/zoom
 var left=maxi(0,floori((low.x-origin.x)/span));var right=mini(int(info.cols)-1,floori((high.x-origin.x)/span))
 var top=maxi(0,floori((low.y-origin.y)/span));var bottom=mini(int(info.rows)-1,floori((high.y-origin.y)/span))
 # Draw only the visible tiles at a suitable detail level. Text and markers
 # remain vector overlays, so panning never rebuilds city polygons.
 for y in range(top,bottom+1):
  for x in range(left,right+1):
   var texture=game.world.atlas_texture(level,x,y)
   if texture:
    var corner=(origin+Vector2(x,y)*span-centre)*zoom+size*0.5
    draw_texture_rect(texture,Rect2(corner,Vector2.ONE*span*zoom),false)
    tiles_drawn+=1


func fit_floor():
 if not game.world.interior:return
 var b=game.world.blueprint
 centre=Vector2(0,(int(b.depth)-1)*3.5)
 zoom=minf(size.x/(float(b.width)*14+15),size.y/(float(b.depth)*7+8))
 queue_redraw()
func draw_interior():
 var world=game.world
 var f=world.current_floor if floor_view<0 else clampi(floor_view,0,world.blueprint.floor_count-1)
 var floor=world.blueprint.floors[f];var walls=PackedVector2Array()
 for c in floor.cells:
  var p=screen([c.x*7,c.y*7]);var stair=floor.themes[c]=="Stairs"
  draw_rect(Rect2(p-Vector2.ONE*3.5*zoom,Vector2.ONE*7*zoom),Color("496b72") if stair else Color("586c60"))
  for dir in world.Interiors.DIRS:
   var n=c+dir;var connected=floor.cells.has(n) and floor.edges.has(world.Interiors.edge_key(c,n))
   if c.x==0 and n.x==0 and mini(c.y,n.y)<=2 and maxi(c.y,n.y)>=0 and connected:continue
   var mid=Vector2(c.x*7+dir.x*3.5,c.y*7+dir.y*3.5)
   var along=Vector2(0,1) if dir.x else Vector2(1,0)
   var spans=[[-3.5,-0.9],[0.9,3.5]] if connected else [[-3.5,3.5]]
   for span in spans:
    walls.append((mid+along*span[0]-centre)*zoom+size*0.5);walls.append((mid+along*span[1]-centre)*zoom+size*0.5)
 if walls.size():draw_multiline(walls,Color("c1bfa2"),1.4)
 for chest in world.indoors_loot:
  if not chest.taken and world.floor_at(chest.pos)==f:draw_circle(screen([chest.pos.x,chest.pos.z]),3,Color("d7ad64"))
 for a in world.actors:
  if is_instance_valid(a) and a.get_parent()==world.indoor and a.floor_index==f and not a.dead:draw_circle(screen([a.position.x,a.position.z]),2,Color("d47759") if a.hostile else Color("87c6ac"))
 if f==world.current_floor:
  var p=game.player.position;draw_circle(screen([p.x,p.z]),5,Color("f0ecd8"))
 if f==0:draw_circle(screen([0,-2]),6,Color("8cc3ce"),false,2)
 draw_string(ThemeDB.fallback_font,Vector2(16,24),"%s / FLOOR %d OF %d"%[world.interior_type.to_upper(),f+1,world.blueprint.floor_count],HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("e3d5b8"))
 draw_string(ThemeDB.fallback_font,Vector2(16,size.y-16),"Blue: stairwell · gold: lockers · green: citizens · white: you",HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("d5d0b3"))
