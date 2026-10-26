extends Node2D

var game
var art: Texture2D
var atlas: Texture2D
var hero: Texture2D
var clock = 0.0
var camera = Vector2.ZERO
var view_rect = Rect2()
var font: Font
var serif: Font
var foliage_motion = true

func _ready() -> void:
	art = load("res://assets/art/lantern_vale.png")
	atlas = load("res://assets/art/forest_atlas.png")
	hero = load("res://assets/art/wanderer.png")
	font = load("res://assets/fonts/Outfit.ttf")
	serif = load("res://assets/fonts/CormorantGaramond.ttf")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	if game == null or not game.playing: return
	clock += delta
	var target: Vector2 = game.player_pos
	var screen = get_viewport_rect().size
	var bounds: Vector2 = game.zone.size
	target.x = clampf(target.x,screen.x*.5,bounds.x-screen.x*.5)
	target.y = clampf(target.y,screen.y*.5,bounds.y-screen.y*.5)
	camera = camera.lerp(target,1-exp(-delta*7))
	position = (screen*.5-camera).round()
	view_rect = Rect2(-position-Vector2(220,260),screen+Vector2(440,520))
	queue_redraw()

func _draw() -> void:
	if game == null or not game.playing: return
	if game.room_id == 0:
		draw_texture_rect(art,Rect2(Vector2.ZERO,game.zone.size),false)
	else:
		terrain()
		if game.room_id == 3:
			draw_circle(Vector2(1536,660),340,Color("354644"))
			for radius in [130,240,320]:
				draw_arc(Vector2(1536,660),radius,0,TAU,96,Color("8d8765"),2)
			for i in 12:
				var a = i*TAU/12
				draw_line(Vector2(1536,660)+Vector2.from_angle(a)*240,Vector2(1536,660)+Vector2.from_angle(a)*320,Color("8d8765"),2)
	for effect in game.combat.effects:
		if effect.get("zone",false): draw_effect(effect)
	var items: Array = []
	for prop in game.zone.props:
		if view_rect.has_point(prop.position): items.append({"kind":"prop","position":prop.position,"source":prop})
	for object in game.zone.objects:
		if game.changed.has(object.id) and object.kind in ["memory","chest"]: continue
		if view_rect.has_point(object.position): items.append({"kind":"object","position":object.position,"source":object})
	for enemy in game.combat.enemies:
		if enemy.hp > 0 and view_rect.has_point(enemy.position): items.append({"kind":"enemy","position":enemy.position,"source":enemy})
	items.append({"kind":"player","position":game.player_pos})
	items.sort_custom(func(a,b): return a.position.y < b.position.y)
	for item in items:
		match item.kind:
			"prop": prop_sprite(item.source.sprite,item.position,item.source.scale)
			"player": draw_actor(item.position,Color.WHITE,game.animation,game.facing,game.animation_time)
			"enemy": draw_enemy(item.source)
			"object": draw_object(item.source)
	for effect in game.combat.effects:
		if not effect.get("zone",false): draw_effect(effect)
	for point in game.combat.prisms:
		draw_prism(point,Color("c9b3ec"))
	for projectile in game.combat.projectiles:
		draw_circle(projectile.position,15,Color(projectile.color,.12))
		draw_circle(projectile.position,6,projectile.color)
		draw_line(projectile.position,projectile.position-projectile.direction*24,Color(projectile.color,.5),3)
	if game.combat.familiar_time > 0:
		for i in game.combat.familiar_count:
			var p: Vector2 = game.player_pos+Vector2.from_angle(clock*2+i*TAU/game.combat.familiar_count)*65
			prop_sprite(18,p,.25)
	if game.shield > 0:
		draw_arc(game.player_pos-Vector2(0,26),43,0,TAU,40,Color(.6,.85,.87,.45),2)
	ambient_particles()
	for floating in game.floating_texts:
		draw_string(font,floating.position+Vector2(-14,-(1.2-floating.time)*40),floating.text,HORIZONTAL_ALIGNMENT_LEFT,-1,18,Color(floating.color,minf(1,floating.time*2)))
	if not game.nearest_object.is_empty():
		var p: Vector2 = game.nearest_object.position+Vector2(0,-90)
		draw_circle(p,15,Color("142e30"))
		draw_arc(p,15,0,TAU,24,Color("d6bd86"),1)
		draw_string(font,p+Vector2(-5,6),game.key_label("interact"),HORIZONTAL_ALIGNMENT_LEFT,-1,14,Color("eee1bb"))

