class_name PrismWorld
extends Node2D

signal region_completed(area: int)
signal checkpoint_reached(area: int)
signal story_requested(key: String)
signal player_died

const WORLD_WIDTH: float = 3200.0
const TARGET := Vector2(1950, 266)
const EMITTER := Vector2(1900, 266)
const ELEMENTS: Array[String] = ["fire", "ice", "nature"]

var region: int = 0
var player: Node2D
var boss: Node2D
var checkpoint := Vector2(140, 299)
var checkpoint_id: int = 0
var objective: String = ""
var puzzle_solved: bool = false
var boss_defeated: bool = false
var width: float = WORLD_WIDTH
var info: Dictionary = {}
var progress: Dictionary = {}
var puzzle_step: int = 0
var puzzle_hits: int = 0
var elapsed: float = 0.0
var emitter_timer: float = 1.0
var emitter_index: int = 0
var camera: Camera2D
var platforms: Array[Rect2] = []
var moving_platform: AnimatableBody2D
var spirit_bridge: StaticBody2D
var spirit_shape: CollisionShape2D
var puzzle_gate: StaticBody2D
var arena_gate: StaticBody2D
var encounter_nodes: Array[Node2D] = []
var effects: Array[Dictionary] = []
var triggered: Dictionary = {}
var palette: Array[Color] = []
var dead: bool = false
var transitioning: bool = false
var flash_time: float = 0.0
var hint_text: String = ""
var hint_timer: float = 0.0
var boss_started: bool = false
var checkpoint_cooldown: float = 0.0
var hazard_clock: float = 0.0
var _enemy_script: Script
var _projectile_script: Script

func configure(area: int, saved_progress: Dictionary) -> void:
	region = clampi(area, 0, 4)
	progress = saved_progress.duplicate(true)

func _ready() -> void:
	var raw: String = FileAccess.get_file_as_string("res://data/regions.json").trim_prefix("\ufeff")
	var regions: Variant = JSON.parse_string(raw)
	if not regions is Array or regions.size() != 5:
		push_error("PRISMBOUND: region data could not be read")
		return
	info = regions[region]
	for value in info["palette"]:
		palette.append(Color(str(value)))
	_enemy_script = load("res://scripts/enemy.gd")
	_projectile_script = load("res://scripts/projectile.gd")
	_build_geometry()
	var flags: Dictionary = progress.get("flags", {})
	if int(flags.get("checkpoint_region", -1)) == region:
		checkpoint_id = clampi(int(flags.get("checkpoint_id", 0)), 0, 1)
		if checkpoint_id == 1:
			checkpoint = Vector2(2250, 299)
			puzzle_solved = true
			puzzle_step = 3
			_remove_puzzle_gate()
	var player_script: Script = load("res://scripts/player.gd")
	player = player_script.new()
	player.position = checkpoint
	player.configure_progress(region, int(progress.get("upgrades", 0)))
	player.shards = int(progress.get("shards", 0))
	add_child(player)
	player.died.connect(_on_player_died)
	camera = Camera2D.new()
	camera.position = Vector2(clampf(player.position.x, 320, WORLD_WIDTH - 320), 180)
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_WIDTH)
	camera.limit_bottom = 360
	add_child(camera)
	_build_encounters()
	_update_objective()
	queue_redraw()

