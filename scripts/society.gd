extends RefCounted
const FIRST=["Alex","Morgan","Sam","Taylor","Jamie","Priya","Noah","Olivia","Avery","Jordan","Amir","Maya","Liam","Harper","Evelyn","Noor","Riley","Daniel","Chloe","Lucas","Zoe","Cameron","Amelia","Theo","Sofia","Elijah","Ethan","Grace","Arjun","Mila","Quinn","Isla"]
const LAST=["Robinson","Chen","Patel","Reid","Thompson","Roy","Singh","Martin","Wilson","Brown","Campbell","Nguyen","Walker","Ahmed","MacDonald","Clarke","Bennett","Scott","Tremblay","Fraser","Lewis","Young","Wright","Evans","Kelly","Cooper","Park","Shah","Davis","Morgan"]
const JOBS=["electrician","library assistant","bus driver","lab technician","nurse","student","retired machinist","office administrator","courier","caretaker","shopkeeper","mechanic","teacher","warehouse clerk","cook","maintenance supervisor"]
const HOBBIES=["fishing by the river","restoring old radios","walking the waterfront","playing hockey","gardening","photographing ships","collecting used books","repairing bicycles","weekend music","cooking for friends","watching the freighters","local history"]
const TRAITS=["friendly","reserved","chatty","skeptical","practical","cheerful","hurried","thoughtful"]
const TOPICS=["Local news","Work and daily life","This building","Directions","The Bluewater File","Personal interests"]
static func person(identity: String,place: String="Sarnia",job: String="") -> Dictionary:
 var r=RandomNumberGenerator.new();r.seed=hash(identity+"/person")
 var occupation=JOBS[r.randi_range(0,JOBS.size()-1)] if job.is_empty() else job
 return {"id":identity,"name":FIRST[r.randi_range(0,FIRST.size()-1)]+" "+LAST[r.randi_range(0,LAST.size()-1)],"job":occupation,"trait":TRAITS[r.randi_range(0,TRAITS.size()-1)],"hobby":HOBBIES[r.randi_range(0,HOBBIES.size()-1)],"place":place,"shift":r.randi_range(6,10),"opinion":r.randi_range(0,3),"tint":Color.from_hsv(r.randf(),r.randf_range(0.15,0.45),r.randf_range(0.65,1.0)).to_html(),"sprite":r.randi_range(0,11)}
static func memory(profile: Dictionary,state: Dictionary) -> Dictionary:
 if not state.has("citizen_memory"):state.citizen_memory={}
 if not state.citizen_memory.has(profile.id):state.citizen_memory[profile.id]={"met":0,"affinity":0,"last_topic":"","practised":{},"exchanges":0}
 return state.citizen_memory[profile.id]
static func greeting(p: Dictionary,state: Dictionary) -> String:
 var m=memory(p,state);var hour=int(state.minutes/60)%24
 var opening="Good morning" if hour<12 else "Afternoon" if hour<18 else "Evening"
 if m.met>0:opening="Back again, "+state.name if m.affinity>=0 else "Oh. It’s you again"
 m.met+=1
 var attitude={"friendly":"Nice to meet someone out and about.","reserved":"I can spare a moment.","chatty":"I was just thinking I hadn’t talked to anyone in a while.","skeptical":"Depends what you’re asking.","practical":"What can I help you with?","cheerful":"Lovely to see a new face.","hurried":"I have a shift to get to, but go ahead.","thoughtful":"There’s always something worth talking about."}
 var article="an" if p.job.left(1).to_lower() in ["a","e","i","o","u"] else "a"
 return "%s. I’m %s, %s %s. %s"%[opening,p.name,article,p.job,attitude[p.trait]]
