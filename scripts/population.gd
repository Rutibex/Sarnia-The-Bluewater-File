extends RefCounted
const Actor=preload("res://scripts/actor.gd")
const Vehicle=preload("res://scripts/vehicle.gd")
const Society=preload("res://scripts/society.gd")
var world
var graph={}
var pedestrians: Array=[]
var vehicles: Array=[]
var refresh_timer=99.0
var generation=0
var rng=RandomNumberGenerator.new()
var density=1.0
var car_materials=[]
func setup(w):
 world=w;rng.seed=83313
 # Merge actual shared OSM road vertices. Bridges without shared vertices do
 # not become artificial intersections in this route graph.
 for road in world.data.roads:
  if road.kind in ["motorway","motorway_link","trunk","trunk_link","steps","proposed","construction"]:continue
  var width=12.0 if road.kind in ["primary","secondary"] else 9.0
  if road.kind in ["footway","path","cycleway"]:width=2.4
  elif road.kind in ["service","track"]:width=5.0
  for i in range(road.p.size()-1):
   var a=Vector2i(roundi(road.p[i][0]),roundi(road.p[i][1]));var b=Vector2i(roundi(road.p[i+1][0]),roundi(road.p[i+1][1]))
   if a==b or a.distance_to(b)>1200:continue
   if not graph.has(a):graph[a]=[]
   if not graph.has(b):graph[b]=[]
   graph[a].append({"to":b,"width":width});graph[b].append({"to":a,"width":width})
func pos(key: Vector2i) -> Vector3:return Vector3(key.x,0,key.y)
func choose(node: Vector2i,previous: Vector2i,vehicle: bool) -> Dictionary:
 var options=[]
 for edge in graph.get(node,[]):
  if vehicle and edge.width<5:continue
  if edge.to!=previous:options.append(edge)
 if options.is_empty():
  for edge in graph.get(node,[]):
   if not vehicle or edge.width>=5:options.append(edge)
 return options[rng.randi_range(0,options.size()-1)] if options.size() else {}
func lane(a: Vector2i,b: Vector2i,width: float,walking: bool) -> Vector3:
 var direction=(pos(b)-pos(a)).normalized();var right=direction.cross(Vector3.UP)
 return right*(width*0.5+0.75 if walking else width*0.25)
func refresh(player: Vector3,hour: int):
 for a in pedestrians.duplicate():
  if not is_instance_valid(a):pedestrians.erase(a);continue
  if a.position.distance_to(player)>650:
   world.actors.erase(a);pedestrians.erase(a);a.queue_free()
 for car in vehicles.duplicate():
  if not is_instance_valid(car):vehicles.erase(car);continue
  if car.position.distance_to(player)>750:vehicles.erase(car);car.queue_free()
 var nearby=[];var key=Vector2i(floori(player.x/256),floori(player.z/256))
 for x in range(-2,3):
  for z in range(-2,3):
   var k=key+Vector2i(x,z)
   if not world.chunks.has(k):continue
   for road in world.chunks[k].roads:
    if road[0].distance_to(player)<470:nearby.append(road)
 if nearby.is_empty():return
 var target=int((120 if hour>=6 and hour<22 else 48)*density)
 var car_target=int((48 if hour>=6 and hour<22 else 24)*density)
 while pedestrians.size()>target:
  var a=pedestrians.pop_back();world.actors.erase(a);a.queue_free()
 while vehicles.size()>car_target:vehicles.pop_back().queue_free()
 var attempts=0
 while (pedestrians.size()<target or vehicles.size()<car_target) and attempts<100:
  attempts+=1;var road=nearby[rng.randi_range(0,nearby.size()-1)]
  var a=Vector2i(roundi(road[0].x),roundi(road[0].z));var edge=choose(a,a,false)
  if edge.is_empty():continue
  var b=edge.to;var t=rng.randf_range(0.05,0.95)
  if pedestrians.size()<target:
   var point=pos(a).lerp(pos(b),t)+lane(a,b,edge.width,true)
   if point.distance_to(player)>480 or point.distance_to(player)<3 or world.point_in_building(point):continue
   var citizen=Actor.new();world.outdoor.add_child(citizen);var id="street/%d/%d/%d"%[a.x,a.y,generation];generation+=1
   var profile=Society.person(id,road[3]);citizen.setup(profile.name,"citizen",point);citizen.set_profile(profile);citizen.managed=true;citizen.path_timer=rng.randf_range(0.0,0.4)
   citizen.route_from=a;citizen.route_to=b;citizen.route_width=edge.width;pedestrians.append(citizen);world.actors.append(citizen)
  if vehicles.size()<car_target:
   var ve=choose(a,a,true)
   if ve.is_empty():continue
   var spawn=pos(a).lerp(pos(ve.to),t)+lane(a,ve.to,ve.width,false)
   if spawn.distance_to(player)<12:continue
   var crowded=false
   for other in vehicles:
    if other.position.distance_to(spawn)<9:crowded=true;break
   if crowded:continue
   var car=Vehicle.new();world.outdoor.add_child(car);car.setup(["Car","Car","Pickup","Van","Bus"][rng.randi_range(0,4)],Color.from_hsv(rng.randf(),rng.randf_range(0.1,0.5),rng.randf_range(0.4,0.85)));car.route_from=a;car.route_to=ve.to;car.previous=a;car.road_width=ve.width
   car.position=spawn;vehicles.append(car)
