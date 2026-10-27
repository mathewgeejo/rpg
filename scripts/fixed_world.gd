extends RefCounted
## Fixed, editable tile maps. The seed is retained for save compatibility only.

const GENERATOR_VERSION = 2
const TILE = 32
const MAPS = ["00_lanternwick","01_wispwood","02_stonewater","03_observatory"]
const TERRAIN = {".":0,":":1,"~":2,"#":3,"v":4,"=":5,"+":6,"^":7,"p":8}
var world_seed = 731904
var rooms: Dictionary = {}
var graph: Dictionary = {}

func _init(_legacy_seed: int = 731904) -> void:
	graph = {"version":2,"locations":[
		{"id":0,"name":"Lanternwick","x":.20,"y":.76,"kind":"town"},
		{"id":1,"name":"Wispwood Path","x":.40,"y":.59,"kind":"forest"},
		{"id":2,"name":"Stonewater Crossing","x":.63,"y":.44,"kind":"river"},
		{"id":3,"name":"The Observatory","x":.79,"y":.20,"kind":"ruin"}
	],"routes":[{"from":0,"to":1},{"from":1,"to":2},{"from":2,"to":3}]}

func room(index: int) -> Dictionary:
	if rooms.has(index): return rooms[index]
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/maps/%s.json" % MAPS[index]))
	var result: Dictionary = {"id":index,"name":source.name,"subtitle":source.subtitle,"size":Vector2(source.width,source.height)*TILE,"spawn":_point(source.spawn),"finish":_point(source.finish),"tiles":[],"props":[],"objects":[],"enemies":[],"collision":{},"buildings":[]}
	for line in source.terrain:
		var row: Array = []
		for symbol in line: row.append(TERRAIN[symbol])
		result.tiles.append(row)
	for category in ["props","objects","enemies"]:
		for item in source[category]:
			var copy: Dictionary = item.duplicate(true)
			copy.position = _point(item.position)
			if item.has("path"):
				copy.path = item.path.map(func(p): return _point(p))
				copy["path_index"] = 0
				copy["moving"] = false
				copy["facing"] = Vector2.DOWN
			result[category].append(copy)
	for prop in result.props:
		if prop.sprite < 6:
			var cell = Vector2i(prop.position/TILE)
			if not result.collision.has(cell): result.collision[cell] = []
			result.collision[cell].append(prop.position)
		if prop.sprite == 7: result.buildings.append(Rect2(prop.position-Vector2(46,52),Vector2(92,52)))
		if prop.sprite == 22: result.buildings.append(Rect2(prop.position-Vector2(30,20),Vector2(60,22)))
		if prop.sprite == 20: result.buildings.append(Rect2(prop.position-Vector2(16,5),Vector2(32,6)))
		if prop.sprite == 21: result.buildings.append(Rect2(prop.position-Vector2(22,8),Vector2(44,10)))
		if prop.sprite in [24,25,26]:
			var spacing = 52 if prop.sprite == 24 else (48 if prop.sprite == 25 else 77)
			for side in [-1,1]:
				result.buildings.append(Rect2(prop.position+Vector2(side*spacing-12,-20),Vector2(24,24)))
	rooms[index] = result
	return result

func _point(value: Array) -> Vector2:
	return Vector2(float(value[0])*TILE+16,float(value[1])*TILE+16)

func walkable(index: int, point: Vector2, origin: Vector2 = Vector2.INF) -> bool:
	var zone = room(index)
	if point.x < 40 or point.y < 40 or point.x > zone.size.x-40 or point.y > zone.size.y-40: return false
	var cell = Vector2i(point/TILE)
	var tile: int = zone.tiles[cell.y][cell.x]
	if tile in [2,3,4]: return false
	if origin != Vector2.INF:
		var prior = Vector2i(origin/TILE)
		if prior.x >= 0 and prior.y >= 0 and prior.y < zone.tiles.size() and prior.x < zone.tiles[0].size():
			var before: int = zone.tiles[prior.y][prior.x]
			if (tile == 5) != (before == 5) and tile != 7 and before != 7: return false
	for building in zone.buildings:
		if building.has_point(point): return false
	for y in range(-1,2):
		for x in range(-1,2):
			for trunk in zone.collision.get(cell+Vector2i(x,y),[]):
				if point.distance_squared_to(trunk) < 15*15: return false
	return true

func commissions() -> Array:
	return [
		{"id":"quiet","name":"Make room for a small light","story":"Orin cannot mend the trail lanterns while restless echoes crowd the road. Quiet four of them.","kind":"defeat","target":4,"reward":45},
		{"id":"names","name":"Names for the nameless","story":"Sella keeps an empty page for each lost villager. Bring home three memories so she can begin filling them.","kind":"memory","target":3,"reward":50},
		{"id":"satchels","name":"Someone kept your place","story":"Mira has marked two lost satchels on the road. One may contain the words her brother never sent.","kind":"chest","target":2,"reward":40}
	]

func reachable(index: int) -> bool:
	var zone = room(index)
	var width: int = zone.tiles[0].size()
	var height: int = zone.tiles.size()
	var origin = Vector2i(zone.spawn/TILE)
	if not walkable(index,zone.spawn): return false
	var queue: Array[Vector2i] = [origin]
	var seen: Dictionary = {origin:true}
	var cursor = 0
	while cursor < queue.size():
		var cell = queue[cursor]
		cursor += 1
		for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next: Vector2i = cell+direction
			if next.x < 0 or next.y < 0 or next.x >= width or next.y >= height or seen.has(next): continue
			if walkable(index,Vector2(next)*TILE+Vector2(16,16),Vector2(cell)*TILE+Vector2(16,16)):
				seen[next] = true
				queue.append(next)
	for object in zone.objects:
		var target = Vector2i(object.position/TILE)
		var found = false
		for y in range(-1,2):
			for x in range(-1,2):
				if seen.has(target+Vector2i(x,y)): found = true
		if not found:
			printerr("Unreachable authored landmark: room ",index," / ",object.id)
			return false
	return true
