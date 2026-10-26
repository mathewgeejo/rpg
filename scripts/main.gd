extends Node2D

const Data = preload("res://scripts/game_data.gd")
const World = preload("res://scripts/world_model.gd")
const Combat = preload("res://scripts/combat.gd")
const Store = preload("res://scripts/save_store.gd")
const View = preload("res://scripts/world_view.gd")
const Interface = preload("res://scripts/interface.gd")
const Sound = preload("res://scripts/soundscape.gd")

var data = Data.new()
var store = Store.new()
var model = World.new()
var combat
var world_view
var ui
var sound
var zone: Dictionary = {}
var playing = false
var paused = false
var assigned = false
var world_seed = 731904
var room_id = 0
var player_pos = Vector2(1080,1150)
var facing = Vector2.DOWN
var animation = "idle"
var animation_time = 0.0
var class_id = "luck"
var class_def: Dictionary = {}
var rank = 1
var xp = 0
var hp = 120.0
var max_hp = 120.0
var mana = 100.0
var max_mana = 100.0
var stamina = 100.0
var shield = 0.0
var invulnerable = 0.0
var invisible = 0.0
var haste = 0.0
var rooted = 0.0
var luck = 0
var coins = 25
var answers: Array = []
var changed: Dictionary = {}
var quest_stage = 0
var memories = 0
var side_quests: Dictionary = {"lanterns":0,"garden":0,"letter":0}
var contracts: Dictionary = {}
var seal_choice = ""
var specialization: Dictionary = {}
var floating_texts: Array = []
var nearest_object: Dictionary = {}
var settings = {"sound":true,"flashes":true,"shake":true,"text_scale":1.0}
var dodge_time = 0.0
var autosave_time = 30.0
var regen_time = 0.0
var play_time = 0.0
var screenshot_mode = ""
var screenshot_frames = 0
var testing = false
var capture_elapsed = 0.0
var capture_warm_frames = 0
var hud_timer = 0.0
const DEFAULT_KEYS = {"move_up":KEY_W,"move_down":KEY_S,"move_left":KEY_A,"move_right":KEY_D,"interact":KEY_E,"signature":KEY_Q,"dodge":KEY_SPACE,"circle":KEY_2,"star":KEY_3,"ward":KEY_R,"journal":KEY_J,"atlas":KEY_M,"codex":KEY_C}

func _ready() -> void:
	Engine.max_fps = 60
	_setup_input()
	_load_settings()
	sound = Sound.new()
	add_child(sound)
	sound.enabled = settings.sound
	combat = Combat.new(self)
	world_view = View.new()
	world_view.game = self
	add_child(world_view)
	ui = Interface.new()
	ui.game = self
	add_child(ui)
	class_def = data.class_by_id(class_id)
	ui.title_screen()
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--capture-"):
			screenshot_mode = argument.trim_prefix("--capture-")
			testing = true
			store.path = "user://atlas_capture.json"
			if screenshot_mode != "title":
				new_journey(731904,true)
				if screenshot_mode == "ritual": ui.ritual_screen()
				if screenshot_mode == "map": ui.atlas_screen()
				if screenshot_mode == "forest":
					enter_room(1)
					player_pos = Vector2(1470,1450)
					world_view.camera = player_pos
					invulnerable = 1000

func _setup_input() -> void:
	for action in DEFAULT_KEYS:
		if not InputMap.has_action(action): InputMap.add_action(action)
		var key = InputEventKey.new()
		key.physical_keycode = DEFAULT_KEYS[action]
		InputMap.action_add_event(action,key)
	var joy_actions = {"interact":JOY_BUTTON_A,"dodge":JOY_BUTTON_B,"signature":JOY_BUTTON_X,"ward":JOY_BUTTON_Y,"journal":JOY_BUTTON_BACK,"atlas":JOY_BUTTON_START,"circle":JOY_BUTTON_RIGHT_SHOULDER,"star":JOY_BUTTON_LEFT_SHOULDER}
	for action in joy_actions:
		var button = InputEventJoypadButton.new()
		button.button_index = joy_actions[action]
		InputMap.action_add_event(action,button)

func key_label(action: String) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey: return OS.get_keycode_string(event.physical_keycode)
	return action

