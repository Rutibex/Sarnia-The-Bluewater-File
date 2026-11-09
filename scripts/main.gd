extends Node3D
const Society=preload("res://scripts/society.gd")
const Rules=preload("res://scripts/rules.gd")
const World=preload("res://scripts/world.gd")
const Interface=preload("res://scripts/interface.gd")
var rules=Rules.new()
var conversation_actor
var conversation_profile={}
var conversation_text=""
var conversation_tone="Direct"
var world
var ui
var player: CharacterBody3D
var camera: Camera3D
var sun: DirectionalLight3D
var env: WorldEnvironment
var started=false
var street="Christina Street North"
var tick=0.0
var move_tick=0.0
var swing=0.0
var attack_cooldown=0.0
var selected_device=0
var active_effects={}
var watch_seconds=0.0
var street_timer=0.0
var effect_time=0.0
var selected_poi={}
var hud_draw: Control
var targets_visible=false
var current_hint=""
var prior_wall_time=0.0
var patrol_spawned=false
var ambience: AudioStreamPlayer
var fx: AudioStreamPlayer
var foot: AudioStreamPlayer
var foot_timer=0.0
func _ready():
 seed(7193)
 ambience=AudioStreamPlayer.new();var audio=load("res://assets/ambience.wav");audio.loop_mode=AudioStreamWAV.LOOP_FORWARD;audio.loop_end=audio.data.size()/2;ambience.stream=audio;ambience.volume_db=-9;add_child(ambience);ambience.play()
 fx=AudioStreamPlayer.new();fx.stream=load("res://assets/tool.wav");fx.volume_db=-5;add_child(fx)
 foot=AudioStreamPlayer.new();foot.stream=load("res://assets/step.wav");foot.volume_db=-10;add_child(foot)
 world=World.new();add_child(world);world.setup()
 make_player()
 env=WorldEnvironment.new();var e=Environment.new();e.background_mode=Environment.BG_COLOR;e.background_color=Color("839b9e");e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("a1b6ba");e.ambient_light_energy=0.65;e.tonemap_mode=Environment.TONE_MAPPER_FILMIC;e.fog_enabled=true;e.fog_light_color=Color("9eafa8");e.fog_density=0.0015;env.environment=e;add_child(env)
 sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-27,-125,0);sun.light_color=Color("ffd6a0");sun.light_energy=1.1;add_child(sun)
 ui=Interface.new();add_child(ui);ui.setup(self)
 hud_draw=Control.new();hud_draw.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);hud_draw.mouse_filter=Control.MOUSE_FILTER_IGNORE;ui.root.add_child(hud_draw);hud_draw.draw.connect(draw_tool)
 player.position=world.street_position(Vector3(0,0,10))+Vector3(0,0.2,0);player.rotation.y=-0.5
 world.update_chunks(player.position)
 if "--capture" in OS.get_cmdline_user_args():call_deferred("capture_run")
 if "--smoke" in OS.get_cmdline_user_args():
  begin();rules.note("Smoke run");ui.close();await get_tree().create_timer(3).timeout
  print("SMOKE world: ",world.data.buildings.size()," buildings; ",world.loaded.size()," chunks")
  world.enter("Fictional service complex",player.position,player.rotation.y);player.position=Vector3(0,0.1,0)
  await get_tree().create_timer(2).timeout
  print("SMOKE interior: ",world.indoors_loot.size()," lockers")
  world.leave();player.position=world.last_out;ui.open("Character");await get_tree().process_frame;ui.open("Atlas");await get_tree().process_frame;ui.open("Services");await get_tree().process_frame
  print("SMOKE complete");stop_audio();await get_tree().create_timer(0.1).timeout;get_tree().quit()
func make_player():
 player=CharacterBody3D.new();player.name="Resident";add_child(player)
 var shape=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.32;capsule.height=1.8;shape.shape=capsule;shape.position.y=0.9;player.add_child(shape)
 camera=Camera3D.new();camera.position.y=1.65;camera.fov=76;camera.near=0.2;camera.far=1500;player.add_child(camera);camera.current=true
 var light=OmniLight3D.new();light.position=Vector3(0,1.7,0);light.omni_range=16;light.light_energy=0.7;light.light_color=Color("e3d8b2");player.add_child(light)
