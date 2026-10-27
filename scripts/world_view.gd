extends Node2D

const PixelArt = preload("res://scripts/pixel_art.gd")
const CHUNK = 16
var game
var art
var clock = 0.0
var camera = Vector2.ZERO
var view_rect = Rect2()
var font: Font
var serif: Font
var preview = true
var chunks: Dictionary = {}
var static_items: Array = []
var water_points: Array[Vector2] = []
var foliage_motion = true
var pixel_scale = 2.0

func _ready() -> void:
	art = PixelArt.new()
	font = load("res://assets/fonts/body.tres")
	serif = load("res://assets/fonts/display.tres")
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	scale = Vector2.ONE*pixel_scale
	modulate = Color.WHITE

func prepare_ground() -> void:
	chunks.clear()
	static_items.clear()
	water_points.clear()
	for y in game.zone.tiles.size():
		for x in game.zone.tiles[y].size():
			if game.zone.tiles[y][x] == 2 and (x+y)%3 == 0: water_points.append(Vector2(x*32+8,y*32+14))
	for prop in game.zone.props:
		static_items.append({"kind":"prop","position":prop.position,"source":prop})
	static_items.sort_custom(func(a,b): return a.position.y < b.position.y)

func _chunk_image(cell: Vector2i) -> Texture2D:
	var image = Image.create(CHUNK*32,CHUNK*32,false,Image.FORMAT_RGBA8)
	var height: int = game.zone.tiles.size()
	var width: int = game.zone.tiles[0].size()
	for yy in CHUNK:
		for xx in CHUNK:
			var x = cell.x*CHUNK+xx
			var y = cell.y*CHUNK+yy
			if x >= width or y >= height: continue
			var tile: int = game.zone.tiles[y][x]
			var variant = (x*3+y*7)%4
			if tile == 4: variant = 0 if y == 0 or int(game.zone.tiles[y-1][x]) != 4 else 1
			image.blit_rect(art.tile_images[tile*4+variant],Rect2i(0,0,32,32),Vector2i(xx*32,yy*32))
	return ImageTexture.create_from_image(image)

func _process(delta: float) -> void:
	if game == null or (not game.playing and not preview) or game.zone.is_empty(): return
	clock += delta
	modulate = Color(.78,.82,1) if game.room_id == 3 and game.playing and not game.changed.has("seal_resolved") else Color.WHITE
	var target: Vector2 = game.player_pos if game.playing else Vector2(670+sin(clock*.045)*45,485+cos(clock*.04)*25)
	var screen = get_viewport_rect().size/pixel_scale
	var bounds: Vector2 = game.zone.size
	target.x = clampf(target.x,screen.x*.5,bounds.x-screen.x*.5)
	target.y = clampf(target.y,screen.y*.5,bounds.y-screen.y*.5)
	camera = camera.lerp(target,1-exp(-delta*7))
	position = ((screen*.5-camera)*pixel_scale).round()
	view_rect = Rect2(-position/pixel_scale-Vector2(130,180),screen+Vector2(260,360))
	queue_redraw()

