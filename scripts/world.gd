class_name PrismWorld
extends Node2D
## Chapter controller: builds one PrismRoom at a time from data/rooms.json and relays its events.

signal room_completed(room_id: String, time: float)
signal chapter_completed(chapter: int)
signal story_requested(key: String)
signal player_died

var chapter: int = 0
var room: PrismRoom
var room_index: int = 0
var deaths: int = 0
var time_control: PrismTimeControl = PrismTimeControl.new()
var boss_phase_checkpoint: int = 1
var transitioning: bool = false
var objective: String = ""
var load_error: String = ""
var rooms_path: String = "res://data/rooms.json"
var player: PrismPlayer:
	get: return room.player if is_instance_valid(room) else null
var boss: Node:
	get: return room.boss if is_instance_valid(room) else null
var palette: Array[Color] = []
var info: Dictionary = {}
var _rooms: Array = []
var _dead: bool = false
var _clock: float = 0.0

func configure(chapter_index: int, start_room: int = 0) -> void:
	chapter = clampi(chapter_index, 0, 4)
	room_index = maxi(0, start_room)

func _ready() -> void:
	var json := JSON.new()
	var regions: Variant = json.data if json.parse(FileAccess.get_file_as_string("res://data/regions.json").trim_prefix("﻿")) == OK else null
	if regions is Array and (regions as Array).size() == 5:
		info = regions[chapter]
		for value in info["palette"]:
			palette.append(Color(str(value)))
	var all: Dictionary = PrismRoom.load_rooms(rooms_path)
	if all.is_empty() or (all["chapters"] as Array).size() <= chapter or not all["chapters"][chapter] is Array or (all["chapters"][chapter] as Array).is_empty():
		_fail("Oda verisi okunamadı.")
		return
	for entry in all["chapters"][chapter]:
		var problem: String = PrismRoom.validate_room(entry) if entry is Dictionary else "Oda kaydı geçersiz."
		if not problem.is_empty():
			_fail(problem)
			return
	_rooms = all["chapters"][chapter]
	room_index = clampi(room_index, 0, _rooms.size() - 1)
	_build_room(true)

func is_ready() -> bool:
	return load_error.is_empty() and not _rooms.is_empty()

func _fail(reason: String) -> void:
	load_error = reason
	_rooms = []
	push_error("PRISMBOUND: " + reason)

func _exit_tree() -> void:
	time_control.reset()

func _process(delta: float) -> void:
	_clock += delta
	var wants_slow: bool = InputMap.has_action("slow") and Input.is_action_pressed("slow") and not _dead
	time_control.update(delta / maxf(Engine.time_scale, 0.001), wants_slow)
	queue_redraw()

func _build_room(announce: bool) -> void:
	if _rooms.is_empty():
		return
	var data: Dictionary = _rooms[room_index]
	_dead = false
	var is_boss: bool = data.get("boss") != null
	if announce:
		boss_phase_checkpoint = 1
	room = PrismRoom.new()
	room.chapter = chapter
	room.palette = palette
	room.configure(data, boss_phase_checkpoint if is_boss else 1)
	add_child(room)
	room.cleared.connect(_on_room_cleared.bind(room))
	room.exited.connect(_on_room_exited.bind(room))
	room.player_died.connect(_on_room_player_died.bind(room))
	room.boss_phase_reached.connect(_on_boss_phase.bind(room))
	objective = "Düşmanları temizle"
	if announce and is_boss:
		story_requested.emit("boss_%d" % int(data["boss"]))

func _retire_room() -> void:
	if not is_instance_valid(room):
		return
	var old: PrismRoom = room
	room = null
	# Queued nodes stay in their groups until freed: leave every group now so lookups see only the new room.
	var stack: Array[Node] = [old]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		for group in node.get_groups():
			if not str(group).begins_with("_"):
				node.remove_from_group(group)
		stack.append_array(node.get_children())
	remove_child(old)
	old.queue_free()

func restart_room() -> void:
	_retire_room()
	time_control.reset()
	transitioning = false
	_build_room(false)

