extends SceneTree
var checks=0
func expect(ok: bool,description: String):
 if not ok:push_error("FAIL: "+description);quit(1)
 assert(ok,description);checks+=1
func _initialize():
 var r=preload("res://scripts/rules.gd").new()
 expect(r.SKILLS.size()==35,"35 skills")
 expect(r.s.primary.size()==3 and r.s.major.size()==3 and r.s.minor.size()==6,"skill categories")
 expect(r.s.level==1,"initial level")
 var first=r.s.primary[0];r.s.skills[first]+=2;r.advance(360)
 expect(r.s.level==2,"first level requires 2 counted points")
 expect(r.s.points>=16 and r.s.points<=18,"attribute award")
 var hp=r.s.max_hp;var p=r.s.points;r.allocate("Strength")
 expect(r.s.points==p-1 and r.s.attrs.Strength==51,"attribute allocation")
 var misc="Swimming"
 if misc in r.s.primary or misc in r.s.major or misc in r.s.minor:misc="Dragonish"
 # Choose a genuine miscellaneous skill rather than relying on class contents.
 for k in r.SKILLS:
  if not k in r.s.primary and not k in r.s.major and not k in r.s.minor:misc=k;break
 var score=r.score();r.s.skills[misc]+=10;expect(r.score()==score,"miscellaneous does not count")
 r.s.money=10000;r.s.minutes+=1000;var before=r.s.skills[first]
 expect(r.train(first),"paid training accepted");expect(r.s.skills[first]==before+1,"training raises skill")
 r.s.skills[first]=51;r.s.minutes+=1000;expect(not r.train(first),"training cap")
 r.fresh("Field Technician","Graduate",true,false,20)
 expect(r.s.attrs.Intelligence==60 and r.max_energy()==180,"background and battery advantage")
 r.s.hp=1;r.s.energy=0;r.s.stamina=0;r.rest(6);expect(r.s.hp>1 and r.s.stamina==100 and r.s.energy>0,"rest recovers resources")
 for k in r.SKILLS:r.practice(k,1000)
 var prior=r.s.skills[first];r.advance(360);expect(r.s.skills[first]>prior,"practice advances after time gate")
 r.join(r.FACTIONS[0]);expect(r.s.factions[r.FACTIONS[0]].rank==0,"faction joining")
 var f=r.FACTIONS[0];r.s.factions[f].rep=100;r.s.skills["Impact Tools"]=90;r.s.skills["Trades Jargon"]=90;r.promote(f)
 expect(r.s.factions[f].rank==1,"promotion uses reputation and skills")
 r.promote(f);expect(r.s.factions[f].rank==1,"28-day promotion gate")
 r.advance(28*1440);r.promote(f);expect(r.s.factions[f].rank==2,"promotion after waiting")
 var q=r.make_quest(f,{"name":"Test","p":[10,20]},0);r.accept(q);r.advance(10*1440);expect(q.status=="failed","quest deadline failure")
 var q2=r.make_quest(f,{"name":"Test2","p":[10,20]},2);r.accept(q2);q2.done=true;var cash=r.s.money;r.turn_in(f);expect(q2.status=="complete" and r.s.money>cash,"quest turn-in")
 r.s.money=10000;var inv=r.s.inventory.size();r.buy(r.shop_stock()[0]);expect(r.s.inventory.size()==inv+1,"purchase")
 r.s.hp=1;r.equip(r.s.inventory.size()-1);expect(r.s.hp>1,"consumable")
 r.s.hp=10;r.s.debt=1000;r.s.debt_due=r.s.minutes;r.advance(1440);expect(r.s.debt==1020 and r.s.wanted>0,"overdue loan")
 r.save_game(Vector3(12,0,34),1.5);var level=r.s.level;r.fresh("Courier","Local",false,false,20);expect(r.load_game() and r.s.level==level and r.s.position[0]==12,"save/load roundtrip")
 var d=r.s.devices[0];var cost=r.device_cost(d);r.s.skills["First Aid"]=95;expect(r.device_cost(d)<cost,"device skill reduces cost")
 for job in r.CLASS_NAMES:
  if job=="Custom":continue
  r.fresh(job,"Local",false,false,20)
  var selected=r.s.primary+r.s.major+r.s.minor
  expect(selected.size()==12,"preset skill count "+job)
  var seen={}
  for skill in selected:expect(skill in r.SKILLS and not seen.has(skill),"valid unique skill "+job+" "+skill);seen[skill]=true
 print("PASS: ",checks," rules checks")
 quit(0)
