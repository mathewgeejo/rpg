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
	game = Main.new()
	root.add_child(game)
	game.testing = true
	game.set_physics_process(false)
	game.sound.enabled = false
	game.new_journey(731904,true)
	game.set_physics_process(false)
	check(game.data.classes.size() == 50,"Exactly 50 authored classes")
	check(game.data.questions.size() == 24,"Exactly 24 ritual questions")
	var ids: Dictionary = {}
	for entry in game.data.classes:
		check(not ids.has(entry.id),"Unique class ID: "+entry.id)
		ids[entry.id] = true
		var matches: Array = game.data.affinities(entry.prototype)
		check(matches[0]["class"].id == entry.id,"Class reachable through valid answers: "+entry.name)
		check(game.data.affinities(entry.prototype)[0].score == matches[0].score,"Deterministic affinity score")
		check(game.data.explanation(entry,entry.prototype).length() > 80,"Evidence-based class explanation")
		for rank in [2,3]:
			var specialization: Dictionary = game.data.specialization(entry.id,731904,rank)
			check(specialization == game.data.specialization(entry.id,731904,rank),"Deterministic specialization")
			check(specialization.bonus <= .3 and specialization.penalty > 0,"Bounded specialization tradeoff")
	print("RITUAL: all 50 classes reachable; specialization checks complete.")
	for seed_value in range(100):
		var world = World.new(seed_value*7919+17)
		check(world.graph.towns.size() == 12,"12 towns")
		check(world.graph.routes.size() == 30,"30 routes")
		check(world.graph.dungeons.size() == 12,"12 dungeons")
		var copy = World.new(seed_value*7919+17)
		check(JSON.stringify(world.graph) == JSON.stringify(copy.graph),"Deterministic world graph")
		for index in [1,2,3]:
			check(world.reachable(index),"All room objectives reachable, seed %d room %d" % [seed_value,index])
			check(world.walkable(index,world.room(index).spawn),"Safe player spawn")
			for enemy in world.room(index).enemies:
				check(world.walkable(index,enemy.position),"Safe enemy spawn, seed %d room %d" % [seed_value,index])
		check(JSON.stringify(world.commissions()) == JSON.stringify(copy.commissions()),"Deterministic commissions")
		if seed_value%10 == 0:
			print("GENERATION: ",seed_value+1," / 100 seeds")
			await process_frame
	print("GENERATION: 100 seeds checked across all three wilderness rooms.")
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
	print("COMBAT: all 50 signatures and shared abilities executed.")
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
		game.changed["the_keeper"] = true
		game.quest_stage = 3
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
	var saver = Store.new()
	saver.path = "user://atlas_automated_test.json"
	game.answers = game.data.classes[0].prototype.duplicate()
	check(saver.save(game.state()),"Save writes successfully")
	var restored: Dictionary = saver.load_state()
	check(restored.changed == game.changed,"Changed objects round trip")
	check(restored.answers == game.answers,"Ritual answers round trip")
	check(restored.quest_stage == game.quest_stage,"Quest state round trip")
	check(saver.save(game.state()),"Save replacement succeeds")
	var broken = FileAccess.open(saver.path,FileAccess.WRITE)
	broken.store_string("{broken")
	broken.close()
	check(not saver.load_state().is_empty(),"Corrupt save recovers backup")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saver.path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(saver.path+".bak"))
	for screen in ["ritual_screen","codex_screen","journal_screen","atlas_screen","settings_screen","pause_screen","commission_screen"]:
		game.ui.call(screen)
		game.ui.close_modal()
	game.ui.affinity_screen()
	game.ui.close_modal()
	print("STORY / SAVES / UI: complete.")
	print("RESULT: ",checks," checks; ",failures.size()," failures.")
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