func _load_settings() -> void:
	if FileAccess.file_exists("user://settings.json"):
		var saved = JSON.parse_string(FileAccess.get_file_as_string("user://settings.json"))
		if saved is Dictionary:
			for setting in settings:
				if saved.has(setting): settings[setting] = saved[setting]
			for action in saved.get("keys",{}):
				if DEFAULT_KEYS.has(action): rebind(action,int(saved.keys[action]),false)

func save_settings() -> void:
	var value = settings.duplicate()
	var keys = {}
	for action in DEFAULT_KEYS:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey: keys[action] = event.physical_keycode
	value["keys"] = keys
	var file = FileAccess.open("user://settings.json",FileAccess.WRITE)
	if file: file.store_string(JSON.stringify(value))
	sound.enabled = settings.sound

func rebind(action: String, keycode: int, persist: bool = true) -> void:
	# Swap existing bindings to preserve an accessible movement/action set.
	var previous = DEFAULT_KEYS[action]
	for event in InputMap.action_get_events(action):
		if event is InputEventKey: previous = event.physical_keycode
	for other in DEFAULT_KEYS:
		if other == action: continue
		for event in InputMap.action_get_events(other):
			if event is InputEventKey and event.physical_keycode == keycode:
				InputMap.action_erase_event(other,event)
				var replacement = InputEventKey.new()
				replacement.physical_keycode = previous
				InputMap.action_add_event(other,replacement)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey: InputMap.action_erase_event(action,event)
	var replacement = InputEventKey.new()
	replacement.physical_keycode = keycode
	InputMap.action_add_event(action,replacement)
	if persist: save_settings()

func new_journey(seed_value: int = 0, explore: bool = false) -> void:
	world_seed = seed_value if seed_value != 0 else int(Time.get_unix_time_from_system())%999999999
	model = World.new(world_seed)
	class_id = "luck"
	class_def = data.class_by_id(class_id)
	assigned = false
	rank = 1
	xp = 0
	max_hp = 120
	hp = max_hp
	max_mana = 100
	mana = max_mana
	stamina = 100
	shield = 0
	coins = 25
	answers = []
	changed = {}
	side_quests = {"lanterns":0,"garden":0,"letter":0}
	contracts = {}
	quest_stage = 0
	memories = 0
	seal_choice = ""
	specialization = {}
	play_time = 0
	combat = Combat.new(self)
	combat.rng.seed = world_seed
	playing = true
	paused = false
	enter_room(0)
	if explore:
		ui.show_hud()
		toast("Welcome to Lanternwick. Find Mira beside the old path.")
	else:
		ui.ritual_screen()

func assign_class(id: String) -> void:
	class_id = id
	class_def = data.class_by_id(id)
	assigned = true
	specialization = data.specialization(id,world_seed,rank) if rank > 1 else {}
	ui.close_modal()
	ui.show_hud()
	save_game()
	toast("%s · %s" % [class_def.name,class_def.signature])

func enter_room(index: int) -> void:
	var previous = room_id
	room_id = index
	zone = model.room(index)
	if world_view != null: world_view.prepare_ground()
	player_pos = zone.spawn
	if index > 0 and previous > index: player_pos = zone.finish+Vector2(0,120)
	if index == 0 and previous > 0: player_pos = Vector2(1100,1320)
	combat.load_room(zone)
	nearest_object = {}
	world_view.camera = player_pos
	if ui != null:
		ui.show_hud()
		ui.location_banner(zone.name,zone.subtitle)
	if index == 3 and quest_stage < 2:
		toast("The seal awaits three fragments. You can explore, then return.")

