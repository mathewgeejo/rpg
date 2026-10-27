extends CanvasLayer

const MapView = preload("res://scripts/atlas_map.gd")
const LocalMap = preload("res://scripts/local_map.gd")
const VitalBar = preload("res://scripts/vital_bar.gd")
const Hud = preload("res://scripts/hud.gd")
const CREAM = Color("eee4ca")
const GOLD = Color("d6b77d")
const MUTED = Color("a8acbc")
const JADE = Color("b4d8b6")
const INK = Color("171c32")
var game
var root: Control
var modal: Control
var hud: Control
var toast_label: Label
var toast_panel: Panel
var toast_time = 0.0
var banner: Control
var banner_time = 0.0
var serif: Font = preload("res://assets/fonts/display.tres")
var sans: Font = preload("res://assets/fonts/body.tres")
var waiting_binding = ""
var selected_class = "luck"
var hp_bar
var mana_bar
var stamina_bar
var stats_label: Label
var quest_label: Label
var prompt_label: Label
var signature_label: Label
var binding_labels: Dictionary = {}
var class_label: Label
var coin_label: Label
var title_bg: TextureRect
var local_map
var menu_clock = 0.0
var class_list: VBoxContainer
var detail: Control
var active_dialogue: Array = []
var dialogue_index = 0
var dialogue_name = ""
var dialogue_text: Label
var typewriter = 0.0
var theme_main: Theme

func _ready() -> void:
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	theme_main = Theme.new()
	theme_main.default_font = sans
	theme_main.default_font_size = 17
	root.theme = theme_main
	toast_panel = panel(root,Vector2(450,155),Vector2(540,84),Color(.035,.11,.12,.96),GOLD,.35)
	toast_panel.z_index = 100
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label = label(toast_panel,"",Vector2(20,14),Vector2(500,60),16,CREAM)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_panel.hide()

func clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 1) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(2 if border.a > 0 else 0)
	box.set_corner_radius_all(radius)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 10
	box.content_margin_bottom = 10
	return box

func panel(parent: Node, pos: Vector2, dimensions: Vector2, color: Color = INK, border: Color = GOLD, border_alpha: float = .25) -> Panel:
	var node = Panel.new()
	node.position = pos
	node.size = dimensions
	node.add_theme_stylebox_override("panel",style(color,Color(border,border_alpha)))
	parent.add_child(node)
	return node

func label(parent: Node, text: String, pos: Vector2, dimensions: Vector2, font_size: int = 18, color: Color = CREAM, display: bool = false) -> Label:
	var node = Label.new()
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.text = text
	node.position = pos
	node.size = dimensions
	node.add_theme_font_override("font",serif if display else sans)
	node.add_theme_font_size_override("font_size",int(font_size*game.settings.text_scale))
	node.add_theme_color_override("font_color",color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	node.size = dimensions
	return node

func button(parent: Node, text: String, pos: Vector2, dimensions: Vector2, callback: Callable, primary: bool = false) -> Button:
	var node = Button.new()
	node.text = text
	node.position = pos
	node.size = dimensions
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size",int(16*game.settings.text_scale))
	node.add_theme_color_override("font_color",INK if primary else CREAM)
	node.add_theme_color_override("font_hover_color",INK if primary else Color("fff1cf"))
	node.add_theme_color_override("font_focus_color",INK if primary else CREAM)
	node.add_theme_color_override("font_pressed_color",INK if primary else CREAM)
	node.add_theme_stylebox_override("normal",style(GOLD if primary else Color("263047"),Color(GOLD,.35)))
	node.add_theme_stylebox_override("hover",style(Color("e6ca91") if primary else Color("36435e"),GOLD))
	node.add_theme_stylebox_override("pressed",style(Color("ad986c") if primary else Color("222c41"),GOLD))
	node.add_theme_stylebox_override("focus",style(Color.TRANSPARENT,JADE))
	node.pressed.connect(func():
		game.sound.note(523.25,.1,.045)
		callback.call())
	parent.add_child(node)
	return node

func rule(parent: Node, pos: Vector2, width: float, color: Color = GOLD) -> void:
	var line = ColorRect.new()
	line.position = pos
	line.size = Vector2(width,1)
	line.color = Color(color,.3)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)

func _process(delta: float) -> void:
	menu_clock += delta
	if is_instance_valid(dialogue_text) and dialogue_text.visible_characters >= 0:
		typewriter += delta*44
		dialogue_text.visible_characters = int(typewriter)
	if is_instance_valid(title_bg) and not game.playing:
		title_bg.position = Vector2(-20+sin(menu_clock*.08)*8,-30+cos(menu_clock*.1)*7)
	if toast_time > 0:
		toast_time -= delta
		toast_panel.modulate.a = minf(1,toast_time)
		if toast_time <= 0: toast_panel.hide()
	if banner_time > 0:
		banner_time -= delta
		if is_instance_valid(banner):
			banner.modulate.a = minf(1,banner_time)
			if banner_time <= 0: banner.hide()