func tick(dt: float,player: Vector3,minutes: float):
 if world.interior:return
 refresh_timer+=dt
 if refresh_timer>2:
  refresh_timer=0;refresh(player,int(minutes/60)%24)
 for a in pedestrians:
  if not is_instance_valid(a) or a.dead or a.hostile:continue
  var destination=pos(a.route_to)+lane(a.route_from,a.route_to,a.route_width,true)
  if a.position.distance_to(destination)<0.6:
   var edge=choose(a.route_to,a.route_from,false)
   if edge.is_empty():continue
   a.route_from=a.route_to;a.route_to=edge.to;a.route_width=edge.width;destination=pos(a.route_to)+lane(a.route_from,a.route_to,a.route_width,true)
  var direction=destination-a.position;direction.y=0
  if direction.length()>0.1 and a.position.distance_to(player)>1.2:
   var next=a.position+direction.normalized()*dt*a.walk_speed
   a.path_timer-=dt
   var blocked=false
   if a.path_timer<=0:a.path_timer=0.3;blocked=world.point_in_building(next+direction.normalized()*0.5)
   if not blocked:a.position=next
   else:
    var temp=a.route_from;a.route_from=a.route_to;a.route_to=temp
  a.animate(dt,player)
 # Light traffic: right-hand lane offsets, shared junction phases, queues,
 # pedestrian/player yielding and no simulation outside the active district.
 var time=Time.get_ticks_msec()/1000.0
 var walkers={}
 for a in pedestrians:
  if not is_instance_valid(a):continue
  var k=Vector2i(floori(a.position.x/10),floori(a.position.z/10))
  if not walkers.has(k):walkers[k]=[]
  walkers[k].append(a.position)
 for car in vehicles:
  var destination=pos(car.route_to)+lane(car.route_from,car.route_to,car.road_width,false)
  var delta=destination-car.position;var distance=delta.length()
  if distance<1:
   var edge=choose(car.route_to,car.route_from,true)
   if edge.is_empty():continue
   car.previous=car.route_from;car.route_from=car.route_to;car.route_to=edge.to;car.road_width=edge.width;continue
  var direction=delta.normalized();var stop=false
  if distance<10 and graph.get(car.route_to,[]).size()>2:
   var ns=absf(direction.z)>absf(direction.x);var phase=int(time+absi(car.route_to.x+car.route_to.y)%6)%16
   stop=(phase>=7 if ns else phase<9)
  for other in vehicles:
   if other==car:continue
   var gap=other.position-car.position
   if gap.length()<7.5 and gap.dot(direction)>0 and absf(gap.cross(direction).y)<2.0:stop=true;break
  var grid=Vector2i(floori(car.position.x/10),floori(car.position.z/10))
  for dx in [-1,0,1]:
   for dz in [-1,0,1]:
    for p in walkers.get(grid+Vector2i(dx,dz),[]):
     var gap=p-car.position
     if gap.length()<5 and gap.dot(direction)>0 and absf(gap.cross(direction).y)<1.6:stop=true
  var user=player-car.position
  if user.length()<6 and user.dot(direction)>0:stop=true
  car.speed=move_toward(car.speed,0.0 if stop else car.cruise,dt*(8 if stop else 2.5));car.position+=direction*car.speed*dt
  car.rotation.y=lerp_angle(car.rotation.y,atan2(-direction.x,-direction.z),minf(1,dt*5))