func _physics_process(delta: float) -> void:
	if not playing or paused: return
	play_time += delta
	autosave_time -= delta
	if autosave_time < 0:
		autosave_time = 30
		save_game()
	for stat_name in ["invulnerable","invisible","haste","rooted"]:
		set(stat_name,maxf(0,float(get(stat_name))-delta))
	shield = maxf(0,shield-delta*.7)
	animation_time = maxf(0,animation_time-delta)
	stamina = minf(100,stamina+delta*(25 if animation == "idle" else 17))
	mana = minf(max_mana,mana+delta*(7 if class_id == "silence" and combat.attack_cd == 0 else 4)*stat("mana_regen"))
	var move = Input.get_vector("move_left","move_right","move_up","move_down")
	if Input.is_physical_key_pressed(KEY_UP): move.y -= 1
	if Input.is_physical_key_pressed(KEY_DOWN): move.y += 1
	if Input.is_physical_key_pressed(KEY_LEFT): move.x -= 1
	if Input.is_physical_key_pressed(KEY_RIGHT): move.x += 1
	if Input.get_connected_joypads().size() > 0:
		var joy = Input.get_connected_joypads()[0]
		var stick = Vector2(Input.get_joy_axis(joy,JOY_AXIS_LEFT_X),Input.get_joy_axis(joy,JOY_AXIS_LEFT_Y))
		if stick.length() > .2: move = stick
		var aim = Vector2(Input.get_joy_axis(joy,JOY_AXIS_RIGHT_X),Input.get_joy_axis(joy,JOY_AXIS_RIGHT_Y))
		if aim.length() > .25: facing = aim.normalized()
	move = move.limit_length()
	if move.length() > .1 and animation_time <= 0: facing = move.normalized()
	var speed = 190.0*stat("speed")*(1.35 if haste > 0 else 1.0)
	if dodge_time > 0:
		dodge_time -= delta
		move = facing
		speed = 580
		animation = "dodge"
	elif animation_time <= 0:
		animation = "run" if move.length() > .1 else "idle"
	if rooted > 0: speed = 0
	var step = move*speed*delta
	if model.walkable(room_id,player_pos+Vector2(step.x,0)): player_pos.x += step.x
	if model.walkable(room_id,player_pos+Vector2(0,step.y)): player_pos.y += step.y
	if class_id == "vow" and move.length() < .1: shield = minf(35,shield+delta*2)
	if class_id == "banner" and move.length() > .1: haste = maxf(haste,.3)
	combat.tick(delta)
	for item in floating_texts.duplicate():
		item.time -= delta
		if item.time <= 0: floating_texts.erase(item)
	nearest_object = {}
	var distance = 95.0
	for object in zone.objects:
		if changed.has(object.id) and object.kind in ["memory","chest"]: continue
		var d: float = object.position.distance_to(player_pos)
		if d < distance:
			distance = d
			nearest_object = object
	hud_timer -= delta
	if hud_timer <= 0:
		hud_timer = .1
		ui.update_hud()

func _process(delta: float) -> void:
	if screenshot_mode != "":
		screenshot_frames += 1
		if screenshot_frames > 20:
			capture_elapsed += delta
			capture_warm_frames += 1
		if screenshot_frames == 100:
			get_viewport().get_texture().get_image().save_png("res://artifacts/%s.png" % screenshot_mode)
			print("CAPTURED ",screenshot_mode)
			print("MEASURED: ",snappedf(capture_warm_frames/maxf(.001,capture_elapsed),.1)," FPS; renderer ",RenderingServer.get_video_adapter_name())
			get_tree().quit()

func _unhandled_input(event: InputEvent) -> void:
	if ui.waiting_binding != "" and event is InputEventKey and event.pressed:
		if event.keycode != KEY_ESCAPE: rebind(ui.waiting_binding,event.physical_keycode)
		ui.waiting_binding = ""
		ui.settings_screen()
		return
	if event.is_action_pressed("ui_cancel"):
		if not playing: return
		if paused: ui.close_modal()
		else: ui.pause_screen()
		return
	if not playing or paused: return
	if event.is_action_pressed("interact"): interact()
	elif event.is_action_pressed("signature"): combat.signature()
	elif event.is_action_pressed("circle"): combat.cast_circle()
	elif event.is_action_pressed("star"): combat.star_step()
	elif event.is_action_pressed("ward"): combat.ward()
	elif event.is_action_pressed("dodge"): dodge()
	elif event.is_action_pressed("journal"): ui.journal_screen()
	elif event.is_action_pressed("atlas"): ui.atlas_screen()
	elif event.is_action_pressed("codex"): ui.codex_screen()
	elif event is InputEventMouseButton and event.pressed:
		facing = player_pos.direction_to((get_global_mouse_position()-world_view.position)/world_view.pixel_scale)
		if event.button_index == MOUSE_BUTTON_LEFT: combat.basic()
		if event.button_index == MOUSE_BUTTON_RIGHT: combat.cast_circle()
	elif event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_RIGHT_STICK:
		combat.basic()

