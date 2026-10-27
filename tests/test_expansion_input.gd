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
	await key(KEY_F10)
	check(game.paused,"F10 opens the test chamber")
	await click(Vector2(315,293))
	check(game.god_mode,"God mode button toggles the actual game state")
	await click(Vector2(715,293))
	var owned = 0
	for entry in game.data.classes:
		if game.changed.get("class:"+entry.id,false): owned += 1
	check(owned == 20,"Unlock button grants all 20 classes")
	await click(Vector2(332,775))
	check(game.assigned and game.class_id == "door","Collection button equips a rare class")
	await click(Vector2(1291,97))
	check(not game.paused,"Close button returns to gameplay")
	await key(KEY_P)
	check(game.paused,"P opens the companion roster")
	await key(KEY_ESCAPE)
	await key(KEY_F10)
	await click(Vector2(1017,443))
	await click(Vector2(1160,650))
	check(game.companions.active() == 4,"Companion Call button selects Star Wisp")
	await key(KEY_ESCAPE)
	game.god_mode = false
	game.enter_room(1)
	var target: Dictionary = game.combat.enemies[0]
	target.hp = target.max_hp*.3
	game.player_pos = target.position
	game.inventory.river_fish = 1
	var before: int = game.coins
	await key(KEY_T)
	check(game.companions.active() == target.type and game.inventory.river_fish == 0,"T tames and consumes a fish through input dispatch")
	check(game.coins == before,"Taming input does not grant a kill reward")
	game.ui.settings_screen()
	await process_frame
	for control in game.ui.modal.find_children("*","Button",true,false):
		check(control.get_global_rect().end.y <= 846,"Settings button fits inside its modal")
	var glyphs: Dictionary = preload("res://scripts/class_emblem.gd").GLYPHS
	check(glyphs.size() == 20,"20 authored class glyphs")
	for entry in game.data.classes:
		check(glyphs.has(entry.id),"Class has its own glyph: "+entry.id)
	game.queue_free()
	await process_frame
	print("Expansion input: %d checks, %d failures" % [checks,failures])
	quit(1 if failures else 0)

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
