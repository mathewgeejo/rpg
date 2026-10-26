extends RefCounted

const VERSION = 1
var path = "user://atlas_save.json"
var last_error = ""

func exists() -> bool:
	return FileAccess.file_exists(path)

func save(state: Dictionary) -> bool:
	last_error = ""
	var payload = state.duplicate(true)
	payload["save_version"] = VERSION
	payload["generator_version"] = 1
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
	var value = JSON.parse_string(FileAccess.get_file_as_string(source))
	if not value is Dictionary:
		return {}
	if int(value.get("save_version",0)) != VERSION or int(value.get("generator_version",0)) != 1:
		return {}
	if not value.get("answers",[]) is Array or not value.get("changed",{}) is Dictionary:
		return {}
	if int(value.get("room",0)) < 0 or int(value.get("room",0)) > 3:
		return {}
	if not value.get("position",[]) is Array or value.get("position",[]).size() != 2:
		return {}
	return value
