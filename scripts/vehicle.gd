extends Node3D
const Decor=preload("res://scripts/decor.gd")
var route_from=Vector2i.ZERO
var route_to=Vector2i.ZERO
var previous=Vector2i.ZERO
var road_width=9.0
var speed=0.0
var cruise=8.0
var vehicle_type="Car"
var phase=0.0
var body: StaticBody3D
var brake: MeshInstance3D
func setup(kind: String,color: Color):
 vehicle_type=kind
 var model=Decor.new();var length=4.0;var width=1.8
 if kind=="Bus":length=8.5;width=2.35;cruise=7
 elif kind=="Van":length=5.1;width=2.0;cruise=8
 elif kind=="Pickup":length=5.0;width=2.0;cruise=8.5
 else:cruise=9.0
 model.cube(Vector3(0,0.65,0),Vector3(width,0.75,length),color)
 if kind=="Bus":
  model.cube(Vector3(0,1.65,0),Vector3(width*0.95,1.45,length*0.96),color)
  for z in range(-3,4):
   for x in [-1,1]:model.cube(Vector3(x*width*0.505,1.9,z),Vector3(0.04,0.7,0.7),Color("354e58"))
 elif kind=="Van":
  model.cube(Vector3(0,1.45,0.25),Vector3(width*0.95,1.2,length*0.83),color)
  model.cube(Vector3(0,1.65,-length*0.38),Vector3(width*0.8,0.6,0.04),Color("354e58"))
 else:
  model.cube(Vector3(0,1.3,0 if kind=="Car" else -0.8),Vector3(width*0.8,0.65,length*0.5),Color("354e58"))
  model.cube(Vector3(0,1.65,0 if kind=="Car" else -0.8),Vector3(width*0.85,0.1,length*0.53),color)
 for x in [-1,1]:
  for z in [-1,1]:model.cube(Vector3(x*width*0.51,0.4,z*length*0.31),Vector3(0.25,0.7,0.7),Color("20272b"))
  model.cube(Vector3(x*width*0.33,0.7,-length*0.51),Vector3(0.34,0.18,0.05),Color("e8d9a3"))
  model.cube(Vector3(x*width*0.33,0.7,length*0.51),Vector3(0.28,0.17,0.05),Color("a24b3f"))
 model.finish(self)
 body=StaticBody3D.new();add_child(body);var collision=CollisionShape3D.new();var box=BoxShape3D.new();box.size=Vector3(width,1.7,length);collision.shape=box;collision.position.y=1;body.add_child(collision)
