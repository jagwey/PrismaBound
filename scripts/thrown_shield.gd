class_name PrismThrownShield
extends Node2D

signal caught

const Combat = preload("res://scripts/combat.gd")
const SPEED := 420.0
const MAX_BOUNCES := 3
const OUT_TIME := 1.2
const RETURN_SPEED := 520.0
const CATCH_RADIUS := 16.0
const HIT_PADDING := 8.0

var velocity: Vector2 = Vector2.ZERO
var bounces: int = 0
var returning: bool = false
var thrower: Node2D
var age: float = 0.0
var hit_set: Dictionary = {}
var _first_step: bool = true
var _done: bool = false

static func launch(parent: Node, from: Vector2, direction: Vector2, thrower_node: Node2D) -> PrismThrownShield:
	var shield := PrismThrownShield.new()
	shield.thrower = thrower_node
	shield.velocity = direction.normalized() * SPEED
	parent.add_child(shield)
	shield.global_position = from
	return shield

func _ready() -> void:
	add_to_group("thrown_shields")

func recall() -> void:
	returning = true

func _physics_process(delta: float) -> void:
	if _done:
		return
	age += delta
	if not returning and age >= OUT_TIME:
		returning = true
	if returning:
		_return_step(delta)
	else:
		_out_step(delta)
	queue_redraw()

func _out_step(delta: float) -> void:
	var from := global_position
	var space := get_world_2d().direct_space_state
	if _first_step:
		_first_step = false
		var point := PhysicsPointQueryParameters2D.new()
		point.position = from
		point.collision_mask = 1
		if not space.intersect_point(point, 1).is_empty():
			# Launched inside a solid: skip ricochet logic and come straight back.
			returning = true
			return
	var to := from + velocity * delta
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var normal: Vector2 = hit["normal"]
		velocity = velocity.bounce(normal)
		to = hit["position"] + normal * 2.0
		bounces += 1
		if bounces >= MAX_BOUNCES:
			returning = true
	_hit_enemies(from, to)
	global_position = to

func _return_step(delta: float) -> void:
	if not is_instance_valid(thrower):
		_finish(false)
		return
	var target: Vector2 = thrower.global_position + Vector2(0, -18)
	var offset := target - global_position
	var dist := offset.length()
	if dist <= CATCH_RADIUS or dist <= RETURN_SPEED * delta:
		_hit_enemies(global_position, target)
		global_position = target
		_finish(true)
		return
	velocity = offset / dist * RETURN_SPEED
	var to := global_position + velocity * delta
	_hit_enemies(global_position, to)
	global_position = to

func _hit_enemies(a: Vector2, b: Vector2) -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
			continue
		var id: int = enemy.get_instance_id()
		if hit_set.has(id):
			continue
		var radius: float = float(enemy.get("hurt_radius")) if enemy.get("hurt_radius") != null else 15.0
		if Combat.segment_distance(enemy.global_position, a, b) <= radius + HIT_PADDING:
			hit_set[id] = true
			enemy.hit_by(self, global_position, "shield")

func _finish(was_caught: bool) -> void:
	_done = true
	remove_from_group("thrown_shields")
	if was_caught:
		caught.emit()
	queue_free()

func _draw() -> void:
	var spin := Vector2.from_angle(age * 18.0)
	var pts := PackedVector2Array([spin * 11.0, spin.orthogonal() * 11.0, -spin * 11.0, -spin.orthogonal() * 11.0])
	draw_colored_polygon(pts, Color("203a51"))
	draw_polyline(pts + PackedVector2Array([pts[0]]), Color("75edee"), 2)
	draw_rect(Rect2(Vector2(-3, -3), Vector2(6, 6)), Color("e9e5ff"))
