extends SceneTree
const Interiors=preload("res://scripts/interiors.gd")
const Society=preload("res://scripts/society.gd")
var checks=0
func expect(value: bool,text: String):
 assert(value,text);checks+=1
func _initialize():call_deferred("run")
func run():
 var hashes={}
 for n in range(80):
  var plan=Interiors.generate("OSM/test/"+str(n),"house" if n%2 else "industrial")
  expect(plan.floor_count>=3 and plan.floor_count<=6,"multiple floors")
  expect(plan.rooms>=75,"complex interiors")
  var stamp=str(plan.seed);expect(not hashes.has(stamp),"unique building seed");hashes[stamp]=true
  for f in plan.floors:
   expect(Interiors.reachable(f)==f.cells.size(),"every room connected")
   for cell in f.cells:
    if f.themes[cell]=="Stairs":continue
    expect(Interiors.path(f,Vector2i.ZERO,cell).size()>0,"every room reachable without walking across stair holes")
  var again=Interiors.generate("OSM/test/"+str(n),"house" if n%2 else "industrial")
  expect(plan.seed==again.seed and plan.floors[0].edges==again.floors[0].edges,"repeatable layout")
 var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.begin();game.ui.close();var world=game.world
 world.population.refresh(game.player.position,10)
 expect(world.population.pedestrians.size()>=20,"street population")
 expect(world.population.vehicles.size()>=10,"street vehicles")
 var initial={}
 for a in world.population.pedestrians:initial[a.get_instance_id()]=a.position
 for i in range(120):world.population.tick(1.0/60.0,game.player.position,600)
 var moved=0
 for a in world.population.pedestrians:
  if initial.has(a.get_instance_id()) and a.position.distance_to(initial[a.get_instance_id()])>0.4:moved+=1
 expect(moved>10,"citizens actually walk")
 var profile=world.population.pedestrians[0].profile
 expect(profile.id!="" and profile.job!="","citizen biography")
 var greeting=Society.greeting(profile,game.rules.s)
 expect(greeting.contains(profile.name),"personalized greeting")
 var lines={}
 for topic in Society.TOPICS:
  var reply=Society.reply(profile,topic,"Polite",game.rules,world);expect(reply.text.length()>20,"generated topic response");lines[reply.text]=true
 expect(lines.size()>=4,"varied generated conversation")
 expect(game.rules.s.citizen_memory.has(profile.id),"conversation memory stored")
 game.enter_interior("Fictional service complex");expect(world.blueprint.floor_count>=4,"complex multiple floors")
 expect(world.indoors_loot.size()>10,"many furnished rooms and lockers")
 var occupants=0
 for actor in world.actors:
  if actor.get_parent()==world.indoor and not actor.hostile:occupants+=1
 expect(occupants>=20,"citizens on every building floor")
 for f in range(world.blueprint.floor_count):
  world.tick_life(0.1,Vector3(0,f*Interiors.HEIGHT+0.1,21),600);expect(world.current_floor==f,"floor tracking")
 expect(world.doors.size()>0,"optional secret service panels")
 if world.doors.size():
  var door=world.doors[0];world.toggle_door(door);expect(world.interior_state.has(door.key),"panel state persists")
 var identity=world.interior_key;var old_seed=world.blueprint.seed;world.leave();game.enter_interior("Fictional service complex")
 expect(world.interior_key==identity and world.blueprint.seed==old_seed,"interior stable on return")
 game.stop_audio();await create_timer(0.1).timeout;game.queue_free();game=null;await process_frame;await process_frame
 print("PASS: ",checks," population, layout, dialogue and persistence checks")
 quit()
