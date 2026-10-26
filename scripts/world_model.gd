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
	var collision: Dictionary = {}
	for prop in result.props:
		if int(prop.sprite) < 7:
			var cell = Vector2i(prop.position/TILE)
			if not collision.has(cell): collision[cell] = []
			collision[cell].append(prop.position)
	result["collision"] = collision
	rooms[index] = result
	return result

func _town() -> Dictionary:
	var tiles: Array = []
	var props: Array = []
	var rng = RandomNumberGenerator.new()
	rng.seed = 18391
	for y in 48:
		var row: Array = []
		for x in 72:
			var tile = 0
			if x < 2 or y < 2 or x > 69 or y > 45: tile = 3
			if (x >= 31 and x <= 37) or (y >= 25 and y <= 29 and x > 13 and x < 65) or (y >= 34 and y <= 37 and x > 16 and x < 43): tile = 1
			if x >= 58 and x <= 61: tile = 2
			if y >= 26 and y <= 28 and x >= 57 and x <= 62: tile = 6
			# A genuine raised terrace, with a two-tile exposed cliff face.
			if x >= 45 and x <= 56 and y >= 6 and y <= 16: tile = 5
			if x >= 45 and x <= 56 and y >= 17 and y <= 18: tile = 4
			if x >= 49 and x <= 51 and y >= 16 and y <= 20: tile = 7
			row.append(tile)
		tiles.append(row)
	for p in [Vector2(830,850),Vector2(830,1160),Vector2(1380,920),Vector2(1100,650),Vector2(1430,1190)]:
		props.append({"sprite":7,"position":p,"scale":1.0})
	props.append({"sprite":8,"position":Vector2(1140,790),"scale":1.0})
	props.append({"sprite":10,"position":Vector2(1620,390),"scale":1.0})
	for p in [Vector2(960,700),Vector2(1250,750),Vector2(1450,1000),Vector2(830,1300)]:
		props.append({"sprite":0,"position":p,"scale":1.0})
	for y in range(3,46,3):
		for x in range(3,69,3):
			var point = Vector2(x*32+rng.randi_range(-10,10),y*32+rng.randi_range(-10,10))
			var clear = false
			for prop in props:
				if prop.sprite == 7 and point.distance_to(prop.position-Vector2(0,60)) < 150: clear = true
			if (x < 15 or x > 63 or y < 5 or y > 42) and not clear and tiles[y][x] in [0,3]:
				props.append({"sprite":rng.randi_range(0,3),"position":point,"scale":1.0})
			elif tiles[y][x] == 0 and not clear and rng.randf() < .21 and absi(x-34) > 7:
				props.append({"sprite":13 if rng.randf() < .6 else 0,"position":point,"scale":1.0})
	for p in [Vector2(900,980),Vector2(1280,1200),Vector2(950,600),Vector2(1410,930),Vector2(1930,900)]:
		props.append({"sprite":11,"position":p,"scale":1.0})
	return {"id":0,"name":"Lanternwick", "subtitle":"LANTERN VALE · A TOWN HELD IN MEMORY", "size":Vector2(2304,1536),"spawn":Vector2(1100,1050),"tiles":tiles,"props":props,"enemies":[],"objects":[
		{"id":"mira","kind":"npc","name":"Mira · Cartographer","position":Vector2(1020,850),"sprite":-1},
		{"id":"orin","kind":"npc","name":"Orin · Lantern keeper","position":Vector2(850,900),"sprite":-1},
		{"id":"sella","kind":"npc","name":"Sella · Gardener","position":Vector2(1220,1120),"sprite":-1},
		{"id":"lantern","kind":"rest","name":"Rest at the lantern","position":Vector2(1320,1020),"sprite":11},
		{"id":"exit_1","kind":"exit","name":"Wispwood Path","position":Vector2(1100,1400),"to":1,"sprite":-1},
		{"id":"ritual","kind":"ritual","name":"The Remembering Stone","position":Vector2(1300,650),"sprite":6}
		,{"id":"board","kind":"board","name":"Wayfarer's commissions","position":Vector2(1200,940),"sprite":14}
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
	# Terraces are kept well away from the reserved road and quest anchors.
	for y in range(15,31):
		for x in range(8,27):
			tiles[y][x] = 5 if y < 29 else 4
	for y in range(28,34):
		for x in range(15,18): tiles[y][x] = 7
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
	var cell = Vector2i(point/TILE)
	var tile: int = zone.tiles[cell.y][cell.x]
	if tile == 2 or tile == 3 or tile == 4:
		return false
	if index == 0:
		for prop in zone.props:
			if prop.sprite == 7 and Rect2(prop.position-Vector2(64,82),Vector2(128,82)).has_point(point): return false
	# Only the trunk's footprint blocks; canopy overlap remains walkable.
	for y in range(-1,2):
		for x in range(-1,2):
			for trunk in zone.collision.get(cell+Vector2i(x,y),[]):
				if point.distance_squared_to(trunk) < 22.0*22.0: return false
	return true

func commissions() -> Array:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed+873719
	var deck = [
		{"id":"quiet","name":"A little quiet for the road","story":"Orin needs time to mend the trail lanterns. Quiet the restless echoes along the road.","kind":"defeat","target":rng.randi_range(4,7),"reward":45},
		{"id":"names","name":"Names for the nameless","story":"The village archivist asks for memories the seals have misplaced. Bring back their fragments.","kind":"memory","target":rng.randi_range(3,5),"reward":50},
		{"id":"lights","name":"Someone is waiting","story":"A traveler asks you to light both wilderness lanterns. Her partner is following the road home.","kind":"lantern","target":2,"reward":35},
		{"id":"satchels","name":"What the river leaves","story":"Mira marks two lost satchels on your route. Recover their contents before the wilderness shifts.","kind":"chest","target":2,"reward":40}
	]
	var result: Array = []
	while result.size() < 3:
		var index = rng.randi_range(0,deck.size()-1)
		result.append(deck[index])
		deck.remove_at(index)
	return result

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
