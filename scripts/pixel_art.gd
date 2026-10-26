extends RefCounted
## Runtime assembly of credited, human-authored LPC art. No generated imagery.

const BASE = "res://assets/pixel/base/"
var textures: Dictionary = {}
var tile_images: Array[Image] = []

func _init() -> void:
	for name in ["grass","grassalt","dirt","cement","water","mountains","house","treetop","trunk","rock","chests","signs","castlewalls","castle_outside","castlefloors_outside","bridges","soldier","soldier_altcolor","princess","hairmale","slime","bat","bee","ghost","eyeball","pumpking"]:
		textures[name] = load(BASE+name+".png")
	textures["forest"] = load("res://assets/pixel/forest/forest_tiles.png")
	textures["decorations"] = load("res://assets/pixel/decorations/decorations-medieval.png")
	for kind in 8:
		for variant in 4:
			var source: Texture2D = textures.grass
			var rect = Rect2i(32,160,32,32)
			match kind:
				0,3:
					source = textures.grass
					if kind == 0 and variant > 0:
						source = textures.forest
						rect = Rect2i((variant-1)*32,0,32,32)
				1:
					source = textures.dirt
					rect = Rect2i(32,160,32,32)
				2:
					source = textures.water
					rect = Rect2i(32,160,32,32)
				4:
					source = textures.mountains
					rect = Rect2i(192+variant%2*32,64,32,32)
				5:
				source = textures.cement
				rect = Rect2i(32,160,32,32)
				6:
					source = textures.bridges
					rect = Rect2i(160,128,32,32)
				7:
					source = textures.castlefloors_outside
					rect = Rect2i(0,96,32,32)
			tile_images.append(source.get_image().get_region(rect))

func region(canvas: CanvasItem, sheet: String, source: Rect2, target: Rect2, tint: Color = Color.WHITE) -> void:
	canvas.draw_texture_rect_region(textures[sheet],target,source,tint)

func prop(canvas: CanvasItem, index: int, point: Vector2, amount: float = 1.0, tint: Color = Color.WHITE) -> void:
	# Native pixel dimensions stay integral; no AI raster assets or filters.
	var p = point.round()
	match index:
		0,2,3,5:
			region(canvas,"trunk",Rect2(0,0,96,96),Rect2(p-Vector2(48,91),Vector2(96,96)),tint)
			var color = tint
			if index == 3: color = color*Color(.85,.77,1.0)
			if index == 5: color = color*Color(1.0,.9,.6)
			region(canvas,"treetop",Rect2(0,0,96,96),Rect2(p-Vector2(48,156),Vector2(96,96)),color)
		1:
			region(canvas,"treetop",Rect2(0,96,96,128),Rect2(p-Vector2(48,122),Vector2(96,128)),tint)
		4:
			region(canvas,"forest",Rect2(160,0,128,128),Rect2(p-Vector2(64,120),Vector2(128,128)),tint)
		6:
			region(canvas,"decorations",Rect2(0,32,32,64),Rect2(p-Vector2(16,60),Vector2(32,64)),Color(.8,.95,.9)*tint)
		7: house(canvas,p,tint)
		8:
			region(canvas,"decorations",Rect2(0,432,64,80),Rect2(p-Vector2(32,76),Vector2(64,80)),tint)
		9:
			region(canvas,"forest",Rect2(160,96,32,32),Rect2(p-Vector2(16,24),Vector2(32,32)),tint)
		10:
			region(canvas,"castlewalls",Rect2(0,320,128,160),Rect2(p-Vector2(64,156),Vector2(128,160)),tint)
		11:
			canvas.draw_line(p,p-Vector2(0,69),Color("5e4937"),4)
			canvas.draw_line(p-Vector2(0,68),p+Vector2(19,-68),Color("987052"),3)
			region(canvas,"decorations",Rect2(384,32,32,32),Rect2(p+Vector2(3,-65),Vector2(32,32)),tint)
		12:
			region(canvas,"rock",Rect2(0,0,32,32),Rect2(p-Vector2(16,28),Vector2(32,32)),tint)
		13:
			region(canvas,"forest",Rect2(32,96,32,32),Rect2(p-Vector2(16,28),Vector2(32,32)),tint)
		14:
			region(canvas,"signs",Rect2(0,0,32,64),Rect2(p-Vector2(16,60),Vector2(32,64)),tint)
		15:
			region(canvas,"chests",Rect2(0,0,32,32),Rect2(p-Vector2(16,28),Vector2(32,32)),tint)
		16:
			region(canvas,"decorations",Rect2(96,288,64,96),Rect2(p-Vector2(32,90),Vector2(64,96)),tint)
		17:
			region(canvas,"decorations",Rect2(224,1504,64,64),Rect2(p-Vector2(32,54),Vector2(64,64)),tint)

