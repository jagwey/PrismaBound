class_name PrismEnemy
extends Node2D
## All attack damage is preceded by a visible wind-up. Art is original temporary pixel geometry.

signal defeated(enemy)
signal phase_changed(phase: int)

enum State { IDLE, PATROL, DETECT, TELEGRAPH, ATTACK, RECOVER, STUNNED, DEAD }
const NAMES := ["Orman Nişancısı", "Aldatıcı Büyücü", "Kristal Okçu", "Demir Muhafız", "Işın Gözü", "", "Çılgın Savaşçı"]
const TYPE_IDS := {"shooter": 0, "feint": 1, "spread": 2, "armored": 3, "beam": 4, "melee": 6}
const BOSS_HITS := [3, 4, 4, 5, 5]
const BOSS_HIT_GUARD := 0.25
const BOSSES := ["ORMAN MUHAFIZI", "KRİSTAL GOLEM", "KIZIL ŞÖVALYE", "KÖR KÂHİN", "PRİZMA'NIN YANSIMASI"]
const PALETTES := [Color("71cba6"), Color("af8fe9"), Color("ee795e"), Color("c087e8"), Color("bcebef")]

var archetype: int = 0
var region: int = 0
var is_boss: bool = false
var hits_left: int = 0
var display_name: String = NAMES[0]
var hurt_radius: float = 15.0
var state: State = State.IDLE
var phase: int = 1
var attack_index: int = 0
var state_time: float = 0.0
var age: float = 0.0
var facing: float = -1.0
var home: Vector2
var target: Vector2
var _flash: float = 0.0
var hit_guard: float = 0.0
var _attack_time: float = 0.0
var _next_shot: float = 0.0
var _shot_count: int = 0
var _feint: bool = false
var _death_emitted: bool = false
var _player: Node2D

func configure(type: int, area: int, boss: bool = false, start_phase: int = 1) -> void:
	archetype = type if TYPE_IDS.values().has(type) else 0
	region = clampi(area, 0, 4)
	is_boss = boss
	hurt_radius = 27.0 if boss else 16.0
	display_name = BOSSES[region] if boss else NAMES[archetype]
	if boss:
		phase = clampi(start_phase, 1, 3 if region == 4 else 2)
		hits_left = _hits_for_phase(phase)
	else:
		phase = 1
		hits_left = 1

func _hits_for_phase(p: int) -> int:
	var total: int = BOSS_HITS[region]
	if p >= 3 and region == 4:
		return 1
	if p == 2:
		return total - ceili(total / 2.0)
	return total

func phase_for_hits(hits: int) -> int:
	var total: int = BOSS_HITS[region]
	if region == 4 and hits == 1:
		return 3
	return 2 if total - hits >= ceili(total / 2.0) else 1

func _ready() -> void:
	add_to_group("enemies")
	if is_boss:
		add_to_group("bosses")
	home = position
	_player = get_tree().get_first_node_in_group("player") as Node2D
	_enter(State.IDLE, 0.3)

