class_name PrismCombat
extends RefCounted

const MODE_NAMES: Array[String] = ["Prizma Kalkanı", "Kırık Ayna", "Odak Aynası", "Ağır Ayna", "Ruh Aynası", "Prizma Modu"]
const MODE_COLORS: Array[Color] = [Color("75edee"), Color("ba8dff"), Color("ffe6a3"), Color("ff9b75"), Color("c187ff"), Color("99f0b5")]

static func reflected(direction: Vector2, normal: Vector2) -> Vector2:
	if direction.is_zero_approx() or normal.is_zero_approx():
		return -direction.normalized()
	return direction.normalized().bounce(normal.normalized()).normalized()

static func facing(center: Vector2, projectile_position: Vector2, normal: Vector2, incoming: Vector2) -> bool:
	return (projectile_position - center).normalized().dot(normal) > 0.30 and incoming.normalized().dot(normal) < -0.05

static func segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, a, b))

static func element_color(element: String) -> Color:
	match element:
		"fire": return Color("ff825d")
		"ice": return Color("7cdfff")
		"nature", "poison": return Color("a4ed77")
		"spirit", "dark": return Color("c992ff")
	return Color("f6dba4")