func _on_room_cleared(source: PrismRoom) -> void:
	if source == room:
		objective = "Çıkışa git"

func _on_boss_phase(phase: int, source: PrismRoom) -> void:
	if source == room:
		boss_phase_checkpoint = phase

func _on_room_player_died(source: PrismRoom) -> void:
	if source != room or transitioning or _dead:
		return
	_dead = true
	deaths += 1
	player_died.emit()

func _on_room_exited(source: PrismRoom) -> void:
	if source != room or transitioning or _dead:
		return
	transitioning = true
	room_completed.emit(str(_rooms[room_index]["id"]), source.elapsed)
	call_deferred("_advance")

func _advance() -> void:
	if not transitioning:
		return
	if room_index + 1 >= _rooms.size():
		chapter_completed.emit(chapter)
		return
	_retire_room()
	room_index += 1
	boss_phase_checkpoint = 1
	transitioning = false
	_build_room(true)

func _draw() -> void:
	if palette.size() < 5:
		return
	draw_rect(Rect2(0, 0, 640, 360), palette[0])
	# Three parallax layers; the camera is fixed so they drift slowly with the clock.
	for layer in range(3):
		var rate: float = [0.12, 0.30, 0.58][layer]
		var spacing: int = [180, 110, 72][layer]
		var offset: float = fposmod(_clock * rate * 4.0, float(spacing))
		var color: Color = palette[mini(layer + 1, 3)].darkened(0.42 if layer == 2 else 0.23)
		for index in range(-1, 640 / spacing + 2):
			var x: float = roundf(index * spacing - offset)
			var variation: int = absi(index * 43 + layer * 17) % 71
			var ground: float = 295.0 - layer * 9.0
			match chapter:
				0:
					var height: float = 160.0 + variation + layer * 11.0
					draw_rect(Rect2(x + 20, ground - height, 11 + layer * 4, height), color)
					for branch in range(3):
						var y: float = ground - height + branch * 38.0
						draw_rect(Rect2(x - 16 - branch * 7, y, 85 + branch * 12, 25), color)
						draw_rect(Rect2(x - 4 - branch * 7, y - 12, 61 + branch * 12, 12), color)
				1:
					var height: float = 58.0 + variation * 2.0
					draw_colored_polygon(PackedVector2Array([Vector2(x, ground), Vector2(x + 15, ground - height), Vector2(x + 30, ground - height - 24), Vector2(x + 48, ground)]), color)
					draw_colored_polygon(PackedVector2Array([Vector2(x + 45, 0), Vector2(x + 60, 65 + variation), Vector2(x + 78, 0)]), color)
				2:
					var height: float = 110.0 + variation
					draw_rect(Rect2(x, ground - height, 65, height), color)
					for crenel in range(0, 65, 20):
						draw_rect(Rect2(x + crenel, ground - height - 12, 12, 12), color)
				3:
					var float_y: float = 85.0 + variation + roundf(sin(_clock * 0.5 + index) * 5.0)
					draw_rect(Rect2(x, float_y, 65, 12), color)
					draw_rect(Rect2(x + 12, float_y + 12, 10, 65), color)
					draw_rect(Rect2(x + 43, float_y + 12, 10, 65), color)
				4:
					var float_y: float = 75.0 + variation + roundf(sin(_clock * 0.4 + index) * 8.0)
					draw_colored_polygon(PackedVector2Array([Vector2(x, float_y), Vector2(x + 40, float_y - 22), Vector2(x + 76, float_y), Vector2(x + 45, float_y + 55)]), color)
	for i in range(28):
		var px: float = fposmod(i * 97.0 - _clock * 3.0 + sin(_clock * 0.3 + i) * 8.0, 640.0)
		var py: float = fposmod(i * 37.0 + _clock * (5.0 if chapter == 2 else -1.8), 275.0)
		var alpha: float = 0.15 + (sin(_clock * 1.2 + i) + 1.0) * 0.11
		draw_rect(Rect2(roundf(px), roundf(py), 2, 2), Color(palette[4], alpha))