func _physics_process(delta: float) -> void:
	age += delta
	state_time -= delta
	_flash = maxf(0.0, _flash - delta)
	hit_guard = maxf(0.0, hit_guard - delta)
	if state == State.DEAD:
		if state_time <= 0.0:
			queue_free()
		queue_redraw()
		return
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node2D
		return
	var distance: float = global_position.distance_to(_player.global_position)
	if distance > 740.0:
		return
	if state != State.ATTACK:
		facing = signf(_player.global_position.x - global_position.x)
		if facing == 0.0:
			facing = -1.0
	position.x = clampf(position.x, home.x - 145.0, home.x + 145.0)
	match state:
		State.IDLE:
			if distance < (430.0 if is_boss else 340.0):
				_enter(State.DETECT, 0.5)
			elif state_time <= 0.0:
				_enter(State.PATROL, 1.5)
		State.PATROL:
			position.x = home.x + sin(age * 0.7) * 22.0
			if distance < (430.0 if is_boss else 340.0):
				_enter(State.DETECT, 0.45)
			elif state_time <= 0.0:
				_enter(State.IDLE, 0.7)
		State.DETECT, State.RECOVER:
			if state_time <= 0.0:
				_begin_telegraph()
		State.TELEGRAPH:
			if state_time <= 0.0:
				if _feint:
					_feint = false
					_enter(State.TELEGRAPH, 0.42)
				else:
					target = _player.global_position + Vector2(0.0, -17.0)
					_enter(State.ATTACK, _attack_duration())
					_shot_count = 0
					_next_shot = 0.0
					_attack_time = 0.0
		State.ATTACK:
			_attack_time += delta
			_next_shot -= delta
			_contact_check()
			if _next_shot <= 0.0:
				_attack_tick()
			if state_time <= 0.0:
				attack_index += 1
				_enter(State.RECOVER, 0.9 if phase == 1 else 0.65)
		State.STUNNED:
			if state_time <= 0.0:
				_enter(State.RECOVER, 0.65)
	if is_boss and region == 4 and state == State.RECOVER:
		# Reflection moves in response to the player while remaining inside its arena.
		position.x = move_toward(position.x, home.x - (_player.position.x - (home.x - 150.0)) * 0.35, delta * 35.0)
	queue_redraw()

func _enter(next: State, duration: float) -> void:
	state = next
	state_time = duration
	queue_redraw()

func _begin_telegraph() -> void:
	target = _player.global_position + Vector2(0, -17)
	_feint = not is_boss and archetype == 1
	_enter(State.TELEGRAPH, 0.8 if is_boss else 0.65)

func _attack_duration() -> float:
	if is_boss:
		return [1.0, 1.25, 1.0, 1.3, 1.25][region]
	return 1.0 if archetype == 4 else 0.5

func _attack_tick() -> void:
	_next_shot = 0.28
	if is_boss:
		_boss_attack()
	else:
		_enemy_attack()
	_shot_count += 1

func _enemy_attack() -> void:
	var direction: Vector2 = global_position.direction_to(target)
	match archetype:
		0:
			if _shot_count == 0:
				_shoot(direction * 150.0, "normal")
		1:
			if _shot_count == 0:
				_shoot(direction * 175.0, "arc")
		2:
			if _shot_count < 2:
				_spread(direction, 175.0, 3, 0.16, "spread")
		3:
			if _shot_count == 0:
				_shoot(direction * 120.0, "heavy")
		4:
			# Closely spaced visible beam segments: no invisible ray damage.
			_next_shot = 0.10
			_shoot(direction * 245.0, "beam")
		6:
			if _shot_count == 0:
				position.x = move_toward(position.x, target.x, 46.0)
				_melee(46.0)

func _boss_attack() -> void:
	var direction: Vector2 = global_position.direction_to(target)
	var pattern: int = attack_index % 4
	match region:
		0:
			match pattern:
				0:
					if _shot_count < phase + 1:
						_shoot(direction * 150.0, "normal")
				1:
					if _shot_count < 3:
						_shoot(Vector2(facing * (80.0 + _shot_count * 25.0), -155.0), "arc")
				2:
					if _shot_count < phase:
						_shoot(Vector2(facing * 150.0, 0), "shockwave", Vector2(0, 8))
				3:
					if _shot_count == 0:
						_spread(direction, 160.0, 3 + phase * 2, 0.19, "spread")
		1:
			match pattern:
				0:
					if _shot_count < phase:
						_shoot(direction * 125.0, "heavy")
				1:
					if _shot_count < 3:
						_shoot(Vector2(facing * 140.0, 0), "shockwave", Vector2(0, 8))
				2:
					if _shot_count < phase:
						_spread(direction, 155.0, 5, 0.15, "spread")
				3:
					_next_shot = 0.13
					_shoot(direction.rotated(sin(_attack_time * 2.0) * 0.12) * 250.0, "beam")
		2:
			match pattern:
				0:
					if _shot_count < phase + 1:
						_shoot(Vector2(facing * 170, 0), "shockwave", Vector2(0, 8))
				1:
					if _shot_count == 0:
						_shoot(direction * 135.0, "heavy")
				2:
					if _shot_count < 2:
						position.x = move_toward(position.x, target.x, 45.0)
						_melee(48.0)
				3:
					if _shot_count == 0:
						_spread(direction, 135.0, 3 + phase, 0.22, "explosive")
		3:
			match pattern:
				0:
					if _shot_count < phase + 1:
						_shoot(direction * 125.0, "dark")
				1:
					if _shot_count == 0:
						_shoot(direction * 145.0, "dark")
				2:
					_next_shot = 0.16
					_shoot(direction * 220.0, "beam")
				3:
					if _shot_count < phase:
						_shoot(Vector2(facing * 155.0, 0), "shockwave", Vector2(0, 8))
		4:
			match pattern:
				0:
					if _shot_count < phase + 1:
						_shoot(direction.rotated((_shot_count - 1) * 0.10) * 165.0, "normal")
				1:
					if _shot_count < phase:
						_shoot(direction * 145.0, "heavy")
				2:
					if _shot_count == 0:
						_spread(direction, 160.0, 3 + phase, 0.18, "dark")
				3:
					_next_shot = 0.16
					_shoot(direction * 240.0, "beam")

