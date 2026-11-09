extends SceneTree
func _initialize():call_deferred("run")
func run():
 var game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.begin();game.ui.close();game.enter_interior("Fictional service complex")
 for a in game.world.actors:
  if a.get_parent()==game.world.indoor:a.hostile=false
 Engine.time_scale=3
 for f in range(mini(3,game.world.blueprint.floor_count-1)):
  game.player.position=Vector3(0,f*4.4+0.3,0);game.player.velocity=Vector3.ZERO;game.player.rotation.y=PI
  await create_timer(0.3).timeout
  var e=InputEventKey.new();e.physical_keycode=KEY_W;e.keycode=KEY_W;e.pressed=true;Input.parse_input_event(e)
  await create_timer(5.3).timeout
  e=InputEventKey.new();e.physical_keycode=KEY_W;e.keycode=KEY_W;e.pressed=false;Input.parse_input_event(e)
  print("STAIRS floor ",f+1," -> ",f+2," actual feet ",game.player.position)
  assert(game.player.position.y>(f+1)*4.4-0.2,"Player must walk up physical ramp to next floor")
 Engine.time_scale=1
 game.stop_audio();await create_timer(0.1).timeout;game.queue_free();game=null;await process_frame
 print("PASS physical multi-floor stair traversal");quit()