func begin():
 world.interior_state={}
 started=true;player.position=world.street_position(Vector3(0,0,10))+Vector3(0,0.1,0);selected_device=0;ui.close();rules.note("Welcome to Sarnia. Speak to Civic Liaison by City Hall. [E]")
func load_game():
 if rules.load_game():
  if world.interior:world.leave()
  world.interior_state=rules.s.get("interior_doors",{})
  started=true;player.position=world.v3([0,0])+Vector3.UP*0.1
  if rules.s.has("position"):player.position=Vector3(rules.s.position[0],rules.s.position[1],rules.s.position[2])
  player.rotation.y=rules.s.get("yaw",0.0);ui.close();selected_device=0
func key(code: int) -> bool:return Input.is_physical_key_pressed(code)
func _unhandled_input(e):
 if e is InputEventKey and e.pressed and not e.echo:
  if e.keycode==KEY_ESCAPE:
   if ui.panel.visible:ui.close()
   else:ui.open("Help")
   return
  if not started:return
  if e.keycode==KEY_F5:
   rules.s.interior_doors=world.interior_state
   if world.interior:rules.save_game(world.last_out,world.last_yaw)
   else:rules.save_game(player.position,player.rotation.y)
   return
  if e.keycode==KEY_F9:load_game();return
  if ui.panel.visible:return
  var tabs={KEY_TAB:"Character",KEY_I:"Inventory",KEY_J:"Journal",KEY_M:"Atlas",KEY_F:"Factions",KEY_R:"Rest",KEY_T:"Devices"}
  if tabs.has(e.keycode):ui.open(tabs[e.keycode]);return
  if e.keycode==KEY_E:interact()
  if e.keycode==KEY_B:cycle_transport()
  if e.keycode>=KEY_1 and e.keycode<=KEY_8:selected_device=mini(e.keycode-KEY_1,rules.s.devices.size()-1);rules.note("Selected "+rules.s.devices[selected_device].name)
 if e is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not ui.panel.visible:
  player.rotation.y-=e.relative.x*0.0024;camera.rotation.x=clampf(camera.rotation.x-e.relative.y*0.0024,-1.45,1.45)
 if e is InputEventMouseButton and e.pressed and not ui.panel.visible and started:
  if Input.mouse_mode!=Input.MOUSE_MODE_CAPTURED:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;return
  if e.button_index==MOUSE_BUTTON_LEFT:attack()
  if e.button_index==MOUSE_BUTTON_RIGHT:use_device()
