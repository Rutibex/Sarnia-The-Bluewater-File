extends RefCounted
# All rules are original implementations, inspired by skill-based CRPGs.
const ATTRS = ["Strength","Intelligence","Willpower","Agility","Endurance","Personality","Speed","Luck"]
const SKILLS = ["Marksmanship","Axes","Impact Tools","Long Tools","Small Tools","Unarmed","Evasion","Precision","Ambush","Materials","Electronics","Optics","Networks","First Aid","Fieldcraft","Climbing","Jumping","Running","Swimming","Recovery","Stealth","Locks","Light Fingers","Bargaining","Protocol","Streetwise","Trades Jargon","Security Codes","Engineering","Heavy Industry","Wildlife","Machine Logic","Community Outreach","Underworld Cant","Ecology"]
const ORIGINAL = ["Archery","Axe","Blunt Weapon","Long Blade","Short Blade","Hand-to-Hand","Dodging","Critical Strike","Backstabbing","Alteration","Destruction","Illusion","Mysticism","Restoration","Thaumaturgy","Climbing","Jumping","Running","Swimming","Medical","Stealth","Lockpicking","Pickpocket","Mercantile","Etiquette","Streetwise","Centaurian","Daedric","Dragonish","Giantish","Harpy","Impish","Nymph","Orcish","Spriggan"]
const DESC = ["Air-powered sporting launcher accuracy.","Fire axes and heavy cutting tools.","Wrenches, clubs and impact tools.","Pry bars and long-handled tools.","Utility blades and compact tools.","Boxing and unarmed defence.","Passive avoidance of incoming attacks.","Additional chance to land a precise hit.","Extra damage when approaching unseen.","Foam armour and material treatments.","Stun emitters and electronic disruption.","Optical concealment and dazzling lights.","Remote sensors, navigation and extraction beacons.","Medical injector effectiveness.","Climbing rigs and environmental equipment.","Scale walls while holding E.","Jump height and efficiency.","Running efficiency and speed.","Swimming speed and endurance.","Resting recovery efficiency.","Sneaking near threats.","Open secured maintenance lockers.","Risky theft from people and shops.","Merchant prices.","Formal requests and institutional access.","Rumours and informal negotiation.","Communicate with trade crews.","Communicate with patrols.","Understand technical specialists.","Communicate with industrial crews.","Calm hostile animals.","Disable maintenance drones peacefully.","Communicate with neighbourhood volunteers.","Communicate with fictional smugglers.","Understand environmental field workers."]
const CLASS_NAMES = ["Shift Worker","Field Technician","Paramedic","Courier","Private Investigator","Civic Warden","Demolition Hand","Conservation Officer","Range Instructor","Boxer","Response Technician","Battery Specialist","Industrial Electrician","Systems Intruder","Street Operator","Locksmith","Covert Contractor","Community Organizer","Custom"]
const LOADOUTS = [
 ["Impact Tools","Running","Trades Jargon","Axes","Recovery","Bargaining","Long Tools","Climbing","First Aid","Protocol","Heavy Industry","Unarmed"],
 ["Electronics","Networks","Engineering","Materials","Machine Logic","Fieldcraft","Optics","Locks","First Aid","Bargaining","Recovery","Running"],
 ["First Aid","Recovery","Community Outreach","Running","Protocol","Unarmed","Fieldcraft","Bargaining","Evasion","Swimming","Ecology","Streetwise"],
 ["Running","Streetwise","Evasion","Climbing","Jumping","Bargaining","Swimming","Stealth","Small Tools","First Aid","Protocol","Community Outreach"],
 ["Locks","Stealth","Streetwise","Precision","Small Tools","Protocol","Networks","Marksmanship","Ambush","Light Fingers","Bargaining","Security Codes"]]