func _build_geometry() -> void:
	_add_platform(Rect2(0, 300, 730, 60))
	_add_platform(Rect2(900, 300, 690, 60))
	_add_platform(Rect2(1680, 300, 1520, 60))
	_add_platform(Rect2(-24, -200, 24, 600), false)
	_add_platform(Rect2(3200, -200, 24, 600), false)
	_add_platform(Rect2(300, 246, 100, 13))
	_add_platform(Rect2(525, 207, 100, 13))
	_add_platform(Rect2(970, 247, 110, 13))
	_add_platform(Rect2(1170, 203, 115, 13))
	_add_platform(Rect2(1460, 246, 100, 13))
	_add_platform(Rect2(1608, 267, 53, 12))
	_add_platform(Rect2(2110, 247, 90, 13))
	if region == 3:
		spirit_bridge = _body(Rect2(742, 278, 146, 12), false)
		spirit_shape = spirit_bridge.get_child(0)
	else:
		moving_platform = AnimatableBody2D.new()
		moving_platform.position = Vector2(810, 264)
		moving_platform.collision_layer = 1
		moving_platform.collision_mask = 0
		moving_platform.sync_to_physics = false
		var shape := CollisionShape2D.new()
		var rectangle := RectangleShape2D.new()
		rectangle.size = Vector2(94, 12)
		shape.shape = rectangle
		moving_platform.add_child(shape)
		add_child(moving_platform)
	puzzle_gate = _body(Rect2(2345, 110, 12, 190), false)

func _body(rect: Rect2, one_way: bool = false) -> StaticBody2D:
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
	return body

func _add_platform(rect: Rect2, visible_platform: bool = true) -> void:
	_body(rect, rect.position.y < 290 and visible_platform)
	if visible_platform:
		platforms.append(rect)

func _build_encounters() -> void:
	var types: Array = info["enemies"]
	var positions: Array[Vector2] = [Vector2(540, 280), Vector2(1050, 280), Vector2(1410, 280), Vector2(1480, 280)]
	for i in range(positions.size()):
		if checkpoint_id > 0:
			break
		var enemy: Node2D = _enemy_script.new()
		enemy.configure(int(types[i]), region, false)
		enemy.position = positions[i]
		enemy.defeated.connect(_on_enemy_defeated)
		add_child(enemy)
		encounter_nodes.append(enemy)

func _spawn_boss() -> void:
	if boss_started or boss_defeated:
		return
	boss_started = true
	boss = _enemy_script.new()
	boss.configure(region, region, true)
	boss.position = Vector2(2830, 260)
	boss.defeated.connect(_on_boss_defeated)
	add_child(boss)
	arena_gate = _body(Rect2(2410, 80, 10, 220), false)
	story_requested.emit("boss_%d" % region)
	_update_objective()

func _physics_process(delta: float) -> void:
	if not is_instance_valid(player) or palette.is_empty():
		return
	elapsed += delta
	flash_time = maxf(0.0, flash_time - delta)
	hint_timer = maxf(0.0, hint_timer - delta)
	checkpoint_cooldown = maxf(0.0, checkpoint_cooldown - delta)
	if is_instance_valid(moving_platform):
		moving_platform.position = Vector2(815 + sin(elapsed * 1.15) * 36, 267 + sin(elapsed * 0.8) * 12)
	if is_instance_valid(spirit_shape):
		spirit_shape.set_deferred("disabled", int(player.mode) != 4 and int(player.mode) != 5)
	camera.position.x = roundf(clampf(player.position.x, 320, WORLD_WIDTH - 320))
	_update_effects(delta)
	if dead or transitioning:
		queue_redraw()
		return
	if player.position.y > 410:
		player.take_damage(18.0, player.position + Vector2(0, 40))
		if not dead:
			player.position = checkpoint
			player.velocity = Vector2.ZERO
			_show_hint("Uçurum seni sunağa geri bıraktı. Kayıp: 18 can.")
	if player.position.x > 1660 and player.position.x < 2310 and not puzzle_solved:
		emitter_timer -= delta
		if emitter_timer <= 0.0:
			_emit_puzzle_projectile()
			emitter_timer = 2.5 if region != 4 else 2.1
	if region == 2 and player.position.x > 1290 and player.position.x < 1360:
		hazard_clock += delta
		if fmod(elapsed, 3.5) > 2.0 and player.position.y > 277 and hazard_clock > 0.7:
			hazard_clock = 0.0
			player.take_damage(12.0, Vector2(1325, 310))
	if player.position.x > 2450 and puzzle_solved:
		_spawn_boss()
	if Input.is_action_just_pressed("interact"):
		_interact()
	_update_objective()
	queue_redraw()

