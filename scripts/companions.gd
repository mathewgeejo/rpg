extends RefCounted

const SPECIES = ["Mossling","River Fang","Cinder Moth","Stone Sprout","Star Wisp"]
var game
var position = Vector2.ZERO
var cooldown = 0.0

func _init(owner_game) -> void:
	game = owner_game

func tame() -> void:
	var target: Dictionary = game.combat.nearest(110)
	if target.is_empty() or target.boss:
		game.toast("Come closer to a wild creature before offering a fish. Bosses cannot be tamed.")
		return
	if target.hp / target.max_hp > .4 and not game.god_mode:
		game.toast("Weaken the creature below 40% health before offering a river fish.")
		return
	if game.inventory.river_fish < 1 and not game.god_mode:
		game.toast("Taming needs one river fish. Fish by the bridge or visit Sella's stall.")
		return
	if not game.god_mode: game.inventory.river_fish -= 1
	var species = clampi(int(target.type),0,4)
	game.changed["pet:"+str(species)] = true
	game.changed["pet:active"] = species
	game.changed[target.id] = true
	game.changed["tamed:"+target.id] = true
	game.changed.erase("respawn:"+target.id)
	target.hp = 0
	position = game.player_pos
	game.combat.fx("bloom",target.position,70,Color("9fe4ba"),1)
	game.toast(SPECIES[species]+" trusts you. It will follow and fight beside you.")
	game.save_game()

func active() -> int:
	return int(game.changed.get("pet:active",-1))

func tick(delta: float) -> void:
	if active() < 0: return
	var destination: Vector2 = game.player_pos-game.facing*35
	if position.distance_to(destination) > 200: position = destination
	var next = position.move_toward(destination,125*delta)
	if game.model.walkable(game.room_id,next,position): position = next
	elif position.distance_to(game.player_pos) > 100:
		# Recall around corners instead of sliding through walls or remaining stuck.
		position = game.player_pos
	cooldown = maxf(0,cooldown-delta)
	if cooldown > 0: return
	var target: Dictionary = game.combat.nearest(230)
	# Keep low-health wild creatures available to tame.
	if target.is_empty() or (not target.boss and target.hp/target.max_hp <= .4): return
	if target.boss and not target.aggro: return
	cooldown = 2.0
	var species = active()
	var bond = int(game.changed.get("pet:bond:"+str(species),0))
	game.combat.hit(target,8+mini(10,bond/10))
	game.changed["pet:bond:"+str(species)] = bond+1
	match species:
		0: game.heal(2)
		1: target.weak = 1.5
		2: target.burn = 2.0
		3: game.shield = minf(20,game.shield+3)
		4: game.mana = minf(game.max_mana,game.mana+3)
	game.combat.fx("line",target.position,18,Color("a5e6cd"),.35,position)
