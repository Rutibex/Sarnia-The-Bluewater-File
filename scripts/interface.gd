extends CanvasLayer
const Atlas=preload("res://scripts/atlas.gd")
var game
var root: Control
var hud: Label
var hint: Label
var notices: Label
var panel: PanelContainer
var body: VBoxContainer
var title_label: Label
var current=""
var service=""
var selected_custom: Array=[]
var map_widget
var compass: Label
var bars: Label
var overlay: Control
var clock_label: Label
var colour=Color("dbc493")
func setup(g):
 game=g;root=Control.new();root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(root)
 var theme=Theme.new();theme.default_font=load("res://assets/mono.ttf");theme.default_font_size=15
 for cname in ["Button","OptionButton","LineEdit","SpinBox"]:
  var box=StyleBoxFlat.new();box.bg_color=Color("26383b");box.border_color=Color("68756a");box.set_border_width_all(1);box.set_content_margin_all(10);theme.set_stylebox("normal",cname,box)
  var hover=box.duplicate();hover.bg_color=Color("49564a");theme.set_stylebox("hover",cname,hover);theme.set_color("font_color",cname,Color("e6d9bc"));theme.set_stylebox("focus",cname,hover)
 root.theme=theme
 var bottom=Panel.new();bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE);bottom.offset_top=-135;root.add_child(bottom)
 var bs=StyleBoxFlat.new();bs.bg_color=Color("152528");bs.border_color=Color("9b8a61");bs.border_width_top=2;bottom.add_theme_stylebox_override("panel",bs)
 hud=Label.new();hud.position=Vector2(24,12);bottom.add_child(hud)
 bars=Label.new();bars.position=Vector2(24,44);bottom.add_child(bars)
 clock_label=Label.new();clock_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT);clock_label.position.x-=360;clock_label.position.y=13;bottom.add_child(clock_label)
 var buttons=HBoxContainer.new();buttons.position=Vector2(24,88);bottom.add_child(buttons)
 for tab in ["Character","Inventory","Journal","Atlas","Factions","Devices","Rest","Help"]:
  button(buttons,tab,func():open(tab))
 hint=Label.new();hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER);hint.offset_top=55;hint.offset_left=-260;hint.offset_right=260;hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_color_override("font_color",Color("f4deaa"));root.add_child(hint)
 compass=Label.new();compass.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE);compass.offset_top=18;compass.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;root.add_child(compass)
 notices=Label.new();notices.position=Vector2(24,50);notices.custom_minimum_size=Vector2(560,75);notices.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;root.add_child(notices)
 panel=PanelContainer.new();panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);panel.offset_left=75;panel.offset_right=-75;panel.offset_top=65;panel.offset_bottom=-160
 var ps=StyleBoxFlat.new();ps.bg_color=Color("17282bf5");ps.border_color=Color("b6a16d");ps.set_border_width_all(2);ps.set_content_margin_all(22);panel.add_theme_stylebox_override("panel",ps);root.add_child(panel)
 var outer=VBoxContainer.new();panel.add_child(outer);var header=HBoxContainer.new();outer.add_child(header)
 title_label=Label.new();title_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL;title_label.add_theme_font_size_override("font_size",25);title_label.add_theme_color_override("font_color",colour);header.add_child(title_label)
 button(header,"Close [Esc]",close)
 var scroll=ScrollContainer.new();scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;outer.add_child(scroll);body=VBoxContainer.new();body.size_flags_horizontal=Control.SIZE_EXPAND_FILL;body.add_theme_constant_override("separation",10);scroll.add_child(body)
 open("Welcome")
func button(parent: Node,text: String,callback: Callable) -> Button:
 var b=Button.new();b.text=text;b.pressed.connect(callback);parent.add_child(b);return b
func label(parent: Node,text: String,size: int=15) -> Label:
 var l=Label.new();l.text=text;l.autowrap_mode=TextServer.AUTOWRAP_OFF if parent is HBoxContainer or parent is GridContainer else TextServer.AUTOWRAP_WORD_SMART;l.add_theme_font_size_override("font_size",size);parent.add_child(l);return l
