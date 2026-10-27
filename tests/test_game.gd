extends SceneTree

const Main = preload("res://scripts/main.gd")
const World = preload("res://scripts/world_model.gd")
const Store = preload("res://scripts/save_store.gd")
var failures: Array[String] = []
var checks = 0
var game

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: ",message)

func run() -> void:
	root.size = Vector2i(1440,900)
	game = Main.new()
	game.testing = true
	game.store.path = "user://atlas_isolated_test_session.json"
	root.add_child(game)
	game.testing = true
	game.set_physics_process(false)
	game.sound.enabled = false
	game.new_journey(731904,true)
	game.set_physics_process(false)
	check(game.data.classes.size() == 20,"Exactly 20 authored classes")
	var ids: Dictionary = {}
	for entry in game.data.classes:
		check(not ids.has(entry.id),"Unique class ID: "+entry.id)
		ids[entry.id] = true
		for rank in [2,3]:
			var specialization: Dictionary = game.data.specialization(entry.id,731904,rank)
			check(specialization == game.data.specialization(entry.id,731904,rank),"Deterministic specialization")
			check(specialization.bonus <= .3 and specialization.penalty > 0,"Bounded specialization tradeoff")
	print("ROSTER: 20 classes; specialization checks complete.")
	check(game.model.reachable(0),"All town NPCs, exits, and services reachable")
	var reference = World.new()
	check(reference.graph.locations.size() == 4,"Exactly four authored places")
	check(reference.graph.routes.size() == 3,"Exactly three connecting roads")
	for index in 4:
		var zone: Dictionary = reference.room(index)
		check(reference.reachable(index),"All objectives reachable in authored room %d" % index)
		check(reference.walkable(index,zone.spawn),"Safe player spawn in authored room")
		for enemy in zone.enemies:
			check(reference.walkable(index,enemy.position),"Authored enemy spawn is walkable")
		for npc in zone.objects:
			if npc.has("path"):
				for point in npc.path: check(reference.walkable(index,point),"NPC's authored walk cycle stays on traversable ground")
	for seed_value in [0,17,99,731904,999999999]:
		var world = World.new(seed_value)
		check(world.graph == reference.graph,"World topology does not change with seed")
		for index in 4:
			check(world.room(index).tiles == reference.room(index).tiles,"Authored terrain never changes with seed")
	print("WORLD: all four fixed maps, spawns, objectives, and seed independence checked.")
	game.enter_room(1)
	for entry in game.data.classes:
		game.class_id = entry.id
		game.class_def = entry
		game.assigned = true
		game.rank = 1
		game.hp = 90
		game.mana = 100
		game.stamina = 100
		game.coins = 100
		game.invulnerable = 100
		game.player_pos = game.zone.spawn+Vector2(0,-120)
		game.facing = Vector2.UP
		game.changed = {}
		game.combat = Main.Combat.new(game)
		game.combat.load_room(game.zone)
		for i in game.combat.enemies.size():
			game.combat.enemies[i].position = game.player_pos+Vector2((i%3-1)*30,-40-i*10)
			game.combat.enemies[i].hp = 9999.0
			game.combat.enemies[i].max_hp = 9999.0
		game.combat.signature()
		check(game.combat.signature_cd > 0 or entry.id == "luck","Signature executes: "+entry.name)
		for i in 30: game.combat.tick(.1)
		game.combat.basic()
		game.combat.cast_circle()
		game.combat.ward()
		game.combat.star_step()
		check(is_finite(game.hp) and is_finite(game.mana),"Finite resources after kit execution")
		check(game.mana >= 0 and game.stamina >= 0,"No negative combat resources")
	print("COMBAT: all 20 signatures and shared abilities executed.")
	# Complete the authored chapter, side quests, and both seal outcomes.
	for ending in ["remember","release"]:
		game.new_journey(17,true)
		game.talk("mira")
		game.ui.close_modal()
		game.talk("orin")
		game.ui.close_modal()
		game.talk("sella")
		game.ui.close_modal()
		for index in [1,2]:
			game.enter_room(index)
			for object in game.zone.objects:
				if object.kind in ["memory","rest","chest"]:
					game.nearest_object = object
					game.interact()
					game.ui.close_modal()
		check(game.quest_stage == 2,"Memories unlock the observatory")
		game.enter_room(3)
		var boss: Dictionary = game.combat.enemies.filter(func(e): return e.boss)[0]
		game.combat.hit(boss,boss.max_hp*2)
		check(game.changed.has("the_keeper") and game.quest_stage == 3,"Defeating the boss unlocks the seal")
		game.choose_seal(ending)
		game.ui.close_modal()
		game.enter_room(0)
		game.talk("orin")
		game.ui.close_modal()
		game.talk("sella")
		game.ui.close_modal()
		game.talk("mira")
		game.ui.close_modal()
		if game.quest_stage < 5:
			game.talk("mira")
			game.ui.close_modal()
		check(game.quest_stage == 5,"Chapter concludes: "+ending)
		check(game.side_quests.letter == 2,"Letter side quest complete")
		check(game.side_quests.lanterns == 4,"Lantern side quest complete")
		check(game.side_quests.garden == 2,"Garden side quest complete")
		check(game.seal_choice == ending,"Seal consequence persists")
	await rpg_features()
	var contract: Dictionary = game.model.commissions()[0]
	game.commission_action(contract)
	game.ui.close_modal()
	check(game.contracts.get(contract.id) == "active","Commission can be accepted")
	match contract.kind:
		"memory":
			for i in contract.target: game.changed["memory_test_%d" % i] = true
		"defeat":
			for i in contract.target: game.changed["r1_e%d" % i] = true
		"lantern":
			game.changed["rest_1"] = true
			game.changed["rest_2"] = true
		"chest":
			game.changed["chest_1"] = true
			game.changed["chest_2"] = true
	var money_before: int = game.coins
	game.commission_action(contract)
	game.ui.close_modal()
	check(game.coins == money_before+contract.reward,"Completed commission pays its reward")
	game.commission_action(contract)
	game.ui.close_modal()
	check(game.coins == money_before+contract.reward,"Commission cannot pay twice")
	var saver = Store.new()
	saver.path = "user://atlas_automated_test.json"
	game.answers = game.data.classes[0].prototype.duplicate()
	check(saver.save(game.state()),"Save writes successfully")
	var restored: Dictionary = saver.load_state()
	check(restored.changed == game.changed,"Changed objects round trip")
	check(restored.answers == game.answers,"Ritual answers round trip")
	check(restored.quest_stage == game.quest_stage,"Quest state round trip")
	check(restored.contracts == game.contracts,"Commission state round trip")
	check(restored.skills == game.skills and restored.inventory == game.inventory,"Training and inventory round trip")
	check(restored.armor == game.armor and restored.magic_focus == game.magic_focus,"Equipment and magic focus round trip")
	check(str(restored.combat_rng_state) == str(game.combat.rng.state),"Exact gambler RNG state survives save serialization")
	var previous_store = game.store
	game.store = saver
	game.inventory = {"willow_wood":0,"river_fish":0}
	game.hp = 1
	game.continue_journey()
	check(game.inventory == restored.inventory,"Continue actually restores the player's inventory")
	check(game.hp == restored.hp,"Continue actually restores player health")
	check(str(game.combat.rng.state) == str(restored.combat_rng_state),"Continue restores the exact future dice sequence")
	game.store = previous_store
	check(saver.save(game.state()),"Save replacement succeeds")
	var broken = FileAccess.open(saver.path,FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	check(not saver.load_state().is_empty(),"Corrupt save recovers backup")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saver.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saver.path+".bak"))
	for screen in ["ritual_screen","codex_screen","journal_screen","atlas_screen","settings_screen","pause_screen","commission_screen","character_screen"]:
		game.ui.call(screen)
		game.ui.close_modal()
	game.ui.debug_screen()
	game.ui.close_modal()
	# Exercise actual GUI and input dispatch, not only direct method calls.
	game.playing = false
	game.ui.title_screen()
	await process_frame
	await click(Vector2(250,655))
	check(game.playing and game.paused,"Begin journey opens summoning")
	await click(Vector2(280,399))
	check(game.assigned,"Free summon assigns a class through GUI")
	await click(Vector2(280,822))
	check(game.playing and not game.paused,"Return button enters the world")
	var mana_before_click: float = game.mana
	await click(Vector2(685,800))
	check(game.mana < mana_before_click and game.combat.circle_cd > 0,"Clicking the HUD circle slot casts the displayed ability")
	var stamina_before_pad: float = game.stamina
	var pad = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_B
	pad.pressed = true
	root.push_input(pad,true)
	await process_frame
	check(not game.paused and game.stamina < stamina_before_pad,"Controller B evades during gameplay instead of opening pause")
	pad = pad.duplicate()
	pad.pressed = false
	root.push_input(pad,true)
	var hits_before: int = game.combat.hit_count
	await key(KEY_F)
	check(game.combat.hit_count == hits_before+1,"Keyboard attack dispatch reaches combat")
	await key(KEY_M)
	check(game.paused,"Atlas keyboard shortcut opens a modal")
	await key(KEY_ESCAPE)
	check(not game.paused,"Escape closes the modal and resumes play")
	print("STORY / SAVES / UI: complete.")
	print("RESULT: ",checks," checks; ",failures.size()," failures.")
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)