func title_screen() -> void:
	game.paused = false
	if is_instance_valid(hud): hud.queue_free()
	if is_instance_valid(modal): modal.queue_free()
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	game.world_view.preview = true
	game.room_id = 0
	game.zone = game.model.room(0)
	game.world_view.prepare_ground()
	game.world_view.camera = Vector2(670,485)
	var veil = ColorRect.new()
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shader = Shader.new()
	shader.code = "shader_type canvas_item; void fragment(){ float shade = mix(0.94,0.04,smoothstep(0.05,0.88,UV.x)); float vignette = smoothstep(0.3,0.9,distance(UV,vec2(0.5))); COLOR=vec4(0.018,0.065,0.073,min(0.97,shade+vignette*0.2)); }"
	var material = ShaderMaterial.new()
	material.shader = shader
	veil.material = material
	modal.add_child(veil)
	label(modal,"✧   THE UNWRITTEN ATLAS",Vector2(82,57),Vector2(470,35),17,GOLD)
	label(modal,"AN ORIGINAL FANTASY ROLE-PLAYING GAME",Vector2(85,180),Vector2(600,26),12,JADE)
	label(modal,"The Unwritten\nAtlas",Vector2(77,215),Vector2(710,236),80,CREAM,true)
	rule(modal,Vector2(85,480),72)
	label(modal,"Some places remember you.\nOthers are waiting to be written.",Vector2(85,504),Vector2(490,85),24,Color("c6d0bc"),true)
	button(modal,"Begin your journey    →",Vector2(85,628),Vector2(342,56),func(): game.new_journey(),true).grab_focus()
	if game.store.exists():
		button(modal,"Continue your journey",Vector2(85,696),Vector2(342,48),func(): game.continue_journey())
		button(modal,"Class codex",Vector2(85,756),Vector2(165,42),func(): codex_screen())
		button(modal,"Settings",Vector2(262,756),Vector2(165,42),func(): settings_screen())
	else:
		button(modal,"Explore Lantern Vale",Vector2(85,696),Vector2(342,48),func(): game.new_journey(0,true))
		button(modal,"20 classes · View codex",Vector2(85,756),Vector2(223,42),func(): codex_screen())
		button(modal,"Settings",Vector2(320,756),Vector2(107,42),func(): settings_screen())
	label(modal,"CHAPTER  I",Vector2(1174,66),Vector2(185,25),12,GOLD)
	label(modal,"Lantern Vale",Vector2(1122,91),Vector2(240,48),34,CREAM,true)
	label(modal,"A WORLD HELD IN MEMORY",Vector2(1092,818),Vector2(290,24),11,Color("d5d4b8"))
	label(modal,"WASD  EXPLORE     ·     MOUSE  AIM     ·     CONTROLLER READY",Vector2(85,854),Vector2(790,22),10,MUTED)
	button(modal,"×",Vector2(1383,17),Vector2(36,34),func(): game.get_tree().quit())
	button(modal,"Art credits",Vector2(1270,851),Vector2(122,30),func(): credits_screen())

func close_modal() -> void:
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
		modal = null
	if not game.playing:
		title_screen()
		return
	game.paused = false
	if not is_instance_valid(hud): show_hud()

func modal_base(eyebrow: String, title: String, subtitle: String = "") -> Panel:
	toast_panel.hide()
	toast_time = 0
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
	game.paused = game.playing
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var shade = ColorRect.new()
	shade.color = Color(.015,.045,.055,.88)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(shade)
	var surface = panel(modal,Vector2(90,52),Vector2(1260,796),Color("181e32"),GOLD,.5)
	label(surface,eyebrow,Vector2(38,26),Vector2(1100,24),11,GOLD)
	label(surface,title,Vector2(35,55),Vector2(1120,65),48,CREAM,true)
	if subtitle != "": label(surface,subtitle,Vector2(38,123),Vector2(1160,48),15,MUTED)
	rule(surface,Vector2(38,180),1184)
	button(surface,"×",Vector2(1180,24),Vector2(42,38),func(): close_modal()).grab_focus()
	return surface

func show_hud() -> void:
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
		modal = null
	game.paused = false
	if is_instance_valid(hud):
		root.remove_child(hud)
		hud.queue_free()
	hud = Hud.new()
	hud.game = game
	root.add_child(hud)

func update_hud() -> void:
	if is_instance_valid(hud): hud.refresh()

func location_banner(title: String, subtitle: String) -> void:
	if is_instance_valid(banner): banner.queue_free()
	banner = Control.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(banner)
	var a = label(banner,title,Vector2(420,48),Vector2(600,64),45,CREAM,true)
	a.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var b = label(banner,subtitle,Vector2(350,115),Vector2(740,28),10,GOLD)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner_time = 5