func dodge() -> void:
	var cost = 15 if class_id == "gravity" else 22
	if stamina < cost or dodge_time > 0: return
	stamina -= cost
	dodge_time = .23
	invulnerable = .32
	luck = mini(3,luck+1)
	if class_id == "delay": combat.signature_cd = maxf(0,combat.signature_cd-.5)
	if class_id == "afterimage": combat.fx("decoy",player_pos,35,Color("b9c7e1"),.8)
	if class_id == "ash": combat.zone(player_pos,60,2,6,0,Color("dfa777"))

func blink(displacement: Vector2) -> void:
	var distance = displacement.length()
	var direction = displacement.normalized()
	for i in int(distance/8):
		var next = player_pos+direction*8
		if not model.walkable(room_id,next): break
		player_pos = next
	invulnerable = maxf(invulnerable,.2)

func take_damage(amount: float) -> void:
	if invulnerable > 0: return
	if class_id == "burden" and stamina > 65: amount *= .75
	var absorbed = minf(shield,amount)
	shield -= absorbed
	amount -= absorbed
	hp -= amount
	combat.stored_hurt = minf(80,combat.stored_hurt+amount)
	invulnerable = .4
	animation = "hurt"
	animation_time = .4
	float_text("−%d" % int(amount),player_pos,Color("e8a18c"))
	if settings.shake and settings.flashes:
		world_view.camera += Vector2(5,-4)
	if hp <= 0:
		if class_id == "lantern" and not changed.has("lantern_mercy"):
			changed["lantern_mercy"] = true
			hp = 1
			invulnerable = 3
		else:
			hp = max_hp
			mana = max_mana
			coins = maxi(0,coins-10)
			enter_room(0)
			toast("The lanterns guide you home. Ten coins were lost on the road.")
			save_game()

func heal(amount: float) -> void:
	hp = minf(max_hp,hp+amount*stat("healing"))

func stat(name: String) -> float:
	var value = 1.0
	if not specialization.is_empty():
		if specialization.stat == name: value += specialization.bonus
		if specialization.cost == name: value -= specialization.penalty
	return value

func gain_xp(amount: int) -> void:
	xp += amount
	var desired = 3 if xp >= 420 else (2 if xp >= 140 else 1)
	if desired > rank:
		rank = desired
		max_hp = 120+20*(rank-1)
		hp = max_hp
		specialization = data.specialization(class_id,world_seed,rank)
		toast("Rank %d · %s %s\n%s +%d%%, %s −%d%%" % [rank,specialization.name,class_def.name,specialization.stat,int(specialization.bonus*100),specialization.cost,int(specialization.penalty*100)])
		combat.fx("star",player_pos,160,Color("e8d192"),1.4)

func interact() -> void:
	if nearest_object.is_empty():
		toast("Follow the path, or approach someone to speak.")
		return
	var object = nearest_object
	match object.kind:
		"exit":
			enter_room(int(object.to))
			save_game()
		"ritual": ui.ritual_screen()
		"board": ui.commission_screen()
		"rest":
			hp = max_hp
			mana = max_mana
			stamina = 100
			shield = 0
			changed.erase("lantern_mercy")
			if class_id == "hearth" and not changed.has("hearth_welcome"):
				max_hp += 10
				hp = max_hp
				changed["hearth_welcome"] = true
			if object.id != "lantern" and not changed.has(object.id):
				changed[object.id] = true
				if side_quests.lanterns > 0: side_quests.lanterns = mini(3,side_quests.lanterns+1)
			combat.fx("bloom",player_pos,100,Color("e4cb8f"),1)
			toast("A small light. A place to begin again.\nHealth, mana, and stamina restored. Journey saved.")
			save_game()
		"memory":
			changed[object.id] = true
			memories += 1
			gain_xp(25)
			if class_id == "coin": heal(7)
			if class_id == "memory": max_mana += 3
			if memories >= 3 and quest_stage == 1: quest_stage = 2
			combat.fx("bloom",object.position,100,Color("9ee3d0"),1)
			ui.dialogue("A borrowed memory",["“My sister tied a gold thread around my wrist. So I would always find my way home.”","For a moment, the voice is yours. Then the forest is quiet again.\n\nMemory fragments: %d / 3" % memories])
			save_game()
		"chest":
			changed[object.id] = true
			coins += 30
			if room_id == 2: side_quests.letter = 1
			toast("Found 30 coins%s." % (" and an undelivered letter" if room_id == 2 else ""))
			save_game()
		"npc": talk(object.id)
		"seal":
			if quest_stage < 2:
				ui.dialogue("The seal is silent",["Three memories are needed to open its history. Search the rune stones along Wispwood Path and Stonewater Crossing."])
			elif not changed.has("the_keeper"):
				ui.dialogue("The Unremembered Keeper",["The guardian stands between you and the seal. Its wide attacks leave a moment to move, then a moment to strike."])
			else:
				ui.seal_screen()

