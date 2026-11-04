extends RefCounted
class_name PrismSave

const PATH := "user://prismbound_save.json"
const BACKUP := "user://prismbound_save.backup.json"
const SETTINGS := "user://prismbound_settings.json"

static func fresh() -> Dictionary:
	return {"version": 1, "region": 0, "unlocked": 0, "upgrades": 0, "shards": 0, "cleared": [], "flags": {}, "ending": "", "checkpoint": 0, "hp": 100.0}

static func valid(data: Variant) -> bool:
	if not data is Dictionary:
		return false
	for key in ["version", "region", "unlocked", "upgrades", "shards"]:
		if not data.has(key) or not (data[key] is float or data[key] is int):
			return false
	if int(data.version) != 1 or int(data.region) < 0 or int(data.region) > 4:
		return false
	if int(data.unlocked) < 0 or int(data.unlocked) > 4 or int(data.upgrades) < 0 or int(data.upgrades) > 20 or int(data.shards) < 0:
		return false
	if not data.get("cleared", []) is Array or not data.get("flags", {}) is Dictionary:
		return false
	for area in data.get("cleared", []):
		if not (area is float or area is int) or int(area) < 0 or int(area) > 4:
			return false
	return data.get("ending", "") is String

static func read_path(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not valid(parsed):
		return {}
	var result := fresh()
	result.merge(parsed, true)
	return result

static func load_game() -> Dictionary:
	var result := read_path(PATH)
	if result.is_empty():
		result = read_path(BACKUP)
	return result

static func save_game(data: Dictionary) -> bool:
	if not valid(data):
		return false
	var tmp := PATH + ".tmp"
	var file := FileAccess.open(tmp, FileAccess.WRITE)
	if not file:
		return false
	file.store_string(JSON.stringify(data, "\t"))
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
