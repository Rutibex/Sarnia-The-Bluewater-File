extends SceneTree
var game
func _initialize():call_deferred("run")
func run():
 game=load("res://main.tscn").instantiate();root.add_child(game);await process_frame
 game.started=true;game.ui.open("Atlas")
 var atlas=game.ui.map_widget
 await process_frame;await process_frame
 for scale in [0.025,0.11,0.4,1.5]:
  var samples=[];var tiles=[]
  atlas.zoom=scale
  for i in range(16):
   atlas.centre=Vector2(i*17,i*11);atlas.queue_redraw();await process_frame;await process_frame
   samples.append(atlas.last_draw_usec)
   tiles.append(atlas.tiles_drawn)
  samples.sort();tiles.sort()
  print("ATLAS zoom=",scale," median_us=",samples[8]," max_us=",samples[-1]," tiles=",tiles[-1] if tiles.size() else "vector baseline")
  assert(tiles[-1]<=16,"Only visible atlas tiles should be rendered")
  assert(game.world.atlas_tiles.size()<=96,"Atlas cache must remain bounded")
 # Verify interior atlas coordinates and zoom limits as well.
 game.ui.close();game.enter_interior("Fictional service complex");game.ui.open("Atlas");atlas=game.ui.map_widget
 assert(atlas.centre.distance_to(Vector2(game.player.position.x,game.player.position.z))<0.01)
 var e=InputEventMouseButton.new();e.button_index=MOUSE_BUTTON_WHEEL_UP;e.pressed=true;e.position=atlas.size*0.5
 atlas._gui_input(e);assert(atlas.zoom>7.0)
 assert(game.camera.near>=0.2)
 assert(game.world.BASE_Y<game.world.PARK_Y and game.world.PARK_Y<game.world.BEACH_Y and game.world.BEACH_Y<game.world.WATER_Y and game.world.WATER_Y<game.world.ROAD_Y and game.world.ROAD_Y<game.world.MARKING_Y)
 for key in ["asphalt","grass"]:
  assert(game.world.mats[key].albedo_texture.get_image().has_mipmaps(),key+" needs mipmaps")
 print("PASS atlas bounds, interior zoom, camera precision, ground layers and mipmaps")
 game.stop_audio();await create_timer(0.1).timeout;game.queue_free();game=null;await process_frame;quit()