func talk(id: String) -> void:
	if id == "mira":
		if quest_stage == 0:
			quest_stage = 2 if memories >= 3 else 1
			ui.dialogue("Mira · Cartographer",["You have the look of someone the road hasn't finished with. Good. I need someone who can remember a stranger.","My brother's name was Elian. Yesterday, everyone knew him. Today, even our mother thinks I invented him.","He went to the old observatory. Find three memories in the wilderness, follow them past Stonewater Crossing, and ask the seal what it took from us."])
		elif quest_stage >= 4 and side_quests.letter != 1:
			quest_stage = 5
			var ending = "We remember him now. All of him, even the choice he made for us. It hurts. It is ours." if seal_choice == "remember" else "He is still missing from their stories. But the seal no longer takes anyone else. We can learn to remember him ourselves."
			ui.dialogue("Mira · A map with room to change",[ending,"Keep the Atlas. There are seven more seals, and every road asks the same thing differently: what do we owe the world, and what may it ask of us?\n\nCHAPTER ONE COMPLETE\nYou can keep exploring Lantern Vale."])
		elif side_quests.letter == 1:
			side_quests.letter = 2
			coins += 35
			gain_xp(40)
			ui.dialogue("A letter never sent",["That's his handwriting. He wrote that he was afraid. I thought brave people weren't supposed to be.\n\nQuest complete · The Undelivered Letter\n+35 coins · +40 experience"])
		else:
			ui.dialogue("Mira · Cartographer",["%d of the three fragments have answered you. The observatory stands beyond Wispwood Path and Stonewater Crossing. The road south leaves town." % mini(memories,3)])
	elif id == "orin":
		if side_quests.lanterns == 0:
			side_quests.lanterns = 1
			ui.dialogue("Orin · Lantern keeper",["Roads disappear when nobody tends them. Light the two wayfarers' lanterns, one on each wilderness trail. Then tell me what the road was like."])
		elif side_quests.lanterns >= 3 and side_quests.lanterns < 4:
			side_quests.lanterns = 4
			coins += 40
			gain_xp(45)
			ui.dialogue("Small lights, long roads",["Two little lights. That is enough to make a road feel as though someone expects you.\n\nQuest complete · Keep the Lanterns\n+40 coins · +45 experience"])
		else: ui.dialogue("Orin · Lantern keeper",["The lanterns stand near the beginning of each wilderness trail. Rest beside them to kindle their light."])
	elif id == "sella":
		if side_quests.garden == 0:
			side_quests.garden = 1
			ui.dialogue("Sella · Gardener",["The rune stones carry seeds as well as memories. Bring back three memories, and I can plant something that remembers the old forest."])
		elif memories >= 3 and side_quests.garden == 1:
			side_quests.garden = 2
			max_hp += 10
			hp = max_hp
			gain_xp(45)
			ui.dialogue("What grief can grow",["Look. The first leaf is silver. Perhaps remembering doesn't have to mean remaining the same.\n\nQuest complete · A Garden for Tomorrow\n+10 maximum health · +45 experience"])
		else: ui.dialogue("Sella · Gardener",["The garden has room for everything that returns. Even you."])
	save_game()

