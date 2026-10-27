extends Control

const Bar = preload("res://scripts/vital_bar.gd")
const MiniMap = preload("res://scripts/local_map.gd")
const Icon = preload("res://scripts/pixel_icon.gd")
var game
var ui
var hp
var mana
var stamina
var name_label: Label
var rank_label: Label
var health_label: Label
var quest_label: Label
var prompt: Label
var location: Label
var coin_label: Label
var skill_labels: Dictionary = {}
var ability_buttons: Dictionary = {}
var sig_label: Label
var sig_key: Label
var portrait: TextureRect
var portrait_source: AtlasTexture
var map
var last_class = ""

func _ready() -> void:
	ui = game.ui
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame = ui.panel(self,Vector2(24,748),Vector2(1392,128),Color("161b31"),Color("b8a1cd"),.8)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.rule(frame,Vector2(10,5),1372,Color("ead9b8"))
	portrait = TextureRect.new()
	portrait.position = Vector2(16,21)
	portrait.size = Vector2(64,80)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait_source = AtlasTexture.new()
	portrait_source.region = Rect2(8,4,32,40)
	portrait.texture = portrait_source
	frame.add_child(portrait)
	name_label = ui.label(frame,"Wanderer",Vector2(95,12),Vector2(290,32),25,ui.CREAM,true)
	rank_label = ui.label(frame,"CIRCLE I  /  THE UNWRITTEN",Vector2(97,46),Vector2(280,22),12,ui.GOLD)
	hp = bar(frame,Vector2(97,76),Vector2(263,8),Color("de8f94"))
	mana = bar(frame,Vector2(97,96),Vector2(127,5),Color("95cbd3"))
	stamina = bar(frame,Vector2(235,96),Vector2(125,5),Color("a7cf9b"))
	health_label = ui.label(frame,"",Vector2(97,106),Vector2(270,16),10,ui.MUTED)
	for x in [386,1106]:
		var separator = ColorRect.new()
		separator.position = Vector2(x,18)
		separator.size = Vector2(1,90)
		separator.color = Color(.8,.73,.86,.3)
		separator.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(separator)
	var specs = [["signature","fate",410,186,"Signature"],["circle","circle",612,112,"Circle"],["star","star",738,112,"Starstep"],["ward","ward",864,112,"Ward"],["dodge","evade",990,106,"Evade"]]
	for spec in specs:
		var action: String = spec[0]
		var trigger = Button.new()
		trigger.position = Vector2(spec[2]-7,14)
		trigger.size = Vector2(spec[3],100)
		trigger.focus_mode = Control.FOCUS_NONE
		trigger.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		trigger.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
		trigger.add_theme_stylebox_override("pressed",StyleBoxEmpty.new())
		trigger.add_theme_stylebox_override("hover",ui.style(Color(.7,.6,.8,.08),Color(.8,.7,.9,.35),1))
		trigger.pressed.connect(func():
			if game.paused: return
			if action == "dodge": game.dodge()
			else: game.combat.call({"signature":"signature","circle":"cast_circle","star":"star_step","ward":"ward"}[action]))
		frame.add_child(trigger)
		ability_buttons[action] = trigger
		var icon = Icon.new()
		icon.position = Vector2(spec[2],24)
		icon.size = Vector2(32,32)
		icon.kind = spec[1]
		icon.color = ui.GOLD if spec[0] == "signature" else (Color("96d6d1") if spec[0] == "circle" else Color("d2c1e8"))
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.add_child(icon)
		var title = ui.label(frame,spec[4],Vector2(spec[2]+39,20),Vector2(spec[3]-35,47),14,ui.CREAM)
		var key = ui.label(frame,"",Vector2(spec[2]+4,78),Vector2(spec[3]-3,35),12,ui.MUTED)
		skill_labels[spec[0]] = key
		if spec[0] == "signature": sig_label = title; sig_key = key
	coin_label = ui.label(frame,"",Vector2(1130,19),Vector2(226,24),17,ui.GOLD)
	ui.button(frame,"M  Atlas",Vector2(1129,75),Vector2(106,34),func(): ui.atlas_screen())
	ui.button(frame,"J  Journal",Vector2(1241,75),Vector2(126,34),func(): ui.journal_screen())
	ui.button(frame,"Ⅱ",Vector2(1330,15),Vector2(38,36),func(): ui.pause_screen())
	var header = ui.panel(self,Vector2(26,24),Vector2(470,108),Color(.075,.10,.17,.88),ui.GOLD,.3)
	header.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	header.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: ui.journal_screen())
	ui.label(header,"THE UNWRITTEN ATLAS   /   CHAPTER I",Vector2(16,10),Vector2(430,20),11,ui.GOLD)
	location = ui.label(header,"Lanternwick",Vector2(16,33),Vector2(435,29),23,ui.CREAM,true)
	quest_label = ui.label(header,"",Vector2(16,69),Vector2(435,35),13,ui.JADE)
	var map_frame = ui.panel(self,Vector2(1190,24),Vector2(226,188),Color(.075,.10,.17,.93),ui.GOLD,.4)
	ui.button(self,"P  Companions",Vector2(1190,222),Vector2(226,34),func(): ui.companion_screen())
	map_frame.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	map_frame.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT: ui.atlas_screen())
	ui.label(map_frame,"LANTERN VALE",Vector2(14,10),Vector2(198,20),12,ui.GOLD)
	map = MiniMap.new()
	map.game = game
	map.position = Vector2(14,38)
	map.size = Vector2(198,132)
	map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	map_frame.add_child(map)
	prompt = ui.label(self,"",Vector2(420,691),Vector2(600,34),17,ui.CREAM)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# Gameplay buttons must not consume Space as a focused menu activation.
	for control in find_children("*","Button",true,false): control.focus_mode = Control.FOCUS_NONE
	refresh()