func _shoot(velocity: Vector2, kind: String, offset: Vector2 = Vector2.ZERO) -> Node:
	var projectile_script: Script = load("res://scripts/projectile.gd") as Script
	if projectile_script == null:
		return null
	var shot: Node = projectile_script.spawn(get_parent(), global_position + Vector2(facing * 22.0, -8.0) + offset, velocity, kind, 0)
	shot.set("owner_actor", self)
	return shot

func _spread(direction: Vector2, speed: float, count: int, spacing: float, kind: String) -> void:
	for i in count:
		_shoot(direction.rotated((i - (count - 1) * 0.5) * spacing) * speed, kind)

func _melee(radius: float) -> void:
	if is_instance_valid(_player) and global_position.distance_to(_player.global_position + Vector2(0, -15)) < radius:
		_player.kill(global_position)

func _contact_check() -> void:
	# Contact during an attack kills the player, same as a direct melee strike.
	if is_boss or not is_instance_valid(_player):
		return
	if global_position.distance_to(_player.global_position + Vector2(0, -18)) < 22.0:
		_player.kill(global_position)

func hit_by(_source: Node, from: Vector2, cause: String) -> bool:
	if state == State.DEAD or _death_emitted:
		return false
	if not is_boss and archetype == 3 and cause == "reflect":
		var side: float = signf(from.x - global_position.x)
		if facing == 0.0 or side == facing:
			_flash = 0.1
			return false
	if not is_boss:
		_die()
		return true
	if hit_guard > 0.0:
		return false
	hit_guard = BOSS_HIT_GUARD
	hits_left -= 1
	_flash = 0.13
	if hits_left <= 0:
		hits_left = 0
		_die()
		return true
	var desired: int = phase_for_hits(hits_left)
	if desired > phase:
		phase = desired
		phase_changed.emit(phase)
		_enter(State.STUNNED, 0.8)
	queue_redraw()
	return true

func _die() -> void:
	if _death_emitted:
		return
	_death_emitted = true
	remove_from_group("enemies")
	remove_from_group("bosses")
	if is_boss:
		for projectile in get_tree().get_nodes_in_group("projectiles"):
			if projectile.get("owner_actor") == self:
				# No lingering boss-owned attacks after the victory transition.
				projectile.queue_free()
	_enter(State.DEAD, 0.55)
	defeated.emit(self)

