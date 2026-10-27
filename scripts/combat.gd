extends RefCounted

var game
var enemies: Array = []
var effects: Array = []
var projectiles: Array = []
var pending: Array = []
var hazards: Array = []
var rng = RandomNumberGenerator.new()
var attack_cd = 0.0
var signature_cd = 0.0
var circle_cd = 0.0
var ward_cd = 0.0
var star_cd = 0.0
var hit_count = 0
var action_count = 0
var stored_hurt = 0.0
var vow = 0
var die = 1
var empower = 0
var paradox_fire = false
var familiar_time = 0.0
var familiar_count = 0
var hearth = Vector2.ZERO
var prisms: Array = []
var last_attack_position = Vector2.ZERO
var last_attack_direction = Vector2.DOWN
var familiar_hits = 0
var prophet_time = 0.0
var prophet_charge = false
var last_action = ""
var alternating = false
var combo_time = 0.0

func _init(owner_game = null) -> void:
	game = owner_game
	rng.seed = 81731

func load_room(room: Dictionary) -> void:
	enemies.clear()
	effects.clear()
	projectiles.clear()
	pending.clear()
	hazards.clear()
	prisms.clear()
	hearth = Vector2.ZERO
	familiar_time = 0
	for source in room.enemies:
		if game.changed.has(source.id) and not game.changed.get("respawn:"+source.id,false):
			continue
		var enemy: Dictionary = source.duplicate(true)
		enemy.merge({"hp":620.0 if source.boss else 65.0+source.type*15,"max_hp":620.0 if source.boss else 65.0+source.type*15,"windup":0.0,"cooldown":1.2,"stun":0.0,"slow":0.0,"poison":0.0,"burn":0.0,"weak":0.0,"mark":0.0,"sleep":0.0,"bound":0.0,"repeat":0.0,"poison_tick":0.0,"flash":0.0,"attack_target":Vector2.ZERO,"study":0,"enraged":false,"aggro":false,"attack_radius":100.0 if source.boss else 45.0})
		enemies.append(enemy)

