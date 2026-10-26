extends RefCounted

var game
var enemies: Array = []
var effects: Array = []
var projectiles: Array = []
var pending: Array = []
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

func _init(owner_game = null) -> void:
	game = owner_game
	rng.seed = 81731

func load_room(room: Dictionary) -> void:
	enemies.clear()
	effects.clear()
	projectiles.clear()
	pending.clear()
	prisms.clear()
	hearth = Vector2.ZERO
	familiar_time = 0
	for source in room.enemies:
		if game.changed.has(source.id):
			continue
		var enemy: Dictionary = source.duplicate(true)
		enemy.merge({"hp":620.0 if source.boss else 65.0+source.type*15,"max_hp":620.0 if source.boss else 65.0+source.type*15,"windup":0.0,"cooldown":1.2,"stun":0.0,"slow":0.0,"poison":0.0,"weak":0.0,"mark":0.0,"sleep":0.0,"bound":0.0,"repeat":0.0,"poison_tick":0.0,"flash":0.0,"attack_target":Vector2.ZERO})
		enemies.append(enemy)

func tick(delta: float) -> void:
	attack_cd = maxf(0,attack_cd-delta)
	signature_cd = maxf(0,signature_cd-delta)
	circle_cd = maxf(0,circle_cd-delta)
	ward_cd = maxf(0,ward_cd-delta)
	star_cd = maxf(0,star_cd-delta)
	for event in pending.duplicate():
		event.time -= delta
		if event.time <= 0:
			pending.erase(event)
			blast(event.position,event.radius,event.damage,event.get("color",Color("8ed8cf")),event.get("kind","ring"))
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
						if effect.get("slow",false): enemy.slow = 1.0
						if effect.get("null",false): enemy.stun = .8
				if game.player_pos.distance_to(effect.position) < effect.radius:
					if effect.get("heal",0) > 0: game.heal(effect.heal)
					if effect.get("mana",0) > 0: game.mana = minf(game.max_mana,game.mana+effect.mana)
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		for status in ["stun","slow","weak","mark","sleep","bound","repeat","flash"]:
			enemy[status] = maxf(0,float(enemy[status])-delta)
		if enemy.poison > 0:
			enemy.poison -= delta
			enemy.poison_tick -= delta
			if enemy.poison_tick <= 0:
				enemy.poison_tick = .65
				hit(enemy,5.0,true)
		if enemy.stun > 0 or enemy.sleep > 0:
			continue
		enemy.cooldown -= delta
		var distance = enemy.position.distance_to(game.player_pos)
		if enemy.windup > 0:
			enemy.windup -= delta
			if enemy.windup <= 0:
				var radius = 150.0 if enemy.boss else 65.0
				if game.player_pos.distance_to(enemy.attack_target) < radius:
					game.take_damage(24.0 if enemy.boss else 11.0)
				fx("impact",enemy.attack_target,radius,Color("d78e88"),.45)
				enemy.cooldown = 2.6 if enemy.boss else 1.5
		elif distance < (125 if enemy.boss else 54) and enemy.cooldown <= 0:
			enemy.attack_target = game.player_pos
			enemy.windup = (1.05 if enemy.boss else .7) + (.2 if game.class_id == "witness" else 0)
		elif distance < (700 if enemy.boss else 390):
			var target: Vector2 = game.player_pos
			for effect in effects:
				if effect.kind == "decoy": target = effect.position
			if game.invisible > 0: continue
			var direction: Vector2 = enemy.position.direction_to(target)
			var speed = (58.0 if enemy.boss else 70.0) * (.4 if enemy.slow > 0 or enemy.bound > 0 else 1.0)
			var next: Vector2 = enemy.position+direction*speed*delta
			if game.model.walkable(game.room_id,next): enemy.position = next
	for projectile in projectiles.duplicate():
		projectile.time -= delta
		projectile.position += projectile.direction*projectile.speed*delta
		if projectile.time <= 0 or not game.model.walkable(game.room_id,projectile.position):
			projectiles.erase(projectile)
			continue
		for enemy in enemies:
			if enemy.hp > 0 and enemy.position.distance_to(projectile.position) < (55 if enemy.boss else 26):
				hit(enemy,projectile.damage)
				fx("impact",projectile.position,30,projectile.color,.3)
				projectiles.erase(projectile)
				break
	if familiar_time > 0:
		familiar_time -= delta
		if int(familiar_time*2) != int((familiar_time+delta)*2):
			var enemy = nearest(400)
			if not enemy.is_empty():
				hit(enemy,9.0*familiar_count)
				fx("line",enemy.position,16,Color("dcc187"),.2,game.player_pos)
				if game.class_id == "ink": game.mana = minf(game.max_mana,game.mana+2)

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
		if game.class_id == "penance": power *= 1.0+(1.0-game.hp/game.max_hp)*.5
		if game.class_id == "hunger" and game.mana < 25: power *= 1.25
		if game.class_id == "exile" and game.room_id > 0: power *= 1.15
		if game.class_id == "name" and enemy.hp == enemy.max_hp: power *= 1.35
		if game.class_id == "anatomy": power *= 1.0+minf(.4,hit_count*.015)
		if game.class_id == "lance" and enemy.position.distance_to(game.player_pos) > 60: power *= 1.25
		if game.class_id == "glass": power *= 1.0+prisms.size()*.08
		if game.class_id == "paradox" and action_count % 2 == 0: power *= 1.15
		if game.class_id == "prophet" and game.shield <= 0: power *= 1.12
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
		game.coins += 8 if game.class_id == "auction" else 5
		game.gain_xp(150 if enemy.boss else 18)
		fx("defeat",enemy.position,60,Color("a5dcc6"),.8)
		if game.class_id in ["debt","rot","bloom"]: game.heal(5)
		if game.class_id == "epitaph": signature_cd = maxf(0,signature_cd-1)
		if game.class_id == "moment": game.haste = 3
		if enemy.boss:
			game.quest_stage = maxi(3,game.quest_stage)
			game.toast("The Keeper falls. The seal is waiting for your answer.")
			game.save_game()

