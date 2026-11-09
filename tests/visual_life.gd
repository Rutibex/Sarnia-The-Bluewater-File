extends SceneTree
func _initialize():call_deferred("run")
func shot(name: String):
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("/tmp/"+name+".png")
func run():
 var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.begin();game.ui.close();await create_timer(5).timeout
 await shot("sarnia-life-street")
 game.enter_interior("Generated office","visual-office","office")
 var world=game.world;var chosen=Vector2i(2,2)
 for c in world.blueprint.floors[0].cells:
  if world.blueprint.floors[0].themes[c]=="Office":chosen=c;break
 game.player.position=Vector3(chosen.x*7,0.2,chosen.y*7-1.5);game.player.rotation.y=PI;await create_timer(0.5).timeout
 await shot("sarnia-life-room")
 game.ui.open("Atlas");await create_timer(0.3).timeout;await shot("sarnia-life-floorplan")
 var actor
 for a in world.actors:
  if a.get_parent()==world.indoor and not a.hostile:actor=a;break
 if actor:
  game.conversation_profile=actor.profile;game.conversation_actor=actor;game.conversation_text=game.Society.greeting(actor.profile,game.rules.s);game.ui.service=actor.title
  game.talk("Work and daily life");await create_timer(0.3).timeout;await shot("sarnia-life-dialogue")
 print("VISUAL buildings ",world.blueprint.floor_count," floors, ",world.blueprint.rooms," rooms; exterior citizens ",world.population.pedestrians.size()," vehicles ",world.population.vehicles.size())
 game.stop_audio();await create_timer(0.1).timeout;game.queue_free();game=null;await process_frame;quit()
