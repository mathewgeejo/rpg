extends SceneTree

var failures = 0
var checks = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: "+message)

func run() -> void:
	root.size = Vector2i(1440,900)
	var game = preload("res://scripts/main.gd").new()
	game.testing = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.enabled = false
	game.new_journey(0,true)
	var summon = preload("res://scripts/summoning.gd")
	check(game.data.classes.size() == 20,"20 live classes")
	var coins: int = game.coins
	var first: Dictionary = summon.summon(game)
	check(not first.is_empty() and game.assigned,"Free summon assigns a class")
	check(game.coins == coins,"First summon is free")
	game.coins = 0
	check(summon.summon(game).is_empty(),"No summon without coins")
	game.coins = 10000
	game.changed["summon:pity"] = 79
	check(summon.summon(game).rarity == "SSS","80th summon guarantees SSS")
	game.changed["summon:rare"] = 9
	check(summon.summon(game).rarity in ["S","SS","SSS"],"10th summon guarantees S or better")
	for entry in game.data.classes:
		game.assign_class(entry.id)
		game.changed.erase("r1_e0")
		game.enter_room(1)
		var enemy: Dictionary = game.combat.enemies[0]
		game.player_pos = enemy.position-Vector2(0,45)
		game.facing = Vector2.DOWN
		game.combat.attack_cd = 0
		game.stamina = 100
		game.combat.basic()
		check(game.combat.attack_cd > 0,"Attack executed: "+entry.id)
		check(enemy.hp < enemy.max_hp or not game.combat.projectiles.is_empty() or not game.combat.pending.is_empty(),"Attack produces damage or payload: "+entry.id)
		game.combat.signature_cd = 0
		game.mana = 100
		game.combat.signature()
		check(game.mana < 100 or entry.id == "luck","Special executes: "+entry.id)
	game.enter_room(1)
	var target: Dictionary = game.combat.enemies[0]
	game.player_pos = target.position
	game.inventory.river_fish = 2
	game.companions.tame()
	check(target.hp > 0,"Healthy creature cannot be tamed")
	target.hp = target.max_hp*.3
	game.companions.tame()
	check(target.hp == 0 and game.companions.active() == target.type,"Weakened creature becomes companion")
	check(game.inventory.river_fish == 1,"Taming consumes exactly one fish")
	game.hp = 50
	game.god_mode = true
	game.take_damage(1000)
	check(game.hp == 50,"God mode prevents lethal damage")
	game.ui.ritual_screen()
	game.ui.companion_screen()
	game.ui.debug_screen()
	check(game.paused,"New menus open and pause gameplay")
	game.store.path = "user://constellation_isolated_test.json"
	check(game.store.save(game.state()),"Save new progression")
	var saved: Dictionary = game.store.load_state()
	check(saved.changed["pet:active"] == target.type,"Companion persists")
	check(saved.changed["summon:first"],"Summoning progression persists")
	game.inventory.river_fish = 1
	var purse: int = game.coins
	game.sell_material("river_fish")
	check(game.coins == purse+6 and game.inventory.river_fish == 0,"Fish sale consumes stock and pays correctly")
	game.sell_material("river_fish")
	check(game.coins == purse+6,"Empty inventory cannot create coins")
	var species: Dictionary = {}
	for area in [1,2]:
		for enemy in game.model.room(area).enemies:
			if not enemy.boss: species[int(enemy.type)] = true
	check(species.size() == 5,"All five tameable species occur in the fixed world")
	for area in [1,2,3]:
		game.changed = {}
		game.quest_stage = 1
		game.enter_room(area)
		var boss: Dictionary = {}
		for enemy in game.combat.enemies:
			if enemy.boss: boss = enemy
		check(not boss.is_empty(),"Authored boss exists in area %d" % area)
		game.player_pos = boss.position+Vector2(0,100)
		boss.cooldown = 0
		game.combat.tick(.01)
		check(not game.combat.hazards.is_empty(),"Boss telegraphs its attack")
		var initial_count: int = game.combat.hazards.size()
		boss.hp = boss.max_hp*.4
		boss.cooldown = 0
		game.combat.hazards.clear()
		game.combat.tick(.01)
		check(boss.enraged,"Boss enters its second phase")
		check(game.combat.hazards.size() >= initial_count,"Second phase maintains or increases pressure")
		game.combat.hit(boss,10000)
		check(game.combat.hazards.is_empty(),"Defeat clears pending boss attacks")
		check(game.quest_stage == (3 if area == 3 else 1),"Only the Keeper unlocks the ending")
	await verify_systems(game)
	game.queue_free()
	await process_frame
	print("Constellations: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

func verify_systems(game) -> void:
	game.new_journey(0,true)
	game.ui.close_modal()
	game.assign_class("smith")
	game.mana = 10
	for i in 3:
		game.combat.attack_cd = 0
		game.combat.basic()
	check(game.mana == 14,"Smith's third basic restores four mana")
	game.memories = 4
	game.assign_class("memory")
	check(game.max_mana == 112,"Memory passive reflects collected fragments")
	game.assign_class("oath")
	check(game.max_mana == 100,"Switching classes releases the memory mana bonus")
	game.assign_class("lantern")
	game.hp = 10
	game.invulnerable = 0
	game.take_damage(1000)
	check(game.hp == 1,"Lantern survives one lethal hit")
	game.invulnerable = 0
	game.take_damage(1000)
	check(game.room_id == 0 and game.hp == game.max_hp,"Second lethal hit returns the player home")
	game.nearest_object = game.zone.objects.filter(func(o): return o.kind == "rest")[0]
	game.interact()
	check(not game.changed.has("lantern_mercy"),"Lantern rest refreshes the last-life passive")
	var contract: Dictionary = game.model.commissions()[0]
	check(game.commission_progress(contract) == 0,"Rest/respawn flags do not count as victories")
	game.enter_room(1)
	var target: Dictionary = game.combat.enemies[0]
	game.player_pos = target.position
	target.hp = target.max_hp*.3
	game.inventory.river_fish = 1
	game.companions.tame()
	check(game.commission_progress(contract) == 0,"Taming does not count as defeating a creature")
	game.enter_room(0)
	game.nearest_object = game.zone.objects.filter(func(o): return o.kind == "rest")[0]
	game.interact()
	game.enter_room(1)
	check(game.combat.enemies.any(func(e): return e.id == target.id),"Wild creatures return after resting")
	check(game.changed.has("pet:0"),"Resting preserves the companion collection")
	for creature in game.combat.enemies:
		if creature.id == target.id: game.combat.hit(creature,1000)
	check(game.commission_progress(contract) == 1,"Defeating a previously tamed spawn records one victory")
	game.ui.close_modal()
	game.god_mode = true
	game.hp = 1
	game.mana = 0
	game.stamina = 0
	game.combat.signature_cd = 5
	game._physics_process(.02)
	check(game.hp == game.max_hp and game.mana == game.max_mana and game.stamina == 100,"God mode refills all combat resources")
	check(game.combat.signature_cd == 0,"God mode removes skill cooldowns")
	game.god_mode = false
	for species in 5:
		game.enter_room(1)
		game.changed["pet:active"] = species
		game.companions.cooldown = 0
		game.hp = 50
		game.mana = 50
		game.shield = 0
		var enemy: Dictionary = game.combat.enemies[0]
		enemy.hp = enemy.max_hp
		game.player_pos = enemy.position+Vector2(0,80)
		game.companions.position = game.player_pos
		game.companions.tick(.01)
		check(enemy.hp < enemy.max_hp,"Companion attacks: %d" % species)
		match species:
			0: check(game.hp > 50,"Mossling heals")
			1: check(enemy.weak > 0,"River Fang exposes")
			2: check(enemy.burn > 0,"Cinder Moth burns")
			3: check(game.shield > 0,"Stone Sprout protects")
			4: check(game.mana > 50,"Star Wisp returns mana")
		game.companions.cooldown = 0
		enemy.hp = enemy.max_hp*.3
		var before: float = enemy.hp
		game.companions.tick(.01)
		check(enemy.hp == before,"Companion preserves a taming opportunity")
	# Resume real saved collection and pity values, rather than inspecting JSON only.
	game.store.path = "user://constellation_resume_test.json"
	game.changed["class:door"] = true
	game.changed["summon:pity"] = 37
	game.changed["pet:active"] = 4
	game.changed["pet:4"] = true
	game.store.save(game.state())
	game.changed = {}
	game.continue_journey()
	game.set_physics_process(false)
	check(game.companions.active() == 4 and game.changed["pet:4"],"Continue restores owned and active companions")
	check(game.changed["class:door"] and game.changed["summon:pity"] == 37,"Continue restores collection and pity")
	check(not game.god_mode,"Continue starts with god mode off")
	var status_keys = ["weak","mark","repeat","poison","slow","stun","bound","sleep","burn"]
	for entry in game.data.classes:
		game.changed = {}
		game.assign_class(entry.id)
		game.enter_room(1)
		game.player_pos = Vector2(528,720)
		game.facing = Vector2.DOWN
		game.mana = 100
		game.hp = game.max_hp
		game.combat.signature_cd = 0
		var enemy: Dictionary = game.combat.enemies[0]
		enemy.position = game.player_pos+Vector2(0,45)
		enemy.hp = 10000
		enemy.max_hp = 10000
		game.combat.signature()
		game.combat.tick(.02)
		var affected = false
		for status in status_keys:
			if enemy[status] > 0: affected = true
		check(affected,"Special applies a debuff or control effect: "+entry.id)
	# Glass is a setup/detonation kit, rather than a renamed generic attack.
	game.assign_class("glass")
	game.combat.signature_cd = 0
	game.mana = 100
	game.combat.signature()
	check(game.combat.prisms.size() == 3,"Glass special places three persistent prisms")
	game.combat.attack_cd = 0
	game.stamina = 100
	game.combat.basic()
	check(game.combat.prisms.is_empty(),"Glass basic detonates placed prisms")
	game.assign_class("oath")
	for i in 3:
		game.combat.attack_cd = 0
		game.stamina = 100
		game.combat.basic()
	check(game.combat.vow == 4,"Oath third attack adds an extra vow")
	game.combat.signature_cd = 0
	game.mana = 100
	game.combat.signature()
	check(game.combat.vow == 0,"Oath special spends the vow")
	game.enter_room(3)
	var keeper: Dictionary = game.combat.enemies[0]
	game.player_pos = keeper.position+Vector2(0,100)
	keeper.cooldown = 0
	game.combat.tick(.01)
	game.player_pos = game.combat.hazards[0].position
	game.hp = 100
	game.invulnerable = 0
	game.combat.tick(1.3)
	check(game.hp < 100,"Standing in a resolved boss warning deals damage")
	game.hp = 100
	game.invulnerable = 0
	game.stamina = 100
	game.combat.hazards.append(preload("res://scripts/boss_patterns.gd").mark(keeper.id,game.player_pos,80,.01,24,"star"))
	game.dodge()
	game.combat.tick(.02)
	check(game.hp == 100,"Evade invulnerability prevents a boss strike")
	# Exercise fresh production randomness in an isolated, physics-disabled session.
	game.testing = false
	game.new_journey(0,true)
	var first_rng: int = game.combat.rng.state
	var fixed_tiles: Array = game.model.room(1).tiles.duplicate(true)
	game.new_journey(0,true)
	check(game.combat.rng.state != first_rng,"Fresh journeys randomize summon rolls")
	check(game.model.room(1).tiles == fixed_tiles,"Fresh summon randomness preserves the authored world")
	game.testing = true