func basic() -> void:
	if attack_cd > 0: return
	attack_cd = .32
	hit_count += 1
	action_count += 1
	vow = mini(5,vow+(2 if game.class_id == "oath" and hit_count%3 == 0 else 1))
	game.animation = "attack"
	game.animation_time = .3
	game.sound.note(220+hit_count%3*70,.08,.12)
	fx("slash",game.player_pos+game.facing*35,82,Color("f1d69e"),.23,game.facing)
	last_attack_position = game.player_pos
	for enemy in enemies:
		var offset: Vector2 = enemy.position-game.player_pos
		if enemy.hp > 0 and offset.length() < (130 if enemy.boss else 104) and offset.normalized().dot(game.facing) > -.1:
			hit(enemy,18+game.rank*3+(12 if empower > 0 else 0))
			if empower > 0: fx("ring",enemy.position,80,Color("c8deeb"),.3)
	if empower > 0: empower -= 1
	if game.class_id == "smith" and hit_count%3 == 0: game.mana = minf(game.max_mana,game.mana+4)
	if game.class_id == "glass" and not prisms.is_empty():
		for point in prisms: blast(point,120,23,Color("c5b5eb"),"glass")
		prisms.clear()

func cast_circle() -> void:
	if circle_cd > 0 or not pay(12): return
	circle_cd = .65
	game.animation = "cast"
	game.animation_time = .5
	projectiles.append({"position":game.player_pos,"direction":game.facing,"speed":520.0,"damage":26.0+game.rank*4,"time":1.0,"color":Color("91dfd8")})
	fx("circle",game.player_pos,50,Color("8adcd0"),.5)
	game.sound.note(660,.2,.1)