func _interact() -> void:
	for point in [Vector2(140, 299), Vector2(2250, 299)]:
		if player.position.distance_to(point) < 72.0:
			if point.x > 2000 and not puzzle_solved:
				_show_hint("Önce kristal mührü çöz.")
				return
			checkpoint = point
			checkpoint_id = 1 if point.x > 2000 else 0
			player.heal()
			if checkpoint_cooldown <= 0.0:
				checkpoint_cooldown = 1.0
				checkpoint_reached.emit(region)
				_burst(point - Vector2(0, 22), palette[4], 18)
				_show_hint("Prizma sunağı: iyileştin ve ilerlemen kaydedildi.")
			return
	if player.position.distance_to(Vector2(3100, 280)) < 85:
		if boss_defeated:
			transitioning = true
			region_completed.emit(region)
		else:
			_show_hint("Bu geçit muhafızın hatırasına bağlı.")
		return
	if player.position.x > 1620 and player.position.x < 2150:
		_show_hint(str(info["hint"]), 7.0)
		return
	if player.position.x > 330 and player.position.x < 450:
		story_requested.emit("curse" if region == 0 else "region_%d" % region)
		return
	if player.position.x > 1100 and player.position.x < 1260:
		story_requested.emit("region_%d" % region)

func _emit_puzzle_projectile() -> void:
	var element: String = str(info["element"])
	var kind: String = "normal"
	if region == 2:
		kind = "heavy"
	elif region == 3:
		kind = "dark"
	elif region == 4:
		element = ELEMENTS[emitter_index % 3]
		emitter_index += 1
	var speed: float = 160.0 if region < 2 else 145.0
	var shot: Node2D = _projectile_script.spawn(self, EMITTER, Vector2(-speed, 0), 10.0, kind, element, 0)
	shot.set_meta("puzzle_shot", true)
	shot.set_meta("world_mirror_time", -10.0)
	_burst(EMITTER, _element_color(element), 5)

func on_projectile_environment(p: Node) -> bool:
	if not p is Node2D:
		return false
	var point: Vector2 = p.global_position
	if point.x < -40 or point.x > WORLD_WIDTH + 40 or point.y > 420 or point.y < -220:
		return true
	# A deterministic, visible wall mirror. Metadata prevents repeated collisions
	# while a projectile is still inside its narrow contact band.
	if region == 1 and int(p.team) == 1 and point.x >= 2044 and point.x <= 2078 and point.y > 185 and point.y < 291:
		if p.velocity.x > 0 and elapsed - float(p.get_meta("world_mirror_time", -10.0)) > 0.15:
			p.velocity = p.velocity.bounce(Vector2.LEFT)
			p.global_position.x = 2041
			p.reflection_count += 1
			p.set_meta("world_mirror_time", elapsed)
			_burst(Vector2(2048, point.y), palette[4], 8)
	if puzzle_solved or int(p.team) != 1 or point.distance_to(TARGET) > 25:
		return false
	if region == 1 and int(p.reflection_count) < 2:
		return false
	if region == 2 and str(p.kind) != "heavy":
		_show_hint("Kızıl mühür ağır bir küre bekliyor.")
		return true
	if region == 3 and str(p.kind) != "dark":
		_show_hint("Bu kristal yalnız ruh enerjisini duyuyor.")
		return true
	if region == 4 and str(p.element) != ELEMENTS[mini(puzzle_step, 2)]:
		_show_hint("Sıradaki renk: " + ["KIRMIZI", "MAVİ", "YEŞİL"][mini(puzzle_step, 2)])
		_burst(TARGET, Color("b47a8d"), 4)
		return true
	puzzle_hits += 1
	puzzle_step += 1
	flash_time = 0.18
	_burst(TARGET, _element_color(str(p.element)), 18)
	if region != 4 or puzzle_step >= 3:
		_solve_puzzle()
	else:
		_show_hint("Doğru! Sıradaki renk: " + ["KIRMIZI", "MAVİ", "YEŞİL"][puzzle_step])
	return true