const FACTIONS = ["Bluewater Trades Council","Lambton Field Institute","Neighbourhood Aid","Waterfront Couriers","Night Shift Collective","Civic Liaison Office"]
const FSKILLS = [["Impact Tools","Trades Jargon"],["Electronics","Engineering"],["First Aid","Community Outreach"],["Running","Streetwise"],["Stealth","Locks"],["Protocol","Security Codes"]]
const EFFECTS = ["Medical Injector","Stun Pulse","Foam Shield","Optical Veil","Survey Ping","Grapple Assist","Water Filter","Extraction Beacon"]
const ESCHOOL = ["First Aid","Electronics","Materials","Optics","Networks","Fieldcraft","Fieldcraft","Networks"]
const EXTRA_LOADOUTS = [
 ["Long Tools","Protocol","Evasion","Impact Tools","Security Codes","Running","First Aid","Recovery","Bargaining","Marksmanship","Climbing","Heavy Industry"],
 ["Axes","Strength","Heavy Industry","Impact Tools","Recovery","Running","Climbing","Jumping","First Aid","Trades Jargon","Unarmed","Bargaining"],
 ["Wildlife","Ecology","Marksmanship","Swimming","Running","Fieldcraft","First Aid","Climbing","Recovery","Streetwise","Long Tools","Jumping"],
 ["Marksmanship","Precision","Evasion","Running","Small Tools","Recovery","First Aid","Protocol","Climbing","Stealth","Bargaining","Swimming"],
 ["Unarmed","Evasion","Running","Recovery","Jumping","Ambush","First Aid","Climbing","Streetwise","Protocol","Swimming","Precision"],
 ["Electronics","Materials","Impact Tools","First Aid","Fieldcraft","Recovery","Networks","Optics","Engineering","Heavy Industry","Running","Protocol"],
 ["Electronics","Materials","Networks","Optics","Fieldcraft","Engineering","First Aid","Machine Logic","Locks","Bargaining","Recovery","Running"],
 ["Electronics","Long Tools","Engineering","Impact Tools","Materials","Trades Jargon","First Aid","Networks","Locks","Recovery","Running","Bargaining"],
 ["Stealth","Networks","Locks","Optics","Electronics","Machine Logic","Small Tools","Ambush","Security Codes","Running","Streetwise","Precision"],
 ["Light Fingers","Stealth","Streetwise","Locks","Small Tools","Bargaining","Ambush","Running","Evasion","Underworld Cant","Climbing","Protocol"],
 ["Locks","Climbing","Stealth","Small Tools","Bargaining","Evasion","Light Fingers","Running","Engineering","Streetwise","First Aid","Networks"],
 ["Ambush","Small Tools","Precision","Stealth","Marksmanship","Evasion","Running","Underworld Cant","Locks","Optics","First Aid","Protocol"],
 ["Community Outreach","Protocol","Streetwise","Bargaining","First Aid","Recovery","Ecology","Running","Optics","Networks","Trades Jargon","Unarmed"]]
var s: Dictionary
var rng = RandomNumberGenerator.new()
var message = ""
var logbook: Array = []
func _init():
 rng.randomize()
 fresh("Shift Worker","Local",false,false,20)
