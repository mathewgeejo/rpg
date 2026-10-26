extends RefCounted

const GENERATOR_VERSION = 1
const TILE = 32
const WIDTH = 96
const HEIGHT = 72
const TOWN_NAMES = ["Lanternwick", "Willowrest", "Glasshaven", "Tide's End", "Rainmarket", "Cinderwake", "Upfall", "Cloudroot", "Brinehold", "Crownless", "The Commons", "Lastlight"]

var world_seed: int = 731904
var graph: Dictionary = {}
var rooms: Dictionary = {}

func _init(seed_value: int = 731904) -> void:
	world_seed = seed_value
	graph = generate_graph()

func generate_graph() -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed
	var towns: Array = []
	var region_for_town = [0,0,1,1,2,3,4,4,5,6,6,7]
	for i in 12:
		towns.append({"id":"town_%02d" % i, "name":TOWN_NAMES[i], "region":region_for_town[i], "x":0.0, "y":0.0})
	var positions = [Vector2(.18,.72),Vector2(.27,.63),Vector2(.17,.43),Vector2(.28,.32),Vector2(.41,.51),Vector2(.49,.74),Vector2(.54,.28),Vector2(.66,.18),Vector2(.76,.42),Vector2(.72,.67),Vector2(.83,.72),Vector2(.86,.22)]
	for i in towns.size():
		towns[i].x = positions[i].x
		towns[i].y = positions[i].y
	var routes: Array = []
	var edges: Dictionary = {}
	# A connected spine is reserved before any optional links are sampled.
	for i in 11:
		_add_edge(routes, edges, i, i+1, rng)
	while routes.size() < 30:
		var a = rng.randi_range(0,11)
		var b = rng.randi_range(0,11)
		if a != b:
			_add_edge(routes, edges, a, b, rng)
	var dungeons: Array = []
	for i in 12:
		dungeons.append({"id":"dungeon_%02d" % i,"town":i,"region":region_for_town[i],"seed":rng.randi(),"name":["The Unremembered Observatory","The Root Chapel","Mirror Undertow","The Consent Vault","The Patient Garden","The Silent Belfry","The Falling Citadel","The Stair Without End","The Drowned Index","The Vacant Court","The Common Tomb","The First Absence"][i]})
	return {"seed":world_seed,"version":GENERATOR_VERSION,"towns":towns,"routes":routes,"dungeons":dungeons}

func _add_edge(routes: Array, edges: Dictionary, a: int, b: int, rng: RandomNumberGenerator) -> void:
	var key = "%d:%d" % [mini(a,b),maxi(a,b)]
	if edges.has(key):
		return
	edges[key] = true
	routes.append({"id":"route_%02d" % routes.size(),"from":a,"to":b,"seed":rng.randi()})

func room(index: int) -> Dictionary:
	if rooms.has(index):
		return rooms[index]
	var result = _town() if index == 0 else _wilderness(index)
	rooms[index] = result
	return result

func _town() -> Dictionary:
	return {"id":0,"name":"Lanternwick", "subtitle":"LANTERN VALE · A TOWN HELD IN MEMORY", "size":Vector2(2304,1536),"spawn":Vector2(1080,1150),"tiles":[],"props":[],"enemies":[],"objects":[
		{"id":"mira","kind":"npc","name":"Mira · Cartographer","position":Vector2(1020,850),"sprite":-1},
		{"id":"orin","kind":"npc","name":"Orin · Lantern keeper","position":Vector2(710,760),"sprite":-1},
		{"id":"sella","kind":"npc","name":"Sella · Gardener","position":Vector2(1220,1120),"sprite":-1},
		{"id":"lantern","kind":"rest","name":"Rest at the lantern","position":Vector2(1320,1020),"sprite":11},
		{"id":"exit_1","kind":"exit","name":"Wispwood Path","position":Vector2(1100,1400),"to":1,"sprite":-1},
		{"id":"ritual","kind":"ritual","name":"The Remembering Stone","position":Vector2(1300,650),"sprite":6}
	]}

