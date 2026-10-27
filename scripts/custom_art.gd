extends RefCounted
## Draw editable original pixel patterns and deliberate animation poses.
const ROOT = "res://assets/custom/"
var textures: Dictionary = {}
var tile_images: Array[Image] = []

func _init() -> void:
	for name in ["terrain","tree","pine","house","house_green","house_rose","creatures","guardian","memory_stone","lantern","stump","flowers","board","chest","ruin","fence","bench","stall","wanderer_cloth","wanderer_plate","wanderer_leather","mira","orin","sella"]:
		textures[name] = load(ROOT+name+".png")
	textures["guardian_anim"] = load(ROOT+"guardian_anim.png")
	textures["briar_crown"] = load(ROOT+"briar_crown.png")
	textures["tide_bell"] = load(ROOT+"tide_bell.png")
	for name in ["root_gate","bell_chapel","observatory_dome"]: textures[name] = load(ROOT+name+".png")
	var terrain: Image = textures.terrain.get_image()
	for index in 36: tile_images.append(terrain.get_region(Rect2i(index%8*32,index/8*32,32,32)))

func draw_region(canvas: CanvasItem, name: String, source: Rect2, target: Rect2, tint: Color = Color.WHITE) -> void:
	canvas.draw_texture_rect_region(textures[name],target,source,tint)

func prop(canvas: CanvasItem, index: int, position: Vector2, _amount: float = 1, tint: Color = Color.WHITE) -> void:
	var p = position.round()
	var name = "flowers"
	var origin = Vector2(16,20)
	var dimensions = Vector2(32,24)
	match index:
		0,3,5:
			name = "tree"
			origin = Vector2(32,84)
			dimensions = Vector2(64,88)
			if index == 3: tint *= Color(.93,.87,1)
			if index == 5: tint *= Color(1,.95,.8)
		1:
			name = "pine"
			origin = Vector2(24,76)
			dimensions = Vector2(48,80)
		2:
			name = "tree"
			origin = Vector2(64,168)
			dimensions = Vector2(128,176)
		4,12:
			name = "stump"
			origin = Vector2(16,27)
			dimensions = Vector2(32,32)
		6:
			name = "memory_stone"
			origin = Vector2(12,37)
			dimensions = Vector2(24,40)
		7:
			name = ["house","house_green","house_rose"][int(position.x/32)%3]
			origin = Vector2(64,137)
			dimensions = Vector2(128,144)
		8:
			name = "memory_stone"
			origin = Vector2(18,54)
			dimensions = Vector2(36,60)
		10,16:
			name = "ruin"
			origin = Vector2(48,106)
			dimensions = Vector2(96,112)
		11,17:
			name = "lantern"
			origin = Vector2(9,59)
			dimensions = Vector2(32,64)
		14:
			name = "board"
			origin = Vector2(20,52)
			dimensions = Vector2(40,56)
		15:
			name = "chest"
			origin = Vector2(16,28)
			dimensions = Vector2(32,32)
	if index == 20:
		name = "fence"; origin = Vector2(16,35); dimensions = Vector2(32,40)
	if index == 21:
		name = "bench"; origin = Vector2(24,29); dimensions = Vector2(48,32)
	if index == 22:
		name = "stall"; origin = Vector2(36,74); dimensions = Vector2(72,80)
	if index == 24:
		name = "root_gate"; origin = Vector2(80,136); dimensions = Vector2(160,144)
	if index == 25:
		name = "bell_chapel"; origin = Vector2(72,136); dimensions = Vector2(144,144)
	if index == 26:
		name = "observatory_dome"; origin = Vector2(112,168); dimensions = Vector2(224,176)
	if index in [0,2,3,5]:
		var factor = 2.0 if index == 2 else 1.0
		var sway = 1 if sin(float(canvas.get("clock"))*1.2+p.x*.01) > .8 else 0
		draw_region(canvas,"tree",Rect2(0,56,64,32),Rect2(p-Vector2(32,28)*factor,Vector2(64,32)*factor),tint)
		draw_region(canvas,"tree",Rect2(0,0,64,57),Rect2(p-Vector2(32,84)*factor+Vector2(sway*factor,0),Vector2(64,57)*factor),tint)
	else:
		canvas.draw_texture_rect(textures[name],Rect2(p-origin,dimensions),false,tint)

func actor(canvas: CanvasItem, point: Vector2, tint: Color, animation: String, facing: Vector2, clock: float, remaining: float, npc: String = "", discipline: String = "circle") -> void:
	var direction = 0
	if absf(facing.x) > absf(facing.y): direction = 2 if facing.x > 0 else 1
	elif facing.y < 0: direction = 3
	var row = direction
	var frame = int(clock*8)%4 if animation == "run" else (4 if sin(clock+point.x*.01) > .97 else 0)
	match animation:
		"attack":
			row += 4
			frame = clampi(int((.3-remaining)*20),0,5)
		"cast":
			row += 8
			frame = int(clock*10)%6
		"dodge":
			row += 12
			frame = int(clock*18)%4
		"hurt":
			row += 16
			frame = int(clock*10)%2
	var name = npc if npc != "" else ("wanderer_plate" if discipline == "star" else ("wanderer_leather" if discipline == "hybrid" else "wanderer_cloth"))
	var p = point.round()
	if animation == "dodge":
		for i in 3:
			draw_region(canvas,name,Rect2(frame*48,row*48,48,48),Rect2(p-Vector2(24,39)-facing*i*6,Vector2(48,48)),Color(tint,.12-i*.03))
	draw_region(canvas,name,Rect2(frame*48,row*48,48,48),Rect2(p-Vector2(24,39),Vector2(48,48)),tint)

func enemy(canvas: CanvasItem, kind: int, point: Vector2, clock: float, tint: Color, boss: bool, windup: float = 0) -> void:
	if boss:
		var row = 1 if windup > 0 else 0
		var frame = clampi(int((1.2-windup)*2.5),0,2) if windup > 0 else int(clock*2)%3
		draw_region(canvas,"briar_crown" if kind == 6 else ("tide_bell" if kind == 7 else "guardian_anim"),Rect2(frame*48,row*64,48,64),Rect2(point-Vector2(24,60),Vector2(48,64)),tint)
	else:
		var frame = int(clock*6)%4
		draw_region(canvas,"creatures",Rect2(frame*24,(kind%5)*32,24,32),Rect2(point-Vector2(12,27),Vector2(24,32)),tint)