func star_step() -> void:
	if star_cd > 0 or game.stamina < 30: return
	game.stamina -= 30
	star_cd = 4
	var origin: Vector2 = game.player_pos
	game.blink(game.facing*180)
	line_damage(origin,game.player_pos,50,32)
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
	fx("circle",pos,70,Color(game.class_def.color),.7)
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
		"coin":
			if game.coins < 10:
				game.mana += 20
				signature_cd = 0
				game.toast("Mercy Mint needs 10 coins.")
				return
			game.coins -= 10
			game.heal(35)
			blast(pos,160,28*power,Color("eed49a"))
		"fortune":
			status_area(pos,200,"stun",2.5)
			game.haste = 5
		"auction":
			var count = within(pos+game.facing*120,190).size()
			zone(pos+game.facing*120,190,1.8,0,0,Color("dfba86"))
			delay(pos+game.facing*120,190,(35+count*12)*power,1.6)
		"memory":
			blast(pos+game.facing*65,130,29*power,Color("9ae2e0"))
			fx("echo",pos,64,Color("a3dadd"),1.6)
			delay(pos+game.facing*65,145,42*power,.9)
		"name":
			if not target.is_empty():
				target.stun = 2.4
				target.weak = 6
				empower = 1
		"echo":
			var origin = pos
			game.blink(game.facing*170)
			line_damage(origin,game.player_pos,60,32*power)
			delay(origin.lerp(game.player_pos,.5),120,28*power,.6)
		"mask":
			fx("decoy",pos,35,Color("cba0d2"),5)
			game.invisible = 3.5
			game.shield += 12
		"epitaph":
			for e in within(pos,220):
				hit(e,(90 if e.hp/e.max_hp < .35 else 22)*power)
				e.slow = 6
		"oath":
			blast(pos+game.facing*60,190,(22+vow*12)*power,Color("e0ad86"),"slash")
			status_area(pos,230,"weak",5)
			vow = 0
		"vow":
			game.shield = 65*game.stat("shield")
			game.rooted = .8
			blast(pos,140,45*power,Color("e9d39f"),"star")
		"witness":
			status_area(pos,450,"repeat",8)
			status_area(pos,450,"mark",8)
		"penance":
			game.hp = maxf(1,game.hp-18)
			blast(pos,230,70*power,Color("d0a0b4"))
		"banner":
			game.haste = 7
			game.stamina = 100
			zone(pos,170,7,8,0,Color("d7c78f"))
		"clock":
			zone(pos,240,6,9*power,0,Color("a7bfde"),true)
		"smith":
			empower = 3
			fx("star",pos,90,Color("dfb486"),1)
		"delay":
			blast(pos+game.facing*80,140,24*power,Color("b9cce5"),"slash")
			delay(pos+game.facing*80,160,55*power,2)
		"moment":
			game.blink(game.facing*220)
			game.stamina = minf(100,game.stamina+within(game.player_pos,180).size()*20)
			blast(game.player_pos,150,35*power,Color("b3cbdb"),"star")
		"afterimage":
			for i in 3:
				var point = pos+Vector2.from_angle(i*TAU/3)*80
				fx("decoy",point,40,Color("bccce3"),2)
				delay(point,110,24*power,2)
		"thorn":
			zone(pos+game.facing*60,155+stored_hurt,6,(12+stored_hurt*.3)*power,0,Color("98c999"),true)
			status_area(pos,240,"poison",5)
			stored_hurt = 0
		"bloom":
			game.heal(24)
			status_area(pos,210,"poison",8)
			fx("bloom",pos,180,Color("adc88c"),1)
		"moth":
			for e in within(pos,420):
				hit(e,28*power)
				fx("line",e.position,20,Color("c8df9d"),.6,pos)
				game.mana = minf(game.max_mana,game.mana+4)
		"rot":
			zone(pos+game.facing*70,200,8,8*power,3,Color("a3b67f"),true)
			status_area(pos,220,"poison",7)
		"anatomy":
			if not target.is_empty():
				target.weak = 9
				hit(target,40*power)
		"door":
			var origin = pos
			game.blink(game.facing*260)
			fx("portal",origin,65,Color("84ded4"),2)
			fx("portal",game.player_pos,65,Color("84ded4"),2)
			line_damage(origin,game.player_pos,65,56*power)
			game.stamina = minf(100,game.stamina+15)
		"lance":
			game.blink(game.facing*300)
			line_damage(pos,game.player_pos,65,65*power)
			fx("line",game.player_pos,40,Color("c4dfd9"),.5,pos)
		"fold":
			for e in within(pos,270):
				e.position = e.position.lerp(pos,.65)
				e.stun = 1.8
				hit(e,30*power)
			fx("portal",pos,220,Color("a3c6d2"),.8)
		"compass":
			for e in within(pos,220):
				var next: Vector2 = e.position+pos.direction_to(e.position)*100
				if game.model.walkable(game.room_id,next): e.position = next
				hit(e,38*power)
			game.haste = 3
		"gravity":
			status_area(pos,240,"stun",2)
			delay(pos,240,60*power,1)
			fx("star",pos,200,Color("b9dbd7"),1)
		"ink":
			familiar_time = 10
			familiar_count = 1
		"silence":
			for e in within(pos,310):
				e.windup = 0
				e.stun = 3
				hit(e,30*power)
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
		"wound":
			game.shield = (game.max_hp-game.hp)*.6+15
			blast(pos,210,(25+(game.max_hp-game.hp)*.7)*power,Color("dd9ba0"))
		"ash":
			game.blink(game.facing*220)
			for i in 4: zone(pos.lerp(game.player_pos,i/3.0),70,5,12*power,0,Color("e4a879"))
		"hunger":
			var count = within(pos,180).size()
			blast(pos,180,34*power,Color("d7c291"))
			game.heal(maxf(0,game.stamina+count*30-100)*.4)
			game.stamina = minf(100,game.stamina+count*30)
		"lantern":
			zone(pos,190,9,6*power,6,Color("f0d59b"),true)
		"burden":
			game.shield = game.stamina*.5
			game.stamina = 10
			blast(pos,230,58*power,Color("d7b9a1"),"star")
		"paradox":
			if paradox_fire: blast(pos,230,75*power,Color("e0ad83"))
			else: status_area(pos,230,"stun",3)
			paradox_fire = not paradox_fire
		"prophet":
			game.invulnerable = 2.5
			game.shield = 40
			fx("star",pos,110,Color("ddc88f"),2.5)
		"question":
			for e in within(pos,300):
				e.windup = 0
				e.stun = 1.3
				e.weak = 6
				hit(e,42*power)
		"cipher":
			for i in 3: delay(pos+game.facing*(60+i*50),115,23*power,.3+i*.35)
			delay(pos+game.facing*120,180,40*power,1.5)
		"null":
			projectiles.clear()
			zone(pos,210,7,4*power,0,Color("a8bfc5"),false,true,6)
		"thread":
			status_area(pos,300,"bound",8)
			game.shield += within(pos,300).size()*8
			fx("circle",pos,250,Color("c7d8d7"),1)
		"pact":
			game.rooted = 0
			game.invulnerable = 2
			blast(pos,200,52*power,Color("e1d4ac"),"star")
		"familiar":
			familiar_time = 10
			familiar_count = 3
			game.shield += 15
		"hearth":
			if hearth == Vector2.ZERO:
				hearth = pos
				zone(pos,160,16,0,7,Color("edd09d"))
				signature_cd = 2
			else:
				game.player_pos = hearth
				game.heal(20)
				hearth = Vector2.ZERO
		"exile":
			zone(pos,200,8,12*power,0,Color("c9d8c7"))
			blast(pos,220,32*power,Color("c9d8c7"))