func _draw() -> void:
	if art == null or game == null or game.zone.is_empty(): return
	if not game.playing and not preview: return
	terrain()
	if game.room_id == 3 and game.playing:
		var arena = Vector2(496,400)
		draw_circle(arena,170,Color(.25,.29,.26,.08))
		for radius in [82,144,170]: draw_arc(arena,radius,0,TAU,64,Color("a39665"),1)
		for i in 12:
			var a = i*TAU/12
			draw_line(arena+Vector2.from_angle(a)*144,arena+Vector2.from_angle(a)*170,Color("a39665"),1)
	for hazard in game.combat.hazards:
		var tint = Color("d3a178") if hazard.kind == "root" else Color("93cfe8")
		draw_circle(hazard.position,hazard.radius,Color(tint,.13))
		draw_arc(hazard.position,hazard.radius,0,TAU,32,tint,1)
		draw_arc(hazard.position,hazard.radius*.8,-PI*.5,-PI*.5+TAU*(1-hazard.time/hazard.duration),32,tint,2)
	for effect in game.combat.effects:
		if game.playing and effect.get("zone",false): draw_effect(effect)
	var items: Array = []
	for prop in static_items:
		if view_rect.has_point(prop.position): items.append(prop)
	for object in game.zone.objects:
		if game.changed.has(object.id) and object.kind in ["memory","chest"]: continue
		if view_rect.has_point(object.position): items.append({"kind":"object","position":object.position,"source":object})
	if game.playing:
		for enemy in game.combat.enemies:
			if enemy.hp > 0 and view_rect.has_point(enemy.position): items.append({"kind":"enemy","position":enemy.position,"source":enemy})
		items.append({"kind":"player","position":game.player_pos})
		if game.companions != null and game.companions.active() >= 0:
			items.append({"kind":"pet","position":game.companions.position})
	items.sort_custom(func(a,b): return a.position.y < b.position.y)
	for item in items:
		match item.kind:
			"prop":
				var tint = Color.WHITE
				var cover_width = 64 if item.source.sprite in [2,7] else 32
				var cover_height = 168 if item.source.sprite == 2 else (137 if item.source.sprite == 7 else 84)
				if item.source.sprite in [24,25,26]:
					cover_width = 110 if item.source.sprite == 26 else 75
					cover_height = 168 if item.source.sprite == 26 else 136
				# Trees and roofs fade only when they actually cover the hero.
				if game.playing and (item.source.sprite < 8 or item.source.sprite in [24,25,26]) and absf(item.position.x-game.player_pos.x) < cover_width and game.player_pos.y < item.position.y and game.player_pos.y > item.position.y-cover_height: tint.a = .48
				if item.source.sprite != 13:
					var shadow_size = Vector2(46,7) if item.source.sprite == 7 else (Vector2(20,7) if item.source.sprite < 6 else Vector2(12,4))
					if item.source.sprite in [24,25,26]: shadow_size = Vector2(80 if item.source.sprite == 26 else 57,8)
					draw_ellipse_shadow(item.position+Vector2(4,1),shadow_size,.15)
				prop_sprite(item.source.sprite,item.position,item.source.scale,tint)
				if item.source.sprite == 11:
					for radius in [10,16,24]: draw_circle(item.position+Vector2(15,-29),radius,Color(1,.78,.42,.025))
			"player": draw_actor(item.position,Color.WHITE,game.animation,game.facing,game.animation_time)
			"pet":
				draw_ellipse_shadow(item.position,Vector2(10,3),.2)
				art.enemy(self,game.companions.active(),item.position,clock,Color("b8ffe4"),false)
				draw_string(font,item.position+Vector2(-12,-34),"ALLY",HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("b8ffe4"))
			"enemy": draw_enemy(item.source)
			"object": draw_object(item.source)
	if game.playing:
		for effect in game.combat.effects:
			if not effect.get("zone",false): draw_effect(effect)
		for point in game.combat.prisms: draw_prism(point,Color("c9b3ec"))
		for projectile in game.combat.projectiles:
			draw_projectile(projectile)
		if game.combat.familiar_time > 0:
			for i in game.combat.familiar_count:
				var p: Vector2 = game.player_pos+Vector2.from_angle(clock*2+i*TAU/game.combat.familiar_count)*45
				art.enemy(self,4,p,clock,Color.WHITE,false)
		if game.shield > 0: draw_arc(game.player_pos-Vector2(0,22),30,0,TAU,32,Color(.6,.85,.87,.5),1)
		for floating in game.floating_texts:
			draw_string(font,floating.position+Vector2(-7,-(1.2-floating.time)*24),floating.text,HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color(floating.color,minf(1,floating.time*2)))
		if not game.nearest_object.is_empty():
			var p: Vector2 = game.nearest_object.position+Vector2(0,-75)
			draw_circle(p,10,Color("142e30"))
			draw_arc(p,10,0,TAU,20,Color("d6bd86"),1)
			draw_string(font,p+Vector2(-3,4),game.key_label("interact"),HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("eee1bb"))
	ambient_particles()

func terrain() -> void:
	var start = Vector2i(Vector2(maxf(0,view_rect.position.x),maxf(0,view_rect.position.y))/(CHUNK*32))
	var end = Vector2i(view_rect.end/(CHUNK*32))
	var rows = ceili(game.zone.tiles.size()/float(CHUNK))
	var columns = ceili(game.zone.tiles[0].size()/float(CHUNK))
	var active: Dictionary = {}
	for y in range(start.y,mini(rows,end.y+1)):
		for x in range(start.x,mini(columns,end.x+1)):
			var cell = Vector2i(x,y)
			active[cell] = true
			if not chunks.has(cell): chunks[cell] = _chunk_image(cell)
			draw_texture(chunks[cell],Vector2(cell)*(CHUNK*32))
	for cell in chunks.keys():
		if not active.has(cell): chunks.erase(cell)
	# Discrete ripples are cheap and preserve the original pixel-art water.
	if game.settings.flashes:
		for point in water_points:
			if view_rect.has_point(point):
				var p = point+Vector2(int(sin(clock*1.5+point.y)*2),0)
				draw_line(p,p+Vector2(7,0),Color(.7,.91,.87,.5),1)