func terrain() -> void:
	var start = Vector2i(view_rect.position/32)
	var end = Vector2i(view_rect.end/32)
	for y in range(maxi(0,start.y),mini(72,end.y+1)):
		for x in range(maxi(0,start.x),mini(96,end.x+1)):
			var p = Vector2(x*32,y*32)
			var cell: int = game.zone.tiles[y][x]
			var h = absi((x*374761393+y*668265263+game.world_seed)*1274126177)
			var variation = (h%13)/100.0
			match cell:
				0,3:
					var base = Color("274e43") if cell == 0 else Color("15382f")
					draw_rect(Rect2(p,Vector2(32,32)),base.lightened(variation))
					# Tiny native pixel clusters keep the ground continuous between props.
					for i in 4:
						var pp = p+Vector2((h/(i+1))%28,((h/31)/(i+1))%28)
						draw_line(pp,pp+Vector2(1,-4),Color("5b7952"),1)
					if h%11 == 0: draw_rect(Rect2(p+Vector2(11,12),Vector2(2,2)),Color("d1c68a"))
				1:
					draw_rect(Rect2(p,Vector2(32,32)),Color("697660").lightened(variation))
					for i in 3:
						var shift = 5 if (y+i)%2 == 0 else 0
						draw_style_box(stone_style(h+i),Rect2(p+Vector2(shift,i*10+1),Vector2(25,8)))
				2:
					draw_rect(Rect2(p,Vector2(32,32)),Color("155863"))
					var offset = fmod(clock*12+x*7,30)
					draw_line(p+Vector2(offset,12),p+Vector2(minf(offset+10,32),12),Color("4faaa9"),1)
	# Soft canopy shadows add depth without hiding enemy anticipation.
	for prop in game.zone.props:
		if prop.sprite < 6 and view_rect.has_point(prop.position):
			draw_ellipse_shadow(prop.position+Vector2(15,5),Vector2(65,25),.2)

var stone_cache: Dictionary = {}
func stone_style(hash_value: int) -> StyleBoxFlat:
	var k = hash_value%5
	if not stone_cache.has(k):
		var s = StyleBoxFlat.new()
		s.bg_color = Color("9b9a79").darkened(k*.035)
		s.border_color = Color("4f6150")
		s.set_border_width_all(1)
		s.set_corner_radius_all(3)
		stone_cache[k] = s
	return stone_cache[k]

func prop_sprite(index: int, point: Vector2, amount: float = 1.0, tint: Color = Color.WHITE) -> void:
	var cell = atlas.get_size()/Vector2(6,4)
	var src = Rect2(Vector2(index%6,index/6)*cell,cell)
	var side = (220.0 if index < 6 else 132.0)*amount
	var sway = sin(clock*1.4+point.x*.01)*1.2 if index < 6 and foliage_motion else 0.0
	draw_texture_rect_region(atlas,Rect2(point-Vector2(side*.5-sway,side*.91),Vector2(side,side)),src,tint)

func draw_actor(point: Vector2, tint: Color, animation: String = "idle", facing: Vector2 = Vector2.DOWN, remaining: float = 0) -> void:
	draw_ellipse_shadow(point+Vector2(0,4),Vector2(19,7),.3)
	var row = 0
	var frame = int(clock*7)%6
	var flip = false
	match animation:
		"run":
			if absf(facing.x) > absf(facing.y):
				row = 3
				flip = facing.x < 0
			elif facing.y < 0: row = 2
			else: row = 1
		"attack":
			row = 4
			frame = mini(5,int((.3-remaining)*20))
			flip = facing.x < 0
		"cast":
			row = 5
			frame = int(clock*12)%6
		"dodge":
			row = 6
			frame = int(clock*18)%6
			flip = facing.x < 0
		"hurt":
			row = 7
			frame = mini(5,int((.4-remaining)*15))
		_:
			frame = int(clock*2)%2
	var cell = hero.get_size()/Vector2(6,8)
	var src = Rect2(Vector2(clampi(frame,0,5),row)*cell,cell)
	var size = Vector2(98,98)
	if flip:
		size.x = -98
	var rect = Rect2(point-Vector2(49,85)+Vector2(98 if flip else 0,0),size)
	if point == game.player_pos and game.invulnerable > 0:
		tint.a = .55+.35*sin(clock*35)
	draw_texture_rect_region(hero,rect,src,tint)