func fresh(job: String,background: String,high_battery: bool,tough: bool,hp_rate: int,custom: Array=[]):
 var idx=maxi(0,CLASS_NAMES.find(job))
 var selected: Array
 if job=="Custom" and custom.size()==12:selected=custom.duplicate()
 elif idx<5:selected=LOADOUTS[idx].duplicate()
 else:selected=EXTRA_LOADOUTS[mini(idx-5,EXTRA_LOADOUTS.size()-1)].duplicate()
 # Preset label correction: demolition relies on an actual skill, not an attribute.
 for n in range(selected.size()):
  if selected[n]=="Strength":selected[n]="Long Tools"
 s={"name":"Alex","job":job,"background":background,"attrs":{},"skills":{},"practice":{},"primary":selected.slice(0,3),"major":selected.slice(3,6),"minor":selected.slice(6,12),"level":1,"baseline":0,"points":12,"hp_rate":hp_rate,"difficulty":clampf(0.8+float(hp_rate-12)/25.0+(0.6 if high_battery else 0.0)-(0.25 if tough else 0.0),0.3,3.0),"battery_mult":3.0 if high_battery else 1.0,"sensitive":tough,"hp":100.0,"max_hp":100.0,"energy":100.0,"stamina":100.0,"money":350,"bank":0,"debt":0,"debt_due":0.0,"minutes":480.0,"wanted":0,"disease":false,"poison":false,"condition":"None","inventory":[],"equipped":{"weapon":"Pipe Wrench","armour":"Work Jacket"},"factions":{},"quests":[],"completed":0,"main_stage":0,"properties":[],"devices":[],"anchor":[],"last_training":-999.0,"last_skill_check":480.0,"sneaking":false,"mode":"Walk","ammo":40,"day_rest":0.0}
 for a in ATTRS:s.attrs[a]=50
 match background:
  "Local":s.attrs.Personality+=10
  "Trades":s.attrs.Strength+=10
  "Graduate":s.attrs.Intelligence+=10
  "Outdoors":s.attrs.Endurance+=10
 for k in SKILLS:
  s.skills[k]=rng.randi_range(5,10)
  s.practice[k]=0.0
 for k in s.primary:s.skills[k]=rng.randi_range(28,32)
 for k in s.major:s.skills[k]=rng.randi_range(18,22)
 for k in s.minor:s.skills[k]=rng.randi_range(13,17)
 for f in FACTIONS:s.factions[f]={"rep":0,"rank":-1,"last":-999999.0}
 s.max_hp=hp_rate+float(s.attrs.Endurance);s.hp=s.max_hp;s.energy=max_energy()
 s.inventory=[item("Pipe Wrench","weapon",45,2.0,8,"Impact Tools"),item("Work Jacket","armour",65,2.0,5),item("Medical Kit","consumable",35,0.4,25),item("Battery Pack","consumable",25,0.3,30),item("Coffee","consumable",8,0.2,30)]
 s.devices=[{"name":"Basic injector","effect":0,"power":18,"duration":10,"scale":1},{"name":"Pocket stun unit","effect":1,"power":14,"duration":5,"scale":1},{"name":"Survey scanner","effect":4,"power":1,"duration":30,"scale":1}]
 s.baseline=score()
 logbook=["You arrived downtown with $350, a wrench, and a lead on the Bluewater File. Visit the Civic Liaison Office to start the story."]
func item(n: String,t: String,v: int,w: float,p: int,skill: String="") -> Dictionary:
 return {"name":n,"type":t,"value":v,"weight":w,"power":p,"skill":skill,"condition":100.0,"tier":0,"enchant":""}
func note(t: String):
 message=t;logbook.push_front(t)
 if logbook.size()>100:logbook.pop_back()
func max_energy() -> float:return float(s.attrs.Intelligence)*float(s.battery_mult)
func capacity() -> float:return float(s.attrs.Strength)*1.5+(250.0 if s.mode=="Work van" else 0.0)
func weight() -> float:
 var n=0.0
 for i in s.inventory:n+=float(i.weight)
 return n+float(s.money)*0.00001
func score() -> int:
 var n=0
 for k in s.primary:n+=s.skills[k]
 var majors: Array=[];var minors: Array=[]
 for k in s.major:majors.append(s.skills[k])
 for k in s.minor:minors.append(s.skills[k])
 majors.sort();minors.sort()
 return n+majors[-1]+majors[-2]+minors[-1]
func practice(k: String,amount: float=1.0):
 if s.practice.has(k):s.practice[k]+=amount
func process_skills():
 if s.minutes-s.last_skill_check<360:return
 s.last_skill_check=s.minutes
 var gains=[]
 for k in SKILLS:
  var cap=95 if mastered() and int(s.skills[k])<100 else 100
  var threshold=maxf(4.0,float(s.skills[k])*0.55*float(s.difficulty))
  if s.practice[k]>=threshold and s.skills[k]<cap:
   s.practice[k]-=threshold;s.skills[k]+=1;gains.append(k)
 if gains.size():note("Improved: "+", ".join(gains))
 var target=int(floor(float(score()-int(s.baseline)+28)/15.0))
 while s.level<target:
  s.level+=1;s.points+=rng.randi_range(4,6)
  var gain=max(1,rng.randi_range(int(s.hp_rate/2),s.hp_rate)+int((s.attrs.Endurance-50)/10))
  s.max_hp+=gain;s.hp+=gain
  note("LEVEL %d — health +%d; attribute points available."%[s.level,gain])