func prop_sprite(index: int, point: Vector2, amount: float = 1.0, tint: Color = Color.WHITE) -> void:
	art.prop(self,index,point,amount,tint)

func draw_actor(point: Vector2, tint: Color, animation: String = "idle", facing: Vector2 = Vector2.DOWN, remaining: float = 0) -> void:
	draw_ellipse_shadow(point,Vector2(12,4),.25)
	if game.playing and point == game.player_pos and game.invulnerable > 0 and game.invulnerable < 5: tint.a = .65
	art.actor(self,point,tint,animation,facing,clock,remaining,"","star" if game.armor == "plate" else ("hybrid" if game.armor == "leather" else "circle"))

func draw_object(object: Dictionary) -> void:
	var p: Vector2 = object.position
	if object.kind == "npc":
		var tint = Color("e7e2f4") if object.id == "mira" else (Color("efddbd") if object.id == "orin" else Color("d4e1bb"))
		draw_ellipse_shadow(p,Vector2(12,4),.2)
		art.actor(self,p,tint,"run" if object.get("moving",false) else "idle",object.get("facing",Vector2.DOWN),clock,0,object.id)
		if object.id == "mira" and game.quest_stage < 2: draw_string(serif,p+Vector2(-3,-62),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("e7c580"))
	elif object.kind == "exit":
		if object.sprite >= 0: prop_sprite(object.sprite,p)
		draw_arc(p,18,0,TAU,24,Color(.75,.83,.65,.45),1)
		draw_line(p+Vector2(-5,0),p+Vector2(0,-5),Color("d1dcb7"),1)
		draw_line(p+Vector2(0,-5),p+Vector2(5,0),Color("d1dcb7"),1)
	elif object.kind == "memory":
		prop_sprite(6,p)
		draw_circle(p+Vector2(0,-38+sin(clock*2+p.x)*3),3,Color("a9e5d7"))
	else:
		prop_sprite(object.sprite,p)
	if object.kind in ["rest","ritual"]:
		for radius in [15,25,38]: draw_circle(p-Vector2(0,42),radius,Color(1,.76,.32,.018))
	if game.playing and game.player_pos.distance_to(p) < 100:
		var text_width = font.get_string_size(object.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9).x
		draw_string(font,p+Vector2(-text_width*.5,16),object.name,HORIZONTAL_ALIGNMENT_LEFT,-1,9,Color("e5e5cc"))

func draw_enemy(enemy: Dictionary) -> void:
	var point: Vector2 = enemy.position
	if enemy.windup > 0 and not enemy.boss:
		var radius: float = enemy.attack_radius
		draw_circle(enemy.attack_target,radius,Color(.8,.3,.25,.13))
		draw_arc(enemy.attack_target,radius,0,TAU,40,Color(.9,.5,.4,.75),1)
	art.enemy(self,enemy.type,point,clock,Color(1.4,1.4,1.4) if enemy.flash > 0 else Color.WHITE,enemy.boss,enemy.windup)
	var width = 90 if enemy.boss else 28
	var y = -76 if enemy.boss else -34
	draw_rect(Rect2(point+Vector2(-width/2.0,y),Vector2(width,2)),Color("172b2a"))
	draw_rect(Rect2(point+Vector2(-width/2.0,y),Vector2(width*maxf(0,enemy.hp/enemy.max_hp),2)),Color("d89b84"))
	if enemy.boss:
		var title: String = enemy.get("name","The Unremembered Keeper")
		var title_width = serif.get_string_size(title,HORIZONTAL_ALIGNMENT_LEFT,-1,16).x
		draw_rect(Rect2(point+Vector2(-title_width*.5-5,y-25),Vector2(title_width+10,21)),Color("20253a"))
		draw_string(serif,point+Vector2(-title_width*.5,y-9),title,HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("e5d5b3"))
	var statuses: Array[String] = []
	for status in ["poison","burn","weak","slow","bound","mark","repeat"]:
		if enemy[status] > 0: statuses.append(status.to_upper())
	if not statuses.is_empty():
		var caption = " / ".join(statuses)
		draw_string(font,point+Vector2(-30,14),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,8,Color("20253a"))
	if enemy.stun > 0 or enemy.sleep > 0: draw_arc(point-Vector2(0,42),9,clock*3,clock*3+4,16,Color("d7c8eb"),1)