func _draw() -> void:
	var tint: Color = PALETTES[region]
	var scale_factor: float = 1.65 if is_boss else 1.0
	var bob: float = roundf(sin(age * 3.0) * (3.0 if archetype == 4 else 1.0))
	if state == State.DEAD:
		for i in 9:
			var angle: float = i * TAU / 9.0
			var point: Vector2 = Vector2.from_angle(angle) * (0.55 - state_time) * 80.0
			draw_rect(Rect2(point.round(), Vector2(3, 3)), Color(tint, maxf(state_time / 0.55, 0)))
		return
	draw_set_transform(Vector2(0, bob), 0, Vector2.ONE * scale_factor)
	var body: Color = tint.darkened(0.6)
	if _flash > 0:
		body = Color(1, 1, 1)
	draw_rect(Rect2(-12, -19, 24, 35), Color("0a101d"))
	if is_boss:
		# Each boss has a distinct silhouette, not just a palette swap.
		match region:
			0:
				draw_rect(Rect2(-19, -13, 38, 23), body)
				draw_line(Vector2(-8, -18), Vector2(-18, -30), tint, 4)
				draw_line(Vector2(8, -18), Vector2(18, -30), tint, 4)
			1:
				draw_colored_polygon(PackedVector2Array([Vector2(-19, -9), Vector2(-8, -31), Vector2(9, -25), Vector2(20, -5), Vector2(15, 15), Vector2(-14, 15)]), body)
				draw_rect(Rect2(-5, -15, 10, 12), tint if state == State.RECOVER else tint.darkened(0.4))
			2:
				draw_rect(Rect2(-17, -16, 34, 31), body)
				draw_rect(Rect2(-10, -26, 20, 11), tint.darkened(0.3))
				draw_rect(Rect2(8, -32, 4, 18), tint)
			3:
				draw_colored_polygon(PackedVector2Array([Vector2(0, -30), Vector2(-19, 16), Vector2(19, 16)]), body)
				draw_rect(Rect2(-10, -18, 20, 3), tint)
			4:
				draw_rect(Rect2(-8, -20, 16, 29), body)
				for i in 5:
					var p: Vector2 = Vector2.from_angle(age * 0.4 + i * TAU / 5) * 25
					draw_rect(Rect2(p.round(), Vector2(4, 7)), Color.from_hsv(float(i) / 5, 0.5, 0.9))
	else:
		match archetype:
			0, 2:
				draw_rect(Rect2(-8, -16, 16, 26), body)
				draw_line(Vector2(facing * 13, -15), Vector2(facing * 18, 8), tint, 2)
			1:
				draw_colored_polygon(PackedVector2Array([Vector2(0, -24), Vector2(-12, 15), Vector2(12, 15)]), body)
			3:
				draw_rect(Rect2(-12, -18, 24, 31), body)
				draw_rect(Rect2(facing * 12 - 3, -15, 6, 29), tint)
			4:
				draw_colored_polygon(PackedVector2Array([Vector2(-16, -3), Vector2(0, -19), Vector2(16, -3), Vector2(0, 12)]), body)
				draw_rect(Rect2(-5, -8, 10, 7), tint)
			6:
				draw_rect(Rect2(-13, -13, 26, 23), body)
				draw_rect(Rect2(facing * 16 - 3, -13, 6, 24), tint)
	draw_rect(Rect2(-7, -16, 14, 10), tint.darkened(0.4))
	draw_rect(Rect2(facing * 3 - 2, -12, 4, 3), tint.lightened(0.5))
	var step: float = roundf(sin(age * 5) * 2) if state == State.PATROL else 0.0
	draw_rect(Rect2(-9, 10, 6, 8 + step), body)
	draw_rect(Rect2(3, 10, 6, 8 - step), body)
	if state == State.TELEGRAPH:
		var warn: Color = Color("ffe5a0") if not _feint else Color("ae8dca")
		draw_rect(Rect2(-2, -34, 4, 8), warn)
		draw_rect(Rect2(-2, -24, 4, 3), warn)
	if state == State.STUNNED:
		for i in 3:
			draw_rect(Rect2(Vector2(-9 + i * 9, -26 - int(sin(age * 10 + i) * 3)), Vector2(3, 3)), Color("ffe8b5"))
	draw_set_transform(Vector2.ZERO)
	if state == State.TELEGRAPH and is_boss and attack_index % 4 == 2 and region == 2:
		draw_line(Vector2.ZERO, Vector2(facing * 94, 0), Color(1.0, 0.4, 0.25, 0.5), 2)