func rpg_features() -> void:
	game.enter_room(1)
	game.player_pos = game.zone.spawn
	game.facing = Vector2.UP
	for focus in ["aether","ember","frost"]:
		game.magic_focus = focus
		game.mana = 100
		game.circle_strain = 0
		game.combat.circle_cd = 0
		game.combat.projectiles.clear()
		var target: Dictionary = game.combat.enemies[0]
		target.hp = 500
		target.max_hp = 500
		target.position = game.player_pos+Vector2(0,-50)
		target.burn = 0
		target.slow = 0
		game.combat.cast_circle()
		var mana_after: float = game.mana
		game.combat.tick(.1)
		check(target.hp < 500,"Circle projectile reaches and damages a real enemy")
		if focus == "aether": check(game.mana > mana_after,"Aether impact returns mana")
		if focus == "frost": check(target.slow > 0,"Frost impact slows its target")
		if focus == "ember":
			check(target.burn > 0,"Ember impact ignites its target")
			var health_after: float = target.hp
			game.combat.tick(.7)
			check(target.hp < health_after,"Burn causes damage after the initial impact")
	game.circle_strain = 90
	game.mana = 100
	game.hp = 100
	game.combat.circle_cd = 0
	game.combat.cast_circle()
	check(game.hp == 94 and game.combat.circle_cd > 1,"Overchanneling has an explicit health cost and recovery")
	for stance in ["flowing","resolute","rending"]:
		game.sword_stance = stance
		game.player_pos = game.zone.spawn
		game.stamina = 100
		game.shield = 0
		game.combat.star_cd = 0
		game.combat.star_step()
		check(game.player_pos.distance_to(game.zone.spawn) > 80,"Star stance moves through valid space")
		check(game.stamina < 100,"Star stance consumes stamina")
		if stance == "resolute": check(game.shield > 0,"Resolute stance grants a ward")
	game.armor = "cloth"
	var cloth_circle: float = game.stat("circle_power")
	game.armor = "plate"
	check(game.stat("circle_power") < cloth_circle,"Plate trades spell power for protection")
	game.armor = "leather"
	check(game.stat("speed") > 1,"Leather offers movement speed")
	game.nearest_object = game.zone.objects.filter(func(o): return o.id == "wood_1")[0]
	game.inventory.willow_wood = 0
	for i in 4:
		game.harvest_cd = 0
		game.interact()
	check(game.inventory.willow_wood == 3,"Gathering spot has three uses before resting")
	check(game.skill_level("woodcutting") >= 2,"Gathering trains a persistent skill")
	game.coins = 50
	var health_before: float = game.max_hp
	game.craft_charm()
	game.ui.close_modal()
	check(game.max_hp == health_before+10 and game.inventory.willow_wood == 0,"Crafting spends gathered wood and grants permanent health")
	game.craft_charm()
	check(game.max_hp == health_before+10,"Charm cannot be crafted twice")
	game.enter_room(0)
	game.nearest_object = game.zone.objects.filter(func(o): return o.id == "fish_0")[0]
	game.harvest_cd = 0
	game.interact()
	check(game.inventory.river_fish > 0 and game.skills.fishing > 0,"Fishing supplies food and trains fishing")
	game.hp = 20
	game.eat_fish()
	check(game.hp > 20,"Gathered food restores health")
	var coins_before: int = game.coins
	game.buy_fish()
	game.ui.close_modal()
	check(game.coins == coins_before-10 and game.inventory.river_fish > 0,"Shop exchanges coins for usable provisions")
	game.nearest_object = game.zone.objects.filter(func(o): return o.id == "lantern")[0]
	game.interact()
	check(not game.changed.has("harvest:wood_1"),"Rest allows resource spots to recover")
	game.enter_room(3)
	game.changed.erase("the_keeper")
	game.combat.load_room(game.zone)
	var boss: Dictionary = game.combat.enemies.filter(func(e): return e.boss)[0]
	boss.hp = boss.max_hp*.4
	game.player_pos = boss.position+Vector2(0,150)
	boss.cooldown = 0
	game.combat.tick(.01)
	check(boss.enraged and boss.windup > 0,"Guardian enters a second phase and telegraphs an attack")
	game.invulnerable = 0
	game.hp = 100
	game.player_pos += Vector2(170,0)
	game.combat.tick(1.3)
	check(game.hp == 100,"Leaving the telegraphed attack avoids damage")
	game.changed["the_keeper"] = true
	game.enter_room(0)
	game.ui.close_modal()
	print("RPG: focuses, strain, stances, armor, gathering, crafting, food, shop, and boss phases checked.")

func click(position: Vector2) -> void:
	var event = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = position
	event.pressed = true
	root.push_input(event,true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await process_frame

func key(code: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	root.push_input(event,true)
	await process_frame
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await process_frame