func tick(delta: float) -> void:
	preload("res://scripts/boss_patterns.gd").tick(self,delta)
	combo_time = maxf(0,combo_time-delta)
	if combo_time == 0: hit_count = 0
	attack_cd = maxf(0,attack_cd-delta)
	signature_cd = maxf(0,signature_cd-delta)
	circle_cd = maxf(0,circle_cd-delta)
	ward_cd = maxf(0,ward_cd-delta)
	star_cd = maxf(0,star_cd-delta)
	if prophet_time > 0:
		prophet_time -= delta
		if prophet_time <= 0:
			game.shield = 0
			prophet_charge = true
	for event in pending.duplicate():
		event.time -= delta
		if event.time <= 0:
			pending.erase(event)
			blast(event.position,event.radius,event.damage,event.get("color",Color("8ed8cf")),event.get("kind","ring"))
			if event.get("status", "") != "": status_area(event.position,event.radius,event.status,1.0)
	for effect in effects.duplicate():
		effect.time -= delta
		if effect.time <= 0:
			effects.erase(effect)
			continue
		if effect.get("zone",false):
			effect.tick -= delta
			if effect.tick <= 0:
				effect.tick = .65
				for enemy in enemies:
					if enemy.hp > 0 and enemy.position.distance_to(effect.position) < effect.radius:
						if effect.get("damage",0) > 0:
							hit(enemy,effect.damage)
							if effect.get("burn",false): enemy.burn = maxf(enemy.burn,2)
						if effect.get("slow",false): enemy.slow = 1.4 if game.class_id == "clock" else 1.0
						if effect.get("null",false): enemy.stun = .8
				if game.player_pos.distance_to(effect.position) < effect.radius:
					if effect.get("heal",0) > 0: game.heal(effect.heal)
					if effect.get("mana",0) > 0: game.mana = minf(game.max_mana,game.mana+effect.mana)
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		for status in ["stun","slow","weak","mark","sleep","bound","repeat","flash"]:
			enemy[status] = maxf(0,float(enemy[status])-delta)
		if enemy.poison > 0 or enemy.burn > 0:
			enemy.poison = maxf(0,enemy.poison-delta)
			enemy.burn = maxf(0,enemy.burn-delta)
			enemy.poison_tick -= delta
			if enemy.poison_tick <= 0:
				enemy.poison_tick = .65
				hit(enemy,(5.0 if enemy.poison > 0 else 0.0)+(7.0 if enemy.burn > 0 else 0.0),true)
		if enemy.boss and enemy.hp/enemy.max_hp < .5 and not enemy.enraged:
			enemy.enraged = true
			enemy.attack_radius = 120
			game.toast(enemy.get("name","The Keeper")+" awakens. The attack pattern changes!")
			fx("star",enemy.position,120,Color("edbb8b"),1)
		if enemy.stun > 0 or enemy.sleep > 0:
			continue
		enemy.cooldown -= delta
		var distance = enemy.position.distance_to(game.player_pos)
		if enemy.boss and not enemy.aggro:
			if distance < 240 or enemy.hp < enemy.max_hp:
				enemy.aggro = true
				if is_instance_valid(game.ui.banner): game.ui.banner.hide()
			else: continue
		if enemy.boss:
			if distance > 440: continue
			if enemy.cooldown <= 0:
				preload("res://scripts/boss_patterns.gd").prepare(self,enemy)
				enemy.windup = 1.2
				enemy.cooldown = 2.5 if enemy.enraged else 3.5
			enemy.windup = maxf(0,enemy.windup-delta)
			continue
		if enemy.windup > 0:
			enemy.windup -= delta
			if enemy.windup <= 0:
				var radius: float = enemy.attack_radius
				if game.player_pos.distance_to(enemy.attack_target) < radius:
					game.take_damage(24.0 if enemy.boss else 11.0)
				fx("impact",enemy.attack_target,radius,Color("d78e88"),.45)
				enemy.cooldown = (1.8 if enemy.enraged else 2.6) if enemy.boss else 1.5
		elif distance < (500 if enemy.boss else 48) and enemy.cooldown <= 0:
			enemy.attack_target = game.player_pos
			enemy.windup = (1.2 if enemy.boss else .7) + (.2 if game.class_id == "witness" else 0)
		elif distance < (700 if enemy.boss else 390):
			var target: Vector2 = game.player_pos
			for effect in effects:
				if effect.kind == "decoy": target = effect.position
			if game.invisible > 0: continue
			var direction: Vector2 = enemy.position.direction_to(target)
			var speed = (58.0 if enemy.boss else 70.0) * (.4 if enemy.slow > 0 or enemy.bound > 0 else 1.0)
			var next: Vector2 = enemy.position+direction*speed*delta
			if enemy.boss and not Rect2(240,240,480,352).has_point(next): continue
			if game.model.walkable(game.room_id,next,enemy.position): enemy.position = next
	for projectile in projectiles.duplicate():
		projectile.time -= delta
		projectile.position += projectile.direction*projectile.speed*delta
		if projectile.time <= 0 or not game.model.walkable(game.room_id,projectile.position):
			projectiles.erase(projectile)
			continue
		for enemy in enemies:
			if enemy.hp > 0 and enemy.position.distance_to(projectile.position) < (55 if enemy.boss else 26):
				if projectile.has("volley_hits"):
					if enemy.id in projectile.volley_hits: continue
					projectile.volley_hits.append(enemy.id)
				hit(enemy,projectile.damage)
				if projectile.get("status", "") != "": enemy[projectile.status] = 3.0
				if projectile.get("burn",0) > 0: enemy.burn = projectile.burn
				if projectile.get("slow",0) > 0: enemy.slow = projectile.slow
				game.mana = minf(game.max_mana,game.mana+projectile.get("refund",0))
				game.train_skill("circles",3)
				fx("impact",projectile.position,30,projectile.color,.3)
				projectiles.erase(projectile)
				break
	if familiar_time > 0:
		familiar_time -= delta
		if int(familiar_time*2) != int((familiar_time+delta)*2):
			var enemy = nearest(400)
			if not enemy.is_empty():
				hit(enemy,9.0*familiar_count)
				familiar_hits += 1
				fx("line",enemy.position,16,Color("dcc187"),.2,game.player_pos)
				if game.class_id == "ink" and familiar_hits%3 == 0: game.mana = minf(game.max_mana,game.mana+6)
		if game.class_id == "familiar": game.shield = maxf(game.shield,10)

func nearest(radius: float = 400) -> Dictionary:
	var best: Dictionary = {}
	var distance = radius
	for enemy in enemies:
		var d: float = enemy.position.distance_to(game.player_pos)
		if enemy.hp > 0 and d < distance:
			best = enemy
			distance = d
	return best