func toast(text: String) -> void:
	toast_label.text = text
	toast_panel.show()
	toast_panel.modulate.a = 1
	toast_time = 5
	root.move_child(toast_panel,root.get_child_count()-1)

func ritual_screen() -> void:
	var summoning = preload("res://scripts/summoning.gd")
	var surface = modal_base("THE CONSTELLATION WELL", "Summon a calling", "20 playable classes. Earn coins on the road. No purchases or paid currency.")
	label(surface,"BASE ODDS / B 50%   /   A 30%   /   S 15%   /   SS 4%   /   SSS 1%",Vector2(42,199),Vector2(1176,30),18,GOLD)
	label(surface,"Guaranteed S or higher by pull 10; guaranteed SSS by pull 80. Each class within a tier is equally likely.",Vector2(42,238),Vector2(1176,35),15,MUTED)
	label(surface,"%d coins   |   S+ pity %d/10   |   SSS pity %d/80   |   Duplicates refund 15 coins" % [game.coins,int(game.changed.get("summon:rare",0)),int(game.changed.get("summon:pity",0))],Vector2(42,277),Vector2(1176,30),16,JADE)
	button(surface,"Summon - 30 coins" if game.changed.get("summon:first",false) else "First summon - FREE",Vector2(42,323),Vector2(340,48),func():
		var result: Dictionary = summoning.summon(game)
		if not result.is_empty(): summon_reveal(result)
		else: ritual_screen(),true).disabled = game.changed.get("summon:first",false) and game.coins < 30
	var last_id: String = game.changed.get("summon:last","")
	if last_id != "":
		var last: Dictionary = game.data.class_by_id(last_id)
		label(surface,"%s  %s%s" % [last.rarity,last.name," - duplicate, +15 coins" if game.changed.get("summon:duplicate",false) else " - unlocked!"],Vector2(412,327),Vector2(790,40),24,Color(last.color),true)
	for i in game.data.classes.size():
		var entry: Dictionary = game.data.classes[i]
		var unlocked: bool = summoning.owned(game,entry.id)
		var item = button(surface,"%s  %s%s" % [entry.rarity,entry.name,"  [equipped]" if game.assigned and game.class_id == entry.id else ("  Equip" if unlocked else "  Locked")],Vector2(42+(i/10)*595,391+(i%10)*35),Vector2(575,31),func(): game.assign_class(entry.id); ritual_screen())
		item.disabled = not unlocked
		item.tooltip_text = entry.basic_name+": "+entry.gameplay+"\nSpecial: "+entry.signature+" - "+entry.description
	button(surface,"Return to the road",Vector2(42,750),Vector2(340,38),func(): close_modal(); show_hud())

func summon_reveal(entry: Dictionary) -> void:
	var surface = modal_base("THE SKY ANSWERS",entry.rarity+"  /  "+entry.name,"A duplicate returns 15 coins." if game.changed.get("summon:duplicate",false) else "A new calling joins your collection. Equip it whenever you choose.")
	var emblem = preload("res://scripts/class_emblem.gd").new()
	emblem.class_id = entry.id
	emblem.color = Color(entry.color)
	emblem.animated = game.settings.flashes
	emblem.position = Vector2(62,235)
	emblem.size = Vector2(265,265)
	surface.add_child(emblem)
	label(surface,entry.discipline.to_upper()+" DISCIPLINE",Vector2(395,235),Vector2(790,28),14,JADE)
	label(surface,entry.tagline,Vector2(395,285),Vector2(790,66),29,Color(entry.color),true)
	label(surface,"BASIC / "+entry.basic_name,Vector2(395,370),Vector2(790,32),17,GOLD)
	label(surface,entry.gameplay,Vector2(395,414),Vector2(790,85),20,CREAM)
	label(surface,"Q / "+entry.signature,Vector2(395,525),Vector2(790,30),17,GOLD)
	label(surface,entry.description,Vector2(395,566),Vector2(790,95),20,CREAM)
	label(surface,entry.passive+" / "+entry.passive_description,Vector2(60,675),Vector2(1135,50),16,JADE)
	button(surface,"Return to the road",Vector2(42,750),Vector2(340,38),func(): close_modal(); show_hud())
	button(surface,"Equip "+entry.name,Vector2(425,750),Vector2(380,38),func(): game.assign_class(entry.id),true)
	button(surface,"Summoning collection",Vector2(845,750),Vector2(350,38),func(): ritual_screen())
	if game.settings.flashes:
		emblem.modulate.a = 0
		create_tween().tween_property(emblem,"modulate:a",1.0,.6)