func draw_object(object: Dictionary) -> void:
	var p: Vector2 = object.position
	if object.kind == "npc":
		var tint = Color("b9b5dd") if object.id == "mira" else (Color("e0c89d") if object.id == "orin" else Color("bac89c"))
		draw_actor(p,tint)
		if object.id == "mira" and game.quest_stage < 2:
			draw_string(serif,p+Vector2(-4,-100),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,31,Color("e7c580"))
	elif object.kind == "exit":
		if object.sprite >= 0: prop_sprite(object.sprite,p,1.5)
		draw_arc(p,28,0,TAU,32,Color(.75,.83,.65,.4+sin(clock*2)*.15),2)
		draw_line(p+Vector2(-8,0),p+Vector2(0,-8),Color("d1dcb7"),2)
		draw_line(p+Vector2(0,-8),p+Vector2(8,0),Color("d1dcb7"),2)
	elif object.kind == "memory":
		prop_sprite(6,p,.65)
		var bob = sin(clock*2+p.x)*5
		draw_circle(p+Vector2(0,-45+bob),5,Color("a9e5d7"))
		draw_arc(p+Vector2(0,-45+bob),13,0,TAU,24,Color(.6,.9,.8,.3),1)
	else:
		prop_sprite(object.sprite,p,1.4 if object.kind == "seal" else .85)
	if game.player_pos.distance_to(p) < 150:
		var width = font.get_string_size(object.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x
		draw_string(font,p+Vector2(-width*.5,28),object.name,HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("e5e5cc"))

func draw_enemy(enemy: Dictionary) -> void:
	var point: Vector2 = enemy.position
	if enemy.windup > 0:
		var radius = 150 if enemy.boss else 65
		draw_circle(enemy.attack_target,radius,Color(.8,.3,.25,.13))
		draw_arc(enemy.attack_target,radius,0,TAU,48,Color(.9,.5,.4,.75),2)
	var bob = sin(clock*3+point.x)*5 if enemy.type in [0,1,3] else sin(clock*2)*1.5
	prop_sprite(18+int(enemy.type),point+Vector2(0,bob),1.55 if enemy.boss else .65,Color(1.7,1.7,1.7) if enemy.flash > 0 else Color.WHITE)
	var width = 110 if enemy.boss else 42
	var y = -175 if enemy.boss else -66
	draw_rect(Rect2(point+Vector2(-width/2.0,y),Vector2(width,4)),Color("172b2a"))
	draw_rect(Rect2(point+Vector2(-width/2.0,y),Vector2(width*maxf(0,enemy.hp/enemy.max_hp),4)),Color("d89b84"))
	if enemy.boss:
		draw_string(serif,point+Vector2(-85,y-12),"The Unremembered Keeper",HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("e5d5b3"))
	if enemy.stun > 0 or enemy.sleep > 0:
		draw_arc(point-Vector2(0,65),14,clock*3,clock*3+4,20,Color("d7c8eb"),2)

func draw_effect(effect: Dictionary) -> void:
	var progress = 1-effect.time/effect.duration
	var p: Vector2 = effect.position
	var r: float = effect.radius
	var c: Color = effect.color
	c.a = minf(1,effect.time*3)*.8
	match effect.kind:
		"slash":
			var direction: Vector2 = effect.origin
			var angle = direction.angle() if direction != Vector2.ZERO else -PI*.5
			draw_arc(p,r*(.6+progress*.4),angle-1.1,angle+1.1,32,c,4)
			for i in 3: draw_arc(p,r*(.45+progress*.4)-i*5,angle-1,angle+.8,28,Color(c,.2),2)
		"line":
			draw_line(effect.origin,p,c,3)
		"decoy","echo":
			draw_actor(p,Color(c,.45))
		"glass":
			for i in 12:
				var shard = p+Vector2.from_angle(i*TAU/12)*r*progress
				draw_prism(shard,Color(c,1-progress))
		"dice":
			draw_arc(p,r*progress,0,TAU,48,c,3)
			var box = Rect2(p-Vector2(18,60+progress*20),Vector2(36,36))
			draw_rect(box,Color("eee0b1"))
			draw_string(font,box.position+Vector2(12,26),str(game.combat.die),HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color("3e3a2f"))
		"garden","field":
			draw_circle(p,r,Color(c,.08))
			draw_arc(p,r,0,TAU,64,Color(c,.4),2)
			for i in 12:
				var q = p+Vector2.from_angle(i*TAU/12+clock*.05)*(r*.75)
				draw_line(q,q+Vector2(4,-10-sin(clock*2+i)*8),Color(c,.5),2)
		_:
			var rr = r*(.45+.55*progress) if not effect.kind in ["portal","circle","star"] else r*minf(1,progress*5)
			draw_arc(p,rr,0,TAU,64,c,2)
			draw_arc(p,rr*.77,clock*.2,TAU+clock*.2,64,Color(c,.5),1)
			for i in 6:
				var a = i*TAU/6+clock*.4
				var q = p+Vector2.from_angle(a)*rr
				draw_line(q,p+Vector2.from_angle(a+TAU/3)*rr,Color(c,.3),1)
				draw_circle(q,3,c)

func draw_prism(point: Vector2, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([point+Vector2(0,-25),point+Vector2(12,0),point+Vector2(0,10),point+Vector2(-12,0)]),Color(color,.45))
	draw_polyline(PackedVector2Array([point+Vector2(0,-25),point+Vector2(12,0),point+Vector2(0,10),point+Vector2(-12,0),point+Vector2(0,-25)]),color,1)

func draw_ellipse_shadow(point: Vector2, size: Vector2, alpha: float) -> void:
	var vertices = PackedVector2Array()
	for i in 24: vertices.append(point+Vector2(cos(i*TAU/24)*size.x,sin(i*TAU/24)*size.y))
	draw_colored_polygon(vertices,Color(0,.03,.03,alpha))

func ambient_particles() -> void:
	for i in 75:
		var p = Vector2(fmod(i*173.7+sin(clock*.2+i)*24,game.zone.size.x),fmod(i*117.3+cos(clock*.3+i)*19,game.zone.size.y))
		if not view_rect.has_point(p): continue
		var alpha = (.2+.25*sin(clock*1.5+i)) if game.settings.flashes else .2
		draw_circle(p,2,Color(.95,.82,.45,maxf(0,alpha)))
		if i%3 == 0: draw_circle(p,8,Color(.95,.82,.4,maxf(0,alpha)*.08))