static func reply(p: Dictionary,topic: String,tone: String,rules,world) -> Dictionary:
 var s=rules.s;var m=memory(p,s);var rng=RandomNumberGenerator.new();rng.seed=hash(p.id+topic+str(m.exchanges)+str(int(s.minutes/1440)))
 m.exchanges+=1;m.last_topic=topic
 var skill="Protocol" if tone=="Polite" else "Streetwise"
 var disposition=45+int(s.attrs.Personality-50)/2+m.affinity-s.wanted*7
 if p.trait=="skeptical":disposition-=15
 disposition+=12 if tone=="Polite" and p.trait in ["reserved","thoughtful"] else 8 if tone=="Blunt" and p.trait=="practical" else -12 if tone=="Blunt" else 3
 disposition+=int(s.skills[skill]/4)
 var helpful=rng.randi_range(0,99)<clampi(disposition,10,95)
 var prefix=["Well, ","To be honest, ","As far as I know, ","Let me think. ","Here’s what I’ve heard. "][rng.randi_range(0,4)]
 var result={"text":"","destination":{},"helpful":helpful}
 if not helpful:
  result.text=["I don’t really know you well enough to get into that.","You could try asking somebody else. I’m not the right person.","Maybe another time. I’ve got enough on my plate."][rng.randi_range(0,2)];m.affinity=maxi(-20,m.affinity-1)
 else:
  m.affinity=mini(25,m.affinity+1)
  match topic:
   "Work and daily life":
    result.text="I work as %s %s. Usually I’m starting around %02d:00. %s"%["an" if p.job.left(1).to_lower() in ["a","e","i","o","u"] else "a",p.job,p.shift,["The paperwork is endless, but the people make it worthwhile.","It’s a living. I’d rather be "+p.hobby+".","You learn a lot about a place by keeping it running.","Every day somebody needs a problem solved before the next shift."][rng.randi_range(0,3)]]
   "This building":
    result.text="%s has its own way of doing things. %s"%[p.place,["The stairwell connects every level; follow the floor signs if you get turned around.","The corridors loop around. Don’t assume the room beside you has its door on this side.","The upper floors are quieter. The lockers and notice boards are worth a look.","There are old service doors behind some of the panels. They’re shortcuts, not the main route."][rng.randi_range(0,3)]]
   "Personal interests":result.text="Outside work I like %s. %s"%[p.hobby,["It’s how I clear my head after a long week.","There’s more to this city than the view from the highway.","If you stay around a while, you’ll find your own favourite spots."][rng.randi_range(0,2)]]
   "The Bluewater File":
    var lines=["People are whispering about missing inspection records. Civic Liaison might know where to start.","I’d talk to Neighbourhood Aid before handing sensitive records back to the people asking for them.","I haven’t seen the records, but maintenance staff keep copies of more things than you’d expect.","Nobody tells the whole story first time. Compare what people say, and keep your own notes."]
    result.text=lines[p.opinion]
    if int(s.main_stage)>=5:result.text="I heard the investigation is over. "+("You did the neighbourhood a favour making it public." if s.main_stage==5 else "I suppose some questions are going to stay unanswered.")
   "Directions":
    var destinations=world.faction_points
    var target=destinations[rng.randi_range(0,destinations.size()-1)];result.destination=target
    result.text="Try %s near %s. I can mark the location on your atlas."%[target.name,target.real]
   _:
    var stop=world.faction_points[rng.randi_range(0,world.faction_points.size()-1)]
    result.text=["%s is looking for reliable help. Ask about assignments."%stop.name,"The buses make the long trips easier. You can plan transit from your atlas.","There’s been trouble with maintenance units in the fictional service complexes. Bring a charged device.","I heard someone found useful components in an old locker. Most people walk past without checking.","The waterfront is a good place to get your bearings. Front and Christina will keep you oriented."][rng.randi_range(0,4)]
  if topic=="This building" and not world.interior:result.text="I’m often around "+p.place+". Ask for directions if you need a particular organization; I can put a location on your atlas."
  if topic in ["Work and daily life","Personal interests"]:prefix=["Well, ","As for me, ","Actually, ",""][rng.randi_range(0,3)]
  result.text=prefix+result.text
 if float(s.minutes)-float(m.practised.get(topic,-99999))>=60:
  rules.practice(skill,3);m.practised[topic]=s.minutes
 return result
