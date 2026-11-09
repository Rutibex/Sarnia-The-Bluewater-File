extends RefCounted
# Original code-built props: one instanced cube mesh per decoration batch.
var transforms: Array[Transform3D]=[]
var colors: Array[Color]=[]
var colliders: Array=[]
func cube(p: Vector3,size: Vector3,color: Color,solid: bool=false,yaw: float=0.0):
 var basis=Basis(Vector3.UP,yaw).scaled(size);transforms.append(Transform3D(basis,p));colors.append(color)
 if solid:colliders.append([p,size,yaw])
func finish(parent: Node3D) -> MultiMeshInstance3D:
 var node=MultiMeshInstance3D.new();var mm=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.use_colors=true;mm.mesh=BoxMesh.new();mm.instance_count=transforms.size()
 var material=StandardMaterial3D.new();material.vertex_color_use_as_albedo=true;material.roughness=0.9;mm.mesh.material=material
 for i in range(transforms.size()):mm.set_instance_transform(i,transforms[i]);mm.set_instance_color(i,colors[i])
 node.multimesh=mm;parent.add_child(node)
 if colliders.size():
  var body=StaticBody3D.new();parent.add_child(body)
  for c in colliders:
   var shape=CollisionShape3D.new();var box=BoxShape3D.new();box.size=c[1];shape.shape=box;shape.position=c[0];shape.rotation.y=c[2];body.add_child(shape)
 return node
func bench(p: Vector3,yaw: float=0):
 var axis=Basis(Vector3.UP,yaw)
 for offset in [-0.7,0.7]:cube(p+axis*Vector3(offset,0.28,0),Vector3(0.1,0.55,0.55),Color("34413c"),false,yaw)
 cube(p+Vector3(0,0.58,0),Vector3(1.8,0.15,0.6),Color("95724e"),false,yaw)
 cube(p+axis*Vector3(0,0.9,0.26),Vector3(1.8,0.55,0.1),Color("95724e"),false,yaw)
func lamp(p: Vector3):
 cube(p+Vector3(0,2.5,0),Vector3(0.12,5,0.12),Color("465254"))
 cube(p+Vector3(0.4,5,0),Vector3(1,0.12,0.35),Color("dfd5a9"))
func planter(p: Vector3):
 cube(p+Vector3(0,0.3,0),Vector3(0.6,0.6,0.6),Color("977056"));cube(p+Vector3(0,0.78,0),Vector3(0.65,0.5,0.65),Color("4c6b4c"))
func cabinet(p: Vector3,rng: RandomNumberGenerator):
 cube(p+Vector3(0,1,0),Vector3(1.4,2,0.55),Color("7d745d"),true)
 for y in [0.45,1.05,1.65]:
  cube(p+Vector3(0,y,-0.29),Vector3(1.25,0.08,0.05),Color("b5a47c"))
  for x in [-0.45,-0.15,0.15,0.45]:cube(p+Vector3(x,y+0.17,-0.32),Vector3(0.16,0.3,0.11),Color.from_hsv(rng.randf(),0.35,0.55))
func room(p: Vector3,theme: String,rng: RandomNumberGenerator):
 var wood=Color("a2825d");var metal=Color("677b7a")
 # Furniture occupies the room edges; central axes stay clear for occupants.
 match theme:
  "Office","Archive","Classroom":
   cube(p+Vector3(-2,0.8,1.6),Vector3(1.7,0.12,0.9),wood)
   cube(p+Vector3(-2,0.4,1.6),Vector3(1.1,0.8,0.65),metal,true)
   cube(p+Vector3(-2,1.1,1.85),Vector3(0.65,0.45,0.07),Color("303f45"))
   cube(p+Vector3(-2,1.1,1.8),Vector3(0.5,0.3,0.02),Color("78a8a2"))
   cube(p+Vector3(-2,0.45,0.65),Vector3(0.6,0.8,0.6),Color("4e6266"))
   cabinet(p+Vector3(2,0,2.8),rng)
  "Apartment","Dormitory":
   cube(p+Vector3(-2,0.35,1.3),Vector3(1.55,0.7,2.4),wood,true)
   cube(p+Vector3(-2,0.76,1.3),Vector3(1.5,0.15,2.3),Color.from_hsv(rng.randf(),0.25,0.7))
   cube(p+Vector3(-2,0.88,2.05),Vector3(1.2,0.2,0.55),Color("d7d4bc"));cabinet(p+Vector3(2,0,2.7),rng)
  "Medical":
   cube(p+Vector3(-2,0.7,1.5),Vector3(1.2,1.4,2),Color("c2c8b9"),true)
   cube(p+Vector3(-2,1.45,1.5),Vector3(1.25,0.15,2.05),Color("739c93"))
   cube(p+Vector3(2,0.8,2.5),Vector3(1.2,1.6,0.55),metal,true)
   cube(p+Vector3(2,1.1,2.2),Vector3(0.15,0.55,0.04),Color("e3d9c5"));cube(p+Vector3(2,1.1,2.19),Vector3(0.5,0.15,0.04),Color("e3d9c5"))
  "Washroom":
   cube(p+Vector3(-2,0.35,2.3),Vector3(0.65,0.7,0.8),Color("c6cbc0"),true);cube(p+Vector3(-2,0.8,2.7),Vector3(0.65,0.6,0.25),Color("c6cbc0"))
   cube(p+Vector3(2,0.8,2.5),Vector3(1,0.18,0.6),Color("bcc8c0"));cube(p+Vector3(2,1.6,3.1),Vector3(0.85,0.8,0.06),Color("7e9c9d"))
  "Cafeteria","Lounge":
   bench(p+Vector3(-2,0,1.8));cube(p+Vector3(-2,0.9,0.8),Vector3(1.8,0.15,0.7),wood)
   cube(p+Vector3(2.3,1,2.6),Vector3(1.1,2,0.7),Color("526d6b"),true)
   cube(p+Vector3(2.3,1.15,2.2),Vector3(0.8,1.1,0.05),Color("84958a"))
   for x in [-0.2,0,0.2]:cube(p+Vector3(2.3+x,1.4,2.16),Vector3(0.12,0.25,0.04),Color("cfac6a"))
  _:
   for i in range(rng.randi_range(2,4)):
    var x=-2.3 if i%2==0 else 2.3;var z=1.6+int(i/2)*0.9
    cube(p+Vector3(x,0.45,z),Vector3(1.1,0.9,0.75),Color("9c865d"),true)
    cube(p+Vector3(x,0.85,z),Vector3(1.15,0.08,0.8),Color("bfa779"))
 if rng.randf()<0.4:planter(p+Vector3(2.65,0,-2.4))
 cube(p+Vector3(0,3.85,0),Vector3(1.6,0.06,0.4),Color("ddd9bd"))
 cube(p+Vector3(-3.25,1.9,1.8),Vector3(0.05,0.65,0.9),Color.from_hsv(rng.randf(),0.25,0.65))