func _wilderness(index: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed + index * 104729
	var tiles: Array = []
	var path_x: Array = []
	var drift = rng.randf_range(-2,2)
	for y in HEIGHT:
		path_x.append(WIDTH/2 + int(sin(y*.105 + drift)*9.0))
	for y in HEIGHT:
		var row: Array = []
		for x in WIDTH:
			var border = x < 3 or y < 2 or x >= WIDTH-3 or y >= HEIGHT-2
			var tile = 3 if border else 0
			if absi(x-path_x[y]) <= 3:
				tile = 1
			if index == 2 and x > 65 and x < 73 and y > 8 and y < 63:
				tile = 2
			if index == 2 and y > 32 and y < 37:
				tile = 1
			row.append(tile)
		tiles.append(row)
	var start = Vector2(path_x[HEIGHT-5]*TILE+16,(HEIGHT-5)*TILE+16)
	var finish = Vector2(path_x[5]*TILE+16,5*TILE+16)
	var props: Array = []
	var enemies: Array = []
	for y in range(4,HEIGHT-3,3):
		for x in range(4,WIDTH-3,3):
			if absi(x-path_x[y]) > 6 and tiles[y][x] == 0 and rng.randf() < .59:
				var sprite = rng.randi_range(0,4) if rng.randf() < .76 else [6,9,12,13,14][rng.randi_range(0,4)]
				props.append({"sprite":sprite,"position":Vector2(x*TILE+rng.randf_range(-15,15),y*TILE+rng.randf_range(-15,15)),"scale":rng.randf_range(.72,1.12)})
	for i in (10 if index != 3 else 5):
		var y = rng.randi_range(12,HEIGHT-14)
		var x = path_x[y] + rng.randi_range(-5,5)
		enemies.append({"id":"r%d_e%d" % [index,i],"position":Vector2(x*TILE,y*TILE),"type":rng.randi_range(0,3),"boss":false})
	var objects: Array = [
		{"id":"back_%d" % index,"kind":"exit","name":"Return to Lanternwick" if index == 1 else "Previous trail","position":start,"to":index-1,"sprite":-1},
		{"id":"rest_%d" % index,"kind":"rest","name":"Wayfarer's lantern","position":start+Vector2(100,-110),"sprite":11}
	]
	if index < 3:
		objects.append({"id":"exit_%d" % (index+1),"kind":"exit","name":"Stonewater Crossing" if index == 1 else "The Unremembered Observatory","position":finish,"to":index+1,"sprite":16})
		for i in 3:
			var yy = 17+i*17
			objects.append({"id":"memory_%d_%d" % [index,i],"kind":"memory","name":"A memory without an owner","position":Vector2((path_x[yy]+5)*TILE,yy*TILE),"sprite":6})
		objects.append({"id":"chest_%d" % index,"kind":"chest","name":"Forgotten satchel","position":Vector2((path_x[30]-5)*TILE,30*TILE),"sprite":15})
	else:
		# A fixed, obstacle-free arena protects the authored story sequence.
		for y in range(12,35):
			for x in range(32,65):
				tiles[y][x] = 1
		props = props.filter(func(p): return not Rect2(960,320,1180,900).has_point(p.position))
		enemies.append({"id":"the_keeper","position":Vector2(1536,660),"type":5,"boss":true})
		objects.append({"id":"seal","kind":"seal","name":"The Observatory Seal","position":Vector2(1536,470),"sprite":16})
		objects.append({"id":"home","kind":"exit","name":"Follow the lanterns home","position":finish,"to":0,"sprite":10})
	return {"id":index,"name":["", "Wispwood Path", "Stonewater Crossing", "The Unremembered Observatory"][index],"subtitle":["", "LANTERN VALE · THE WILDERNESS REMEMBERS", "LANTERN VALE · WHERE TWO STORIES MEET", "LANTERN VALE · THE FIRST SEAL"][index],"size":Vector2(WIDTH*TILE,HEIGHT*TILE),"spawn":start+Vector2(0,-90),"finish":finish,"tiles":tiles,"props":props,"enemies":enemies,"objects":objects}

func walkable(index: int, point: Vector2) -> bool:
	var zone = room(index)
	if point.x < 40 or point.y < 40 or point.x > zone.size.x-40 or point.y > zone.size.y-40:
		return false
	if index == 0:
		var corridors = [Rect2(890,240,370,1250),Rect2(680,520,640,510),Rect2(420,1050,1460,350),Rect2(1170,650,980,200),Rect2(1100,850,430,380),Rect2(1180,90,160,350)]
		for corridor in corridors:
			if corridor.has_point(point):
				return true
		return false
	var cell = Vector2i(point/TILE)
	var tile: int = zone.tiles[cell.y][cell.x]
	if tile == 2 or tile == 3:
		return false
	# Only the trunk's footprint blocks; canopy overlap remains walkable.
	for prop in zone.props:
		if int(prop.sprite) < 7 and point.distance_squared_to(prop.position) < 22.0*22.0:
			return false
	return true

func reachable(index: int) -> bool:
	var zone = room(index)
	if index == 0:
		return true
	var origin = Vector2i(zone.spawn/TILE)
	var queue: Array[Vector2i] = [origin]
	var seen: Dictionary = {origin:true}
	var cursor = 0
	while cursor < queue.size():
		var cell = queue[cursor]
		cursor += 1
		for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+delta
			if next.x < 0 or next.y < 0 or next.x >= WIDTH or next.y >= HEIGHT or seen.has(next):
				continue
			if walkable(index, Vector2(next)*TILE+Vector2(16,16)):
				seen[next] = true
				queue.append(next)
	for object in zone.objects:
		var target = Vector2i(object.position/TILE)
		var near = false
		for y in range(-2,3):
			for x in range(-2,3):
				if seen.has(target+Vector2i(x,y)):
					near = true
		if not near:
			return false
	return true
