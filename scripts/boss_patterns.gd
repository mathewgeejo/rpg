extends RefCounted

static func prepare(c, enemy: Dictionary) -> void:
	var pattern = int(enemy.get("cycle",0))
	enemy["cycle"] = pattern+1
	var target: Vector2 = c.game.player_pos
	var origin: Vector2 = enemy.position
	var phase: bool = enemy.enraged
	match enemy.id:
		"briar_crown":
			# Roots mark the player's last position; the crown itself stays rooted.
			for i in (5 if phase else 3):
				var offset = Vector2.from_angle(i*TAU/(5 if phase else 3)+pattern*.5)*85
				c.hazards.append(mark(enemy.id,target+offset,43,1.35+i*.12,17,"root"))
			if phase: c.hazards.append(mark(enemy.id,target,45,1.5,17,"root"))
		"tide_bell":
			# Alternate stepping-stone lanes; clear gaps remain between each wave.
			for i in 5:
				var point = origin+Vector2((i-2)*65,70 if pattern%2 == 0 else -70)
				c.hazards.append(mark(enemy.id,point,27,1.2+i*.15,20,"tide"))
			c.hazards.append(mark(enemy.id,target,48,.95 if phase else 1.5,20,"tide"))
		_:
			c.hazards.append(mark(enemy.id,target,85 if phase else 65,1.2,24,"star"))
			if phase:
				for i in 4:
					c.hazards.append(mark(enemy.id,origin+Vector2.from_angle(i*PI*.5+pattern*.4)*125,42,1.7,22,"star"))

static func mark(owner: String, point: Vector2, radius: float, time: float, damage: float, kind: String) -> Dictionary:
	return {"owner":owner,"position":point,"radius":radius,"time":time,"duration":time,"damage":damage,"kind":kind}

static func tick(c, delta: float) -> void:
	for hazard in c.hazards.duplicate():
		hazard.time -= delta
		if hazard.time > 0: continue
		c.hazards.erase(hazard)
		if c.game.player_pos.distance_to(hazard.position) < hazard.radius:
			var can_root: bool = not c.game.god_mode and c.game.invulnerable <= 0
			c.game.take_damage(hazard.damage)
			if hazard.kind == "root" and can_root: c.game.rooted = .45
		c.fx("bloom" if hazard.kind == "root" else "star",hazard.position,hazard.radius,Color("b8cc91") if hazard.kind == "root" else Color("a4d6e7"),.5)
