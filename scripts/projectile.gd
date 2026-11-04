class_name PrismProjectile
extends Node2D

const Combat = preload("res://scripts/combat.gd")
var velocity: Vector2 = Vector2.ZERO
var team: int = 0
var kind: String = "normal"
var lifetime: float = 8.0
var reflection_count: int = 0
var owner_actor: Node
var reflectable: bool = true
var collision_grace: float = 0.0
var dead: bool = false
var age: float = 0.0
var radius: float = 4.0
var previous_position: Vector2
var effects_intensity: float = 1.0

static func spawn(parent: Node, pos: Vector2, vel: Vector2, type: String = "normal", allegiance: int = 0) -> PrismProjectile:
	var result := PrismProjectile.new()
	result.position = pos
	result.velocity = vel
	result.kind = type
	result.team = allegiance
	parent.add_child(result)
	return result

func _ready() -> void:
	add_to_group("projectiles")
	radius = 7.0 if kind == "heavy" else 4.0
	previous_position = global_position
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead:
		queue_free()
		return
	age += delta
	lifetime -= delta
	collision_grace = maxf(0.0, collision_grace - delta)
	if lifetime <= 0.0 or global_position.y > 900.0 or global_position.y < -500.0 or reflection_count > 12:
		consume()
		return
	previous_position = global_position
	if kind == "arc":
		velocity.y += 120.0 * delta
	global_position += velocity * delta
	if get_parent().has_method("on_projectile_environment"):
		if bool(get_parent().call("on_projectile_environment", self)):
			consume()
			return
	if collision_grace <= 0.0:
		if team == 0:
			var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
			if is_instance_valid(player):
				var center: Vector2 = player.global_position + Vector2(0, -18)
				var closest: Vector2 = Geometry2D.get_closest_point_to_segment(center, previous_position, global_position)
				if center.distance_to(closest) < 30.0 + radius:
					# Sweep the contact back to the shield: fast shots cannot tunnel through it.
					var travel: Vector2 = global_position - previous_position
					var steps: int = maxi(1, int(ceil(travel.length() / 4.0)))
					var end: Vector2 = global_position
					for i in range(steps + 1):
						global_position = previous_position.lerp(end, float(i) / float(steps))
						if center.distance_to(global_position) < 30.0 + radius and bool(player.call("handle_projectile", self)):
							queue_redraw()
							return
					global_position = end
				if Combat.segment_distance(center, previous_position, global_position) < 12.0 + radius:
					player.call("kill", previous_position)
					consume()
					return
		else:
			for target in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(target) or target.is_queued_for_deletion():
					continue
				var hit_radius: float = float(target.get("hurt_radius")) if target.get("hurt_radius") != null else (28.0 if target.is_in_group("bosses") else 15.0)
				if Combat.segment_distance(target.global_position, previous_position, global_position) < hit_radius + radius:
					target.call("hit_by", self, previous_position, "reflect")
					consume()
					return
	# Geometry collisions use world layer only. Actors are tested by swept hit volumes above.
	if collision_grace <= 0.0 and kind != "shockwave":
		var query := PhysicsRayQueryParameters2D.create(previous_position, global_position, 1)
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			consume()
	queue_redraw()

func consume() -> void:
	if dead:
		return
	dead = true
	queue_free()

func _draw() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player): effects_intensity = float(player.get("effects_intensity"))
	var tint: Color = Color("f6dba4") if team == 0 else Color("9effed")
	var direction: Vector2 = velocity.normalized()
	if kind == "beam":
		draw_line(-direction * 22.0, direction * 8.0, tint * 0.4, 6.0)
		draw_line(-direction * 22.0, direction * 8.0, tint, 2.0)
	elif kind == "shockwave":
		draw_colored_polygon(PackedVector2Array([Vector2(-9, 5), Vector2(0, -12), Vector2(9, 5)]), tint)
	else:
		if effects_intensity > 0:
			draw_line(-direction * 12.0 * effects_intensity, Vector2.ZERO, Color(tint, 0.4 * effects_intensity), radius)
		draw_rect(Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2.0), tint)
		draw_rect(Rect2(-2, -2, 4, 4), Color("fff8dd"))
