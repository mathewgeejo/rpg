extends RefCounted

const MODIFIERS = [
	{"name":"Merciful", "stat":"healing", "bonus":0.25, "cost":"damage", "penalty":0.08},
	{"name":"Restless", "stat":"speed", "bonus":0.12, "cost":"shield", "penalty":0.15},
	{"name":"Deliberate", "stat":"damage", "bonus":0.18, "cost":"speed", "penalty":0.06},
	{"name":"Unbroken", "stat":"shield", "bonus":0.3, "cost":"mana_regen", "penalty":0.15},
	{"name":"Curious", "stat":"mana_regen", "bonus":0.3, "cost":"damage", "penalty":0.08},
	{"name":"Defiant", "stat":"damage", "bonus":0.22, "cost":"healing", "penalty":0.2}
]

var classes: Array = []
var regions: Array = []

func _init() -> void:
	classes = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
	regions = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions.json"))

func class_by_id(id: String) -> Dictionary:
	for entry in classes:
		if entry.id == id:
			return entry
	return classes[0]

func specialization(id: String, world_seed: int, rank: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed + id.hash() + rank * 1009
	var modifier: Dictionary = MODIFIERS[rng.randi_range(0, MODIFIERS.size()-1)].duplicate(true)
	modifier["class_id"] = id
	modifier["rank"] = rank
	return modifier
