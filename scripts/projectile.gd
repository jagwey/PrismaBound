class_name PrismProjectile
extends Node2D

const Combat = preload("res://scripts/combat.gd")
var velocity: Vector2 = Vector2.ZERO
var damage: float = 12.0
var team: int = 0
var kind: String = "normal"
var element: String = "neutral"
var lifetime: float = 8.0
var reflection_count: int = 0
var owner_actor: Node
var perfect: bool = false
var reflectable: bool = true
var collision_grace: float = 0.0
var dead: bool = false
var age: float = 0.0
var radius: float = 4.0
var previous_position: Vector2
var effects_intensity: float = 1.0
var explosion_timer: float = 0.0
var primary_hit: Node

static func spawn(parent: Node, pos: Vector2, vel: Vector2, amount: float = 12.0, type: String = "normal", affinity: String = "neutral", allegiance: int = 0) -> PrismProjectile:
	var result := PrismProjectile.new()
	result.position = pos
	result.velocity = vel
	result.damage = amount
	result.kind = type
	result.element = affinity
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
		explosion_timer -= delta
		queue_redraw()
		if explosion_timer <= 0: queue_free()
		return
	age += delta
	lifetime -= delta
	collision_grace = maxf(0.0, collision_grace - delta)
	if lifetime <= 0.0 or global_position.y > 900.0 or global_position.y < -500.0 or reflection_count > 12:
		consume(false)
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
					var hp_before: float = float(player.get("hp"))
					player.call("take_damage", damage, previous_position)
					primary_hit = player
					if float(player.get("hp")) < hp_before and player.has_method("apply_status"):
						player.call("apply_status", element)
					consume()
					return
		else:
			for target in get_tree().get_nodes_in_group("enemies"):
				if not is_instance_valid(target) or target.is_queued_for_deletion():
					continue
				var hit_radius: float = float(target.get("hurt_radius")) if target.get("hurt_radius") != null else (28.0 if target.is_in_group("bosses") else 15.0)
				if Combat.segment_distance(target.global_position, previous_position, global_position) < hit_radius + radius:
					if target.has_method("intercept_projectile") and bool(target.call("intercept_projectile", self)):
						return
					var hp_before: float = float(target.get("hp"))
					target.call("take_damage", damage, previous_position, perfect)
					primary_hit = target
					if float(target.get("hp")) < hp_before and target.has_method("apply_status"):
						target.call("apply_status", element)
					consume()
					return
	# Geometry collisions use world layer only. Actors are tested by swept hit volumes above.
	if collision_grace <= 0.0 and kind != "shockwave":
		var query := PhysicsRayQueryParameters2D.create(previous_position, global_position, 1)
		var hit: Dictionary = get_world_2d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():
			consume()
	queue_redraw()

func consume(explode: bool = true) -> void:
	if dead:
		return
	dead = true
	if kind == "explosive" and explode and is_inside_tree():
		explosion_timer = 0.20
		var candidates: Array[Node] = get_tree().get_nodes_in_group("enemies" if team == 1 else "player")
		for target in candidates:
			if not is_instance_valid(target) or target == primary_hit or target.is_queued_for_deletion():
				continue
			var center: Vector2 = target.global_position + (Vector2(0, -18) if team == 0 else Vector2.ZERO)
			if center.distance_to(global_position) >= 42.0:
				continue
			# Terrain blocks splash: the blast cannot damage through walls.
			var query := PhysicsRayQueryParameters2D.create(global_position, center, 1)
			if not get_world_2d().direct_space_state.intersect_ray(query).is_empty():
				continue
			var hp_before: float = float(target.get("hp"))
			if team == 1:
				target.call("take_damage", damage * 0.5, global_position, perfect)
			else:
				target.call("take_damage", damage * 0.5, global_position)
			if float(target.get("hp")) < hp_before and target.has_method("apply_status"):
				target.call("apply_status", element)
		queue_redraw()
		return
	queue_free()
func _draw() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player): effects_intensity = float(player.get("effects_intensity"))
	var tint: Color = Combat.element_color(element)
	if dead:
		if explosion_timer > 0:
			var blast_radius: float = 42.0 * (1.0 - explosion_timer / 0.20)
			draw_arc(Vector2.ZERO, blast_radius, 0, TAU, 16, Color(tint, 0.35 + effects_intensity * 0.45), 2)
		return
	if team == 1:
		tint = Color("9effed") if not perfect else Color("fff4ae")
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
	if kind == "dark":
		draw_arc(Vector2.ZERO, radius + 3, age * 4, age * 4 + PI * 1.5, 8, Color("d1a1ff"), 1)



