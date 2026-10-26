extends CanvasLayer

const MapView = preload("res://scripts/atlas_map.gd")
const CREAM = Color("eee4ca")
const GOLD = Color("d6b77d")
const MUTED = Color("94aaa4")
const JADE = Color("8bc9b5")
const INK = Color("0c2428")
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
var art: Texture2D = preload("res://assets/art/lantern_vale.png")
var hero: Texture2D = preload("res://assets/art/wanderer.png")
var waiting_binding = ""
var question_index = 0
var selected_class = "luck"
var hp_bar: ProgressBar
var mana_bar: ProgressBar
var stamina_bar: ProgressBar
var stats_label: Label
var quest_label: Label
var prompt_label: Label
var signature_label: Label
var class_label: Label
var coin_label: Label
var title_bg: TextureRect
var menu_clock = 0.0
var class_list: VBoxContainer
var detail: Control
var active_dialogue: Array = []
var dialogue_index = 0
var dialogue_name = ""
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

func style(color: Color, border: Color = Color.TRANSPARENT, radius: int = 5) -> StyleBoxFlat:
	var box = StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0 else 0)
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
	node.text = text
	node.position = pos
	node.size = dimensions
	node.add_theme_font_override("font",serif if display else sans)
	node.add_theme_font_size_override("font_size",int(font_size*game.settings.text_scale))
	node.add_theme_color_override("font_color",color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
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
	node.add_theme_stylebox_override("normal",style(GOLD if primary else Color(.05,.15,.16,.8),Color(GOLD,.35)))
	node.add_theme_stylebox_override("hover",style(Color("e6ca91") if primary else Color("214640"),GOLD))
	node.add_theme_stylebox_override("pressed",style(Color("ad986c") if primary else Color("2e5148"),GOLD))
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
	title_bg = TextureRect.new()
	title_bg.texture = art
	title_bg.position = Vector2(-20,-30)
	title_bg.size = Vector2(1500,1000)
	title_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	title_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	modal.add_child(title_bg)
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
	label(modal,"The Unwritten\nAtlas",Vector2(77,215),Vector2(710,236),100,CREAM,true)
	rule(modal,Vector2(85,480),72)
	label(modal,"Some places remember you.\nOthers are waiting to be written.",Vector2(85,504),Vector2(490,85),24,Color("c6d0bc"),true)
	button(modal,"Begin your journey    →",Vector2(85,628),Vector2(342,56),func(): game.new_journey(),true)
	if game.store.exists():
		button(modal,"Continue your journey",Vector2(85,696),Vector2(342,48),func(): game.continue_journey())
		button(modal,"Class codex",Vector2(85,756),Vector2(165,42),func(): codex_screen())
		button(modal,"Settings",Vector2(262,756),Vector2(165,42),func(): settings_screen())
	else:
		button(modal,"Explore Lantern Vale",Vector2(85,696),Vector2(342,48),func(): game.new_journey(0,true))
		button(modal,"50 classes · View codex",Vector2(85,756),Vector2(223,42),func(): codex_screen())
		button(modal,"Settings",Vector2(320,756),Vector2(107,42),func(): settings_screen())
	label(modal,"CHAPTER  I",Vector2(1174,66),Vector2(185,25),12,GOLD)
	label(modal,"Lantern Vale",Vector2(1122,91),Vector2(240,48),34,CREAM,true)
	label(modal,"A WORLD HELD IN MEMORY",Vector2(1092,818),Vector2(290,24),11,Color("d5d4b8"))
	label(modal,"WASD  EXPLORE     ·     MOUSE  AIM     ·     CONTROLLER READY",Vector2(85,854),Vector2(790,22),10,MUTED)
	button(modal,"×",Vector2(1383,17),Vector2(36,34),func(): game.get_tree().quit())

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
	var surface = panel(modal,Vector2(90,52),Vector2(1260,796),Color("0d282c"),GOLD,.3)
	label(surface,eyebrow,Vector2(38,26),Vector2(1100,24),11,GOLD)
	label(surface,title,Vector2(35,55),Vector2(1120,65),48,CREAM,true)
	if subtitle != "": label(surface,subtitle,Vector2(38,123),Vector2(1160,48),15,MUTED)
	rule(surface,Vector2(38,180),1184)
	button(surface,"×",Vector2(1180,24),Vector2(42,38),func(): close_modal())
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
	hud = Control.new()
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	var status = panel(hud,Vector2(28,26),Vector2(308,136),Color(.025,.075,.085,.92))
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	class_label = label(status,"Wanderer",Vector2(20,12),Vector2(265,30),25,CREAM,true)
	hp_bar = progress(status,Vector2(20,52),Vector2(266,7),Color("cc9983"))
	mana_bar = progress(status,Vector2(20,68),Vector2(266,5),Color("7dc7c2"))
	stamina_bar = progress(status,Vector2(20,82),Vector2(266,4),Color("b3c38a"))
	stats_label = label(status,"",Vector2(20,100),Vector2(270,22),11,MUTED)
	var quest = panel(hud,Vector2(1050,26),Vector2(362,126),Color(.025,.075,.085,.90))
	quest.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label(quest,"CHAPTER I  ·  A BROTHER UNREMEMBERED",Vector2(20,13),Vector2(326,23),10,GOLD)
	quest_label = label(quest,"",Vector2(20,46),Vector2(320,56),18,CREAM,true)
	var dock = panel(hud,Vector2(373,800),Vector2(694,74),Color(.025,.075,.085,.94))
	dock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label(dock,"LMB\nStrike",Vector2(20,12),Vector2(78,52),13,CREAM)
	label(dock,"RMB / 2\nCircle",Vector2(108,12),Vector2(95,52),13,JADE)
	signature_label = label(dock,"Q\nSignature",Vector2(221,12),Vector2(178,52),13,GOLD)
	label(dock,"3\nStarstep",Vector2(408,12),Vector2(83,52),13,CREAM)
	label(dock,"R\nWard",Vector2(503,12),Vector2(65,52),13,CREAM)
	label(dock,"SPACE\nEvade",Vector2(584,12),Vector2(85,52),13,CREAM)
	button(hud,"M  Atlas",Vector2(28,818),Vector2(116,43),func(): atlas_screen())
	button(hud,"J  Journal",Vector2(154,818),Vector2(126,43),func(): journal_screen())
	button(hud,"C  Codex",Vector2(1107,818),Vector2(125,43),func(): codex_screen())
	button(hud,"Ⅱ",Vector2(1343,818),Vector2(66,43),func(): pause_screen())
	coin_label = label(hud,"",Vector2(1236,830),Vector2(100,25),14,GOLD)
	prompt_label = label(hud,"",Vector2(430,741),Vector2(580,40),17,CREAM)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	update_hud()

func progress(parent: Node, pos: Vector2, dimensions: Vector2, color: Color) -> ProgressBar:
	var bar = ProgressBar.new()
	bar.position = pos
	bar.size = dimensions
	bar.show_percentage = false
	var background = style(Color("28413f"))
	var fill = style(color)
	for box in [background,fill]:
		box.content_margin_top = 0
		box.content_margin_bottom = 0
		box.content_margin_left = 0
		box.content_margin_right = 0
	bar.add_theme_stylebox_override("background",background)
	bar.add_theme_stylebox_override("fill",fill)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(bar)
	return bar

func update_hud() -> void:
	if not is_instance_valid(hud): return
	class_label.text = "%s  ·  %s %d" % [game.class_def.name if game.assigned else "Wanderer","Circle" if game.class_def.discipline == "circle" else ("Star" if game.class_def.discipline == "star" else "Rank"),game.rank]
	hp_bar.value = game.hp/game.max_hp*100
	mana_bar.value = game.mana/game.max_mana*100
	stamina_bar.value = game.stamina
	stats_label.text = "%d / %d HP     %d MANA     %d XP" % [game.hp,game.max_hp,game.mana,game.xp]
	quest_label.text = game.quest_text()
	coin_label.text = "◈  %d" % game.coins
	prompt_label.text = "%s   %s" % [game.key_label("interact"),game.nearest_object.name] if not game.nearest_object.is_empty() else ""
	signature_label.text = "%s%s\n%s" % [game.key_label("signature"),"  %.1fs" % game.combat.signature_cd if game.combat.signature_cd > 0 else "",game.class_def.signature]

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
	question_index = mini(game.answers.size(),23)
	_draw_question()

func _draw_question() -> void:
	var q: Dictionary = game.data.questions[question_index]
	var surface = modal_base("THE RITUAL OF AFFINITY", "The shape of a soul", "Twenty-four dilemmas. No correct answers. Only the things you choose to carry.")
	label(surface,"%02d / 24" % (question_index+1),Vector2(1114,129),Vector2(110,30),15,GOLD)
	label(surface,q.title,Vector2(42,204),Vector2(1138,44),30,CREAM,true)
	var story: String = q.text
	if q.has("reflection") and game.answers.size() > q.reflection.question:
		story += "\n"+q.reflection.text
	label(surface,story,Vector2(42,259),Vector2(1165,106),18,Color("c6d1c4"))
	for i in 4:
		var selected = game.answers.size() > question_index and int(game.answers[question_index]) == i
		var choice = button(surface,("●   " if selected else "○   ")+q.choices[i].text,Vector2(42,385+i*69),Vector2(1176,58),func():
			if game.answers.size() == question_index: game.answers.append(i)
			else: game.answers[question_index] = i
			game.save_game()
			_draw_question(),selected)
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label(surface,"This ritual interprets a fictional character. It is not a psychological diagnosis.",Vector2(42,679),Vector2(780,27),12,MUTED)
	button(surface,"← Previous",Vector2(42,724),Vector2(150,42),func():
		question_index = maxi(0,question_index-1)
		_draw_question()).disabled = question_index == 0
	button(surface,"Take the road · resume later",Vector2(208,724),Vector2(308,42),func():
		game.save_game()
		close_modal()
		show_hud())
	button(surface,"Reveal affinities  →" if question_index == 23 else "Next question  →",Vector2(990,724),Vector2(228,42),func():
		if question_index == 23: affinity_screen()
		else:
			question_index += 1
			_draw_question(),true).disabled = game.answers.size() <= question_index

func affinity_screen() -> void:
	var matches: Array = game.data.affinities(game.answers)
	var surface = modal_base("THREE WAYS TO ANSWER THE WORLD", "Your affinities", "The strongest resonance is an invitation. You may affirm it, or choose one of the other two paths.")
	for i in 3:
		var entry: Dictionary = matches[i]["class"]
		var card = panel(surface,Vector2(38+i*402,209),Vector2(380,505),Color("143438"),Color(entry.color),.5)
		label(card,"STRONGEST RESONANCE" if i == 0 else "ANOTHER THREAD",Vector2(23,20),Vector2(332,24),10,Color(entry.color))
		label(card,entry.name,Vector2(20,63),Vector2(338,60),36,CREAM,true)
		label(card,entry.discipline.to_upper()+"  ·  "+entry.values[0].to_upper(),Vector2(23,133),Vector2(332,24),11,JADE)
		label(card,game.data.explanation(entry,game.answers),Vector2(23,178),Vector2(331,240),15,Color("cad4c5"))
		button(card,"Walk this path   →",Vector2(23,439),Vector2(334,45),func(): game.assign_class(entry.id),i == 0)
	button(surface,"← Revisit your answers",Vector2(38,735),Vector2(260,37),func(): question_index = 0; _draw_question())

func codex_screen() -> void:
	var surface = modal_base("FIFTY WAYS TO BECOME", "The class codex", "A class is a philosophy made playable. Explore its signature, its cost, and the kind of power it cultivates.")
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
	label(detail,entry.tagline,Vector2(0,116),Vector2(780,55),24,Color(entry.color),true)
	rule(detail,Vector2(0,194),780)
	label(detail,"SIGNATURE  ·  "+entry.signature.to_upper(),Vector2(0,220),Vector2(780,30),12,GOLD)
	label(detail,entry.description,Vector2(0,260),Vector2(773,75),20,CREAM,true)
	label(detail,"PASSIVE  ·  "+entry.passive,Vector2(0,355),Vector2(780,28),12,JADE)
	label(detail,entry.passive_description,Vector2(0,391),Vector2(780,54),16,MUTED)
	label(detail,"I   AWAKENING       II   RESONANCE       III   ASCENDANCE",Vector2(0,474),Vector2(780,28),12,GOLD)
	label(detail,"Seeded specializations reshape strengths through a meaningful tradeoff.",Vector2(0,511),Vector2(780,37),14,MUTED)

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

func atlas_screen() -> void:
	var surface = modal_base("THE WORLD BETWEEN THE SEALS", "The Unwritten Atlas", "Eight regions. Twelve towns. Thirty routes. Twelve dungeons. A fixed story across a seeded wilderness.")
	var map_view = MapView.new()
	map_view.game = game
	map_view.position = Vector2(38,208)
	map_view.size = Vector2(1184,486)
	surface.add_child(map_view)
	label(surface,"✧  Lantern Vale is explorable in Chapter I. The other regions chart the journey ahead.",Vector2(42,716),Vector2(1150,27),14,JADE)
	label(surface,"WORLD SEED   %d     /     GENERATOR  01" % game.world_seed,Vector2(42,758),Vector2(850,24),11,MUTED)

func settings_screen() -> void:
	var surface = modal_base("MAKE THE ROAD YOUR OWN", "Settings", "Changes save automatically. Select a binding, then press a key. Existing bindings swap to avoid conflicts.")
	var toggles = [["sound","Ambient music & sound"],["flashes","Animated light effects"],["shake","Camera shake"]]
	for i in 3:
		var setting: String = toggles[i][0]
		button(surface,("●  " if game.settings[setting] else "○  ")+toggles[i][1],Vector2(40,215+i*60),Vector2(390,46),func(): game.settings[setting] = not game.settings[setting]; game.save_settings(); settings_screen())
	button(surface,"Text size: %d%%" % (game.settings.text_scale*100),Vector2(40,410),Vector2(390,46),func(): game.settings.text_scale = 1.15 if game.settings.text_scale == 1.0 else 1.0; game.save_settings(); settings_screen())
	label(surface,"CONTROLLER",Vector2(40,509),Vector2(400,25),11,GOLD)
	label(surface,"Left stick · Move\nRight stick · Aim\nA · Interact     B · Evade\nX · Signature     Y · Ward\nRB · Circle     LB · Starstep\nRight stick click · Strike",Vector2(40,554),Vector2(400,180),16,MUTED)
	var actions: Array = game.DEFAULT_KEYS.keys()
	for i in actions.size():
		var action: String = actions[i]
		var x = 490+(i%2)*354
		var y = 215+(i/2)*76
		label(surface,action.replace("_"," ").capitalize(),Vector2(x,y),Vector2(220,24),13,MUTED)
		button(surface,"Press a key…" if waiting_binding == action else game.key_label(action),Vector2(x,y+28),Vector2(285,36),func(): waiting_binding = action; settings_screen())

func pause_screen() -> void:
	var surface = modal_base("A MOMENT BETWEEN ROADS", "Rest your eyes", "Your journey saves at lanterns, story moments, transitions, and regular intervals.")
	button(surface,"Return to the road",Vector2(405,238),Vector2(450,52),func(): close_modal(),true)
	button(surface,"Save journey",Vector2(405,310),Vector2(450,52),func(): if game.save_game(): toast("Your place in the Atlas is saved."))
	button(surface,"The ritual of affinity",Vector2(405,382),Vector2(450,52),func(): ritual_screen())
	button(surface,"Settings & controls",Vector2(405,454),Vector2(450,52),func(): settings_screen())
	button(surface,"Return to title",Vector2(405,526),Vector2(450,52),func(): game.save_game(); game.playing = false; game.world_view.queue_redraw(); title_screen())
	button(surface,"Save & quit",Vector2(405,598),Vector2(450,52),func(): game.save_game(); game.get_tree().quit())
	label(surface,"World seed  %d     ·     %d minutes on the road" % [game.world_seed,int(game.play_time/60)],Vector2(405,706),Vector2(600,28),13,MUTED)

func dialogue(speaker: String, pages: Array) -> void:
	dialogue_name = speaker
	active_dialogue = pages
	dialogue_index = 0
	_draw_dialogue()

func _draw_dialogue() -> void:
	if is_instance_valid(modal):
		root.remove_child(modal)
		modal.queue_free()
	game.paused = true
	modal = Control.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(modal)
	var surface = panel(modal,Vector2(205,544),Vector2(1030,302),Color(.025,.09,.10,.98),GOLD,.5)
	label(surface,dialogue_name.to_upper(),Vector2(30,22),Vector2(950,29),12,GOLD)
	label(surface,str(active_dialogue[dialogue_index]),Vector2(30,71),Vector2(966,140),23,CREAM,true)
	label(surface,"%d / %d" % [dialogue_index+1,active_dialogue.size()],Vector2(30,250),Vector2(300,25),12,MUTED)
	button(surface,"Continue  →" if dialogue_index+1 < active_dialogue.size() else "Return to the road",Vector2(760,237),Vector2(237,43),func():
		if dialogue_index+1 < active_dialogue.size():
			dialogue_index += 1
			_draw_dialogue()
		else: close_modal(),true).grab_focus()

func seal_screen() -> void:
	var surface = modal_base("THE FIRST SEAL", "What should a world remember?", "Elian offered his memories to keep Lantern Vale safe. The seal learned to take without asking.")
	label(surface,"Inside the seal, a voice is still counting the names of people it has protected. Elian is one of them. He has almost forgotten that he is also a person.\n\nYou can restore what the town lost, or end the seal's claim over human memory. Both choices leave work for the living.",Vector2(52,230),Vector2(1150,200),26,CREAM,true)
	button(surface,"Return the memory · Let the town remember Elian and choose its future keepers.",Vector2(52,485),Vector2(1150,72),func(): game.choose_seal("remember"),true)
	button(surface,"Release the claim · Let the wilderness change; no memory will be taken again.",Vector2(52,583),Vector2(1150,72),func(): game.choose_seal("release"))
	label(surface,"There is no answer without a consequence. There is still an answer that belongs to you.",Vector2(52,714),Vector2(1150,41),17,MUTED)
