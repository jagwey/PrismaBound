class_name PrismPlayer
extends CharacterBody2D

signal died
signal combat_event(kind: String, pos: Vector2)

const Combat = preload("res://scripts/combat.gd")
const RUN_SPEED: float = 155.0
const JUMP_SPEED: float = -305.0
const GRAVITY: float = 870.0
const REFLECT_WINDOW := 0.20
const REFLECT_COOLDOWN := 0.30
var aim: Vector2 = Vector2.RIGHT
var snap_aim: bool = false
var effects_intensity: float = 1.0
var dead: bool = false
var shield_out: bool = false
var thrown_shield: PrismThrownShield = null
var state: String = "idle"
var reflect_timer: float = -1.0
var reflect_cooldown: float = 0.0
var dash_timer: float = 0.0
var dash_cooldown: float = 0.0
var coyote: float = 0.0
var jump_buffer: float = 0.0
var flash: float = 0.0
var clock: float = 0.0
var facing_direction: float = 1.0
var hit_stop: float = 0.0
var dash_direction: float = 1.0
var landing_timer: float = 0.0
var was_on_floor: bool = false
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

func _physics_process(delta: float) -> void:
	clock += delta
	flash = maxf(0, flash - delta)
	if dead:
		state = "death"
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
		move_and_slide()
		queue_redraw()
		return
	if hit_stop > 0:
		hit_stop -= delta
		queue_redraw()
		return
	for key in ["dash_cooldown", "reflect_cooldown", "landing_timer"]:
		set(key, maxf(0.0, float(get(key)) - delta))
	if reflect_timer >= 0.0:
		reflect_timer += delta
		if reflect_timer > REFLECT_WINDOW:
			reflect_timer = -1.0
	_update_aim()
	if Input.is_action_just_pressed("reflect") and reflect_cooldown <= 0 and not shield_out:
		reflect_timer = 0.0
		reflect_cooldown = REFLECT_COOLDOWN
		combat_event.emit("reflect", global_position)
	if Input.is_action_just_pressed("throw"):
		try_throw()
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
	if jump_buffer > 0 and coyote > 0:
		velocity.y = JUMP_SPEED
		jump_buffer = 0
		coyote = 0
		combat_event.emit("jump", global_position)
	if Input.is_action_just_released("jump") and velocity.y < -110.0:
		velocity.y *= 0.5
	var axis: float = Input.get_axis("move_left", "move_right")
	if absf(axis) > 0.1:
		facing_direction = signf(axis)
	if Input.is_action_just_pressed("dash") and dash_cooldown <= 0:
		dash_timer = 0.14
		dash_cooldown = 0.6
		dash_direction = signf(axis) if absf(axis) > 0.1 else facing_direction
		combat_event.emit("dash", global_position)
	if dash_timer > 0:
		dash_timer -= delta
		velocity = Vector2(dash_direction * 320.0, 0)
		state = "dash"
	else:
		var target: float = axis * RUN_SPEED
		velocity.x = move_toward(velocity.x, target, (1100.0 if is_on_floor() else 700.0) * delta)
		velocity.y = minf(velocity.y + GRAVITY * delta, 500.0)
		state = "run" if absf(velocity.x) > 12 else "idle"
		if not is_on_floor():
			state = "jump" if velocity.y < 0 else "fall"
		if reflect_timer >= 0: state = "reflect"
		if landing_timer > 0: state = "land"
	was_on_floor = is_on_floor()
	move_and_slide()
	if global_position.y > 550:
		kill(global_position)
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
	if dead or dash_timer > 0 or shield_out:
		return false
	if reflect_timer < 0.0 or reflect_timer > REFLECT_WINDOW or not projectile.reflectable:
		return false
	var center: Vector2 = global_position + Vector2(0, -18)
	if not Combat.facing(center, projectile.global_position, aim, projectile.velocity):
		return false
	var speed: float = clampf(projectile.velocity.length() * 1.2, 180.0, 650.0)
	projectile.velocity = Combat.reflected(projectile.velocity, aim) * speed
	projectile.team = 1
	projectile.owner_actor = self
	projectile.reflection_count += 1
	projectile.collision_grace = 0.055
	projectile.global_position = center + aim * 33.0
	flash = 0.18
	hit_stop = 0.035
	combat_event.emit("reflect", center)
	return true

func try_throw() -> void:
	if dead:
		return
	if shield_out:
		if is_instance_valid(thrown_shield):
			thrown_shield.recall()
		return
	var center: Vector2 = global_position + Vector2(0, -18)
	thrown_shield = PrismThrownShield.launch(get_parent(), center + aim * 20.0, aim, self)
	thrown_shield.caught.connect(_on_shield_caught)
	shield_out = true
	combat_event.emit("throw", center)

func _on_shield_caught() -> void:
	shield_out = false
	thrown_shield = null
	combat_event.emit("catch", global_position + Vector2(0, -18))

func _free_own_shield() -> void:
	for node in get_tree().get_nodes_in_group("thrown_shields"):
		if node.get("thrower") == self:
			node.remove_from_group("thrown_shields")
			node.queue_free()
	thrown_shield = null
	shield_out = false

func kill(from: Vector2) -> void:
	if dead or dash_timer > 0:
		return
	_free_own_shield()
	dead = true
	state = "death"
	reflect_timer = -1.0
	velocity.x = signf(global_position.x - from.x) * 140.0
	velocity.y = -120.0
	combat_event.emit("death", global_position)
	died.emit()

func _draw() -> void:
	var body: Color = Color("304c69")
	var cloak: Color = Color("80bfb9")
	var tint: Color = Color("75edee")
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
	if not shield_out:
		var shield_center: Vector2 = center + aim * 18
		draw_line(center, shield_center, Color("dcb9a2"), 4)
		var tangent := aim.orthogonal()
		var shield_points := PackedVector2Array([shield_center + tangent * 13, shield_center + aim * 5 + tangent * 8, shield_center + aim * 5 - tangent * 8, shield_center - tangent * 13, shield_center - aim * 3])
		draw_colored_polygon(shield_points, Color("203a51"))
		draw_polyline(shield_points + PackedVector2Array([shield_points[0]]), tint, 2)
		draw_rect(Rect2(shield_center - Vector2(3, 3), Vector2(6, 6)), Color("e9e5ff"))
	if reflect_timer >= 0:
		draw_arc(center, 27, aim.angle() - 0.85, aim.angle() + 0.85, 9, Color(tint, 0.8), 2)
	if flash > 0 and effects_intensity > 0:
		draw_arc(center, 31 + (0.18 - flash) * 80, 0, TAU, 16, Color("fff2bf", flash * 4 * effects_intensity), 2)