func _process(dt):
 if not ui.panel.visible:world.update_chunks(player.position)
 ui.update();hud_draw.queue_redraw();swing=maxf(0,swing-dt*4);attack_cooldown=maxf(0,attack_cooldown-dt)
 if not started or ui.panel.visible:return
 world.tick_life(dt,player.position,rules.s.minutes)
 tick+=dt;street_timer+=dt
 if street_timer>1:
  street_timer=0;street=world.nearest_road(player.position) if not world.interior else world.interior_type+" / floor %d"%(world.current_floor+1);update_hint()
  for m in world.markers:m.visible=m.global_position.distance_to(player.position)<170
 if tick>1:
  rules.advance(tick*2.0);tick=0
  for k in active_effects.keys():
   active_effects[k]-=1
   if active_effects[k]<=0:active_effects.erase(k)
  var hour=int(rules.s.minutes/60)%24;var night=hour<6 or hour>=20
  sun.light_energy=0.12 if night else 1.1
  env.environment.background_color=Color("1a2a39") if night else Color("839b9e")
  env.environment.ambient_light_energy=0.3 if night else 0.65
  if rules.s.condition=="Experimental implant" and not night:rules.s.energy=maxf(0,rules.s.energy-0.15)
  if rules.s.condition=="Night-shift dependency" and not night:rules.s.stamina=maxf(0,rules.s.stamina-0.3)
  if rules.s.sensitive and night:rules.s.stamina=maxf(0,rules.s.stamina-0.15)
  if world.interior and randf()<0.008*(1.2-float(rules.s.attrs.Willpower)/250.0) and not active_effects.has("filter"):
   rules.s.poison=true;rules.note("A leaking canister exposed you to fictional chemical fumes. Seek treatment.")
  update_watch()
  if rules.s.wanted>0 and not world.interior and not patrol_spawned:
   var guard=World.Actor.new();world.outdoor.add_child(guard);guard.setup("Civic Patrol","guard",world.street_position(player.position+Vector3(10,0,8)),true);world.actors.append(guard);patrol_spawned=true;rules.note("A fictional civic patrol approaches. Press E nearby to resolve the offence.")
 for a in world.actors:
  if not is_instance_valid(a) or a.dead:continue
  var inside=a.get_parent()==world.indoor
  if inside!=world.interior:continue
  if world.interior and a.floor_index!=world.current_floor:continue
  if a.managed and not a.hostile:continue
  if a.position.distance_to(player.position)>100:continue
  if a.hostile and rules.s.sneaking and a.position.distance_to(player.position)>maxf(5,25-rules.s.skills.Stealth*0.18):continue
  if a.hostile and active_effects.has("veil") and a.position.distance_to(player.position)>7:continue
  var old=a.position
  var chase=world.navigate(a.position,player.position) if world.interior and a.hostile else player.position
  a.tick(dt,chase)
  if a.hostile:
   var ray=PhysicsRayQueryParameters3D.create(old+Vector3.UP,a.position+Vector3.UP);ray.exclude=[player.get_rid()]
   if get_world_3d().direct_space_state.intersect_ray(ray):a.position=old
   if a.position.distance_to(player.position)<2.3 and a.cooldown<=0:
    a.cooldown=1.6
    rules.practice("Evasion",3)
    if randf()*100>rules.s.skills.Evasion*0.45:
     rules.s.hp-=maxf(1,7+rules.s.level*0.5-rules.armour()*0.35-(8 if active_effects.has("shield") else 0))
     rules.note("The rogue unit strikes you.")
 if rules.s.hp<=0:knockout()
func _physics_process(dt):
 if not started or ui.panel.visible:return
 var s=rules.s
 var input=Vector2(float(key(KEY_D))-float(key(KEY_A)),float(key(KEY_S))-float(key(KEY_W))).normalized()
 s.sneaking=key(KEY_CTRL)
 camera.position.y=lerpf(camera.position.y,1.05 if s.sneaking else 1.65,dt*8)
 var speed=4.2+float(s.attrs.Speed-50)*0.035+float(s.skills.Running)*0.008
 var sprint=key(KEY_SHIFT) and s.stamina>1 and input.length()>0
 if sprint:speed*=1.7;s.stamina=maxf(0,s.stamina-dt*2.7)
 else:s.stamina=minf(100,s.stamina+dt*1.1)
 if s.sneaking:speed*=0.45
 if s.mode=="Bicycle":speed=10
 if s.mode=="Work van":speed=18
 if world.interior and s.mode!="Walk":s.mode="Walk"
 if rules.weight()>rules.capacity():speed*=0.35
 if s.disease:speed*=0.85
 if active_effects.has("grapple"):speed*=1.25
 var direction=player.transform.basis*Vector3(input.x,0,input.y)
 player.velocity.x=direction.x*speed;player.velocity.z=direction.z*speed
 player.velocity.y-=24*dt
 if key(KEY_SPACE) and player.is_on_floor():player.velocity.y=5.5+float(s.skills.Jumping)*0.035;rules.practice("Jumping",1)
 if key(KEY_E) and player.is_on_wall() and input.y<0:
  player.velocity.y=1.6+float(s.skills.Climbing)*0.025;rules.practice("Climbing",dt*2)
 if active_effects.has("grapple") and key(KEY_SPACE):player.velocity.y=3
 player.move_and_slide()
 if player.position.y< -20:player.position=Vector3(0,0.2,0) if world.interior else world.street_position(player.position)+Vector3.UP
 if input.length()>0:
  foot_timer+=dt
  if foot_timer>(0.28 if sprint else 0.48) and player.is_on_floor():foot_timer=0;foot.play()
  move_tick+=dt
  if move_tick>2:
   move_tick=0;rules.practice("Stealth" if s.sneaking else "Running",1)
   if not world.interior and world.water_at(player.position):
    rules.practice("Swimming",3);s.stamina=maxf(0,s.stamina-4)
    if s.stamina<=0 and not active_effects.has("filter"):s.hp-=4