func house(canvas: CanvasItem, p: Vector2, tint: Color = Color.WHITE) -> void:
	# Separate foundations, three-tile facade, roof, door, windows, and eaves.
	# The whole structure sorts at its footprint, so the hero can pass behind it.
	canvas.draw_rect(Rect2(p+Vector2(-62,-8),Vector2(140,18)),Color(0,.03,.03,.22))
	for y in 3:
		for x in 4:
			var sx = 0 if x == 0 else (64 if x == 3 else 32)
			var sy = 0 if y == 0 else (64 if y == 2 else 32)
			region(canvas,"house",Rect2(sx,sy,32,32),Rect2(p+Vector2(-64+x*32,-96+y*32),Vector2(32,32)),tint)
	# Repeated human-drawn shingles and a readable roof thickness.
	for x in 4:
		for y in 2:
			region(canvas,"house",Rect2(128,128+y*32,32,32),Rect2(p+Vector2(-64+x*32,-160+y*32),Vector2(32,32)),tint)
	canvas.draw_rect(Rect2(p+Vector2(-69,-99),Vector2(138,7)),Color("343645"))
	region(canvas,"house",Rect2(96,0,32,64),Rect2(p+Vector2(-16,-64),Vector2(32,64)),tint)
	region(canvas,"house",Rect2(224,0,32,64),Rect2(p+Vector2(-55,-66),Vector2(32,64)),tint)
	region(canvas,"house",Rect2(224,0,32,64),Rect2(p+Vector2(25,-66),Vector2(32,64)),tint)
	canvas.draw_rect(Rect2(p+Vector2(60,-94),Vector2(4,94)),Color(0,0,0,.16))

func actor(canvas: CanvasItem, point: Vector2, tint: Color, animation: String, facing: Vector2, clock: float, remaining: float, npc: String = "") -> void:
	var row = 2
	if absf(facing.x) > absf(facing.y): row = 3 if facing.x > 0 else 1
	elif facing.y < 0: row = 0
	var frame = 0 if animation == "idle" else 1+int(clock*10)%8
	var sheet = "soldier"
	if npc == "mira" or npc == "sella": sheet = "princess"
	elif npc == "orin": sheet = "soldier_altcolor"
	var p = point.round()
	if animation == "dodge":
		for i in 3:
			region(canvas,sheet,Rect2(frame*64,row*64,64,64),Rect2(p-Vector2(32,58)-facing*i*7,Vector2(64,64)),Color(tint,.15-i*.035))
	var bob = 1 if animation == "run" and frame%2 == 0 else 0
	region(canvas,sheet,Rect2(frame*64,row*64,64,64),Rect2(p-Vector2(32,58+bob),Vector2(64,64)),tint)
	if npc == "" or npc == "orin":
		var col = 0 if row == 2 else (1 if row == 0 else 2)
		var width = -40 if row == 1 else 40
		region(canvas,"hairmale",Rect2(col*40,160,40,24),Rect2(p-Vector2(20,51+bob)+Vector2(40 if row == 1 else 0,0),Vector2(width,24)),tint)
	if animation == "attack":
		var angle = facing.angle()+(.3-remaining)*12-1.6
		var hilt = p+Vector2.from_angle(angle)*13-Vector2(0,17)
		canvas.draw_line(hilt,hilt+Vector2.from_angle(angle)*31,Color("ece5d4"),3)
		canvas.draw_line(hilt+Vector2.from_angle(angle+PI/2)*5,hilt-Vector2.from_angle(angle+PI/2)*5,Color("c5a76e"),2)

func enemy(canvas: CanvasItem, index: int, point: Vector2, clock: float, tint: Color, boss: bool) -> void:
	var sheets = ["slime","bat","pumpking","ghost","bee","eyeball"]
	var sheet: String = sheets[index%6]
	var cell = textures[sheet].get_size()/Vector2(3,4)
	var frame = int(clock*7)%3
	var size = cell*(3 if boss else 1)
	region(canvas,sheet,Rect2(Vector2(frame*cell.x,cell.y*2),cell),Rect2(point-Vector2(size.x*.5,size.y*.8),size),tint)