func within(pos: Vector2, radius: float) -> Array:
	return enemies.filter(func(e): return e.hp > 0 and e.position.distance_to(pos) < radius)

func status_area(pos: Vector2, radius: float, status: String, duration: float) -> void:
	for enemy in within(pos,radius): enemy[status] = duration
	fx("circle",pos,radius,Color(game.class_def.color),.8)

func blast(pos: Vector2, radius: float, damage: float, color: Color, kind: String = "ring") -> void:
	for enemy in within(pos,radius): hit(enemy,damage)
	fx(kind,pos,radius,color,.6)

func line_damage(a: Vector2, b: Vector2, width: float, damage: float) -> void:
	for enemy in enemies:
		if enemy.hp > 0 and Geometry2D.get_closest_point_to_segment(enemy.position,a,b).distance_to(enemy.position) < width:
			hit(enemy,damage)

func fx(kind: String, pos: Vector2, radius: float, color: Color, duration: float, origin: Vector2 = Vector2.ZERO) -> void:
	effects.append({"kind":kind,"position":pos,"radius":radius,"color":color,"time":duration,"duration":duration,"origin":origin})

func zone(pos: Vector2, radius: float, duration: float, damage: float, healing: float, color: Color, slow: bool = false, nullify: bool = false, mana: float = 0) -> void:
	effects.append({"kind":"garden" if game.class_id == "thorn" else "field","position":pos,"radius":radius,"color":color,"time":duration,"duration":duration,"zone":true,"tick":0.0,"damage":damage,"heal":healing,"slow":slow,"null":nullify,"mana":mana})

func delay(pos: Vector2, radius: float, damage: float, time: float) -> void:
	pending.append({"position":pos,"radius":radius,"damage":damage,"time":time})