func row(parent: Node) -> HBoxContainer:
 var r=HBoxContainer.new();r.add_theme_constant_override("separation",12);parent.add_child(r);return r
func heading(text: String):label(body,text,20).add_theme_color_override("font_color",colour)
func clear():
 for n in body.get_children():body.remove_child(n);n.queue_free()
 map_widget=null
func close():
 if not game.started:return
 game.world.show()
 panel.hide();current="";Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func open(tab: String):
 game.world.visible=tab!="Atlas"
 current=tab;panel.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;clear();title_label.text=tab.to_upper();game.rules.message=""
 match tab:
  "Welcome":welcome()
  "New resident":creation()
  "Character":character()
  "Inventory":inventory()
  "Journal":journal()
  "Atlas":atlas()
  "Factions":factions()
  "Devices":devices()
  "Rest":rest_menu()
  "Help":help_menu()
  "Services":services()
  "Conversation":conversation()
  "Court":court()
func refresh():
 if current!="":open(current)
func update():
 var s=game.rules.s
 hud.text="%s / %s    LEVEL %d    $%d    %s"%[s.name,s.job,s.level,s.money,"WANTED "+str(s.wanted) if s.wanted else "CLEAR RECORD"]
 bars.text="HEALTH %d/%d     BATTERY %d/%d     STAMINA %d/100     %s"%[s.hp,s.max_hp,s.energy,game.rules.max_energy(),s.stamina,s.condition]
 var day=1+int(s.minutes/1440);var hour=int(s.minutes/60)%24;var minute=int(s.minutes)%60
 clock_label.text="DAY %02d   %02d:%02d\n%s"%[day,hour,minute,s.mode]
 compass.text=("INTERIOR / "+game.world.interior_type if game.world.interior else game.street)+"     |     "+["N","NW","W","SW","S","SE","E","NE"][posmod(int(round(game.player.rotation.y/(PI/4))),8)]
 notices.text=game.rules.message

func welcome():
 heading("S A R N I A")
 label(body,"THE BLUEWATER FILE",32).add_theme_color_override("font_color",colour)
 label(body,"A modern Ontario life-and-adventure RPG",18)
 label(body,"Clock out. Follow the river. Find out who buried the file.\n\nA fictional industrial mystery played across real OpenStreetMap roads and building footprints. Explore downtown, learn a trade, join local organizations and investigate fictional service complexes. Contemporary Sarnia, with a heightened pulp-adventure tone.")
 var r=row(body);button(r,"Create a resident",func():open("New resident"));button(r,"Continue saved game",func():game.load_game())
 heading("Native desktop • original procedural assets")
 label(body,"WASD move · mouse look · E interact · left mouse use tool · right mouse device\nShift sprint · Ctrl sneak · Space jump · M atlas · Tab character · F5 save · F9 load\nEsc releases the mouse and pauses. The full control guide is available below.")
 label(body,"The street network and footprints come from your supplied Sarnia extract. Heights without map tags, facades, interiors, characters, organizations and events are generated fiction. This is an initial playable implementation, not complete Daggerfall parity.")
 button(body,"Controls and system guide",func():open("Help"))
