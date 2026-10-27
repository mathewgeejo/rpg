extends RefCounted

# Explicit attack patterns; the shared circle and knight skills remain secondary tools.
static func fire(c) -> void:
	var g = c.game
	var pos: Vector2 = g.player_pos
	var aim: Vector2 = g.facing
	var color = Color(g.class_def.color)
	var third: bool = c.hit_count % 3 == 0
	var damage: float = (18 + g.rank * 3) * g.stat("sword_power" if g.class_def.discipline == "star" else "circle_power")
	match g.class_id:
		"luck", "glass", "ash":
			var count = 5 if g.class_id == "glass" else 3
			var volley_hits: Array = []
			for i in count:
				bolt(c, aim.rotated((i-(count-1)*.5)*.17), damage, 320, .7, "burn" if g.class_id == "ash" else ("weak" if third else ""),volley_hits)
			if g.class_id == "glass":
				for point in c.prisms: c.blast(point,120,23,color,"glass")
				c.prisms.clear()
		"thorn", "ink", "paradox":
			var status = "poison" if g.class_id == "thorn" else ("mark" if g.class_id == "ink" else ("burn" if c.hit_count%2 == 0 else "slow"))
			bolt(c,aim,damage,360,1.1,status)
		"door", "puppet", "lance":
			var reach = 250 if g.class_id == "door" else (210 if g.class_id == "puppet" else 150)
			var end: Vector2 = pos+aim*reach
			c.line_damage(pos,end,22,damage)
			c.fx("line",end,16,color,.24,pos)
			for enemy in c.enemies:
				if enemy.hp > 0 and Geometry2D.get_closest_point_to_segment(enemy.position,pos,end).distance_to(enemy.position) < 30:
					enemy["bound" if g.class_id == "puppet" else "weak"] = 3.0
		"memory":
			c.blast(pos+aim*70,70,damage*.65,color,"echo")
			c.delay(pos+aim*70,80,damage*.7,.55)
		"gravity":
			var target: Vector2 = pos+aim*130
			c.fx("star",target,80,color,.7)
			c.delay(target,80,damage*1.7,.65,"stun")
			c.attack_cd = .85
		"familiar":
			var enemy: Dictionary = c.nearest(330)
			if not enemy.is_empty():
				c.hit(enemy,damage*.85)
				enemy.mark = 3.0
				c.fx("line",enemy.position,22,color,.35,pos)
		"clock", "dream", "lantern", "smith":
			var radius = 125 if g.class_id == "clock" else 90
			c.blast(pos,radius,damage*(1.6 if g.class_id == "smith" else .7),color,"star" if g.class_id == "smith" else "ring")
			var status = "stun" if g.class_id == "smith" or (g.class_id == "clock" and third) else ("sleep" if g.class_id == "dream" and third else "slow")
			c.status_area(pos,radius,status,1.5 if status == "sleep" else .6)
			if g.class_id == "lantern": g.mana = minf(g.max_mana,g.mana+2)
			if g.class_id == "smith":
				c.attack_cd = .65
				if c.empower > 0:
					c.blast(pos,125,20,color,"star")
					c.empower -= 1
		_:
			var radius = 110 if g.class_id == "oath" else 65
			c.fx("slash",pos+aim*35,radius,color,.23,aim)
			for enemy in c.enemies:
				var offset: Vector2 = enemy.position-pos
				if enemy.hp > 0 and offset.length() < radius and offset.normalized().dot(aim) > -.1:
					c.hit(enemy,damage*(1.25 if third else 1))
					if g.class_id == "anatomy": enemy.weak = 2.0
					if g.class_id == "debt":
						enemy.mark = 4.0
						g.heal(2)
			if g.class_id == "echo": c.attack_cd = .2

static func bolt(c, direction: Vector2, damage: float, speed: float, duration: float, status: String, volley_hits = null) -> void:
	var projectile = {"position":c.game.player_pos,"direction":direction,"speed":speed,"damage":damage,"time":duration,"color":Color(c.game.class_def.color),"status":status,"kind":c.game.class_id,"spin":c.hit_count}
	if volley_hits != null: projectile["volley_hits"] = volley_hits
	c.projectiles.append(projectile)
	c.fx("circle",c.game.player_pos,24,Color(c.game.class_def.color),.2)
