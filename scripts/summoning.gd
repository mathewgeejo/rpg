extends RefCounted

const ODDS = {"B":50.0,"A":30.0,"S":15.0,"SS":4.0,"SSS":1.0}

static func owned(game, id: String) -> bool:
	return game.changed.get("class:"+id,false) or (game.assigned and game.class_id == id)

static func summon(game) -> Dictionary:
	var free: bool = not game.changed.get("summon:first",false)
	if not free and game.coins < 30:
		game.toast("A summon costs 30 earned coins. Your first summon is free.")
		return {}
	if not free: game.coins -= 30
	game.changed["summon:first"] = true
	var pity = int(game.changed.get("summon:pity",0))+1
	var rare_pity = int(game.changed.get("summon:rare",0))+1
	var roll: float = game.combat.rng.randf()*100
	var rarity = "SSS"
	var threshold = 0.0
	for tier in ODDS:
		threshold += ODDS[tier]
		if roll < threshold:
			rarity = tier
			break
	if pity >= 80: rarity = "SSS"
	elif rare_pity >= 10 and rarity in ["B","A"]: rarity = "S"
	var pool: Array = []
	for entry in game.data.classes:
		if entry.rarity == rarity: pool.append(entry)
	var result: Dictionary = pool[game.combat.rng.randi_range(0,pool.size()-1)]
	var duplicate = owned(game,result.id)
	game.changed["class:"+result.id] = true
	game.changed["summon:pity"] = 0 if rarity == "SSS" else pity
	game.changed["summon:rare"] = 0 if rarity in ["S","SS","SSS"] else rare_pity
	if duplicate: game.coins += 15
	game.changed["summon:last"] = result.id
	game.changed["summon:duplicate"] = duplicate
	if not game.assigned: game.assign_class(result.id)
	game.save_game()
	return result