func active_actors() -> Array:
 return world.actors.filter(func(a):return is_instance_valid(a) and (a.get_parent()==world.indoor)==world.interior)
func nearby_actor():
 var nearest=null;var best=4.5
 for a in active_actors():
  var d=player.position.distance_to(a.position)
  if world.interior and a.floor_index!=world.current_floor:continue
  if d<best:nearest=a;best=d
 return nearest
func nearest_poi(maxdist: float=14.0):
 var pbest={};var best=maxdist
 for p in world.points:
  var d=player.position.distance_to(world.v3(p.p))
  if d<best:best=d;pbest=p
 return pbest
func update_hint():
 var a=nearby_actor();current_hint=""
 if a:current_hint="E  /  "+("Search salvage" if a.dead else "Speak to "+a.title)
 elif world.interior:
  for door in world.doors:
   if door.floor==world.current_floor and player.position.distance_to(door.pos)<2.6:current_hint="E / "+("Close service panel" if door.open else "Examine secret service panel")
  if not current_hint.is_empty():ui.hint.text=current_hint;return
  if player.position.distance_to(Vector3(0,0,-2))<4:current_hint="E  /  Return to Sarnia"
  else:
   for c in world.indoors_loot:
    if not c.taken and player.position.distance_to(c.pos)<3:current_hint="E  /  "+("Pick secured locker" if c.locked else "Search locker")
 else:
  var p=nearest_poi(20)
  if not p.is_empty():current_hint="E  /  "+p.name
  else:
   var b=nearby_building()
   if not b.is_empty():current_hint="E  /  Enter "+(b.name if b.name!="" else "building")
 ui.hint.text=current_hint
func nearby_building() -> Dictionary:
 var key2=Vector2i(floori(player.position.x/256),floori(player.position.z/256));var best=3.5;var found={}
 for dx in [-1,0,1]:
  for dz in [-1,0,1]:
   var k=key2+Vector2i(dx,dz)
   if not world.chunks.has(k):continue
   for b in world.chunks[k].buildings:
    for i in range(b.p.size()-1):
     var a=world.v3(b.p[i]);var ab=world.v3(b.p[i+1])-a;var q=a+ab*clampf((player.position-a).dot(ab)/maxf(0.01,ab.length_squared()),0,1);var dist=q.distance_to(player.position)
     if dist<best:best=dist;found=b
 return found