func codex_screen() -> void:
	var surface = modal_base("TWENTY CONSTELLATIONS", "The class codex", "A class is a philosophy made playable. Explore its signature, its cost, and the kind of power it cultivates.")
	var search = LineEdit.new()
	search.position = Vector2(38,208)
	search.size = Vector2(333,42)
	search.placeholder_text = "Search classes or philosophies…"
	search.add_theme_stylebox_override("normal",style(Color("153539"),Color(GOLD,.3)))
	surface.add_child(search)
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(38,266)
	scroll.size = Vector2(350,494)
	surface.add_child(scroll)
	class_list = VBoxContainer.new()
	class_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	class_list.add_theme_constant_override("separation",6)
	scroll.add_child(class_list)
	detail = Control.new()
	detail.position = Vector2(420,210)
	detail.size = Vector2(798,550)
	surface.add_child(detail)
	_fill_classes("")
	_class_detail(selected_class)
	search.text_changed.connect(_fill_classes)

func _fill_classes(query: String) -> void:
	clear(class_list)
	for entry in game.data.classes:
		if query.to_lower() not in (entry.name+" "+entry.tagline+" "+" ".join(entry.values)).to_lower(): continue
		var item = button(class_list,entry.name+("   ✧" if entry.showcase else ""),Vector2.ZERO,Vector2(325,42),func(): selected_class = entry.id; _class_detail(entry.id))
		item.custom_minimum_size = Vector2(325,42)
		item.alignment = HORIZONTAL_ALIGNMENT_LEFT

func _class_detail(id: String) -> void:
	clear(detail)
	var entry: Dictionary = game.data.class_by_id(id)
	label(detail,entry.discipline.to_upper()+" DISCIPLINE    /    "+" + ".join(entry.values).to_upper(),Vector2.ZERO,Vector2(780,25),11,JADE)
	label(detail,entry.name,Vector2(-3,39),Vector2(780,70),58,CREAM,true)
	label(detail,entry.basic_name+" - "+entry.gameplay,Vector2(0,116),Vector2(780,75),17,Color(entry.color),true)
	rule(detail,Vector2(0,194),780)
	label(detail,"SIGNATURE  ·  "+entry.signature.to_upper(),Vector2(0,220),Vector2(780,30),12,GOLD)
	label(detail,entry.description,Vector2(0,260),Vector2(773,75),20,CREAM,true)
	label(detail,"PASSIVE  ·  "+entry.passive,Vector2(0,355),Vector2(780,28),12,JADE)
	label(detail,entry.passive_description,Vector2(0,391),Vector2(780,54),16,MUTED)
	label(detail,"I   AWAKENING       II   RESONANCE       III   ASCENDANCE",Vector2(0,474),Vector2(780,28),12,GOLD)
	label(detail,"At Rank II, a specialization strengthens one trait in exchange for another.",Vector2(0,511),Vector2(780,37),14,MUTED)

func journal_screen() -> void:
	var surface = modal_base("THINGS WORTH REMEMBERING", "Your journal", "Lantern Vale · Chapter I")
	label(surface,"A brother unremembered",Vector2(40,216),Vector2(1100,54),36,CREAM,true)
	label(surface,game.quest_text(),Vector2(42,285),Vector2(1110,65),23,JADE,true)
	label(surface,"Mira remembers a brother nobody else can name. The old observatory may know why. Follow Wispwood Path south from town, then continue through Stonewater Crossing.",Vector2(42,360),Vector2(1090,85),18,MUTED)
	rule(surface,Vector2(40,470),1178)
	var entries = [
		["Keep the lanterns","Speak to Orin, kindle the two wilderness lanterns, and return.","Complete" if game.side_quests.lanterns >= 4 else ("Active" if game.side_quests.lanterns > 0 else "Undiscovered")],
		["A garden for tomorrow","Speak to Sella. Return after collecting three memories.","Complete" if game.side_quests.garden >= 2 else ("Active" if game.side_quests.garden > 0 else "Undiscovered")],
		["The undelivered letter","A forgotten satchel in Stonewater carries words meant for Mira.","Complete" if game.side_quests.letter >= 2 else ("Active" if game.side_quests.letter > 0 else "Undiscovered")]
	]
	for i in 3:
		label(surface,entries[i][0],Vector2(42,498+i*85),Vector2(850,35),25,CREAM,true)
		label(surface,entries[i][1],Vector2(42,536+i*85),Vector2(940,32),15,MUTED)
		label(surface,entries[i][2],Vector2(1060,505+i*85),Vector2(150,30),12,GOLD)
	button(surface,"Wayfarer's commissions  →",Vector2(879,732),Vector2(330,38),func(): commission_screen())
	button(surface,"Forgotten guardians",Vector2(42,732),Vector2(330,38),func(): guardian_screen())

