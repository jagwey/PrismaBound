class_name PrismPlayer
extends CharacterBody2D

signal died
signal stats_changed
signal combat_event(kind: String, pos: Vector2)

const Combat = preload("res://scripts/combat.gd")
const Projectile = preload("res://scripts/projectile.gd")
const RUN_SPEED: float = 155.0
const JUMP_SPEED: float = -305.0
const GRAVITY: float = 870.0
var max_hp: float = 100.0
var hp: float = 100.0
var max_stamina: float = 100.0
var stamina: float = 100.0
var energy: float = 0.0
var shards: int = 0
var mode: int = 0
var unlocked_modes: Array[int] = [0]
var stored_attacks: Array[Dictionary] = []
var storage_capacity: int = 1
var absorb_enabled: bool = false
var aim: Vector2 = Vector2.RIGHT
var perfect_assist: bool = false
var snap_aim: bool = false
var effects_intensity: float = 1.0
var burn_timer: float = 0.0
var burn_tick: float = 0.0
var dead: bool = false
var state: String = "idle"
var guard_broken: float = 0.0
var reflect_timer: float = -1.0
var reflect_cooldown: float = 0.0
var invulnerability: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var bash_cooldown: float = 0.0
var bash_timer: float = 0.0
var stun_timer: float = 0.0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var flash: float = 0.0
var clock: float = 0.0
var facing_direction: float = 1.0
var slow_timer: float = 0.0
var poison_timer: float = 0.0
var poison_tick: float = 0.0
var hit_stop: float = 0.0
var dash_direction: float = 1.0
var landing_timer: float = 0.0
var was_on_floor: bool = false
var guarding: bool = false
var last_mouse_position: Vector2 = Vector2.ZERO
var gamepad_aim_active: bool = false

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(16, 32)
	collider.shape = shape
	collider.position.y = -16
	add_child(collider)
	floor_snap_length = 4.0
	last_mouse_position = get_global_mouse_position()
	queue_redraw()

func configure_progress(region: int, upgrades: int) -> void:
	unlocked_modes.assign([0])
	if region >= 1:
		unlocked_modes.append_array([1, 2])
	if region >= 2:
		unlocked_modes.append(3)
	if region >= 3:
		unlocked_modes.append(4)
	if region >= 4:
		unlocked_modes.append(5)
	absorb_enabled = region >= 1
	max_stamina = 100.0 + float(clampi(upgrades, 0, 8)) * 12.0
	storage_capacity = 2 if upgrades >= 3 else 1
	if mode not in unlocked_modes:
		mode = 0
	stamina = max_stamina
	stats_changed.emit()