func _solve_puzzle() -> void:
	if puzzle_solved:
		return
	puzzle_solved = true
	_remove_puzzle_gate()
	player.add_shards(6)
	_show_hint("Kristal mühür çözüldü. Sağdaki sunakta kaydet.", 5.0)
	_update_objective()

func _remove_puzzle_gate() -> void:
	if is_instance_valid(puzzle_gate):
		puzzle_gate.queue_free()
		puzzle_gate = null

func _on_enemy_defeated(enemy: Node) -> void:
	if is_instance_valid(player):
		player.add_shards(3)
	if enemy is Node2D:
		_burst(enemy.position, palette[4], 12)

func _on_boss_defeated(enemy: Node) -> void:
	if boss_defeated:
		return
	boss_defeated = true
	boss = null
	if is_instance_valid(arena_gate):
		arena_gate.queue_free()
		arena_gate = null
	player.add_shards(15)
	player.heal()
	_burst(enemy.position, palette[4], 30)
	_show_hint("Prizma parçası özgür. Sağdaki geçitte E'ye bas.", 6.0)
	story_requested.emit("victory_%d" % region)
	_update_objective()

func _on_player_died() -> void:
	if dead:
		return
	dead = true
	player_died.emit()

func restart_checkpoint() -> void:
	dead = false
	transitioning = false
	player.heal()
	player.position = checkpoint
	player.velocity = Vector2.ZERO
	for node in get_children():
		if node.get_script() == _projectile_script:
			node.queue_free()
	if is_instance_valid(boss):
		boss.queue_free()
		boss = null
	if is_instance_valid(arena_gate):
		arena_gate.queue_free()
		arena_gate = null
	boss_started = false
	emitter_timer = 1.0
	_update_objective()

func _update_objective() -> void:
	if boss_defeated:
		objective = "Prizma parçasını aldın · Sağdaki geçit [E]"
	elif boss_started:
		objective = "%s · Saldırısını ona geri ver" % str(info["boss"])
	elif puzzle_solved:
		objective = "Sunakta kaydet [E] · Muhafıza ulaş →"
	elif player != null and player.position.x > 1600:
		objective = str(info["hint"])
	else:
		objective = "Doğuya ilerle → · Taş yazıtları ve sunakları [E] ile incele"

func _show_hint(text: String, duration: float = 4.0) -> void:
	hint_text = text
	hint_timer = duration