func mastered() -> bool:
 for k in s.primary:
  if s.skills[k]>=100:return true
 return false
func advance(minutes: float):
 s.minutes+=minutes
 if s.poison:s.hp=maxf(1,s.hp-minutes*0.08)
 if s.disease:s.stamina=maxf(0,s.stamina-minutes*0.02)
 for q in s.quests:
  if q.status=="active" and s.minutes>q.deadline:
   q.status="failed";s.factions[q.faction].rep-=5;note("Deadline missed: "+q.title)
 if s.debt>0 and s.minutes>s.debt_due:
  s.wanted=max(s.wanted,1);s.debt_due+=1440;s.debt=int(s.debt*1.02);note("Overdue loan: interest added and credit flagged.")
 process_skills()
func rest(hours: int):
 advance(hours*60)
 s.hp=minf(s.max_hp,s.hp+hours*(4+s.skills.Recovery*0.3));s.stamina=100;s.energy=minf(max_energy(),s.energy+hours*max_energy()*(0.12+float(s.attrs.Willpower)/500.0))
 practice("Recovery",hours*2);note("Rested %d hours. Time passes; quest deadlines still apply."%hours)
func allocate(a: String):
 if s.points>0 and s.attrs[a]<100:
  s.attrs[a]+=1;s.points-=1
func train(k: String) -> bool:
 var cost=int(s.level)*100
 if s.money<cost:note("Training costs $%d."%cost);return false
 if s.skills[k]>=51:note("This trainer cannot take you beyond 51. Practise in the field.");return false
 if s.minutes-s.last_training<720:note("Allow 12 hours between lessons.");return false
 s.money-=cost;s.skills[k]+=1;s.last_training=s.minutes;advance(180);note(k+" improved through training.");return true
func weapon() -> Dictionary:
 for i in s.inventory:
  if i.name==s.equipped.weapon:return i
 return item("Fists","weapon",0,0.0,4,"Unarmed")
func armour() -> float:
 for i in s.inventory:
  if i.name==s.equipped.armour:return i.power*float(i.condition)/100.0
 return 0
func equip(idx: int):
 var i=s.inventory[idx]
 if i.type in ["weapon","armour"]:s.equipped[i.type]=i.name;note("Equipped "+i.name)
 elif i.type=="consumable":
  match i.name:
   "Medical Kit":s.hp=minf(s.max_hp,s.hp+i.power);practice("First Aid",4)
   "Battery Pack":s.energy=minf(max_energy(),s.energy+i.power)
   "Antidote":s.poison=false;s.disease=false
   _:s.stamina=minf(100,s.stamina+i.power)
  s.inventory.remove_at(idx);note("Used "+i.name)
func shop_stock() -> Array:
 return [item("Medical Kit","consumable",35,0.4,25),item("Battery Pack","consumable",25,0.3,30),item("Coffee","consumable",8,0.2,30),item("Antidote","consumable",80,0.2,0),item("Fire Axe","weapon",170,3.0,14,"Axes"),item("Pry Bar","weapon",110,2.5,11,"Long Tools"),item("Utility Tool","weapon",70,0.7,8,"Small Tools"),item("Sport Launcher","weapon",250,2.0,12,"Marksmanship"),item("Reinforced Vest","armour",220,4.0,12),item("Ballistic Vest","armour",700,6.0,22)]
func buy(i: Dictionary):
 var cost=int(i.value*(1.25-float(s.skills.Bargaining)/250.0-float(s.attrs.Personality-50)/1000.0))
 if s.money<cost:note("Insufficient funds.");return
 if weight()+i.weight>capacity():note("Too heavy to carry.");return
 s.money-=cost;s.inventory.append(i.duplicate(true));practice("Bargaining",3);note("Purchased "+i.name)