func hit(enemy: Dictionary, amount: float, periodic: bool = false) -> void:
	if enemy.hp <= 0: return
	var power = amount * game.stat("damage")
	if enemy.weak > 0: power *= 1.4
	if enemy.sleep > 0:
		power *= 1.8
		enemy.sleep = 0
		if game.class_id == "dream": game.mana = minf(game.max_mana,game.mana+8)
	if not periodic:
		if enemy.mark > 0: power *= 1.1
		if game.class_id == "penance": power *= 1.0+(1.0-game.hp/game.max_hp)*.5
		if game.class_id == "hunger" and game.mana < 25: power *= 1.25
		if game.class_id == "exile" and game.room_id > 0: power *= 1.15
		if game.class_id == "name" and enemy.hp == enemy.max_hp: power *= 1.35
		if game.class_id == "anatomy":
			power *= 1.0+minf(.4,float(enemy.get("study",0))*.04)
			enemy.study = mini(10,int(enemy.get("study",0))+1)
		if game.class_id == "lance" and enemy.position.distance_to(game.player_pos) > 60: power *= 1.25
		if game.class_id == "glass": power *= 1.0+prisms.size()*.08
		if game.class_id == "paradox" and alternating: power *= 1.15
		if game.class_id == "prophet" and prophet_charge:
			power *= 1.35
			prophet_charge = false
		if game.class_id == "echo": power *= 1.0+mini(hit_count,5)*.04
	if enemy.repeat > 0:
		power *= 1.35
		enemy.repeat = 0
	enemy.hp -= power
	enemy.flash = .12
	game.float_text(str(int(power)),enemy.position,Color("f4db9b"))
	if enemy.mark > 0 and game.class_id == "debt": game.heal(3)
	if enemy.stun > 0 and game.class_id == "fortune": game.stamina = minf(100,game.stamina+3)
	if enemy.bound > 0 and not periodic:
		for other in enemies:
			if other != enemy and other.bound > 0 and other.hp > 0:
				hit(other,power*.18,true)
	if enemy.hp <= 0:
		game.changed[enemy.id] = true
		game.changed["defeated:"+enemy.id] = true
		game.changed.erase("respawn:"+enemy.id)
		game.coins += 8 if game.class_id == "auction" else 5
		game.gain_xp(150 if enemy.boss else 18)
		fx("defeat",enemy.position,60,Color("a5dcc6"),.8)
		if game.class_id in ["debt","rot","bloom"]: game.heal(5)
		if game.class_id == "epitaph": signature_cd = maxf(0,signature_cd-1)
		if game.class_id == "moment": game.haste = 3
		if enemy.boss:
			hazards = hazards.filter(func(h): return h.owner != enemy.id)
			game.coins += 75
			if enemy.id != "the_keeper":
				game.toast(enemy.get("name","Guardian")+" defeated. +75 coins. A constellation remembers you.")
				game.save_game()
				return
			game.quest_stage = maxi(3,game.quest_stage)
			game.toast("The Keeper falls. The seal is waiting for your answer.")
			game.save_game()

func basic() -> void:
	var cost = 9 if (hit_count+1)%3 == 0 else 5
	if attack_cd > 0 or game.stamina < cost: return
	game.stamina -= cost
	attack_cd = .32
	hit_count += 1
	combo_time = 2.5
	alternating = last_action == "spell"
	last_action = "basic"
	action_count += 1
	vow = mini(5,vow+(2 if game.class_id == "oath" and hit_count%3 == 0 else 1))
	game.animation = "attack" if game.class_id in ["oath","echo","debt","anatomy","lance","smith"] else "cast"
	game.animation_time = .3
	game.sound.note(220+hit_count%3*70,.08,.12)
	last_attack_position = game.player_pos
	last_attack_direction = game.facing
	preload("res://scripts/class_attacks.gd").fire(self)
	game.train_skill("sword" if game.class_def.discipline == "star" else "circles",1)
	if game.class_id == "smith" and hit_count%3 == 0: game.mana = minf(game.max_mana,game.mana+4)

