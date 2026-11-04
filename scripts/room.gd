class_name PrismRoom
extends Node2D
## One self-contained arena: solids, player, enemies, an exit that opens when every enemy is down.

signal cleared
signal exited
signal player_died
signal boss_phase_reached(phase: int)

const EXIT_RADIUS := 24.0
const MAX_SIZE := Vector2(640, 360)
const MIN_ENEMY_SPAWN_DISTANCE := 160.0

var data: Dictionary = {}
var boss_start_phase: int = 1
var chapter: int = 0
var palette: Array[Color] = []
var player: PrismPlayer
var boss: Node
var enemies_left: int = 0
var exit_open: bool = false
var elapsed: float = 0.0
var _solids: Array[Rect2] = []
var _exit: Vector2 = Vector2.ZERO
var _ended: bool = false

static func load_rooms(path: String = "res://data/rooms.json") -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var raw: String = FileAccess.get_file_as_string(path).trim_prefix("﻿")
	var json := JSON.new()
	if json.parse(raw) != OK:
		return {}
	var parsed: Variant = json.data
	if not parsed is Dictionary or not (parsed as Dictionary).get("chapters") is Array:
		return {}
	return parsed

static func _is_num(value: Variant) -> bool:
	return typeof(value) == TYPE_FLOAT or typeof(value) == TYPE_INT

static func _vec(value: Variant) -> Variant:
	if value is Array and (value as Array).size() == 2 and _is_num(value[0]) and _is_num(value[1]):
		return Vector2(float(value[0]), float(value[1]))
	return null

## Returns "" when the room is usable, otherwise a Turkish reason.
static func validate_room(d: Dictionary) -> String:
	if not d.get("id") is String or str(d["id"]).is_empty():
		return "Oda kimliği eksik."
	var id: String = d["id"]
	var size: Variant = _vec(d.get("size"))
	if size == null or size.x <= 0.0 or size.y <= 0.0 or size.x > MAX_SIZE.x or size.y > MAX_SIZE.y:
		return "%s: oda boyutu geçersiz veya 640x360 sınırını aşıyor." % id
	var spawn: Variant = _vec(d.get("spawn"))
	if spawn == null or not Rect2(Vector2.ZERO, size).has_point(spawn):
		return "%s: doğuş noktası oda dışında." % id
	var exit_point: Variant = _vec(d.get("exit"))
	if exit_point == null or not Rect2(Vector2.ZERO, size).has_point(exit_point):
		return "%s: çıkış noktası oda dışında." % id
	if not d.get("solids") is Array or (d["solids"] as Array).is_empty():
		return "%s: odada zemin yok." % id
	for solid in d["solids"]:
		if not solid is Array or (solid as Array).size() != 4:
			return "%s: katı blok biçimi geçersiz." % id
		for n in solid:
			if not _is_num(n):
				return "%s: katı blok sayısal değil." % id
		if float(solid[2]) <= 0.0 or float(solid[3]) <= 0.0:
			return "%s: katı blok boyutu sıfır." % id
	if not d.get("enemies") is Array:
		return "%s: düşman listesi eksik." % id
	for enemy in d["enemies"]:
		if not enemy is Dictionary:
			return "%s: düşman kaydı geçersiz." % id
		if not enemy.get("type") is String or not PrismEnemy.TYPE_IDS.has(enemy["type"]):
			return "%s: bilinmeyen düşman türü." % id
		var pos: Variant = _vec(enemy.get("pos"))
		if pos == null or not Rect2(Vector2.ZERO, size).has_point(pos):
			return "%s: düşman oda dışında." % id
		if pos.distance_to(spawn) < MIN_ENEMY_SPAWN_DISTANCE:
			return "%s: düşman oyuncu doğuş noktasına çok yakın." % id
		if not _is_num(enemy.get("facing")) or absf(float(enemy["facing"])) != 1.0:
			return "%s: düşman yönü -1 veya 1 olmalı." % id
	var boss_value: Variant = d.get("boss")
	if boss_value != null:
		if not _is_num(boss_value) or int(boss_value) < 0 or int(boss_value) > 4 or float(boss_value) != float(int(boss_value)):
			return "%s: boss numarası 0-4 olmalı." % id
	elif (d["enemies"] as Array).is_empty():
		return "%s: odada düşman yok." % id
	return ""

