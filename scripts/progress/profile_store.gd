class_name ProfileStore
extends RefCounted
## Versioned local snapshots. Write a verified temporary file before rotating the last
## good snapshot to .bak. Never overwrite an unreadable or newer profile silently.

const VERSION: int = 1

static func read_profile(path: String) -> Dictionary:
	var primary: Dictionary = _read(path)
	if primary.status in ["ok", "newer"]:
		return primary
	var backup: Dictionary = _read(path + ".bak")
	if backup.status == "ok":
		backup.status = "recovered"
		return backup
	if backup.status == "newer":
		return backup
	return {"status": "missing" if primary.status == "missing" and backup.status == "missing" else "invalid", "data": {}}


static func write_profile(path: String, data: Dictionary) -> Error:
	if not valid(data):
		return ERR_INVALID_DATA
	var previous: Dictionary = read_profile(path)
	if previous.status in ["invalid", "newer"]:
		return ERR_FILE_CORRUPT
	var error: Error = DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error != OK:
		return error
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "  "))
	file.flush()
	error = file.get_error()
	file.close()
	if error != OK or _read(temporary).status != "ok":
		return ERR_FILE_CANT_WRITE
	if FileAccess.file_exists(path):
		if _read(path).status == "ok":
			if FileAccess.file_exists(path + ".bak"):
				error = DirAccess.remove_absolute(path + ".bak")
				if error != OK:
					return error
			error = DirAccess.rename_absolute(path, path + ".bak")
		else:
			# Recovery retains the good backup and the damaged file for inspection.
			error = DirAccess.rename_absolute(path, path + ".damaged-" + str(Time.get_ticks_usec()))
		if error != OK:
			return error
	return DirAccess.rename_absolute(temporary, path)


static func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"status": "missing", "data": {}}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"status": "invalid", "data": {}}
	var parser: JSON = JSON.new()
	var error: Error = parser.parse(file.get_as_text())
	file.close()
	if error != OK:
		return {"status": "invalid", "data": {}}
	var data: Variant = parser.data
	if data is Dictionary and _whole(data.get("version")) and int(data.version) > VERSION:
		return {"status": "newer", "data": {}}
	if not valid(data):
		return {"status": "invalid", "data": {}}
	return {"status": "ok", "data": data}


static func valid(data: Variant) -> bool:
	if not data is Dictionary or data.get("version") != VERSION:
		return false
	if not data.get("profile_id") is String or not data.get("intro_seen") is bool:
		return false
	if data.get("grade") not in ["K", "1", "2", "3"] or data.get("mode") not in ["explore", "race"]:
		return false
	if data.get("sidekick_id") not in ["henrito", "loganator"] or not data.get("explore_locked") is bool:
		return false
	if not _counts(data.get("care_visits")) or not _counts(data.get("pen_repairs_shown")):
		return false
	if not data.get("rescues") is Array or not data.get("progress") is Dictionary:
		return false
	for rescue: Variant in data.rescues:
		if not rescue is Dictionary:
			return false
		for key: String in ["animal", "habitat", "map"]:
			if not rescue.get(key) is String:
				return false
		var cell: Variant = rescue.get("cell")
		if not cell is Array or cell.size() != 2 or not _whole(cell[0], -1) or not _whole(cell[1], -1):
			return false
	for skill: Variant in data.progress.values():
		if not _valid_skill(skill):
			return false
	return true


static func _valid_skill(skill: Variant) -> bool:
	if not skill is Dictionary:
		return false
	for key: String in ["level", "total_answers", "total_correct"]:
		if not _whole(skill.get(key)):
			return false
	if skill.level < 1 or skill.total_correct > skill.total_answers:
		return false
	if not _number(skill.get("total_seconds")) or not skill.get("extra_help") is bool:
		return false
	if not skill.get("window") is Array or not skill.get("mastered") is Array:
		return false
	if not _counts(skill.get("streaks")) or not skill.get("session") is Dictionary:
		return false
	for entry: Variant in skill.window:
		if not entry is Dictionary or not entry.get("correct") is bool or not _number(entry.get("seconds")):
			return false
	for level: Variant in skill.mastered:
		if not _whole(level, 1):
			return false
	for key: Variant in skill.session:
		if not str(key).is_valid_int() or int(key) < 1:
			return false
		var entry: Variant = skill.session[key]
		if not entry is Dictionary or not _whole(entry.get("answers")) or not _whole(entry.get("correct")):
			return false
		if entry.correct > entry.answers:
			return false
	return true


static func _counts(value: Variant) -> bool:
	if not value is Dictionary:
		return false
	for count: Variant in value.values():
		if not _whole(count):
			return false
	return true


static func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0


static func _whole(value: Variant, minimum: int = 0) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= minimum and float(value) == floorf(float(value))