func cast_circle() -> void:
	var cost = 15 if game.magic_focus == "ember" else (14 if game.magic_focus == "frost" else 12)
	if circle_cd > 0 or not pay(cost): return
	circle_cd = .65
	if game.circle_strain >= 80:
		game.hp = maxf(1,game.hp-6)
		circle_cd = 1.4
		game.toast("Your outer circle frays. Slow your casting to release the strain.")
	game.circle_strain = minf(100,game.circle_strain+20-(game.rank-1)*2)
	game.animation = "cast"
	game.animation_time = .5
	var color = Color("e9b07d") if game.magic_focus == "ember" else (Color("bad0ef") if game.magic_focus == "frost" else Color("91dfd8"))
	projectiles.append({"position":game.player_pos,"direction":game.facing,"speed":370.0,"damage":(24.0+game.rank*4)*game.stat("circle_power"),"time":1.15,"color":color,"burn":3.0 if game.magic_focus == "ember" else 0.0,"slow":3.0 if game.magic_focus == "frost" else 0.0,"refund":3.0 if game.magic_focus == "aether" else 0.0})
	fx("circle",game.player_pos,35,color,.5)
	game.sound.note(660,.2,.1)

func star_step() -> void:
	var cost = 25 if game.sword_stance == "flowing" else 35
	if star_cd > 0 or game.stamina < cost: return
	game.stamina -= cost
	star_cd = 4
	var origin: Vector2 = game.player_pos
	game.blink(game.facing*(200 if game.sword_stance == "flowing" else 140))
	line_damage(origin,game.player_pos,45,(44 if game.sword_stance == "rending" else 28)*game.stat("sword_power")*(1+game.skill_level("stars")*.02))
	if game.sword_stance == "resolute": game.shield += 18*game.stat("shield")
	if game.sword_stance == "flowing": game.haste = 1.5
	if game.sword_stance == "rending": status_area(game.player_pos,90,"weak",4)
	game.train_skill("stars",6)
	fx("star",game.player_pos,70,Color("e7c985"),.5,origin)

func ward() -> void:
	if ward_cd > 0 or not pay(18): return
	ward_cd = 9
	game.shield = 35*game.stat("shield")
	if game.class_id == "wound": game.shield *= 1+(1-game.hp/game.max_hp)
	fx("circle",game.player_pos,80,Color("a7cce8"),.7)

func pay(amount: float) -> bool:
	action_count += 1
	if game.class_id == "moth" and game.mana < 25: amount *= .7
	if game.class_id == "cipher" and action_count%3 == 0: amount *= .5
	if game.mana < amount:
		game.toast("Not enough mana. Let your circles settle.")
		return false
	game.mana -= amount
	alternating = last_action == "basic"
	last_action = "spell"
	return true

