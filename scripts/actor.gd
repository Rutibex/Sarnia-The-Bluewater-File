extends Node3D
const Society=preload("res://scripts/society.gd")
var title="Resident"
var role="citizen"
var hostile=false
var health=35.0
var home=Vector3.ZERO
var cooldown=0.0
var phase=0.0
var velocity=Vector3.ZERO
var dead=false
var sprite: Sprite3D
var label: Label3D
var rng=RandomNumberGenerator.new()
var profile={}
var managed=false
var route_from=Vector2i.ZERO
var route_to=Vector2i.ZERO
var route_width=9.0
var walk_speed=1.3
var floor_index=0
var path: Array=[]
var path_timer=0.0
var last_position=Vector3.ZERO
func setup(n: String,r: String,p: Vector3,enemy: bool=false):
 title=n;role=r;position=p;home=p;last_position=p;hostile=enemy;rng.seed=hash(n+str(p));phase=rng.randf()*6;walk_speed=rng.randf_range(0.95,1.6)
 sprite=Sprite3D.new();sprite.texture=load("res://assets/"+("hostile" if enemy else r)+".png");sprite.billboard=BaseMaterial3D.BILLBOARD_ENABLED;sprite.pixel_size=0.03;sprite.position.y=0.96;sprite.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;add_child(sprite)
 label=Label3D.new();label.text=n;label.position.y=2.15;label.font_size=20;label.pixel_size=0.003;label.billboard=BaseMaterial3D.BILLBOARD_ENABLED;label.modulate=Color("e5c990") if not enemy else Color("ef8d6c");add_child(label)
 if not enemy:set_profile(Society.person("agent/"+n,"Sarnia", "community representative" if r!="citizen" else ""))
func set_profile(p: Dictionary):
 profile=p
 if role=="citizen":
  title=p.name;label.text=title
  sprite.texture=load("res://assets/citizen_%d.png"%int(p.sprite));sprite.hframes=4
func animate(dt: float,player: Vector3):
 cooldown=maxf(0,cooldown-dt);phase+=dt
 var moving=position.distance_squared_to(last_position)>0.000001
 label.visible=position.distance_to(player)<10
 if sprite.hframes>1:sprite.frame=int(phase*7)%4 if moving else 0
 sprite.position.y=0.96+(sin(phase*12)*0.018 if moving else 0)
 last_position=position
func tick(dt: float,player: Vector3):
 if dead:return
 if hostile:
  var delta=player-position;delta.y=0
  if delta.length()<32 and delta.length()>1.7:position+=delta.normalized()*dt*2.3
 elif not managed and role=="citizen":position=home+Vector3(sin(phase*0.35)*0.6,0,cos(phase*0.27)*0.4)
 animate(dt,player)
func hit(damage: float):
 health-=damage;sprite.modulate=Color("ffb0a0")
 var tween=create_tween();tween.tween_property(sprite,"modulate",Color.WHITE,0.25)
 if health<=0:
  dead=true;rotation.z=PI/2;position.y+=0.2;label.text="Salvage • E";label.position=Vector3(0,1,0)