func guardian_screen() -> void:
	var surface = modal_base("MEMORIES THAT LEARNED TO FIGHT", "The forgotten guardians", "Optional guardians guard old places and award summon coins. Only the Observatory Keeper stands between Mira and the seal.")
	var records = [
		["briar_crown","The Briar Crown","Wispwood root-court","Roots blossom around your last position. Move between the circles; more roots grow in phase two."],
		["tide_bell","The Drowned Bell","Stonewater chapel","Waves resolve in a sequence. Step into a gap after the first mark falls; phase two shortens its warning."],
		["the_keeper","The Unremembered Keeper","The Observatory","Dodge the falling star, then strike. Phase two adds four satellite marks around the Keeper."]
	]
	for i in records.size():
		var record: Array = records[i]
		var y = 220+i*165
		label(surface,record[1],Vector2(50,y),Vector2(900,40),30,CREAM,true)
		label(surface,record[2],Vector2(52,y+48),Vector2(900,28),14,GOLD)
		label(surface,record[3],Vector2(52,y+85),Vector2(1070,60),20,MUTED)
		label(surface,"Defeated" if game.changed.has(record[0]) else "Waiting",Vector2(1000,y+7),Vector2(200,35),17,JADE)
	button(surface,"Atlas",Vector2(50,740),Vector2(330,40),func(): atlas_screen())

func commission_screen() -> void:
	var surface = modal_base("WORK FOR THE ROAD AHEAD", "Wayfarer's commissions", "Requests from your neighbors. Accept a commission, follow its clues, and return here for your reward.")
	var entries: Array = game.model.commissions()
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var y = 215+i*172
		label(surface,entry.name,Vector2(42,y),Vector2(860,42),28,CREAM,true)
		label(surface,entry.story,Vector2(42,y+49),Vector2(850,63),16,MUTED)
		var status: String = game.contracts.get(entry.id,"")
		var caption = "Accept commission"
		if status == "active": caption = "Claim reward" if game.commission_progress(entry) >= entry.target else "%d / %d · In progress" % [game.commission_progress(entry),entry.target]
		if status == "complete": caption = "Complete"
		button(surface,caption,Vector2(947,y+29),Vector2(266,46),func(): game.commission_action(entry),status == "").disabled = status == "complete" or (status == "active" and game.commission_progress(entry) < entry.target)
		label(surface,"%d COINS  ·  35 XP" % entry.reward,Vector2(960,y+92),Vector2(250,25),11,GOLD)
		rule(surface,Vector2(42,y+143),1170)

func atlas_screen() -> void:
	var surface = modal_base("THE WORLD BETWEEN THE SEALS", "The Unwritten Atlas", "One small valley. Four connected places. Every path, encounter, and secret has a place.")
	var map_view = MapView.new()
	map_view.game = game
	map_view.position = Vector2(38,208)
	map_view.size = Vector2(1184,486)
	surface.add_child(map_view)
	label(surface,"Follow the road to the Observatory. Rose squares mark guardians; green squares mark defeated guardians.",Vector2(42,716),Vector2(1150,27),14,JADE)
	label(surface,"LANTERN VALE  /  KEEP A LITTLE LIGHT FOR THE ROAD",Vector2(42,758),Vector2(850,24),11,MUTED)

func settings_screen() -> void:
	var surface = modal_base("MAKE THE ROAD YOUR OWN", "Settings", "Changes save automatically. Select a binding, then press a key. Existing bindings swap to avoid conflicts.")
	var toggles = [["sound","Ambient music & sound"],["flashes","Animated light effects"],["shake","Camera shake"]]
	for i in 3:
		var setting: String = toggles[i][0]
		button(surface,("●  " if game.settings[setting] else "○  ")+toggles[i][1],Vector2(40,215+i*60),Vector2(390,46),func(): game.settings[setting] = not game.settings[setting]; game.save_settings(); settings_screen())
	button(surface,"Text size: %d%%" % (game.settings.text_scale*100),Vector2(40,410),Vector2(390,46),func(): game.settings.text_scale = 1.15 if game.settings.text_scale == 1.0 else 1.0; game.save_settings(); settings_screen())
	label(surface,"CONTROLLER",Vector2(40,509),Vector2(400,25),11,GOLD)
	label(surface,"Left stick · Move\nRight stick · Aim\nA · Interact     B · Evade\nX · Signature     Y · Ward\nRB · Circle     LB · Starstep\nRT / Right stick click · Strike",Vector2(40,554),Vector2(400,180),16,MUTED)
	var actions: Array = game.DEFAULT_KEYS.keys()
	for i in actions.size():
		var action: String = actions[i]
		var x = 490+(i%2)*354
		var y = 215+(i/2)*62
		label(surface,action.replace("_"," ").capitalize(),Vector2(x,y),Vector2(220,24),13,MUTED)
		button(surface,"Press a key…" if waiting_binding == action else game.key_label(action),Vector2(x,y+22),Vector2(285,38),func(): waiting_binding = action; settings_screen())