func signature() -> void:
	if signature_cd > 0 or not pay(20): return
	signature_cd = 8.0*(.85 if game.rank >= 3 else 1.0)
	var pos: Vector2 = game.player_pos
	var target = nearest()
	var power = 1.0+(game.rank-1)*.2
	game.animation = "cast"
	game.animation_time = .65
	game.sound.note(440,.3,.15)
	fx("star" if game.class_def.discipline == "star" else "circle",pos,70,Color(game.class_def.color),.7)
	match game.class_id:
		"luck":
			die = rng.randi_range(1,6)
			if game.luck >= 3: die = maxi(die,4)
			game.luck = 0
			game.float_text("FATE · %d" % die,pos,Color("f3d38d"))
			if die <= 2: game.mana = minf(game.max_mana,game.mana+26)
			blast(pos+game.facing*90,160,(14+die*9)*power,Color("e9bf68"),"dice")
			if die == 6: signature_cd = 0
		"debt":
			game.hp = maxf(1,game.hp-12)
			for e in within(pos,200):
				e.mark = 9
				hit(e,48*power)
		"memory":
			blast(pos+game.facing*65,130,29*power,Color("9ae2e0"))
			fx("echo",pos,64,Color("a3dadd"),1.6)
			delay(pos+game.facing*65,145,42*power,.9)
		"echo":
			var origin = pos
			game.blink(game.facing*170)
			line_damage(origin,game.player_pos,60,32*power,"repeat")
			delay(origin.lerp(game.player_pos,.5),120,28*power,.6)
		"oath":
			blast(pos+game.facing*60,190,(22+vow*12)*power,Color("e0ad86"),"slash")
			status_area(pos,230,"weak",5)
			vow = 0
		"clock":
			zone(pos,240,6,9*power,0,Color("a7bfde"),true)
		"smith":
			empower = 3
			fx("star",pos,90,Color("dfb486"),1)
		"thorn":
			zone(pos+game.facing*60,155+stored_hurt,6,(12+stored_hurt*.3)*power,0,Color("98c999"),true)
			status_area(pos,240,"poison",5)
			stored_hurt = 0
		"anatomy":
			if not target.is_empty():
				target.weak = 9
				hit(target,40*power)
		"door":
			var origin = pos
			game.blink(game.facing*260)
			fx("portal",origin,65,Color("84ded4"),2)
			fx("portal",game.player_pos,65,Color("84ded4"),2)
			line_damage(origin,game.player_pos,65,56*power,"weak")
			game.stamina = minf(100,game.stamina+15)
		"lance":
			game.blink(game.facing*300)
			line_damage(pos,game.player_pos,65,65*power,"weak")
			fx("line",game.player_pos,40,Color("c4dfd9"),.5,pos)
		"gravity":
			status_area(pos,240,"stun",2)
			delay(pos,240,60*power,1)
			fx("star",pos,200,Color("b9dbd7"),1)
		"ink":
			familiar_time = 10
			familiar_count = 1
		"glass":
			if prisms.is_empty():
				for i in 3: prisms.append(pos+game.facing*110+Vector2.from_angle(i*TAU/3)*85)
				signature_cd = 1
			else:
				for point in prisms: blast(point,150,44*power,Color("c7b2dc"),"glass")
				prisms.clear()
		"puppet":
			status_area(pos,260,"bound",7)
			blast(pos,260,32*power,Color("d0a5cc"))
		"dream":
			status_area(pos,250,"sleep",6)
			fx("bloom",pos,220,Color("c6b1df"),1)
		"ash":
			game.blink(game.facing*220)
			for i in 4: zone(pos.lerp(game.player_pos,i/3.0),70,5,12*power,0,Color("e4a879"))
		"lantern":
			zone(pos,190,9,6*power,6,Color("f0d59b"),true)
		"paradox":
			if paradox_fire: blast(pos,230,75*power,Color("e0ad83"))
			else: status_area(pos,230,"stun",3)
			paradox_fire = not paradox_fire
		"familiar":
			familiar_time = 10
			familiar_count = 3
			game.shield += 15
	# Specials also carry a readable control or vulnerability effect.
	var debuffs = {"luck":"weak","memory":"repeat","echo":"repeat","ink":"mark","glass":"weak","smith":"stun","door":"weak","lance":"weak","familiar":"mark","ash":"burn","debt":"mark","anatomy":"weak","paradox":"slow"}
	if debuffs.has(game.class_id):
		status_area(game.player_pos+game.facing*60,190,debuffs[game.class_id],1.0 if game.class_id == "smith" else 4.0)

func within(pos: Vector2, radius: float) -> Array:
	return enemies.filter(func(e): return e.hp > 0 and e.position.distance_to(pos) < radius)

func status_area(pos: Vector2, radius: float, status: String, duration: float) -> void:
	if status == "slow" and game.class_id == "clock": duration *= 1.35
	for enemy in within(pos,radius): enemy[status] = duration
	fx("rune",pos,minf(70,radius*.5),Color(game.class_def.color),.4)

func blast(pos: Vector2, radius: float, damage: float, color: Color, kind: String = "ring") -> void:
	for enemy in within(pos,radius): hit(enemy,damage)
	fx(kind,pos,radius,color,.6)

func line_damage(a: Vector2, b: Vector2, width: float, damage: float, status: String = "") -> void:
	for enemy in enemies:
		if enemy.hp > 0 and Geometry2D.get_closest_point_to_segment(enemy.position,a,b).distance_to(enemy.position) < width:
			hit(enemy,damage)
			if status != "": enemy[status] = 4.0

func fx(kind: String, pos: Vector2, radius: float, color: Color, duration: float, origin: Vector2 = Vector2.ZERO) -> void:
	effects.append({"kind":kind,"position":pos,"radius":radius,"color":color,"time":duration,"duration":duration,"origin":origin})

func zone(pos: Vector2, radius: float, duration: float, damage: float, healing: float, color: Color, slow: bool = false, nullify: bool = false, mana: float = 0) -> void:
	effects.append({"kind":"garden" if game.class_id == "thorn" else "field","position":pos,"radius":radius,"color":color,"time":duration,"duration":duration,"zone":true,"tick":0.0,"damage":damage,"heal":healing,"slow":slow,"null":nullify,"mana":mana,"burn":game.class_id == "ash"})

func delay(pos: Vector2, radius: float, damage: float, time: float, status: String = "") -> void:
	pending.append({"position":pos,"radius":radius,"damage":damage,"time":time,"status":status})
