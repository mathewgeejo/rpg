extends RefCounted

const DIMENSIONS = ["agency", "duty", "compassion", "ambition", "uncertainty", "identity", "belonging", "sacrifice", "truth", "change"]
const MODIFIERS = [
	{"name":"Merciful", "stat":"healing", "bonus":0.25, "cost":"damage", "penalty":0.08},
	{"name":"Restless", "stat":"speed", "bonus":0.12, "cost":"shield", "penalty":0.15},
	{"name":"Deliberate", "stat":"damage", "bonus":0.18, "cost":"speed", "penalty":0.06},
	{"name":"Unbroken", "stat":"shield", "bonus":0.3, "cost":"mana_regen", "penalty":0.15},
	{"name":"Curious", "stat":"mana_regen", "bonus":0.3, "cost":"damage", "penalty":0.08},
	{"name":"Defiant", "stat":"damage", "bonus":0.22, "cost":"healing", "penalty":0.2}
]

var classes: Array = []
var questions: Array = []
var regions: Array = []

func _init() -> void:
	classes = JSON.parse_string(FileAccess.get_file_as_string("res://data/classes.json"))
	questions = JSON.parse_string(FileAccess.get_file_as_string("res://data/ritual.json"))
	regions = JSON.parse_string(FileAccess.get_file_as_string("res://data/regions.json"))

func class_by_id(id: String) -> Dictionary:
	for entry in classes:
		if entry.id == id:
			return entry
	return classes[0]

func affinities(answers: Array) -> Array:
	var values: Dictionary = {}
	for dimension in DIMENSIONS:
		values[dimension] = 0.0
	for i in mini(answers.size(), questions.size()):
		var index = clampi(int(answers[i]), 0, 3)
		for dimension in questions[i].choices[index].weights:
			values[dimension] += float(questions[i].choices[index].weights[dimension])
	var result: Array = []
	for entry in classes:
		var distance = 0.0
		for dimension in DIMENSIONS:
			distance += pow((values[dimension] - float(entry.profile[dimension])) / 24.0, 2)
		var motif = 0.0
		for i in mini(answers.size(), entry.prototype.size()):
			if int(answers[i]) == int(entry.prototype[i]):
				motif += 1.0 / 24.0
		result.append({"class":entry, "score":0.65 / (1.0 + distance) + 0.35 * motif})
	result.sort_custom(func(a, b):
		if is_equal_approx(a.score, b.score):
			return str(a["class"].id) < str(b["class"].id)
		return a.score > b.score)
	return result

func explanation(entry: Dictionary, answers: Array) -> String:
	var evidence: Array[String] = []
	for i in mini(answers.size(), questions.size()):
		var choice: Dictionary = questions[i].choices[clampi(int(answers[i]), 0, 3)]
		if choice.weights.has(entry.values[0]) and evidence.size() < 2:
			evidence.append('“%s”' % choice.text)
	return "Your answers return to %s and %s.\n\n%s\n\n%s" % [entry.values[0], entry.values[1], "\n\n".join(evidence), entry.tagline]

func specialization(id: String, world_seed: int, rank: int) -> Dictionary:
	var rng = RandomNumberGenerator.new()
	rng.seed = world_seed + id.hash() + rank * 1009
	var modifier: Dictionary = MODIFIERS[rng.randi_range(0, MODIFIERS.size()-1)].duplicate(true)
	modifier["class_id"] = id
	modifier["rank"] = rank
	return modifier