func draw_projectile(projectile: Dictionary) -> void:
	var p: Vector2 = projectile.position.round()
	var c: Color = projectile.color
	var kind: String = projectile.get("kind", "circle")
	draw_line(p,p-projectile.direction*18,Color(c,.4),2)
	match kind:
		"luck":
			draw_rect(Rect2(p-Vector2(5,5),Vector2(10,10)),Color("30364f"))
			draw_rect(Rect2(p-Vector2(4,4),Vector2(8,8)),c)
			for offset in [Vector2(-2,-2),Vector2(2,2),Vector2(-2,2)]: draw_rect(Rect2(p+offset,Vector2(2,2)),Color("30364f"))
		"glass", "thorn":
			var diamond = PackedVector2Array([p+Vector2(0,-8),p+Vector2(4,0),p+Vector2(0,8),p+Vector2(-4,0)])
			draw_colored_polygon(diamond,c)
			draw_line(p-Vector2(0,6),p+Vector2(0,6),Color("f4e5c2"),1)
		"ash", "paradox":
			if projectile.get("status", "") == "slow": c = Color("a9d8ef")
			var flame = PackedVector2Array([p+Vector2(-4,3),p+Vector2(-3,-3),p+Vector2(0,-8),p+Vector2(2,-2),p+Vector2(5,-4),p+Vector2(4,4),p+Vector2(0,6)])
			draw_colored_polygon(flame,c)
			draw_rect(Rect2(p-Vector2(1,1),Vector2(3,5)),Color("fff0bf"))
		"ink":
			draw_rect(Rect2(p-Vector2(3,5),Vector2(6,10)),c)
			draw_line(p+Vector2(-2,-4),p+Vector2(2,3),Color("f0d4ed"),1)
		_:
			draw_rect(Rect2(p-Vector2(3,3),Vector2(6,6)),c)
			draw_rect(Rect2(p-Vector2(1,1),Vector2(2,2)),Color("fff0cf"))

func draw_effect(effect: Dictionary) -> void:
	var progress = 1-effect.time/effect.duration
	var p: Vector2 = effect.position
	var r: float = effect.radius
	var c: Color = effect.color
	c.a = minf(1,effect.time*3)*.8
	match effect.kind:
		"impact", "defeat":
			var count = 8 if effect.kind == "defeat" else 4
			for i in count:
				var q = (p+Vector2.from_angle(i*TAU/count)*r*progress*.65).round()
				draw_rect(Rect2(q,Vector2.ONE*(3 if effect.kind == "defeat" else 2)),c)
		"ring", "rune":
			draw_arc(p,r*(.4+progress*.6),0,TAU,32,Color(c,.5 if effect.kind == "rune" else .85),1)
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
			for i in 6:
				var shard = p+Vector2.from_angle(i*TAU/6)*r*progress
				draw_prism(shard,Color(c,1-progress))
		"portal":
			var shape = PackedVector2Array()
			var inner = PackedVector2Array()
			for i in 49:
				var angle = i*TAU/48
				shape.append((p+Vector2(cos(angle)*r*.36,sin(angle)*r*.68)-Vector2(0,22)).round())
				inner.append((p+Vector2(cos(angle)*r*.29,sin(angle)*r*.6)-Vector2(0,22)).round())
			draw_colored_polygon(shape,Color(c,.1))
			draw_polyline(shape,c,2)
			draw_polyline(inner,Color(c,.5),1)
			for i in 8:
				var angle = i*TAU/8+clock*.5
				draw_rect(Rect2((p+Vector2(cos(angle)*r*.42,sin(angle)*r*.73)-Vector2(0,22)).round(),Vector2(2,2)),c)
		"star":
			var points = PackedVector2Array()
			for i in 11:
				var angle = i*TAU/10-PI/2+progress*.3
				points.append((p+Vector2.from_angle(angle)*r*(.43 if i%2 else .86)).round())
			draw_polyline(points,c,2)
			for i in game.rank:
				var q = p+Vector2((i-(game.rank-1)*.5)*15,-r*.9)
				draw_line(q-Vector2(0,4),q+Vector2(0,4),c,1)
				draw_line(q-Vector2(4,0),q+Vector2(4,0),c,1)
		"circle":
			var rr = r*minf(1,progress*5)
			for i in game.rank: draw_arc(p,rr*(1-i*.18),0,TAU,64,Color(c,1-i*.16),1 if i else 2)
			for i in 3:
				var angle = i*TAU/3+clock*.3
				draw_line(p+Vector2.from_angle(angle)*rr*.8,p+Vector2.from_angle(angle+TAU/3)*rr*.8,Color(c,.5),1)
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