func interact():
 var a=nearby_actor()
 if a:
  if a.dead:
   if a.title=="Searched":return
   a.title="Searched";rules.s.money+=randi_range(15,45);rules.s.inventory.append(rules.roll_loot());rules.note("Recovered a circuit and petty cash.");return
  if a.title=="Civic Patrol":ui.service="Civic Patrol";ui.open("Court");return
  if a.hostile:
   var language="Machine Logic";rules.practice(language,5)
   if randf()*100<rules.s.skills[language]*0.7:a.hostile=false;a.label.text="Disabled unit";rules.note("You disabled the unit using its maintenance protocol.")
   else:rules.note("The maintenance protocol was rejected.")
   return
  conversation_actor=a;conversation_profile=a.profile;conversation_text=Society.greeting(a.profile,rules.s);conversation_tone="Direct"
  ui.service=a.title;ui.open("Conversation");return
 if world.interior:
  for door in world.doors:
   if door.floor==world.current_floor and player.position.distance_to(door.pos)<2.6:
    world.toggle_door(door);rules.s.interior_doors=world.interior_state;rules.practice("Locks",2);rules.note("Service panel "+("opened. A shortcut revealed." if door.open else "closed."));return
  if player.position.distance_to(Vector3(0,0,-2))<4:
   world.leave();player.position=world.last_out;player.rotation.y=world.last_yaw;return
  for c in world.indoors_loot:
   if c.taken or player.position.distance_to(c.pos)>3:continue
   var lootkey=world.interior_key+str(c.pos)
   if rules.s.get("looted",{}).has(lootkey):recovered_record();rules.note("Locker already searched. Investigation notes checked.");return
   if c.locked:
    rules.practice("Locks",5);rules.advance(5)
    if randf()*100<rules.s.skills.Locks+25:c.locked=false;rules.note("Lock opened.")
    else:rules.note("Lock resisted. You can try again; time passes.")
    return
   if not rules.s.has("looted"):rules.s.looted={}
   rules.s.looted[lootkey]=true
   c.taken=true;c.node.hide();rules.s.inventory.append(rules.roll_loot());rules.s.money+=randi_range(15,55)
   recovered_record();rules.note("Locker searched. Components recovered; journal updated.");return
  return
 var p=nearest_poi(20)
 if not p.is_empty():
  complete_arrival(p)
  if p.get("kind","")=="dungeon":enter_interior(p.name);return
  ui.service=p.name
  if p.get("kind","") in ["bank","pharmacy","cafe","restaurant","convenience","supermarket","mall","department_store","hardware","fuel","bicycle","car","library","townhall"]:ui.open("Services")
  else:enter_interior(p.name,str(int(p.get("id",0))) if p.has("id") else "",p.get("kind","building"))
  return
 var building=nearby_building()
 if not building.is_empty():enter_interior(building.name if building.name!="" else "Building #"+str(int(building.id)),str(int(building.id)),building.kind)
func enter_interior(n: String,identity: String="",kind: String=""):
 if not n.contains("Fictional") and (identity.is_empty() or not world.building_lookup.has(identity)):
  var building=world.identify_building(n,player.position)
  if not building.is_empty():identity=str(int(building.id));kind=building.kind
 world.interior_state=rules.s.get("interior_doors",{})
 world.enter(n,player.position,player.rotation.y,identity,kind);player.position=Vector3(0,0.1,0);player.rotation.y=PI;rules.advance(3);rules.note("Entered "+n+". The door behind you returns to the street.")
func attack():
 if attack_cooldown>0:return
 fx.play()
 var w=rules.weapon();attack_cooldown=maxf(0.15,0.7-float(rules.s.attrs.Speed)*0.004);swing=1
 var ranged=w.skill=="Marksmanship"
 if ranged:
  if rules.s.ammo<=0:rules.note("No ammunition. Buy rounds through local services.");return
  rules.s.ammo-=1
 rules.practice(w.skill,2);rules.s.stamina=maxf(0,rules.s.stamina-1.5)
 var target=aim_target(38 if ranged else 3.6)
 if not target:return
 if not target.hostile:rules.s.wanted+=1;rules.note("Assault reported. Your wanted level increased.");target.hostile=true
 var chance=45+float(rules.s.skills[w.skill])*0.5+float(rules.s.attrs.Agility-50)*0.15+float(rules.s.skills.Precision)*0.1+float(rules.s.attrs.Luck-50)*0.05
 rules.practice("Precision",1)
 if randf()*100>chance:rules.note("Your strike misses.");return
 var dmg=(float(w.power)+float(rules.s.attrs.Strength-50)*0.15)*float(w.condition)/100.0
 if rules.s.sneaking and target.position.distance_to(player.position)>1.5:
  dmg*=1.7;rules.practice("Ambush",3)
 if rules.s.condition=="Night-shift dependency" and (int(rules.s.minutes/60)%24>=20 or int(rules.s.minutes/60)%24<6):dmg*=1.3
 target.hit(dmg);w.condition=maxf(1,w.condition-0.3);rules.note("Hit for %d damage."%dmg)
 if target.dead:
  rules.note("Unit disabled. Search the salvage [E].")
  for q in rules.s.quests:
   if q.status=="active" and q.kind==3 and world.interior and q.target==world.interior_type:q.done=true
