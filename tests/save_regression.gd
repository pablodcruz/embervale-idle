extends RefCounted


static func run(failures: Array[String]) -> void:
	# A system temp directory, never the player's user:// directory.
	var scratch := DirAccess.create_temp("embervale-save-test")
	if scratch == null:
		failures.append("FAIL: could not create disposable save directory")
		return
	var path := scratch.get_current_dir().path_join("run.json")
	var state := GameContent.new_state()
	state.inventory.pine_log = 37
	state.skills.woodcutting_xp = 185
	state.location = "whisperwood"
	state.paused = true
	_check(SaveSystem.load_game(path).status == SaveSystem.Status.MISSING, "missing save", failures)
	_check(SaveSystem.save_game(state, path), "first save", failures)
	var previous := FileAccess.get_file_as_bytes(path)
	state.inventory.pine_log = 41
	_check(SaveSystem.save_game(state, path), "second save", failures)
	_check(FileAccess.get_file_as_bytes(path + ".bak") == previous, "previous generation retained", failures)
	var current := FileAccess.get_file_as_bytes(path)
	# A directory in place of the staging file simulates an unwritable stage.
	DirAccess.make_dir_absolute(path + ".tmp")
	_check(not SaveSystem.save_game(state, path), "staging failure signalled", failures)
	_check(FileAccess.get_file_as_bytes(path) == current, "staging failure kept primary", failures)
	DirAccess.remove_absolute(path + ".tmp")
	_write(path, '{"version":1,"inventory":')
	var recovered := SaveSystem.load_game(path)
	_check(recovered.status == SaveSystem.Status.BACKUP, "truncation uses backup", failures)
	if recovered.status == SaveSystem.Status.BACKUP:
		_check(recovered.state.inventory.pine_log == 37 and recovered.state.paused, "recovered inventory and pause", failures)
		_check(SaveSystem.save_game(recovered.state, path), "save recovered state", failures)
		_check(FileAccess.get_file_as_bytes(path + ".bak") == previous, "never rotate corrupt bytes over backup", failures)
	DirAccess.remove_absolute(path)
	_check(SaveSystem.load_game(path).status == SaveSystem.Status.BACKUP, "interrupted promotion uses backup", failures)
	_write(path, '{"version":99}')
	_check(SaveSystem.load_game(path).status == SaveSystem.Status.UNSUPPORTED, "future save not downgraded via backup", failures)
	_check(not SaveSystem.save_game(state, path), "reject overwrite of future save", failures)
	_write(path + ".bak", "broken")
	_write(path, "truncated")
	_check(SaveSystem.load_game(path).status == SaveSystem.Status.DAMAGED, "corrupt differs from missing", failures)
	_check(not SaveSystem.save_game(state, path) and FileAccess.get_file_as_string(path) == "truncated", "unrecoverable primary preserved", failures)
	_write(path + ".tmp", "incomplete")
	_check(SaveSystem.delete_save(path), "explicit reset", failures)
	_check(SaveSystem.load_game(path).status == SaveSystem.Status.MISSING and not FileAccess.file_exists(path + ".tmp"), "reset removed generations", failures)


static func _write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(value)
	file.close()


static func _check(condition: bool, label: String, failures: Array[String]) -> void:
	if not condition:
		failures.append("FAIL: save regression: " + label)
