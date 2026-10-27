extends RefCounted

const VERSION = 2
var path = "user://atlas_save.json"
var last_error = ""

func exists() -> bool:
	return FileAccess.file_exists(path)

func save(state: Dictionary) -> bool:
	last_error = ""
	var payload = state.duplicate(true)
	payload["save_version"] = VERSION
	payload["generator_version"] = 2
	var file = FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		last_error = "The Atlas could not be saved. Check available disk space."
		return false
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	# Keep a recovery copy before replacing an existing save.
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(path+".bak"))
	var error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
	if error != OK:
		last_error = "The save could not be replaced. Your previous save is intact."
	return error == OK

func load_state() -> Dictionary:
	last_error = ""
	var state = _read(path)
	if state.is_empty() and FileAccess.file_exists(path+".bak"):
		state = _read(path+".bak")
	if state.is_empty():
		last_error = "This save could not be read. A new journey is still available."
	return state

func _read(source: String) -> Dictionary:
	if not FileAccess.file_exists(source):
		return {}
	var parser = JSON.new()
	if parser.parse(FileAccess.get_file_as_string(source)) != OK: return {}
	var value = parser.data
	if not value is Dictionary:
		return {}
	if int(value.get("save_version",0)) not in [1,2] or int(value.get("generator_version",0)) not in [1,2]:
		return {}
	if not value.get("answers",[]) is Array or not value.get("changed",{}) is Dictionary:
		return {}
	if int(value.get("room",0)) < 0 or int(value.get("room",0)) > 3:
		return {}
	if not value.get("position",[]) is Array or value.get("position",[]).size() != 2:
		return {}
	for key in ["skills","inventory","side_quests","contracts"]:
		if value.has(key) and not value[key] is Dictionary: return {}
	# JSON numbers arrive as floats; inventory and training counts are integers.
	for key in ["skills","inventory","side_quests"]:
		if value.has(key):
			for entry in value[key]:
				if typeof(value[key][entry]) not in [TYPE_INT,TYPE_FLOAT]: return {}
				value[key][entry] = maxi(0,int(value[key][entry]))
	for key in ["seed","room","rank","xp","coins","quest_stage","memories"]:
		if value.has(key):
			if typeof(value[key]) not in [TYPE_INT,TYPE_FLOAT]: return {}
			value[key] = int(value[key])
	for key in ["hp","max_hp","mana","max_mana","play_time"]:
		if value.has(key) and typeof(value[key]) not in [TYPE_INT,TYPE_FLOAT]: return {}
	for coordinate in value.position:
		if typeof(coordinate) not in [TYPE_INT,TYPE_FLOAT]: return {}
	return value