func aim_target(distance: float):
 var target=null;var best=distance;var forward=-camera.global_transform.basis.z
 for a in active_actors():
  if a.dead:continue
  var delta=(a.position+Vector3.UP)-camera.global_position;var d=delta.length()
  if d<best and delta.normalized().dot(forward)>0.9:
   var ray=PhysicsRayQueryParameters3D.create(camera.global_position,a.position+Vector3.UP);ray.exclude=[player.get_rid()]
   if not get_world_3d().direct_space_state.intersect_ray(ray):target=a;best=d
 return target
func use_device():
 var d=rules.s.devices[mini(selected_device,rules.s.devices.size()-1)];var cost=rules.device_cost(d)
 if rules.s.condition=="Experimental implant":cost*=0.7
 if rules.s.energy<cost:rules.note("Not enough battery charge.");return
 rules.s.energy-=cost;rules.practice(rules.ESCHOOL[int(d.effect)],3)
 var power=float(d.power)+float(d.scale)*float(rules.s.level);var duration=float(d.duration)
 match int(d.effect):
  0:rules.s.hp=minf(rules.s.max_hp,rules.s.hp+power);rules.note("Medical injector restores %d health."%power)
  1:
   var target=aim_target(25)
   if target:
    if not target.hostile:rules.s.wanted+=1;target.hostile=true
    target.hit(power);target.cooldown=3;rules.note("Stun pulse discharged.")
   else:rules.note("Stun pulse: no target.")
  2:active_effects.shield=duration;rules.note("Protective foam deployed.")
  3:active_effects.veil=duration;rules.note("Optical veil active. Enemy detection range reduced.")
  4:active_effects.survey=duration;rules.note("Survey active: locker locations highlighted.")
  5:active_effects.grapple=duration;rules.note("Grapple assist active. Hold Space to ascend.")
  6:active_effects.filter=duration;rules.s.poison=false;rules.note("Environmental filter active.")
  7:
   if rules.s.anchor.is_empty():
    if world.interior:rules.note("Set the extraction anchor outdoors first.")
    else:rules.s.anchor=[player.position.x,player.position.z];rules.note("Extraction anchor set.")
   else:
    if world.interior:world.leave()
    player.position=world.v3(rules.s.anchor)+Vector3.UP*0.1;rules.advance(30);rules.note("Extracted to anchor.")
func try_rest(hours: int):
 for a in active_actors():
  if a.hostile and not a.dead and a.position.distance_to(player.position)<25:rules.note("A hostile unit is too close to rest.");return
 rules.rest(hours)
func fast_travel(p: Dictionary):
 if world.interior:rules.note("Exit the interior before using transit.");return
 if rules.s.wanted>0:rules.note("Clear your wanted status before boarding transit.");return
 var d=player.position.distance_to(world.v3(p.p));var cost=int(4+d/1000.0*2)
 if rules.s.money<cost:rules.note("Transit fare is $%d."%cost);return
 rules.s.money-=cost;rules.advance(10+d/300.0);player.position=world.street_position(world.v3(p.p))+Vector3.UP*0.1;rules.note("Arrived near %s. Fare $%d."%[p.name,cost])
func cycle_transport():
 var modes=["Walk"]
 for m in ["Bicycle","Work van"]:
  if m in rules.s.properties:modes.append(m)
 rules.s.mode=modes[(modes.find(rules.s.mode)+1)%modes.size()];rules.note("Transport: "+rules.s.mode)