func creation():
 heading("Choose your working life")
 var names=row(body);label(names,"Name");var name_edit=LineEdit.new();name_edit.text="Alex";name_edit.custom_minimum_size.x=220;names.add_child(name_edit)
 var choices=row(body);var job=OptionButton.new();choices.add_child(job)
 for c in game.rules.CLASS_NAMES:job.add_item(c)
 var background=OptionButton.new();choices.add_child(background)
 for c in ["Local","Trades","Graduate","Outdoors"]:background.add_item(c)
 label(body,"Local: +10 Personality · Trades: +10 Strength · Graduate: +10 Intelligence · Outdoors: +10 Endurance")
 var opts=row(body);var energy=CheckButton.new();energy.text="High-capacity battery (slower learning)";opts.add_child(energy);var weak=CheckButton.new();weak.text="Cold-sensitive (faster learning)";opts.add_child(weak)
 var rate=row(body);label(rate,"Maximum health per level");var hp=SpinBox.new();hp.min_value=12;hp.max_value=30;hp.value=20;rate.add_child(hp)
 label(body,"You receive 12 starting attribute points; distribute them in Character after beginning.
Custom class: select exactly 12 skills. Selection order determines 3 Primary, 3 Major, then 6 Minor skills. Higher health and battery capacity slow practice gains.")
 var summary=label(body,"",14)
 var grid=GridContainer.new();grid.columns=4;body.add_child(grid);selected_custom=[]
 for k in game.rules.SKILLS:
  var b=CheckBox.new();b.text=k;b.add_theme_font_size_override("font_size",12);grid.add_child(b)
  b.toggled.connect(func(on):
   if on:selected_custom.append(k)
   else:selected_custom.erase(k)
   summary.text="Selected (%d/12): %s"%[selected_custom.size(),", ".join(selected_custom)])
 button(body,"Begin at Christina Street",func():
  var j=job.get_item_text(job.selected)
  if j=="Custom" and selected_custom.size()!=12:game.rules.note("Choose exactly 12 custom skills.");return
  game.rules.fresh(j,background.get_item_text(background.selected),energy.button_pressed,weak.button_pressed,int(hp.value),selected_custom)
  game.rules.s.name=name_edit.text.substr(0,24) if not name_edit.text.is_empty() else "Alex"
  game.begin();close())
func character():
 var s=game.rules.s;heading("%s · %s · level %d"%[s.name,s.job,s.level])
 label(body,"Unspent attributes: %d     Learning difficulty: ×%.2f     Counted skill total: %d"%[s.points,s.difficulty,game.rules.score()])
 var stats=GridContainer.new();stats.columns=4;body.add_child(stats)
 for a in game.rules.ATTRS:
  var r=row(stats);label(r,"%s %d"%[a,s.attrs[a]]);button(r,"+",func():game.rules.allocate(a);refresh())
 label(body,"Carry %.1f / %.1f kg · Health growth maximum %d per level · Equipment protection %.1f"%[game.rules.weight(),game.rules.capacity(),s.hp_rate,game.rules.armour()])
 for group in ["Primary","Major","Minor","Miscellaneous"]:
  heading(group)
  var grid=GridContainer.new();grid.columns=2;body.add_child(grid)
  for i in range(game.rules.SKILLS.size()):
   var k=game.rules.SKILLS[i];var cat="Primary" if k in s.primary else "Major" if k in s.major else "Minor" if k in s.minor else "Miscellaneous"
   if cat!=group:continue
   var l=label(grid,"%-20s %3d  ·  %s"%[k,s.skills[k],game.rules.ORIGINAL[i]],13);l.tooltip_text=game.rules.DESC[i]
func inventory():
 var s=game.rules.s
 label(body,"Equipped: %s / %s    Ammunition: %d    %.1f / %.1f kg"%[s.equipped.weapon,s.equipped.armour,s.ammo,game.rules.weight(),game.rules.capacity()])
 for idx in range(s.inventory.size()):
  var i=s.inventory[idx];var r=row(body);label(r,"%s%s · %s · %d%% · %.1f kg"%[i.name," ["+i.enchant+"]" if i.enchant!="" else "",i.type,i.condition,i.weight]).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button(r,"Use / equip",func():game.rules.equip(idx);refresh())
  if i.type!="evidence":button(r,"Drop",func():s.inventory.remove_at(idx);refresh())
func journal():
 heading("The Bluewater File")
 var stages=["Speak to the Civic Liaison Office by City Hall.","Retrieve the inspection record from the fictional service complex south-east of downtown.","Return to the Civic Liaison Office with the inspection record.","Investigate the fictional pumping station and retrieve a second record.","Choose whether to publish the records through Neighbourhood Aid or return them to Civic Liaison.","The file is public. The neighbourhood remembers your help.","The file is sealed. Civic Liaison has rewarded your discretion."]
 label(body,stages[mini(safe_int(game.rules.s.main_stage),6)])
 heading("Assignments")
 for q in game.rules.s.quests:
  label(body,"%s\n%s · %s · %s · $%d"%[q.title,q.faction,"ready to report" if q.done and q.status=="active" else q.status,"%.1f days remaining"%maxf(0,(q.deadline-game.rules.s.minutes)/1440.0),q.reward])
 heading("Recent activity")
 for t in game.rules.logbook.slice(0,25):label(body,t,13)
func safe_int(x):return int(x)
func atlas():
 map_widget=Atlas.new();map_widget.game=game;var p=game.player.position;map_widget.centre=Vector2(p.x,p.z);map_widget.zoom=7.0 if game.world.interior else 0.11;body.add_child(map_widget)
 if game.world.interior:
  map_widget.call_deferred("fit_floor")
  var controls=row(body);button(controls,"Centre on resident",func():map_widget.centre=Vector2(game.player.position.x,game.player.position.z);map_widget.floor_view=game.world.current_floor;map_widget.queue_redraw())
  button(controls,"Fit floor",func():map_widget.fit_floor())
  var floors=OptionButton.new();controls.add_child(floors)
  for f in range(game.world.blueprint.floor_count):floors.add_item("Floor %d"%(f+1))
  floors.selected=game.world.current_floor;floors.item_selected.connect(func(f):map_widget.floor_view=f;map_widget.queue_redraw())
  label(body,"Stairs are physical ramps in the shared blue stairwell. The street exit is on floor 1.")
  return
 var r=row(body);button(r,"Centre on resident",func():map_widget.centre=Vector2(game.player.position.x,game.player.position.z);map_widget.queue_redraw())
 var dest=OptionButton.new();dest.custom_minimum_size.x=420;r.add_child(dest)
 var destinations=game.world.faction_points+game.world.points.filter(func(p):return p.get("kind","")=="dungeon")
 for p2 in destinations:dest.add_item(p2.name)
 button(r,"Transit to selected stop",func():game.fast_travel(destinations[dest.selected]);refresh())
 label(body,"Transit charges a distance-based fare and advances the clock. Interiors must be exited first. Orange circles show active assignments.",13)
func factions():
 for f in game.rules.FACTIONS:
  var d=game.rules.s.factions[f];heading(f)
  label(body,"%s · reputation %d · preferred skills: %s"%["Not a member" if d.rank<0 else "Rank %d / 9"%d.rank,d.rep,", ".join(game.rules.FSKILLS[game.rules.FACTIONS.find(f)])])
 label(body,"Join and request promotion in person. Advancement requires reputation, both preferred skills and 28 days between promotions.")
func devices():
 heading("Field devices")
 for idx in range(game.rules.s.devices.size()):
  var d=game.rules.s.devices[idx];var r=row(body);label(r,"%s · %s · %.0f battery"%[d.name,game.rules.EFFECTS[int(d.effect)],game.rules.device_cost(d)]).size_flags_horizontal=Control.SIZE_EXPAND_FILL
  button(r,"Select",func():game.selected_device=idx;game.rules.note("Selected "+d.name);close())
 heading("Prototype workbench")
 label(body,"Build at the Lambton Field Institute after joining. Costs $100 per design. Devices are a fictional technology analogue to custom spells.")
 var r=row(body);var effect=OptionButton.new();r.add_child(effect)
 for e in game.rules.EFFECTS:effect.add_item(e)
 var power=SpinBox.new();power.min_value=1;power.max_value=60;power.value=18;r.add_child(power)
 var duration=SpinBox.new();duration.min_value=1;duration.max_value=180;duration.value=30;r.add_child(duration)
 var scale=SpinBox.new();scale.min_value=0;scale.max_value=4;scale.value=1;r.add_child(scale)
 label(body,"Parameters: effect / base magnitude / duration in seconds / magnitude added per level")
 button(body,"Assemble design ($100)",func():
  if not near_faction("Lambton Field Institute") or game.rules.s.factions["Lambton Field Institute"].rank<0:game.rules.note("Visit and join the Field Institute first.");return
  if game.rules.s.money<100:game.rules.note("Need $100.");return
  game.rules.s.money-=100;game.rules.s.devices.append({"name":"Custom "+game.rules.EFFECTS[effect.selected],"effect":effect.selected,"power":int(power.value),"duration":int(duration.value),"scale":int(scale.value)});refresh())
func near_faction(f: String) -> bool:
 for p in game.world.faction_points:
  if p.name==f and game.player.position.distance_to(game.world.v3(p.p))<15 and not game.world.interior:return true
 return false
func rest_menu():
 heading("Rest and recovery")
 label(body,"Rest restores health, battery and stamina, and processes practice gains. Deadlines and loan interest continue. Hostile units nearby prevent resting.")
 for h in [1,6,12,24]:button(body,"Rest %d hours"%h,func():game.try_rest(h);refresh())
func help_menu():
 var sections=[
 ["Controls","WASD move · mouse look · Shift sprint · Ctrl sneak · Space jump · E talk/open/loot\nHold E at a wall to climb · Left mouse attack · Right mouse use selected device\n1–8 select device · B cycle walk/bicycle/work van (purchase vehicles first)\nM atlas · I inventory · J journal · Tab character · F factions · R rest · T devices\nF5 save · F9 load · Esc pause/release mouse · click the world to capture again"],
 ["Your first evening","Create a resident, talk to Civic Liaison by City Hall, and accept the Bluewater File lead. Open the atlas to find the fictional service complex. Enter, explore, open lockers, recover the inspection record and return. Other organizations offer repeatable work. Choose Atlas → transit if you prefer to skip a long walk."],
 ["Character growth","35 usable skills. Three Primary, two highest Major and highest Minor skills count toward level. Level = floor((current counted total − initial total + 28)/15). Practice is processed every six game hours. Level grants 4–6 attributes and class-dependent health. Paid training stops at 51. After Primary mastery, other skills cap at 95."],
 ["Modern equivalents","Magic → experimental field devices and batteries. Languages → technical/social communication skills. Guilds → fictional organizations. Gold → Canadian dollars. Horse → bicycle; wagon → work van; ships/houses → property deeds. Vampirism/lycanthropy → fictional experimental implant or night-shift dependency, with benefits and drawbacks. No claim is made about real institutions or real residents."],
 ["Interactions","E prioritizes nearby people, lockers and entrances. Generic building interiors are generated fiction. Service menus offer shops, repair, clinic, training, banks and property. Ask residents for directions; marked locations are on the atlas. Hold Ctrl to approach quietly. Tab → skills shows original Daggerfall names for reference."],
 ["Map accuracy","Road centre lines, building footprints and mapped water/park polygons come from the supplied OSM extract in real metre coordinates. No online map calls are needed. Road widths, unspecified heights, architecture, interiors, props, NPCs and all gameplay events are approximations or fiction. Some complex multipolygons and bridge elevations are simplified."],
 ["Implementation limits","This is a foundation and playable campaign, not full Daggerfall parity. No multiplayer, full traffic simulation, navigable boat, dynamic geopolitical simulation, complete trial dialogue, extensive faction-specific story arcs or full original spell-effect catalogue. See PARITY.md for the exact implemented/partial/deferred inventory."],
 ["Credits and licences","Original game code and generated assets: MIT. Map data © OpenStreetMap contributors, ODbL 1.0. Font: DejaVu Sans Mono, Bitstream Vera/DejaVu licence. Godot Engine: MIT. Daggerfall and The Elder Scrolls belong to their respective owners; no original game assets or code are included."]]
 for section in sections:heading(section[0]);label(body,section[1])
 heading("Population")
 label(body,"Nearby citizens and road vehicles are streamed around you. Lower density if needed; the whole city is not simulated at once.")
 var density_row=row(body)
 for preset in [["Quiet",0.5],["Busy",1.0],["Very busy",1.5]]:
  button(density_row,preset[0],func():game.world.population.density=preset[1];game.world.population.refresh_timer=99;game.rules.note("Population density: "+preset[0]))
 button(body,"Toggle ambient audio",func():game.ambience.stream_paused=not game.ambience.stream_paused)
 button(body,"Back",func():open("Welcome") if not game.started else close())
func conversation():
 heading(service)
 if service in game.rules.FACTIONS:
  var f=service;var d=game.rules.s.factions[f];label(body,("“"+game.conversation_text+"”\n" if not game.conversation_profile.is_empty() else "")+"Reputation %d · Rank %d"%[d.rep,d.rank])
  var r=row(body);button(r,"Join",func():game.rules.join(f);game.conversation_text=game.rules.message;refresh());button(r,"Promotion review",func():game.rules.promote(f);game.conversation_text=game.rules.message;refresh());button(r,"Report completed work",func():game.rules.turn_in(f);game.conversation_text=game.rules.message;refresh())
  if f=="Civic Liaison Office" or f=="Neighbourhood Aid":button(body,"Discuss the Bluewater File",func():game.main_story(f);game.conversation_text=game.rules.message;refresh())
  heading("Available assignments")
  var candidates=game.quest_offers(f)
  for q in candidates:
   button(body,"Accept: %s ($%d, %d days)"%[q.title,q.reward,int((q.deadline-game.rules.s.minutes)/1440)],func():game.rules.accept(q.duplicate(true));game.rules.note("Assignment accepted. See journal and atlas.");close())
  button(body,"Member services",func():open("Services"))
 else:
  if game.conversation_profile.is_empty():
   label(body,"Ask a nearby resident about local work, directions or the building.")
  else:
   var p=game.conversation_profile;var memory=game.Society.memory(p,game.rules.s)
   label(body,"%s · %s · %s
Familiarity %d · Rapport %+d"%[p.name,p.job,p.trait,memory.met,memory.affinity],14)
   label(body,"“"+game.conversation_text+"”",18)
   var tones=row(body)
   for tone in ["Polite","Direct","Blunt"]:
    button(tones,("● " if game.conversation_tone==tone else "")+tone,func():game.conversation_tone=tone;refresh())
   heading("Ask about")
   var topics=GridContainer.new();topics.columns=2;body.add_child(topics)
   for topic in game.Society.TOPICS:button(topics,topic,func():game.talk(topic))
   if memory.last_topic=="Directions":
    heading("Where is…")
    var destinations=GridContainer.new();destinations.columns=2;body.add_child(destinations)
    for target in game.world.faction_points:
     button(destinations,target.name,func():game.rules.s.rumor_mark=target;game.conversation_text="I’ve marked "+target.name+" near "+target.real+" on your atlas.";refresh())
   button(body,"Show the marked direction on atlas",func():open("Atlas"))
   button(body,"Risk pickpocketing",func():game.pickpocket();close())
   if game.world.interior:button(body,"Ask about building services",func():open("Services"))
  button(body,"Goodbye",close)
func services():
 heading(service+" / services")
 if not game.world.interior:button(body,"Enter building rooms and upper floors",func():game.enter_service_building())
 var tabs=row(body)
 for t in ["Shop","Bank","Training","Clinic","Workshop","Property"]:button(tabs,t,func():service_page(t))
 service_page("Shop",false)
func service_page(page: String,rebuild: bool=true):
 if rebuild:
  clear();heading(service+" / "+page);var tabs=row(body)
  for t in ["Shop","Bank","Training","Clinic","Workshop","Property"]:button(tabs,t,func():service_page(t))
 var s=game.rules.s
 match page:
  "Shop":
   for i in game.rules.shop_stock():
    var price=int(i.value*(1.25-float(s.skills.Bargaining)/250.0-float(s.attrs.Personality-50)/1000.0));button(body,"Buy %s — $%d"%[i.name,price],func():game.rules.buy(i);service_page("Shop"))
   button(body,"Buy 40 launcher rounds — $30",func():
    if s.money>=30:s.money-=30;s.ammo+=40
    service_page("Shop"))
   heading("Sell inventory")
   for idx in range(s.inventory.size()):button(body,"Sell "+s.inventory[idx].name,func():game.rules.sell(idx);service_page("Shop"))
  "Bank":
   label(body,"Cash $%d · Deposit $%d · Debt $%d"%[s.money,s.bank,s.debt])
   button(body,"Deposit $100",func():
    if s.money>=100:s.money-=100;s.bank+=100
    service_page("Bank"))
   button(body,"Withdraw $100",func():
    if s.bank>=100:s.bank-=100;s.money+=100
    service_page("Bank"))
   button(body,"Borrow $1,000 / due in 30 days",func():
    if s.debt==0:s.debt=1100;s.money+=1000;s.debt_due=s.minutes+43200
    service_page("Bank"))
   button(body,"Repay debt",func():
    if s.money>=s.debt:s.money-=s.debt;s.debt=0
    service_page("Bank"))
  "Training":
   label(body,"Cost $%d per lesson; one lesson per 12 hours. Training ceiling 51."%(100*s.level))
   var grid=GridContainer.new();grid.columns=3;body.add_child(grid)
   for k in game.rules.SKILLS:button(grid,"%s %d"%[k,s.skills[k]],func():game.rules.train(k);service_page("Training"))
  "Clinic":
   button(body,"Treatment, disease and poison cure — $75",func():
    if s.money>=75:s.money-=75;s.hp=s.max_hp;s.poison=false;s.disease=false;game.rules.note("Treated and discharged.")
    service_page("Clinic"))
   label(body,"Experimental programmes are fictional gameplay conditions.")
   button(body,"Experimental implant — $300",func():
    if s.money>=300:s.money-=300;s.condition="Experimental implant";game.rules.note("Devices cost less; battery leaks during daylight.")
    service_page("Clinic"))
   button(body,"Night-shift conditioning — $300",func():
    if s.money>=300:s.money-=300;s.condition="Night-shift dependency";game.rules.note("Stronger at night; daytime fatigue increases.")
    service_page("Clinic"))
   button(body,"Remove experimental condition — $150",func():
    if s.money>=150:s.money-=150;s.condition="None"
    service_page("Clinic"))
  "Workshop":
   button(body,"Open device designer",func():open("Devices"))
   for idx in range(s.inventory.size()):
    var i=s.inventory[idx]
    if i.type not in ["weapon","armour"]:continue
    var r=row(body);label(r,i.name+" / %d%%"%i.condition)
    button(r,"Repair $25",func():
     if s.money>=25:s.money-=25;i.condition=100;game.rules.advance(60)
     service_page("Workshop"))
    button(r,"Upgrade +3 power / $200",func():
     if s.money>=200 and i.tier<9:s.money-=200;i.tier+=1;i.power+=3;i.value+=100;i.enchant="Reinforced %d"%i.tier;game.rules.practice("Materials",5)
     service_page("Workshop"))
   button(body,"Compound 1 medical kit / $20",func():
    if s.money>=20:s.money-=20;s.inventory.append(game.rules.item("Medical Kit","consumable",35,0.4,20+int(s.skills["First Aid"]/3)));game.rules.practice("First Aid",4)
    service_page("Workshop"))
  "Property":
   for pair in [["Bicycle",250],["Work van",2500],["Apartment",5000],["Marina berth",10000]]:
    button(body,"%s — %s"%[pair[0],"owned" if pair[0] in s.properties else "$%d"%pair[1]],func():
     if not pair[0] in s.properties and s.money>=pair[1]:s.money-=pair[1];s.properties.append(pair[0]);game.rules.note("Purchased "+pair[0])
     service_page("Property"))
   button(body,"Pay fines / clear wanted status — $%d"%(s.wanted*100),func():
    var fine=s.wanted*100
    if s.money>=fine:s.money-=fine;s.wanted=0
    service_page("Property"))

func court():
 heading("Civic hearing")
 label(body,"The patrol asks you to account for a reported offence. This is a fictional, simplified game process.
Outstanding offences: %d · Fine: $%d"%[game.rules.s.wanted,game.rules.s.wanted*100])
 button(body,"Pay the fine",func():game.resolve_court("pay"))
 button(body,"Contest using Protocol",func():game.resolve_court("contest"))
 button(body,"Accept community service",func():game.resolve_court("serve"))
