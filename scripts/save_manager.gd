extends RefCounted
class_name PrismSave

static var PATH := "user://prismbound_save.json"
static var BACKUP := "user://prismbound_save.backup.json"
static var SETTINGS := "user://prismbound_settings.json"

static func fresh() -> Dictionary:
	return {"version": 2, "unlocked_chapter": 0, "best_times": {}, "total_deaths": 0}

static func _is_num(v: Variant) -> bool:
	return v is float or v is int

static func valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["version", "unlocked_chapter", "total_deaths"]:
		if not data.has(key) or not _is_num(data[key]):
			return false
	if int(data.version) != 2 or int(data.unlocked_chapter) < 0 or int(data.unlocked_chapter) > 4 or int(data.total_deaths) < 0:
		return false
	if not data.get("best_times") is Dictionary:
		return false
	for room in data.best_times:
		if not _is_num(data.best_times[room]) or not is_finite(float(data.best_times[room])) or float(data.best_times[room]) <= 0.0:
			return false
	return true

static func migrate(data: Dictionary) -> Dictionary:
	if not data.has("version") or not _is_num(data.version):
		return {}
	var version := int(data.version)
	if version == 2:
		return data
	if version != 1:
		return {}
	var result := fresh()
	if data.has("unlocked"):
		if not _is_num(data.unlocked):
			return {}
		result.unlocked_chapter = clampi(int(data.unlocked), 0, 4)
	return result

static func record_room(data: Dictionary, room_id: String, time: float) -> Dictionary:
	var result := data.duplicate(true)
	if not is_finite(time) or time <= 0.0:
		return result
	var times: Dictionary = result.get("best_times", {})
	if not times.has(room_id) or time < float(times[room_id]):
		times[room_id] = time
	result.best_times = times
	return result

static func read_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {}
	var migrated := migrate(parsed)
	if not valid(migrated):
		return {}
	for key in ["version", "unlocked_chapter", "total_deaths"]:
		migrated[key] = int(migrated[key])
	return migrated

static func load_game() -> Dictionary:
	var result := read_path(PATH)
	if result.is_empty():
		result = read_path(BACKUP)
	if result.is_empty():
		result = fresh()
	return result

static func save_game(data: Dictionary) -> bool:
	if not valid(data):
		return false
	var tmp := PATH + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(data, "	"))
	file.close()
	if read_path(tmp).is_empty():
		return false
	if not read_path(PATH).is_empty():
		DirAccess.copy_absolute(PATH, BACKUP)
	return DirAccess.rename_absolute(tmp, PATH) == OK

static func reset_game() -> void:
	for path in [PATH, BACKUP, PATH + ".tmp"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

static func defaults() -> Dictionary:
	return {"master": 0.8, "music": 0.5, "sfx": 0.75, "fullscreen": false, "resolution": 2, "vsync": true, "shake": 0.35, "effects": 0.6, "assist": false, "snap": false, "language": "tr", "bindings": {}}

static func load_settings() -> Dictionary:
	var result := defaults()
	if FileAccess.file_exists(SETTINGS):
		var file := FileAccess.open(SETTINGS, FileAccess.READ)
		if file:
			var data: Variant = JSON.parse_string(file.get_as_text())
			if data is Dictionary:
				for key in result:
					if data.has(key) and typeof(data[key]) == typeof(result[key]):
						result[key] = data[key]
	for key in ["master", "music", "sfx", "shake", "effects"]:
		result[key] = clampf(float(result[key]), 0.0, 1.0)
	result.resolution = clampi(int(result.resolution), 1, 3)
	return result

static func save_settings(settings: Dictionary) -> void:
	var file := FileAccess.open(SETTINGS, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))