func sell(idx: int):
 var i=s.inventory[idx]
 if i.type=="evidence":note("Keep the evidence for your investigation.");return
 s.money+=int(i.value*(0.35+float(s.skills.Bargaining)/250.0)*i.condition/100.0);s.inventory.remove_at(idx);practice("Bargaining",3);note("Sold "+i.name)
func join(f: String):
 if s.factions[f].rank<0:s.factions[f].rank=0;note("Joined "+f)
func promote(f: String):
 var d=s.factions[f];var rank=int(d.rank)+1;var skills=FSKILLS[FACTIONS.find(f)]
 if d.rank<0:join(f);return
 if rank>9:note("You already lead this organization.");return
 if d.rep<rank*10 or s.skills[skills[0]]<rank*8+10 or s.skills[skills[1]]<rank*4+5:note("Next rank needs reputation %d, %s %d and %s %d."%[rank*10,skills[0],rank*8+10,skills[1],rank*4+5]);return
 if s.minutes-d.last<28*1440:note("Promotions require 28 days between reviews.");return
 d.rank=rank;d.last=s.minutes;note("Promoted to rank %d in %s."%[rank,f])
func make_quest(f: String,poi: Dictionary,kind: int) -> Dictionary:
 var names=["Sealed envelope","Inspection report","Recovery assignment","Night watch","Missing courier","Confidential handoff"]
 return {"title":names[kind%6]+" — "+poi.name,"faction":f,"kind":kind%6,"target":poi.name,"pos":poi.p,"deadline":s.minutes+int(2+kind%4)*1440,"status":"active","done":false,"reward":100+s.level*35,"stage":0}
func accept(q: Dictionary):
 for x in s.quests:
  if x.status=="active" and x.title==q.title:note("Already accepted.");return
 s.quests.append(q);note("Accepted: "+q.title)
func turn_in(f: String):
 var n=0
 for q in s.quests:
  if q.faction==f and q.status=="active" and q.done:
   q.status="complete";s.money+=q.reward;s.factions[f].rep+=10;s.completed+=1;n+=1
 if n:note("Assignments paid. Reputation improved.")
 else:note("No completed assignments to report.")
func device_cost(d: Dictionary) -> float:
 var skill=s.skills[ESCHOOL[int(d.effect)]]
 return maxf(3.0,(float(d.power)*0.8+float(d.duration)*0.25+float(d.scale)*3)*(1.2-float(skill)/110.0))
func save_game(pos: Vector3,yaw: float):
 s.position=[pos.x,pos.y,pos.z];s.yaw=yaw;s.logbook=logbook
 var f=FileAccess.open("user://bluewater_save.json",FileAccess.WRITE)
 if f:f.store_string(JSON.stringify(s));note("Game saved.")
func load_game() -> bool:
 if not FileAccess.file_exists("user://bluewater_save.json"):note("No saved game yet.");return false
 var parsed=JSON.parse_string(FileAccess.get_file_as_string("user://bluewater_save.json"))
 if parsed is Dictionary and parsed.has("skills"):
  s=parsed;logbook=s.get("logbook",[]);note("Save loaded.");return true
 return false

func roll_loot() -> Dictionary:
 var stock=shop_stock()
 var result=stock[rng.randi_range(0,stock.size()-1)].duplicate(true)
 if result.type in ["weapon","armour"]:
  var names=["Salvaged","Consumer","Trade-grade","Contractor","Hardened","Precision","Ceramic","Aerospace","Experimental","Prototype"]
  var tier=clampi(rng.randi_range(0,maxi(1,int(s.level/3)+1)),0,9)
  result.tier=tier;result.name=names[tier]+" "+result.name;result.power+=tier*3;result.value+=tier*100;result.condition=rng.randi_range(55,100)
  if rng.randf()<0.12+float(s.attrs.Luck)/1000.0:result.enchant="Calibrated";result.power+=3;result.value+=150
 return result