func configure(room_data: Dictionary, start_phase: int = 1) -> void:
	data = room_data
	boss_start_phase = start_phase

func _ready() -> void:
	var size: Vector2 = Vector2(float(data["size"][0]), float(data["size"][1]))
	for solid in data["solids"]:
		var rect := Rect2(float(solid[0]), float(solid[1]), float(solid[2]), float(solid[3]))
		_solids.append(rect)
		# Platforms hovering above the floor line are drop-through from below.
		_add_body(rect, rect.position.y < size.y - 60.0)
	_add_body(Rect2(-24, -200, 24, size.y + 400), false)
	_add_body(Rect2(size.x, -200, 24, size.y + 400), false)
	_exit = Vector2(float(data["exit"][0]), float(data["exit"][1]))
	player = PrismPlayer.new()
	player.position = Vector2(float(data["spawn"][0]), float(data["spawn"][1]))
	add_child(player)
	player.died.connect(_on_player_died)
	for entry in data["enemies"]:
		var enemy := PrismEnemy.new()
		enemy.configure(PrismEnemy.TYPE_IDS[entry["type"]], chapter)
		enemy.position = Vector2(float(entry["pos"][0]), float(entry["pos"][1]))
		enemy.facing = float(entry["facing"])
		add_child(enemy)
		enemy.defeated.connect(_on_enemy_defeated)
		enemies_left += 1
	if data.get("boss") != null:
		var b := PrismEnemy.new()
		b.configure(0, int(data["boss"]), true, boss_start_phase)
		b.position = Vector2(size.x - 140.0, float(data["spawn"][1]) - 30.0)
		add_child(b)
		b.defeated.connect(_on_enemy_defeated)
		b.phase_changed.connect(func(p: int): boss_phase_reached.emit(p))
		boss = b
		enemies_left += 1
	queue_redraw()

func _add_body(rect: Rect2, one_way: bool) -> void:
	var body := StaticBody2D.new()
	body.position = rect.get_center()
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = rect.size
	shape.shape = rectangle
	shape.one_way_collision = one_way
	body.add_child(shape)
	add_child(body)

func _physics_process(delta: float) -> void:
	if _ended:
		return
	# Real time, so slow-mo does not inflate the score timer.
	elapsed += delta / maxf(Engine.time_scale, 0.01)
	if exit_open and is_instance_valid(player) and not player.dead:
		if player.global_position.distance_to(_exit) <= EXIT_RADIUS:
			_ended = true
			exited.emit()
	queue_redraw()

func _on_enemy_defeated(_enemy: Node) -> void:
	enemies_left = maxi(0, enemies_left - 1)
	if enemies_left == 0 and not exit_open:
		exit_open = true
		cleared.emit()

func _on_player_died() -> void:
	_ended = true
	player_died.emit()

func on_projectile_environment(p: Node) -> bool:
	var point: Vector2 = p.global_position - global_position
	for rect in _solids:
		if rect.has_point(point):
			return true
	return false

func _draw() -> void:
	if data.is_empty():
		return
	var edge: Color = palette[4] if palette.size() > 4 else Color("8fe4b0")
	var fill: Color = palette[2] if palette.size() > 2 else Color("1d4541")
	for rect in _solids:
		draw_rect(rect, fill)
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 2)), edge)
	var color: Color = edge if exit_open else edge.darkened(0.6)
	var c := _exit + Vector2(0, -16)
	var pts := PackedVector2Array([c + Vector2(0, -20), c + Vector2(12, 0), c + Vector2(0, 16), c + Vector2(-12, 0)])
	if exit_open:
		draw_colored_polygon(pts, Color(color, 0.35))
	draw_polyline(pts + PackedVector2Array([pts[0]]), color, 2)