func character_screen() -> void:
	var surface = modal_base("THE THINGS YOU PRACTICE BECOME YOU", "Character & disciplines", "Circle magic shapes the world around you. Knight stars strengthen the promise within you.")
	var titles = {"sword":"Swordcraft","circles":"Circle weaving","stars":"Knight stars","woodcutting":"Wood gathering","fishing":"River fishing"}
	for i in titles.size():
		var key: String = titles.keys()[i]
		label(surface,titles[key],Vector2(42,217+i*76),Vector2(360,31),24,CREAM,true)
		label(surface,"LEVEL %d   /   %d XP" % [game.skill_level(key),game.skills[key]],Vector2(44,252+i*76),Vector2(360,26),13,JADE)
	label(surface,"ARMOR",Vector2(475,214),Vector2(720,28),12,GOLD)
	for i in 3:
		var armor_name = ["cloth","leather","plate"][i]
		button(surface,("◆ " if game.armor == armor_name else "")+armor_name.capitalize(),Vector2(475+i*244,253),Vector2(228,43),func(): game.equip_armor(armor_name),game.armor == armor_name)
	label(surface,"Cloth: stronger circles and mana recovery. Leather: faster movement. Plate: stronger sword strikes, wards, and defense; slower movement.",Vector2(475,313),Vector2(720,67),16,MUTED)
	label(surface,"MAGIC FOCUS",Vector2(475,395),Vector2(720,24),12,GOLD)
	for i in 3:
		var focus: String = ["aether","ember","frost"][i]
		button(surface,("◆ " if game.magic_focus == focus else "")+focus.capitalize(),Vector2(475+i*244,435),Vector2(228,40),func(): game.magic_focus = focus; game.save_game(); character_screen(),game.magic_focus == focus)
	label(surface,"Aether returns mana on impact. Ember burns. Frost slows. Rapid casting builds strain; at 80 strain, casting costs 6 health and recovers more slowly.",Vector2(475,490),Vector2(720,67),15,MUTED)
	label(surface,"SWORD STANCE",Vector2(475,571),Vector2(720,24),12,GOLD)
	for i in 3:
		var stance: String = ["flowing","resolute","rending"][i]
		button(surface,("◆ " if game.sword_stance == stance else "")+stance.capitalize(),Vector2(475+i*244,610),Vector2(228,40),func(): game.sword_stance = stance; game.save_game(); character_screen(),game.sword_stance == stance)
	label(surface,"Flowing travels farther. Resolute grants a ward. Rending trades stamina for a heavy cut that exposes a weakness.",Vector2(475,665),Vector2(720,59),15,MUTED)
	button(surface,"Eat river fish  (%d)" % game.inventory.river_fish,Vector2(42,656),Vector2(360,43),func(): game.eat_fish(); character_screen())
	button(surface,"Willow charm · Equipped" if game.changed.has("willow_charm") else "Carve charm · 3 wood + 10 coins",Vector2(42,594),Vector2(360,43),func(): game.craft_charm()).disabled = game.changed.has("willow_charm")
	label(surface,"Willow wood: %d    ·    Fish: %d" % [game.inventory.willow_wood,game.inventory.river_fish],Vector2(44,724),Vector2(380,35),14,GOLD)
	label(surface,"K  ·  Return here to change your armor, focus, and stance.",Vector2(475,746),Vector2(720,30),12,JADE)

func shop_screen() -> void:
	var surface = modal_base("THE LITTLE PROVISIONS STALL", "Something for the road", "Orin left the ledger open. He says trust is cheaper than hiring a shopkeeper.")
	label(surface,"Wrapped river fish",Vector2(70,245),Vector2(1100,60),38,CREAM,true)
	label(surface,"Restores 25 health. Keep it in your pack and eat it from Character & disciplines when you need it.",Vector2(72,330),Vector2(1050,85),22,MUTED)
	label(surface,"Your purse: %d coins    /    Fish in your pack: %d" % [game.coins,game.inventory.river_fish],Vector2(72,452),Vector2(1060,44),22,GOLD)
	button(surface,"Buy a wrapped fish · 10 coins",Vector2(72,540),Vector2(520,58),func(): game.buy_fish(),true)
	button(surface,"Sell fish +6 coins",Vector2(615,540),Vector2(270,58),func(): game.sell_material("river_fish"))
	button(surface,"Sell wood +4 coins",Vector2(910,540),Vector2(270,58),func(): game.sell_material("willow_wood"))
	label(surface,"Rest at a lantern to refresh gathering spots. Sell supplies to fund more summons. You can also catch your own fish beside the bridge. Willow wood from Wispwood can be carved into a lasting health charm.",Vector2(72,646),Vector2(1060,80),18,JADE)