func _burst(point: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		if effects.size() >= 90:
			break
		var angle: float = float(i) * TAU / float(maxi(count, 1))
		effects.append({"p":point, "v":Vector2.from_angle(angle) * (28 + i % 5 * 12), "life":0.45 + (i % 3) * 0.08, "color":color})

func _update_effects(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		effects[i]["life"] -= delta
		if effects[i]["life"] <= 0:
			effects.remove_at(i)
		else:
			effects[i]["p"] += effects[i]["v"] * delta
			effects[i]["v"].y += 65 * delta

func _element_color(element: String) -> Color:
	match element:
		"fire": return Color("ff977c")
		"ice": return Color("8fddff")
		"nature", "poison": return Color("b5eb9b")
		"spirit", "dark": return Color("d7a1ff")
		_: return palette[4] if not palette.is_empty() else Color.WHITE

func _draw() -> void:
	if palette.is_empty():
		return
	var left: float = camera.position.x - 320 if is_instance_valid(camera) else 0.0
	_draw_background(left)
	for rect in platforms:
		if rect.end.x < left - 30 or rect.position.x > left + 670:
			continue
		draw_rect(rect, palette[1])
		draw_rect(Rect2(rect.position, Vector2(rect.size.x, 4)), palette[3])
		draw_rect(Rect2(rect.position + Vector2(0, 4), Vector2(rect.size.x, 2)), palette[2])
		for tx in range(int(rect.position.x / 24) * 24, int(rect.end.x), 24):
			if tx >= rect.position.x:
				draw_rect(Rect2(tx + 2, rect.position.y + 11 + (tx % 3) * 3, 11, 2), palette[2])
	if is_instance_valid(moving_platform):
		var mp: Vector2 = moving_platform.position.round()
		draw_rect(Rect2(mp - Vector2(47, 6), Vector2(94, 12)), palette[2])
		draw_rect(Rect2(mp - Vector2(47, 6), Vector2(94, 3)), palette[4])
		draw_line(mp + Vector2(-34, 6), mp + Vector2(-34, 20), palette[3], 2)
		draw_line(mp + Vector2(34, 6), mp + Vector2(34, 20), palette[3], 2)
	if region == 3:
		var visible_bridge: bool = is_instance_valid(player) and (int(player.mode) == 4 or int(player.mode) == 5)
		var bridge_color: Color = palette[4] if visible_bridge else Color(palette[3], 0.22)
		for bx in range(742, 888, 16):
			draw_rect(Rect2(bx, 278, 12, 4 if visible_bridge else 1), bridge_color)
		_world_text(Vector2(750, 244), "RUH AYNASI [Q]", palette[4], 10)
	_draw_altar(Vector2(140, 300), checkpoint_id == 0)
	_draw_altar(Vector2(2250, 300), checkpoint_id == 1)
	_draw_sign(Vector2(380, 300), "[E] Kılıç" if region == 0 else "[E] Yazıt")
	_draw_sign(Vector2(1190, 203), "[E] Hatıra")
	_draw_puzzle()
	if is_instance_valid(puzzle_gate):
		_draw_gate(2350, false)
	if is_instance_valid(arena_gate):
		_draw_gate(2415, true)
	_draw_portal(Vector2(3100, 300), boss_defeated)
	if region == 2:
		var active: bool = fmod(elapsed, 3.5) > 2.0
		for fx in range(1290, 1360, 10):
			draw_rect(Rect2(fx, 298, 7, 3), Color("d26a48"))
			if active:
				draw_rect(Rect2(fx + 2, 275 + int(sin(elapsed * 16 + fx) * 5), 4, 24), Color("f9a35a"))
			elif fmod(elapsed, 3.5) > 1.2:
				draw_rect(Rect2(fx + 2, 292, 4, 6), Color("d26a48"))
	for effect in effects:
		var c: Color = effect["color"]
		c.a = minf(1.0, float(effect["life"]) * 3.0)
		draw_rect(Rect2(Vector2(effect["p"]).round(), Vector2(2, 2)), c)
	if hint_timer > 0:
		draw_rect(Rect2(left + 22, 321, 596, 27), Color(0.025, 0.035, 0.065, 0.94))
		_world_text(Vector2(left + 30, 338), hint_text, palette[4], 11)

func _draw_background(left: float) -> void:
	draw_rect(Rect2(left, 0, 640, 360), palette[0])
	# Three distinct parallax rates, kept behind opaque, readable platforms.
	for layer in range(3):
		var rate: float = [0.12, 0.30, 0.58][layer]
		var spacing: int = [180, 110, 72][layer]
		var offset: float = left * (1.0 - rate)
		var begin: int = int(floor(left * rate / spacing)) - 1
		var color: Color = palette[mini(layer + 1, 3)].darkened(0.42 if layer == 2 else 0.23)
		for index in range(begin, begin + int(640 / spacing) + 4):
			var x: float = roundf(index * spacing + offset)
			var variation: int = absi(index * 43 + layer * 17) % 71
			var ground: float = 295 - layer * 9
			match region:
				0:
					var height: float = 160 + variation + layer * 11
					draw_rect(Rect2(x + 20, ground - height, 11 + layer * 4, height), color)
					for branch in range(3):
						var y: float = ground - height + branch * 38
						draw_rect(Rect2(x - 16 - branch * 7, y, 85 + branch * 12, 25), color)
						draw_rect(Rect2(x - 4 - branch * 7, y - 12, 61 + branch * 12, 12), color)
				1:
					var height: float = 58 + variation * 2
					var poly := PackedVector2Array([Vector2(x, ground), Vector2(x + 15, ground - height), Vector2(x + 30, ground - height - 24), Vector2(x + 48, ground)])
					draw_colored_polygon(poly, color)
					draw_line(Vector2(x + 30, ground - height - 20), Vector2(x + 28, ground - 10), color.lightened(0.08), 2)
					draw_colored_polygon(PackedVector2Array([Vector2(x + 45, 0), Vector2(x + 60, 65 + variation), Vector2(x + 78, 0)]), color)
				2:
					var height: float = 110 + variation
					draw_rect(Rect2(x, ground - height, 65, height), color)
					for crenel in range(0, 65, 20):
						draw_rect(Rect2(x + crenel, ground - height - 12, 12, 12), color)
					draw_rect(Rect2(x + 26, ground - height + 24, 8, 19), palette[0])
					draw_line(Vector2(x + 45, ground - height + 38), Vector2(x + 37, ground - 30), palette[0], 2)
				3:
					var float_y: float = 85 + variation + roundf(sin(elapsed * 0.5 + index) * 5)
					draw_rect(Rect2(x, float_y, 65, 12), color)
					draw_rect(Rect2(x + 12, float_y + 12, 10, 65), color)
					draw_rect(Rect2(x + 43, float_y + 12, 10, 65), color)
					draw_rect(Rect2(x + 8, float_y + 77, 49, 8), color)
				4:
					var float_y: float = 75 + variation + roundf(sin(elapsed * 0.4 + index) * 8)
					var poly := PackedVector2Array([Vector2(x, float_y), Vector2(x + 40, float_y - 22), Vector2(x + 76, float_y), Vector2(x + 45, float_y + 55)])
					draw_colored_polygon(poly, color)
					draw_line(Vector2(x + 40, float_y - 22), Vector2(x + 45, float_y + 51), color.lightened(0.12), 2)
	for i in range(28):
		var px: float = left + fposmod(i * 97.0 - left * 0.19 + sin(elapsed * 0.3 + i) * 8, 640)
		var py: float = fposmod(i * 37.0 + elapsed * (5.0 if region == 2 else -1.8), 275)
		var alpha: float = 0.15 + (sin(elapsed * 1.2 + i) + 1) * 0.11
		draw_rect(Rect2(roundf(px), roundf(py), 2, 2), Color(palette[4], alpha))
	# Foreground ground clutter uses the same pixel scale throughout the world.
	for i in range(maxi(0, int(left / 47)), mini(69, int((left + 680) / 47))):
		var x: int = i * 47
		if (x > 720 and x < 910) or (x > 1580 and x < 1690):
			continue
		if region == 0:
			draw_rect(Rect2(x, 292, 2, 8), palette[3])
			draw_rect(Rect2(x + 4, 287, 2, 13), palette[2])
			if i % 3 == 0:
				draw_rect(Rect2(x + 10, 295, 2, 5), palette[3])
				draw_rect(Rect2(x + 7, 291, 8, 4), palette[4].darkened(0.2))
		else:
			draw_rect(Rect2(x, 296 - i % 3 * 2, 12, 4 + i % 3 * 2), palette[2])

func _draw_altar(point: Vector2, active: bool) -> void:
	var c: Color = palette[4] if active else palette[3]
	draw_rect(Rect2(point - Vector2(20, 8), Vector2(40, 8)), palette[2])
	draw_rect(Rect2(point - Vector2(12, 13), Vector2(24, 5)), palette[3])
	var top: Vector2 = point - Vector2(0, 32 + roundf(sin(elapsed * 2.0) * 2))
	_diamond(top, 9, c)
	draw_line(top + Vector2(0, 10), point - Vector2(0, 14), Color(c, 0.4), 2)
	_world_text(point + Vector2(-26, -50), "SUNAK [E]", c, 10)

func _draw_sign(point: Vector2, label: String) -> void:
	draw_rect(Rect2(point - Vector2(11, 31), Vector2(22, 31)), palette[2])
	for i in range(3):
		draw_rect(Rect2(point - Vector2(6, 25 - i * 6), Vector2(11 - i * 2, 2)), palette[4].darkened(0.35))
	_world_text(point + Vector2(-25, -37), label, palette[4], 9)

func _draw_puzzle() -> void:
	var color: Color = _element_color(str(info["element"]))
	if region == 4:
		color = _element_color(ELEMENTS[mini(puzzle_step, 2)])
	draw_rect(Rect2(1886, 273, 28, 27), palette[2])
	draw_rect(Rect2(1889, 258, 22, 17), palette[3])
	_diamond(EMITTER, 7, color.darkened(0.15))
	if not puzzle_solved:
		draw_rect(Rect2(1885, 251, clampf((2.5 - emitter_timer) / 2.5, 0, 1) * 30, 2), color)
	draw_rect(Rect2(TARGET + Vector2(-13, 17), Vector2(26, 17)), palette[2])
	_diamond(TARGET, 14, palette[4] if puzzle_solved else color)
	_diamond(TARGET, 7, Color("f3fff3") if puzzle_solved else palette[0])
	if flash_time > 0:
		draw_rect(Rect2(TARGET - Vector2(20, 20), Vector2(40, 40)), Color(color, 0.3))
	_world_text(Vector2(1690, 216), "MÜHÜR AÇIK" if puzzle_solved else "AYNA MÜHRÜ · İPUCU [E]", palette[4], 11)
	if region == 1:
		draw_rect(Rect2(2046, 185, 8, 106), palette[3])
		draw_rect(Rect2(2046, 189, 3, 98), palette[4])
		for y in range(191, 284, 16):
			draw_line(Vector2(2055, y), Vector2(2061, y + 6), palette[3], 2)
		_world_text(Vector2(1996, 174), "DUVAR AYNASI", palette[4], 9)
	if region == 4:
		for i in range(3):
			_diamond(Vector2(1922 + i * 28, 223), 5, _element_color(ELEMENTS[i]) if i >= puzzle_step else Color("ffffff"))
	if not puzzle_solved:
		_world_text(Vector2(1725, 286), "←  YANSIT  →", color, 10)

func _draw_gate(x: float, arena: bool) -> void:
	var c: Color = Color("df829a") if arena else palette[4]
	draw_rect(Rect2(x - 8, 110, 16, 190), Color(c, 0.12))
	for y in range(116, 300, 12):
		draw_rect(Rect2(x - 3, y, 6, 7), Color(c, 0.65 + sin(elapsed * 3 + y) * 0.2))
	_diamond(Vector2(x, 100), 9, c)

func _draw_portal(point: Vector2, active: bool) -> void:
	var c: Color = palette[4] if active else palette[2]
	draw_rect(Rect2(point - Vector2(27, 85), Vector2(9, 85)), palette[3])
	draw_rect(Rect2(point + Vector2(18, -85), Vector2(9, 85)), palette[3])
	draw_rect(Rect2(point - Vector2(27, 91), Vector2(54, 9)), palette[3])
	for i in range(6):
		draw_rect(Rect2(point - Vector2(15, 12 + i * 12), Vector2(30, 3)), Color(c, 0.25 + 0.2 * sin(elapsed * 2 + i)))
	_diamond(point - Vector2(0, 102), 10, c)
	_world_text(point + Vector2(-38, -120), "GEÇİT [E]" if active else "MÜHÜRLÜ", c, 11)

func _diamond(point: Vector2, size: float, color: Color) -> void:
	for row in range(-int(size), int(size) + 1):
		var length: int = int(size) - absi(row)
		draw_rect(Rect2(roundf(point.x) - length, roundf(point.y) + row, maxi(1, length * 2), 1), color)

func _world_text(point: Vector2, text: String, color: Color, size: int = 10) -> void:
	draw_string(ThemeDB.fallback_font, point.round(), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