func bar(parent: Node, point: Vector2, dimensions: Vector2, color: Color):
	var result = Bar.new()
	result.position = point
	result.size = dimensions
	result.color = color
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(result)
	return result

func refresh() -> void:
	if not is_instance_valid(name_label): return
	name_label.text = game.class_def.name if game.assigned else "Wanderer"
	var discipline: String = game.class_def.get("discipline","circle")
	rank_label.text = "%s %s   /   %s" % ["CIRCLE" if discipline == "circle" else ("STAR" if discipline == "star" else "HYBRID"),["I","II","III"][clampi(game.rank-1,0,2)],"MASTERY" if game.rank == 3 else "%d / %d XP" % [game.xp,140 if game.rank == 1 else 420]]
	hp.value = game.hp/game.max_hp*100
	mana.value = game.mana/game.max_mana*100
	stamina.value = game.stamina
	health_label.text = "%d/%d HP   %d MP   %d%% STRAIN" % [game.hp,game.max_hp,game.mana,game.circle_strain]
	if game.god_mode: health_label.text = "GOD MODE  /  F10 TEST CHAMBER"
	quest_label.text = game.quest_text()
	location.text = game.zone.name
	sig_label.text = game.class_def.signature
	var captions = {"signature":"","circle":"RMB / ","star":"","ward":"","dodge":""}
	for action in skill_labels: skill_labels[action].text = captions[action]+game.key_label(action)
	if game.combat.signature_cd > 0: sig_key.text += "   %.1fs" % game.combat.signature_cd
	if game.class_id == "oath": sig_key.text += "\nVOW  %d / 5" % game.combat.vow
	if game.class_id == "luck": sig_key.text += "\nLUCK  %d / 3" % game.luck
	if game.class_id == "glass": sig_key.text += "\nPRISMS  %d / 3" % game.combat.prisms.size()
	if game.class_id == "thorn": sig_key.text += "\nGROWTH  %d" % game.combat.stored_hurt
	for action in ["circle","star","ward"]:
		var cooldown: float = game.combat.get(action+"_cd")
		if cooldown > 0: skill_labels[action].text += " %.1fs" % cooldown
	ability_buttons.signature.tooltip_text = "%s · 20 mana\n%s" % [game.class_def.signature,game.class_def.description]
	ability_buttons.circle.tooltip_text = "%s circle · %d mana\n0.65 second recovery. Rapid casting builds strain." % [game.magic_focus.capitalize(),15 if game.magic_focus == "ember" else (14 if game.magic_focus == "frost" else 12)]
	ability_buttons.star.tooltip_text = "%s Starstep · %d stamina\n4 second recovery." % [game.sword_stance.capitalize(),25 if game.sword_stance == "flowing" else 35]
	ability_buttons.ward.tooltip_text = "Ward · 18 mana\n9 second recovery. Absorbs incoming damage."
	ability_buttons.dodge.tooltip_text = "Evade · %d stamina\nBrief invulnerability while moving." % (15 if game.class_id == "gravity" else 22)
	coin_label.text = "◈ %d    ·    K  GEAR" % game.coins
	prompt.text = "[%s]  %s" % [game.key_label("interact"),game.nearest_object.name] if not game.nearest_object.is_empty() else ""
	var tame_target: Dictionary = game.combat.nearest(110)
	if not tame_target.is_empty() and not tame_target.boss and tame_target.hp/tame_target.max_hp <= .4:
		prompt.text = "[T] Tame - 1 river fish    |    [P] Companions"
	if last_class != game.class_id+game.armor:
		last_class = game.class_id+game.armor
		portrait_source.atlas = load("res://assets/custom/wanderer_%s.png" % game.armor)
	map.queue_redraw()
