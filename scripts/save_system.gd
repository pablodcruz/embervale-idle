class_name SaveSystem
extends RefCounted

const SAVE_PATH := "user://embervale_save.json"

enum Status { PRIMARY, BACKUP, MISSING, DAMAGED, UNSUPPORTED, UNREADABLE }


static func _read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		var missing := FileAccess.get_open_error() == ERR_FILE_NOT_FOUND and not DirAccess.dir_exists_absolute(path)
		return {"status": Status.MISSING if missing else Status.UNREADABLE}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return {"status": Status.DAMAGED}
	var data: Dictionary = json.data
	if typeof(data.get("version")) not in [TYPE_INT, TYPE_FLOAT]:
		return {"status": Status.DAMAGED}
	if data.version != 1:
		return {"status": Status.UNSUPPORTED}
	if not data.get("inventory") is Dictionary or not data.get("skills") is Dictionary or not data.get("queue") is Array:
		return {"status": Status.DAMAGED}
	if not data.get("location") is String or not data.get("paused") is bool:
		return {"status": Status.DAMAGED}
	if data.get("current_action") != null and not data.current_action is Dictionary:
		return {"status": Status.DAMAGED}
	for action: Variant in data.queue:
		if not action is Dictionary:
			return {"status": Status.DAMAGED}
	return {"status": Status.PRIMARY, "state": data}


static func load_game(path: String = SAVE_PATH) -> Dictionary:
	var primary := _read(path)
	if primary.status in [Status.PRIMARY, Status.UNSUPPORTED, Status.UNREADABLE]:
		return primary
	var backup := _read(path + ".bak")
	if backup.status == Status.PRIMARY:
		return {"status": Status.BACKUP, "state": backup.state}
	if backup.status != Status.MISSING:
		return {"status": backup.status}
	return primary


static func save_game(state: Dictionary, path: String = SAVE_PATH) -> bool:
	# Only rotate a known-good primary. A damaged primary must never replace its backup.
	var existing := load_game(path)
	if existing.status not in [Status.PRIMARY, Status.BACKUP, Status.MISSING]:
		return false
	var payload: Dictionary = state.duplicate(true)
	payload["last_saved_unix"] = Time.get_unix_time_from_system()
	var pending := path + ".tmp"
	var file := FileAccess.open(pending, FileAccess.WRITE)
	if file == null:
		return false
	var encoded := JSON.stringify(payload, "\t")
	var written := file.store_string(encoded)
	file.flush()
	var success := written and file.get_error() == OK
	file.close()
	if not success or _read(pending).status != Status.PRIMARY or FileAccess.get_file_as_string(pending) != encoded:
		return false
	if existing.status == Status.PRIMARY and DirAccess.rename_absolute(path, path + ".bak") != OK:
		return false
	# Both names are on the same filesystem. If interrupted after rotation, load_game uses .bak.
	return DirAccess.rename_absolute(pending, path) == OK


static func delete_save(path: String = SAVE_PATH) -> bool:
	for suffix: String in [".tmp", ".bak", ""]:
		var target := path + suffix
		if FileAccess.file_exists(target) and DirAccess.remove_absolute(target) != OK:
			return false
	return true