func quest_offers(f: String) -> Array:
 var offers=[];var rng=RandomNumberGenerator.new();rng.seed=absi(hash(f))+int(rules.s.minutes/1440)
 var eligible=world.points.filter(func(p):return world.v3(p.p).length()<6500)
 for i in range(3):
  var p=eligible[rng.randi_range(0,eligible.size()-1)]
  if i==2:
   var dungeons=world.points.filter(func(x):return x.get("kind","")=="dungeon")
   p=dungeons[rng.randi_range(0,dungeons.size()-1)]
  var kind=rng.randi_range(0,5)
  if kind==2:
   var ds=world.points.filter(func(x):return x.get("kind","")=="dungeon")
   p=ds[rng.randi_range(0,ds.size()-1)]
  offers.append(rules.make_quest(f,p,kind))
 return offers
func complete_arrival(p: Dictionary):
 for q in rules.s.quests:
  if q.status!="active" or q.target!=p.name:continue
  if q.kind in [0,1,5]:q.done=true;rules.practice("Protocol",4);rules.note("Handoff complete. Return to "+q.faction)
  if q.kind==4:q.done=true;rules.practice("Community Outreach",5);rules.note("Missing courier located. Report the safe return.")
func update_watch():
 for q in rules.s.quests:
  if q.status!="active" or q.done or q.kind!=3:continue
  if not world.interior and player.position.distance_to(world.v3(q.pos))<30:
   q.stage+=1
   if q.stage>=30:q.done=true;rules.note("Watch completed. Return to "+q.faction)
func recovered_record():
 for q in rules.s.quests:
  if q.status=="active" and q.kind==2 and q.target==world.interior_type:q.done=true
 if world.interior_type=="Fictional service complex" and rules.s.main_stage==1:
  rules.s.main_stage=2;rules.s.inventory.append(rules.item("Inspection Record A","evidence",0,0.1,0))
 if world.interior_type=="Fictional pumping station" and rules.s.main_stage==3:
  rules.s.main_stage=4;rules.s.inventory.append(rules.item("Inspection Record B","evidence",0,0.1,0))
func main_story(f: String):
 var s=rules.s
 match int(s.main_stage):
  0:
   if f=="Civic Liaison Office":s.main_stage=1;rules.note("A missing inspection record was last seen in the fictional service complex. Find it before somebody scraps the terminals.")
  1:rules.note("Search a locker in the fictional service complex. The atlas marks the entrance.")
  2:
   if f=="Civic Liaison Office":s.money+=200;s.main_stage=3;s.factions[f].rep+=10;rules.note("The record points to a fictional pumping station. Recover the second file.")
  3:rules.note("Search the fictional pumping station for a second inspection record.")
  4:
   if f=="Neighbourhood Aid":s.main_stage=5;s.money+=350;s.factions[f].rep+=30;rules.note("You released the Bluewater File. The cover-up is exposed. Campaign complete.")
   elif f=="Civic Liaison Office":s.main_stage=6;s.money+=750;s.factions[f].rep+=30;rules.note("You surrendered the records for a confidential settlement. Campaign complete.")
  _:rules.note("The Bluewater File has been resolved. Your life in Sarnia continues.")
func pickpocket():
 rules.practice("Light Fingers",5)
 if randf()*100<rules.s.skills["Light Fingers"]:rules.s.money+=randi_range(10,40);rules.note("You lifted some petty cash.")
 else:rules.s.wanted+=1;rules.note("You were seen. A fine is now outstanding.")
func knockout():
 if world.interior:world.leave()
 player.position=world.street_position(Vector3(0,0,10))+Vector3.UP*0.1;rules.s.hp=rules.s.max_hp*0.5;rules.s.money=maxi(0,rules.s.money-150);rules.s.wanted=0;rules.advance(360);rules.note("You woke after emergency treatment. Six hours passed; $150 treatment fee charged.")