func credits_screen() -> void:
	var surface = modal_base("MADE WITH REAL PIXEL ART", "The artists behind the Atlas", "Original editable pixel artwork and credited artist-made assets. No AI image generation.")
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(40,210)
	scroll.size = Vector2(1180,550)
	surface.add_child(scroll)
	var names = Label.new()
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	names.add_theme_font_size_override("font_size",16)
	names.add_theme_color_override("font_color",CREAM)
	names.text = FileAccess.get_file_as_string("res://assets/custom/README.md")+"\n\nREFERENCE ART CREDITS\n\n"+FileAccess.get_file_as_string("res://assets/pixel/ATTRIBUTION.md")+"\n\nORIGINAL BASE CREDITS\n\n"+FileAccess.get_file_as_string("res://assets/pixel/base/CREDITS.TXT")+"\n\nORIGINAL FOREST CREDITS\n\n"+FileAccess.get_file_as_string("res://assets/pixel/forest/credits.txt")+"\n\nORIGINAL DECORATION CREDITS\n\n"+FileAccess.get_file_as_string("res://assets/pixel/decorations/CREDITS-decorations-medieval.txt")+"\n\nORIGINAL CHARACTER CREDITS\n\n"+FileAccess.get_file_as_string("res://assets/pixel/hero/AUTHORS.txt")
	scroll.add_child(names)

func pause_screen() -> void:
	var surface = modal_base("A MOMENT BETWEEN ROADS", "Rest your eyes", "Your journey saves at lanterns, story moments, transitions, and regular intervals.")
	button(surface,"Return to the road",Vector2(405,238),Vector2(450,52),func(): close_modal(),true)
	button(surface,"Save journey",Vector2(405,310),Vector2(450,52),func(): if game.save_game(): toast("Your place in the Atlas is saved."))
	button(surface,"Summon & equip classes",Vector2(405,382),Vector2(450,52),func(): ritual_screen())
	button(surface,"Settings & controls",Vector2(405,454),Vector2(450,52),func(): settings_screen())
	button(surface,"Return to title",Vector2(405,526),Vector2(450,52),func(): game.save_game(); game.playing = false; game.world_view.queue_redraw(); title_screen())
	button(surface,"Save & quit",Vector2(405,598),Vector2(450,52),func(): game.save_game(); game.get_tree().quit())
	button(surface,"Companions [P]",Vector2(75,598),Vector2(280,52),func(): companion_screen())
	button(surface,"Test chamber [F10]",Vector2(905,598),Vector2(280,52),func(): debug_screen())
	label(surface,"Lantern Vale   /   %d minutes on the road" % int(game.play_time/60),Vector2(405,706),Vector2(600,28),13,MUTED)

func companion_screen() -> void:
	var surface = modal_base("BONDS OF THE VALE", "Your companions", "Weaken a wild creature below 40% health, approach it, and press T to offer one river fish. Taming is guaranteed.")
	var names = preload("res://scripts/companions.gd").SPECIES
	var gifts = ["Restores 2 health", "Exposes enemies", "Inflicts burn", "Builds a protective shield", "Restores 3 mana"]
	var habitats = ["Wispwood lower path / Stonewater west bank","Wispwood bend / Stonewater west bank","Wispwood upper path / Stonewater east bank","Wispwood north path / Stonewater north road","Wispwood, beside the old western satchel"]
	for i in names.size():
		var owned: bool = game.changed.get("pet:"+str(i),false)
		var bond = int(game.changed.get("pet:bond:"+str(i),0))
		label(surface,names[i]+" - "+gifts[i]+" | Bond "+str(bond),Vector2(55,225+i*88),Vector2(850,35),23,CREAM)
		label(surface,habitats[i],Vector2(57,264+i*88),Vector2(850,28),14,MUTED)
		var portrait = TextureRect.new()
		var texture = AtlasTexture.new()
		texture.atlas = load("res://assets/custom/creatures.png")
		texture.region = Rect2(0,i*32,24,32)
		portrait.texture = texture
		portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		portrait.position = Vector2(865,218+i*88)
		portrait.size = Vector2(48,64)
		surface.add_child(portrait)
		var b = button(surface,"Following" if game.companions.active() == i else ("Call" if owned else "Untamed"),Vector2(945,220+i*88),Vector2(250,48),func(): game.changed["pet:active"] = i; game.save_game(); companion_screen())
		b.disabled = not owned
	button(surface,"Offer fish to a nearby creature [T]",Vector2(55,710),Vector2(550,45),func(): close_modal(); game.companions.tame())
	button(surface,"Let companion rest",Vector2(650,710),Vector2(545,45),func(): game.changed["pet:active"] = -1; game.save_game(); companion_screen())
	label(surface,"Companions gain damage with bond and stop attacking weakened wild creatures so you can tame them.",Vector2(55,665),Vector2(1135,40),16,JADE)

