extends SceneTree

# Play each boss through the public combat actions with ordinary resources.
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var game = preload("res://scripts/main.gd").new()
	game.testing = true
	root.add_child(game)
	game.set_physics_process(false)
	game.sound.enabled = false
	for entry in game.data.classes:
		for area in [1,2,3]:
			game.new_journey(0,true)
			game.assign_class(entry.id)
			game.ui.close_modal()
			game.enter_room(area)
			game.ui.close_modal()
			game.quest_stage = 2
			var boss: Dictionary = game.combat.enemies.filter(func(e): return e.boss)[0]
			# Isolate the authored guardian; ordinary wildlife is covered by the chapter suite.
			game.combat.enemies = [boss]
			game.player_pos = boss.position+Vector2(0,55 if entry.id in ["echo","anatomy","debt"] else 75)
			game.inventory.river_fish = 3
			var elapsed = 0.0
			while boss.hp > 0 and elapsed < 120 and game.room_id == area:
				var delta = 1.0/60.0
				elapsed += delta
				game.invulnerable = maxf(0,game.invulnerable-delta)
				game.rooted = maxf(0,game.rooted-delta)
				game.circle_strain = maxf(0,game.circle_strain-delta*16)
				game.mana = minf(game.max_mana,game.mana+delta*4*game.stat("mana_regen"))
				game.stamina = minf(100,game.stamina+delta*17)
				var destination: Vector2 = boss.position+Vector2.from_angle(elapsed*1.2)*(55 if entry.id in ["echo","anatomy","debt"] else 75)
				var next: Vector2 = game.player_pos.move_toward(destination,115*delta)
				if game.rooted <= 0 and game.model.walkable(area,next,game.player_pos): game.player_pos = next
				game.facing = game.player_pos.direction_to(boss.position)
				game.combat.basic()
				if entry.id != "oath" or game.combat.vow >= 4: game.combat.signature()
				if game.shield < 5: game.combat.ward()
				if game.hp < game.max_hp*.4 and game.inventory.river_fish > 0: game.eat_fish()
				game.combat.tick(delta)
			if boss.hp > 0 or game.room_id != area or game.god_mode:
				failures += 1
				printerr("FAIL: ordinary-resource boss playthrough ",area," / HP ",boss.hp," / player HP ",game.hp)
			else: print("BOSS CLEARED: ",entry.id," / ",boss.id," in ",snappedf(elapsed,.1)," seconds; player HP ",int(game.hp))
	game.queue_free()
	await process_frame
	print("Boss playthrough: 60 class/guardian encounters, ",failures," failures")
	quit(1 if failures else 0)