func _physics_process(delta: float) -> void:
	clock += delta
	flash = maxf(0, flash - delta)
	if dead:
		state = "death"
		queue_redraw()
		return
	if hit_stop > 0:
		hit_stop -= delta
		queue_redraw()
		return
	for key in ["guard_broken", "invulnerability", "dash_cooldown", "bash_cooldown", "bash_timer", "stun_timer", "reflect_cooldown", "slow_timer", "landing_timer"]:
		set(key, maxf(0.0, float(get(key)) - delta))
	if reflect_timer >= 0.0:
		reflect_timer += delta
		if reflect_timer > 0.28:
			reflect_timer = -1.0
	if burn_timer > 0:
		burn_timer -= delta
		burn_tick -= delta
		if burn_tick <= 0:
			burn_tick = 0.8
			take_damage(2.0, global_position)
	if poison_timer > 0:
		poison_timer -= delta
		poison_tick -= delta
		if poison_tick <= 0:
			poison_tick = 1.0
			take_damage(2.0, global_position)
	_update_aim()
	guarding = Input.is_action_pressed("guard") and guard_broken <= 0.0 and stun_timer <= 0.0 and dash_timer <= 0.0
	if Input.is_action_just_pressed("mode"):
		var index: int = unlocked_modes.find(mode)
		mode = unlocked_modes[(index + 1) % unlocked_modes.size()]
		combat_event.emit("mode", global_position)
		stats_changed.emit()
	if Input.is_action_just_pressed("reflect") and reflect_cooldown <= 0 and guard_broken <= 0 and stun_timer <= 0:
		reflect_timer = 0.0
		reflect_cooldown = 0.32
		combat_event.emit("guard", global_position)
	if Input.is_action_just_pressed("release"):
		release_stored()
	if Input.is_action_just_pressed("bash"):
		shield_bash()
	if Input.is_action_just_pressed("jump"):
		jump_buffer = 0.13
	else:
		jump_buffer = maxf(0, jump_buffer - delta)
	if is_on_floor():
		coyote = 0.10
		if not was_on_floor:
			landing_timer = 0.09
	else:
		coyote = maxf(0, coyote - delta)
	if jump_buffer > 0 and coyote > 0 and stun_timer <= 0:
		velocity.y = JUMP_SPEED
		jump_buffer = 0
		coyote = 0
		combat_event.emit("jump", global_position)
	if Input.is_action_just_released("jump") and velocity.y < -110.0:
		velocity.y *= 0.5
	var axis: float = Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.1:
		facing_direction = signf(axis)
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0 and stamina >= 18 and stun_timer <= 0:
		dash_timer = 0.14 if mode != 3 else 0.10
		dash_cooldown = 0.6 if mode != 3 else 0.85
		dash_direction = signf(axis) if absf(axis) > 0.1 else facing_direction
		stamina -= 18
		invulnerability = 0.12
		combat_event.emit("dash", global_position)
	if dash_timer > 0:
		dash_timer -= delta
		velocity = Vector2(dash_direction * (320.0 if mode != 3 else 245.0), 0)
		state = "dash"
	else:
		var speed: float = RUN_SPEED * (0.78 if mode == 3 else 1.0) * (0.6 if slow_timer > 0 else 1.0)
		if guarding:
			speed *= 0.68
		var target: float = axis * speed if stun_timer <= 0 else 0.0
		velocity.x = move_toward(velocity.x, target, (1100.0 if is_on_floor() else 700.0) * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
		state = "run" if absf(velocity.x) > 12 else "idle"
		if not is_on_floor():
			state = "jump" if velocity.y < 0 else "fall"
		if guarding: state = "guard"
		if reflect_timer >= 0: state = "reflect"
		if bash_timer > 0: state = "bash"
		if stun_timer > 0 or guard_broken > 0: state = "stunned"
		if landing_timer > 0: state = "land"
	was_on_floor = is_on_floor()
	move_and_slide()
	if not guarding and guard_broken <= 0:
		stamina = minf(max_stamina, stamina + 23.0 * delta)
	for i in range(stored_attacks.size() - 1, -1, -1):
		stored_attacks[i]["time"] = float(stored_attacks[i]["time"]) - delta
		if float(stored_attacks[i]["time"]) <= 0:
			stored_attacks.remove_at(i)
	if global_position.y > 550:
		hp = 0
		_die()
	stats_changed.emit()
	queue_redraw()

func _update_aim() -> void:
	var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down", 0.22)
	var mouse: Vector2 = get_global_mouse_position()
	if stick.length() > 0.2:
		aim = stick.normalized()
		gamepad_aim_active = true
	elif mouse.distance_squared_to(last_mouse_position) > 1.0:
		gamepad_aim_active = false
	if not gamepad_aim_active:
		var relative: Vector2 = mouse - (global_position + Vector2(0, -18))
		if relative.length() > 4:
			aim = relative.normalized()
	last_mouse_position = mouse
	if snap_aim:
		aim = Vector2.from_angle(roundf(aim.angle() / (PI / 4.0)) * (PI / 4.0))

func handle_projectile(projectile: Node) -> bool:
	if dead or guard_broken > 0 or stun_timer > 0 or dash_timer > 0:
		return false
	var active: bool = guarding or reflect_timer >= 0
	if not active or not projectile.reflectable:
		return false
	var center: Vector2 = global_position + Vector2(0, -18)
	if not Combat.facing(center, projectile.global_position, aim, projectile.velocity):
		return false
	if projectile.kind == "dark" and mode != 4 and mode != 5:
		return false
	if absorb_enabled and Input.is_action_pressed("absorb") and stored_attacks.size() < storage_capacity and energy >= 10:
		stored_attacks.append({"kind": projectile.kind, "element": projectile.element, "damage": projectile.damage, "speed": projectile.velocity.length(), "time": 18.0})
		energy -= 10
		projectile.consume(false)
		combat_event.emit("absorb", center)
		stats_changed.emit()
		return true
	if reflect_timer >= 0:
		var window: float = 0.085 if mode == 2 else 0.12
		if perfect_assist: window += 0.09
		var is_perfect: bool = reflect_timer <= window
		if projectile.kind == "heavy" and mode != 3 and mode != 5 and not is_perfect:
			_break_guard()
			return false
		var direction: Vector2 = Combat.reflected(projectile.velocity, aim)
		var speed: float = maxf(80, projectile.velocity.length()) * (1.30 if is_perfect else 1.0)
		projectile.velocity = direction * minf(speed, 650.0)
		projectile.team = 1
		projectile.owner_actor = self
		projectile.reflection_count += 1
		projectile.collision_grace = 0.055
		projectile.perfect = is_perfect
		projectile.damage *= (1.65 if is_perfect else 1.0) * (1.35 if mode == 2 else 1.0)
		projectile.global_position = center + aim * 33.0
		if mode == 1:
			projectile.damage *= 0.44
			for angle in [-0.18, 0.18]:
				var split = Projectile.spawn(get_parent(), projectile.position, projectile.velocity.rotated(angle), projectile.damage * 0.63, projectile.kind, projectile.element, 1)
				split.reflection_count = projectile.reflection_count
				split.collision_grace = 0.08
				split.perfect = is_perfect
				split.owner_actor = self
		if is_perfect:
			stamina = minf(max_stamina, stamina + 15)
			energy = minf(100, energy + 18)
			flash = 0.18
			hit_stop = 0.035
		else:
			energy = minf(100, energy + 5)
		combat_event.emit("perfect" if is_perfect else "reflect", center)
		stats_changed.emit()
		return true
	var cost: float = 34.0 if projectile.kind == "heavy" else 16.0
	if mode == 3: cost *= 0.5
	stamina -= cost
	if stamina <= 0 or (projectile.kind == "heavy" and mode != 3 and mode != 5):
		_break_guard()
		return false
	projectile.consume(false)
	combat_event.emit("guard", center)
	stats_changed.emit()
	return true

func _break_guard() -> void:
	stamina = 0
	guard_broken = 0.8
	stun_timer = 0.45
	reflect_timer = -1
	combat_event.emit("guard_break", global_position)

func shield_bash() -> void:
	if dead or bash_cooldown > 0 or stamina < 15 or stun_timer > 0 or guard_broken > 0:
		return
	bash_cooldown = 0.65
	bash_timer = 0.16
	stamina -= 15
	var center: Vector2 = global_position + Vector2(0, -18)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector2 = enemy.global_position - center
		if offset.length() < 55 and offset.normalized().dot(aim) > 0.25:
			enemy.call("take_damage", 5.0, center, false)
			if enemy.has_method("stun"):
				enemy.call("stun", 0.7)
	combat_event.emit("bash", center)
	stats_changed.emit()

func release_stored() -> void:
	if dead or stored_attacks.is_empty() or stun_timer > 0:
		return
	var attack: Dictionary = stored_attacks.pop_front()
	var shot = Projectile.spawn(get_parent(), position + Vector2(0, -18) + aim * 32, aim * maxf(float(attack.speed), 200), float(attack.damage), str(attack.kind), str(attack.element), 1)
	shot.owner_actor = self
	shot.collision_grace = 0.08
	combat_event.emit("release", global_position)
	stats_changed.emit()

func take_damage(amount: float, from: Vector2) -> void:
	if dead or invulnerability > 0:
		return
	hp = maxf(0, hp - amount)
	invulnerability = 0.75
	velocity.x = signf(global_position.x - from.x) * 115
	velocity.y = -90
	stun_timer = 0.14
	flash = 0.12
	combat_event.emit("damage", global_position)
	stats_changed.emit()
	if hp <= 0:
		_die()

func apply_status(element: String) -> void:
	# Caller must only apply on a successful health hit (not blocked/i-frame contact).
	if dead: return
	if element == "ice": slow_timer = 1.3
	if element == "fire":
		burn_timer = 2.4
		burn_tick = 0.8
	if element == "poison" or element == "nature":
		poison_timer = 3
		poison_tick = 1
func _die() -> void:
	if dead: return
	dead = true
	state = "death"
	died.emit()

func heal() -> void:
	dead = false
	hp = max_hp
	stamina = max_stamina
	guard_broken = 0
	poison_timer = 0
	burn_timer = 0
	slow_timer = 0
	invulnerability = 1
	stats_changed.emit()

func add_shards(amount: int) -> void:
	shards += amount
	stats_changed.emit()

func _draw() -> void:
	if effects_intensity > 0.5 and invulnerability > 0 and int(clock * 18) % 2 == 0 and flash <= 0:
		return
	var body: Color = Color("304c69")
	var cloak: Color = Color("80bfb9")
	var tint: Color = Combat.MODE_COLORS[mode]
	var bob: float = -1 if state == "idle" and sin(clock * 3) > 0 else 0
	var stride: float = roundf(sin(clock * 15) * 3) if state == "run" else 0
	if state == "death":
		draw_rect(Rect2(-14, -7, 27, 6), body)
		draw_rect(Rect2(8, -10, 8, 7), Color("dbc1ad"))
		return
	if state == "dash" and effects_intensity > 0:
		for i in range(1, 4):
			draw_rect(Rect2(-8 - dash_direction * float(i) * 9, -29, 16, 26), Color(tint, 0.12 * float(4 - i) * effects_intensity))
	draw_rect(Rect2(-8, -27 + bob, 16, 18), Color("121b30"))
	draw_rect(Rect2(-6, -25 + bob, 12, 16), body)
	draw_rect(Rect2(-7, -24 + bob, 14, 4), cloak)
	draw_rect(Rect2(-9 - facing_direction * 2, -20 + bob, 4, 12), cloak.darkened(0.2))
	draw_rect(Rect2(-6, -10, 5, 8 + stride), Color("182437"))
	draw_rect(Rect2(1, -10, 5, 8 - stride), Color("182437"))
	draw_rect(Rect2(-7, -3 + stride, 7, 3), Color("8f9aab"))
	draw_rect(Rect2(1, -3 - stride, 7, 3), Color("8f9aab"))
	draw_rect(Rect2(-6, -35 + bob, 12, 11), Color("dcb9a2"))
	draw_rect(Rect2(-7, -38 + bob, 13, 7), Color("141a2b"))
	draw_rect(Rect2(-9, -35 + bob, 4, 8), Color("141a2b"))
	draw_rect(Rect2(4, -37 + bob, 5, 5), Color("141a2b"))
	draw_rect(Rect2(facing_direction * 4 - 1, -30 + bob, 2, 2), Color("8df3eb"))
	var center := Vector2(0, -18 + bob)
	var shield_center: Vector2 = center + aim * (24 if bash_timer > 0 else 18)
	draw_line(center, shield_center, Color("dcb9a2"), 4)
	draw_rect(Rect2(center + aim * 8 - Vector2(2, 2), Vector2(4, 4)), tint)
	var tangent := aim.orthogonal()
	var shield_points := PackedVector2Array([shield_center + tangent * 13, shield_center + aim * 5 + tangent * 8, shield_center + aim * 5 - tangent * 8, shield_center - tangent * 13, shield_center - aim * 3])
	draw_colored_polygon(shield_points, Color("203a51"))
	draw_polyline(shield_points + PackedVector2Array([shield_points[0]]), tint, 2)
	draw_rect(Rect2(shield_center - Vector2(3, 3), Vector2(6, 6)), Color("e9e5ff"))
	for i in range(3):
		draw_rect(Rect2(shield_center + Vector2(i - 1, i - 1), Vector2(2, 2)), Combat.MODE_COLORS[(i * 2 + int(clock * 2)) % 6])
	if guarding or reflect_timer >= 0:
		draw_arc(center, 27, aim.angle() - 0.85, aim.angle() + 0.85, 9, Color(tint, 0.8), 2)
	if flash > 0 and effects_intensity > 0:
		draw_arc(center, 31 + (0.18 - flash) * 80, 0, TAU, 16, Color("fff2bf", flash * 4 * effects_intensity), 2)
	if guard_broken > 0:
		draw_line(Vector2(-5, -45), Vector2(5, -39), Color("ff7968"), 2)
		draw_line(Vector2(5, -45), Vector2(-5, -39), Color("ff7968"), 2)
	for i in range(stored_attacks.size()):
		draw_rect(Rect2(-5 + i * 7, -46, 4, 4), Combat.element_color(str(stored_attacks[i].element)))


