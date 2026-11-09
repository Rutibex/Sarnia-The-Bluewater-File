extends SceneTree
var game
var checks=0
func expect(ok: bool,description: String):
 assert(ok,description);checks+=1
func _initialize():call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();root.add_child(game)
 await process_frame
 game.begin();game.ui.close()
 expect(game.world.data.buildings.size()==11278,"OSM buildings")
 expect(game.world.data.roads.size()==7530,"OSM roads")
 expect(game.world.faction_points.size()==6,"six faction agents")
 for tab in ["New resident","Character","Inventory","Journal","Atlas","Factions","Devices","Rest","Help","Services","Court"]:
  game.ui.open(tab);await process_frame;checks+=1
 for page in ["Shop","Bank","Training","Clinic","Workshop","Property"]:
  game.ui.service_page(page);await process_frame;checks+=1
 game.ui.close()
 var r=game.rules
 r.s.main_stage=0;game.main_story("Civic Liaison Office");expect(r.s.main_stage==1,"campaign offered")
 game.enter_interior("Fictional service complex");expect(game.world.interior,"enter generated dungeon")
 expect(game.world.indoors_loot.size()>0,"lockers generated")
 expect(game.world.indoor_cells.size()>1,"connected dungeon")
 var start=game.world.last_out
 game.recovered_record();expect(r.s.main_stage==2,"first record")
 game.world.leave();game.player.position=start;game.main_story("Civic Liaison Office");expect(r.s.main_stage==3,"campaign intermediate report")
 game.enter_interior("Fictional pumping station");game.recovered_record();expect(r.s.main_stage==4,"second record")
 game.world.leave();game.player.position=start;game.main_story("Neighbourhood Aid");expect(r.s.main_stage==5,"public ending")
 r.s.main_stage=4;game.main_story("Civic Liaison Office");expect(r.s.main_stage==6,"confidential ending")
 r.s.money=500;r.s.wanted=1;game.resolve_court("pay");expect(r.s.wanted==0 and r.s.money==400,"court settlement")
 game.fast_travel(game.world.faction_points[1]);expect(game.player.position.distance_to(game.world.v3(game.world.faction_points[1].p))<1,"transit arrival")
 r.s.properties.append("Work van");r.s.mode="Work van";expect(r.capacity()==r.s.attrs.Strength*1.5+250,"van capacity")
 for idx in [0,2,3,4,5,6]:
  r.s.energy=10000;r.s.devices.append({"name":"Test","effect":idx,"power":10,"duration":10,"scale":1});game.selected_device=r.s.devices.size()-1;game.use_device();checks+=1
 print("PASS: ",checks," integration checks; both campaign endings and all menu pages")
 game.stop_audio();await create_timer(0.1).timeout;game.queue_free();r=null;game=null;await process_frame;await process_frame;quit(0)