func choose_seal(choice: String) -> void:
	if changed.has("seal_resolved"):
		ui.dialogue("The Observatory Seal",["Your answer is part of the Atlas now. Mira is waiting in Lanternwick."])
		return
	seal_choice = choice
	quest_stage = 4
	changed["seal_resolved"] = true
	coins += 80
	gain_xp(150)
	ui.dialogue("The world takes a breath",["Elian volunteered to become the memory holding Lantern Vale together. The seal turned one willing sacrifice into a machine that forgot to ask again.","You return his memory to the town. The grief arrives with the love. The seal will hold, but it will need willing keepers." if choice == "remember" else "You cut the seal's claim over human memory. The wilderness will shift again, but no one else will be taken to keep it still.","Return to Mira in Lanternwick. The portal at the northern edge of the observatory leads home."])
	save_game()

func commission_progress(entry: Dictionary) -> int:
	var count = 0
	for id in changed:
		match entry.kind:
			"defeat":
				if str(id).begins_with("r") and "_e" in str(id): count += 1
			"memory":
				if str(id).begins_with("memory_"): count += 1
			"lantern":
				if str(id).begins_with("rest_"): count += 1
			"chest":
				if str(id).begins_with("chest_"): count += 1
	return mini(count,entry.target)

func commission_action(entry: Dictionary) -> void:
	if not contracts.has(entry.id):
		contracts[entry.id] = "active"
	elif contracts[entry.id] == "active" and commission_progress(entry) >= entry.target:
		contracts[entry.id] = "complete"
		coins += entry.reward
		gain_xp(35)
		toast("Commission complete · %s\n+%d coins · +35 experience" % [entry.name,entry.reward])
	save_game()
	ui.commission_screen()

func quest_text() -> String:
	return ["Speak with Mira beside the village path.","Recover three memory fragments · %d / 3" % mini(memories,3),"Reach the Observatory beyond Stonewater Crossing.","Approach the Observatory Seal.","Return to Mira in Lanternwick.","Chapter complete · The road remains open."][clampi(quest_stage,0,5)]

func state() -> Dictionary:
	return {"seed":world_seed,"room":room_id,"position":[player_pos.x,player_pos.y],"class_id":class_id,"assigned":assigned,"rank":rank,"xp":xp,"hp":hp,"max_hp":max_hp,"mana":mana,"max_mana":max_mana,"coins":coins,"answers":answers,"changed":changed,"quest_stage":quest_stage,"memories":memories,"side_quests":side_quests,"contracts":contracts,"seal_choice":seal_choice,"play_time":play_time}

func save_game() -> bool:
	if testing or not playing: return true
	var success = store.save(state())
	if not success: toast(store.last_error)
	return success

func continue_journey() -> void:
	var value = store.load_state()
	if value.is_empty():
		toast(store.last_error)
		return
	world_seed = int(value.seed)
	model = World.new(world_seed)
	class_id = str(value.get("class_id","luck"))
	class_def = data.class_by_id(class_id)
	class_id = class_def.id
	for property in ["assigned","rank","xp","hp","max_hp","mana","max_mana","coins","answers","changed","quest_stage","memories","side_quests","contracts","seal_choice","play_time"]:
		if value.has(property): set(property,value[property])
	rank = clampi(rank,1,3)
	quest_stage = clampi(quest_stage,0,5)
	max_hp = maxf(1,max_hp)
	hp = clampf(hp,1,max_hp)
	max_mana = maxf(1,max_mana)
	mana = clampf(mana,0,max_mana)
	specialization = data.specialization(class_id,world_seed,rank) if rank > 1 else {}
	combat = Combat.new(self)
	combat.rng.seed = world_seed
	playing = true
	paused = false
	enter_room(int(value.room))
	var position_value = Vector2(float(value.position[0]),float(value.position[1]))
	if model.walkable(room_id,position_value): player_pos = position_value
	world_view.camera = player_pos
	ui.show_hud()
	toast("The Atlas opens where you left it.")

func float_text(text: String, position_value: Vector2, color: Color) -> void:
	floating_texts.append({"text":text,"position":position_value,"color":color,"time":1.2})

func toast(text: String) -> void:
	if ui != null: ui.toast(text)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
