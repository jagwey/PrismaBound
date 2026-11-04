extends SceneTree

class DummyPlayer extends Node2D:
	var mode: int = 4
	var hp: float = 100.0
	func take_damage(amount: float, _from: Vector2) -> void:
		hp -= amount

class DummyProjectile extends Node2D:
	var velocity: Vector2 = Vector2.RIGHT * 100
	var team: int = 1
	var owner_actor: Node
	var reflection_count: int = 1
	var collision_grace: float = 0.0

class TestEnemy extends "res://scripts/enemy.gd":
	var shots: Array[Dictionary] = []
	func _shoot(velocity: Vector2, kind: String, element: String, damage: float = 12.0, offset: Vector2 = Vector2.ZERO) -> Node:
		shots.append({"velocity": velocity, "kind": kind, "element": element, "damage": damage, "offset": offset})
		return null

var failures: int = 0
var checks: int = 0
var arena: Node2D
var player: DummyPlayer

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func make_enemy(type: int, area: int, boss: bool = false) -> TestEnemy:
	var enemy := TestEnemy.new()
	enemy.configure(type, area, boss)
	enemy.position = Vector2(250, 280)
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.target = Vector2(80, 262)
	return enemy

func run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	player = DummyPlayer.new()
	player.position = Vector2(80, 280)
	player.add_to_group("player")
	arena.add_child(player)
	for type in 7:
		var enemy := make_enemy(type, 0)
		check(enemy.is_in_group("enemies"), "Enemy group %s" % type)
		enemy._begin_telegraph()
		check(enemy.state == enemy.State.TELEGRAPH and enemy.state_time >= 0.6, "Readable enemy windup %s" % type)
		enemy._shot_count = 0
		enemy._enemy_attack()
		check(enemy.shots.size() > 0 if type != 6 else enemy.shots.is_empty(), "Distinct ranged/melee enemy %s" % type)
		if type == 1:
			check(enemy._feint, "Mage delayed feint")
		if type == 5:
			player.mode = 0
			enemy.take_damage(20, Vector2.ZERO)
			check(enemy.hp == enemy.max_hp, "Ghost rejects ordinary mirror")
			player.mode = 4
			enemy.take_damage(20, Vector2.ZERO)
			check(enemy.hp < enemy.max_hp, "Ghost accepts spirit mirror")
		enemy.free()
	var kinds: Dictionary = {}
	for area in 5:
		var boss := make_enemy(0, area, true)
		check(boss.is_in_group("bosses"), "Boss group %s" % area)
		for pattern in 4:
			boss.attack_index = pattern
			boss._shot_count = 0
			boss._boss_attack()
		for shot in boss.shots:
			kinds[shot.kind] = true
			check(shot.velocity.length() > 0 and shot.damage > 0, "Valid boss projectile")
		boss.take_damage(boss.max_hp * 0.6, Vector2.ZERO, true)
		check(boss.phase == 2, "Boss phase transition %s" % area)
		check(boss.state == boss.State.STUNNED, "Phase transition recovery %s" % area)
		if area == 4:
			boss._hit_cooldown = 0
			boss.take_damage(boss.max_hp * 0.2, Vector2.ZERO, true)
			check(boss.phase == 3, "Final boss third phase")
			boss._enter(boss.State.RECOVER, 1)
			boss.attack_index = 1
			var shot := DummyProjectile.new()
			arena.add_child(shot)
			check(boss.intercept_projectile(shot), "Final boss returns first reflection")
			check(shot.team == 0 and shot.reflection_count == 2 and shot.velocity.x < 0, "Returned ownership and velocity")
			boss._reflection_cooldown = 0
			check(not boss.intercept_projectile(shot), "Repeated reflection is bounded")
			shot.free()
		boss._hit_cooldown = 0
		boss.take_damage(10000, Vector2.ZERO, true)
		check(boss.state == boss.State.DEAD and not boss.is_in_group("enemies"), "Boss death clears collision group %s" % area)
		boss.free()
	for kind in ["normal", "heavy", "arc", "spread", "beam", "shockwave", "dark", "explosive"]:
		check(kinds.has(kind), "Attack vocabulary contains %s" % kind)
	print("ENEMY TESTS: %d checks; %d failures" % [checks, failures])
	arena.free()
	quit(1 if failures else 0)