func debug_screen() -> void:
	var surface = modal_base("TEST CHAMBER", "Try every constellation", "God mode prevents damage and refills combat resources. Unlocks and rewards are saved; god mode itself is session-only.")
	button(surface,"God mode: "+("ON" if game.god_mode else "OFF"),Vector2(45,215),Vector2(360,48),func(): game.god_mode = not game.god_mode; debug_screen(),true)
	button(surface,"Unlock all 20 classes",Vector2(445,215),Vector2(360,48),func():
		for entry in game.data.classes: game.changed["class:"+entry.id] = true
		game.save_game()
		ritual_screen())
	button(surface,"+3000 coins / +50 fish",Vector2(845,215),Vector2(360,48),func(): game.coins += 3000; game.inventory.river_fish += 50; game.save_game(); toast("Test supplies added."))
	for i in 4:
		button(surface,"Travel: "+game.model.room(i).name,Vector2(45,300+i*65),Vector2(560,48),func(): game.enter_room(i); close_modal())
	button(surface,"Respawn this area's enemies",Vector2(650,300),Vector2(555,48),func():
		for enemy in game.zone.enemies: game.changed.erase(enemy.id)
		game.combat.load_room(game.zone)
		close_modal())
	button(surface,"Unlock all companions",Vector2(650,365),Vector2(555,48),func():
		for i in 5: game.changed["pet:"+str(i)] = true
		game.save_game()
		companion_screen())
	button(surface,"Rank III / full recovery",Vector2(650,430),Vector2(555,48),func(): game.gain_xp(500); game.hp = game.max_hp; game.mana = game.max_mana; game.stamina = 100; toast("Rank and resources restored."))
	button(surface,"Grant story fragments",Vector2(650,495),Vector2(555,48),func(): game.memories = maxi(3,game.memories); game.quest_stage = maxi(2,game.quest_stage); game.save_game(); toast("The Observatory seal is ready."))
	label(surface,"Use Summon & equip classes to switch builds. Press F10 on the road to reopen this chamber.",Vector2(45,640),Vector2(1140,80),23,JADE)

func dialogue(speaker: String, pages: Array) -> void:
	dialogue_name = speaker
	active_dialogue = pages
	dialogue_index = 0
	_draw_dialogue()

func _draw_dialogue() -> void:
	if toast_label.text.begins_with("Welcome"):
		toast_panel.hide()
		toast_time = 0
	if is_instance_valid(banner): banner.hide()
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
	game.paused = true
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var surface = panel(modal,Vector2(60,585),Vector2(1320,266),Color("11162b"),CREAM,.9)
	label(surface,dialogue_name.to_upper(),Vector2(28,18),Vector2(1180,26),14,GOLD)
	var portrait = TextureRect.new()
	var texture = AtlasTexture.new()
	var who = "mira" if dialogue_name.begins_with("Mira") else ("orin" if dialogue_name.begins_with("Orin") else ("sella" if dialogue_name.begins_with("Sella") else "wanderer_cloth"))
	texture.atlas = load("res://assets/custom/%s.png" % who)
	texture.region = Rect2(8,4,32,40)
	portrait.texture = texture
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.position = Vector2(24,66)
	portrait.size = Vector2(96,120)
	surface.add_child(portrait)
	dialogue_text = label(surface,str(active_dialogue[dialogue_index]),Vector2(152,65),Vector2(1135,134),22,CREAM)
	typewriter = 0
	dialogue_text.visible_characters = 0
	label(surface,"%d / %d" % [dialogue_index+1,active_dialogue.size()],Vector2(152,222),Vector2(300,25),12,MUTED)
	button(surface,"Continue  →" if dialogue_index+1 < active_dialogue.size() else "Return to the road",Vector2(1050,210),Vector2(237,40),func():
		if dialogue_text.visible_characters >= 0 and dialogue_text.visible_characters < dialogue_text.text.length():
			typewriter = dialogue_text.text.length()
			dialogue_text.visible_characters = -1
			return
		if dialogue_index+1 < active_dialogue.size():
			dialogue_index += 1
			_draw_dialogue()
		else: close_modal(),true).grab_focus()

func seal_screen() -> void:
	var surface = modal_base("THE FIRST SEAL", "What should a world remember?", "Elian offered his memories to keep Lantern Vale safe. The seal learned to take without asking.")
	label(surface,"Inside the seal, a voice is still counting the names of people it has protected. Elian is one of them. He has almost forgotten that he is also a person.\n\nYou can restore what the town lost, or end the seal's claim over human memory. Both choices leave work for the living.",Vector2(52,230),Vector2(1150,200),26,CREAM,true)
	button(surface,"Return the memory · Let the town remember Elian and choose its future keepers.",Vector2(52,485),Vector2(1150,72),func(): game.choose_seal("remember"),true)
	button(surface,"Release the claim · Let the valley guard itself; no memory will be taken again.",Vector2(52,583),Vector2(1150,72),func(): game.choose_seal("release"))
	label(surface,"There is no answer without a consequence. There is still an answer that belongs to you.",Vector2(52,714),Vector2(1150,41),17,MUTED)