func draw_tool():
 if not started or ui.panel.visible:return
 var size=get_viewport().get_visible_rect().size
 var centre=size*0.5
 hud_draw.draw_line(centre-Vector2(5,0),centre+Vector2(5,0),Color("e9e0be"),1)
 hud_draw.draw_line(centre-Vector2(0,5),centre+Vector2(0,5),Color("e9e0be"),1)
 # Code-drawn pixel-style hand/tool silhouette; original art, no borrowed assets.
 var origin=Vector2(size.x*0.72,size.y-136)+Vector2(-swing*85,-sin(swing*PI)*100)
 var tool=PackedVector2Array([origin+Vector2(12,0),origin+Vector2(-28,-150),origin+Vector2(-36,-180),origin+Vector2(-60,-194),origin+Vector2(-73,-179),origin+Vector2(-56,-165),origin+Vector2(-48,-147),origin+Vector2(-8,0)])
 hud_draw.draw_colored_polygon(tool,Color("303e41"));hud_draw.draw_polyline(tool,Color("97a09a"),3)
 hud_draw.draw_colored_polygon(PackedVector2Array([origin+Vector2(-16,0),origin+Vector2(-30,-52),origin+Vector2(-8,-68),origin+Vector2(12,-48),origin+Vector2(38,0)]),Color("bb916c"))
 hud_draw.draw_rect(Rect2(origin+Vector2(-12,-50),Vector2(27,14)),Color("88694e"))
 if active_effects.has("survey") and world.interior:
  for c in world.indoors_loot:
   if not c.taken and not camera.is_position_behind(c.node.global_position):hud_draw.draw_circle(camera.unproject_position(c.node.global_position+Vector3.UP),9,Color("d8c58a"),false,2)

func resolve_court(choice: String):
 var s=rules.s
 if choice=="pay":
  var fine=s.wanted*100
  if s.money<fine:rules.note("You cannot afford the fine.");return
  s.money-=fine
 elif choice=="contest":
  rules.practice("Protocol",6)
  if randf()*100>25+s.skills.Protocol*0.6:s.money=maxi(0,s.money-s.wanted*125);rules.advance(1440);rules.note("Appeal rejected; one day and a larger fine.")
  else:rules.note("Your appeal was accepted.")
 else:rules.advance(s.wanted*720);s.money=maxi(0,s.money-50);rules.note("You served a community-service sentence. Time passed.")
 s.wanted=0;patrol_spawned=false
 for a in world.actors:
  if is_instance_valid(a) and a.title=="Civic Patrol":a.hostile=false;a.title="Civic Liaison";a.label.text="Civic Liaison"
 ui.close()
func capture_run():
 await get_tree().create_timer(5).timeout
 get_viewport().get_texture().get_image().save_png("/tmp/sarnia-title.png")
 ui.open("New resident");await get_tree().create_timer(1).timeout
 get_viewport().get_texture().get_image().save_png("/tmp/sarnia-creation.png")
 begin();ui.close();player.rotation.y=0;await get_tree().create_timer(4).timeout
 get_viewport().get_texture().get_image().save_png("/tmp/sarnia-street.png")
 ui.open("Atlas");await get_tree().create_timer(1).timeout
 get_viewport().get_texture().get_image().save_png("/tmp/sarnia-atlas.png")
 ui.close();enter_interior("Fictional service complex");player.rotation.y=PI;await get_tree().create_timer(2).timeout
 get_viewport().get_texture().get_image().save_png("/tmp/sarnia-interior.png")
 print("CAPTURE complete");stop_audio();await get_tree().create_timer(0.1).timeout;get_tree().quit()

func stop_audio():
 for audio_player in [ambience,fx,foot]:
  if is_instance_valid(audio_player):audio_player.stop();audio_player.stream=null
func _exit_tree():stop_audio()

func talk(topic: String):
 if conversation_profile.is_empty():return
 var result=Society.reply(conversation_profile,topic,conversation_tone,rules,world)
 conversation_text=result.text
 if not result.destination.is_empty():rules.s.rumor_mark=result.destination;rules.note("Marked "+result.destination.name+" on your atlas.")
 ui.open("Conversation")
func enter_service_building():
 var place=ui.service
 ui.close();enter_interior(place)
