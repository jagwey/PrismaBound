extends SceneTree

class DummyPlayer extends Node2D:
	var dead: bool = false
	var killed_from: Vector2
	func kill(from: Vector2) -> void:
		dead = true
		killed_from = from

class TestEnemy extends "res://scripts/enemy.gd":
	var shots: Array[Dictionary] = []
	func _shoot(velocity: Vector2, kind: String, offset: Vector2 = Vector2.ZERO) -> Node:
		shots.append({"velocity": velocity, "kind": kind, "offset": offset})
		return null

var failures: int = 0
var checks: int = 0
var arena: Node2D
var player: DummyPlayer
var defeats: int = 0
var phases: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func make_enemy(type: int, area: int, boss: bool = false, start_phase: int = 1) -> TestEnemy:
	var enemy := TestEnemy.new()
	enemy.configure(type, area, boss, start_phase)
	enemy.position = Vector2(250, 280)
	arena.add_child(enemy)
	enemy.set_physics_process(false)
	enemy.target = Vector2(80, 262)
	return enemy

func _on_defeated(_e) -> void:
	defeats += 1

func _on_phase(p: int) -> void:
	phases.append(p)

func run() -> void:
	arena = Node2D.new()
	root.add_child(arena)
	player = DummyPlayer.new()
	player.position = Vector2(80, 298)
	player.add_to_group("player")
	arena.add_child(player)
	var stub := Node2D.new()
	arena.add_child(stub)
	var behind := Vector2(400, 280)
	for key in TestEnemy.TYPE_IDS:
		var type: int = TestEnemy.TYPE_IDS[key]
		var enemy := make_enemy(type, 0)
		check(enemy.is_in_group("enemies"), "Enemy group %s" % key)
		enemy.facing = -1.0
		enemy._begin_telegraph()
		check(enemy.state == enemy.State.TELEGRAPH and is_equal_approx(enemy.state_time, 0.65), "0.65s windup %s" % key)
		enemy._shot_count = 0
		enemy._enemy_attack()
		check(enemy.shots.size() > 0 if type != 6 else enemy.shots.is_empty(), "Ranged/melee split %s" % key)
		if type == 1:
			check(enemy._feint, "Mage delayed feint")
		defeats = 0
		enemy.defeated.connect(_on_defeated)
		check(enemy.hit_by(stub, behind, "reflect"), "Reflect from behind kills %s" % key)
		check(defeats == 1, "defeated once %s" % key)
		check(not enemy.hit_by(stub, behind, "reflect"), "Second hit returns false %s" % key)
		check(defeats == 1, "defeated not repeated %s" % key)
		enemy.free()
	# Armored: front vs shield
	var armored := make_enemy(3, 0)
	armored.facing = -1.0
	var front := Vector2(100, 280)
	check(not armored.hit_by(stub, front, "reflect"), "Armored front reflect blocked")
	check(armored.state != armored.State.DEAD and armored.is_in_group("enemies"), "Armored survives front reflect")
	check(armored.hit_by(stub, front, "shield"), "Armored front shield kills")
	armored.free()
	var armored2 := make_enemy(3, 0)
	armored2.facing = 0.0
	check(not armored2.hit_by(stub, behind, "reflect"), "Armored with facing 0 treats as front")
	armored2.free()
	# Melee
	for cause in ["reflect", "shield"]:
		var m := make_enemy(6, 0)
		check(m.hit_by(stub, Vector2(100, 280), cause), "Melee dies to %s" % cause)
		m.free()
	var melee := make_enemy(6, 0)
	melee._player = player
	melee.position = Vector2(80, 280)
	player.dead = false
	melee._enter(melee.State.ATTACK, 0.5)
	melee._physics_process(0.016)
	check(player.dead, "Melee contact kills player")
	melee.free()
	var far := make_enemy(6, 0)
	far._player = player
	far.position = Vector2(200, 280)
	player.dead = false
	far._enter(far.State.ATTACK, 0.5)
	far._physics_process(0.016)
	check(not player.dead, "Melee far from player does not kill")
	far.free()
	# Bosses
	var kinds: Dictionary = {}
	for area in 5:
		var total: int = TestEnemy.BOSS_HITS[area]
		var boss := make_enemy(0, area, true)
		check(boss.is_in_group("bosses") and boss.hits_left == total, "Boss setup %s" % area)
		check(is_equal_approx(boss.state_time, 0.3), "Boss initial idle %s" % area)
		boss._begin_telegraph()
		check(is_equal_approx(boss.state_time, 0.8), "0.8s boss windup %s" % area)
		for pattern in 4:
			boss.attack_index = pattern
			boss._shot_count = 0
			boss._boss_attack()
		for shot in boss.shots:
			kinds[shot.kind] = true
			check(shot.velocity.length() > 0, "Valid boss projectile")
		defeats = 0
		phases.clear()
		boss.defeated.connect(_on_defeated)
		boss.phase_changed.connect(_on_phase)
		var half: int = ceili(total / 2.0)
		var expected_phase_hit: int = half
		for n in range(1, total + 1):
			boss.hit_guard = 0.0
			var ok: bool = boss.hit_by(stub, behind, "reflect")
			check(ok, "Boss hit %d accepted region %s" % [n, area])
			if n < total:
				check(boss.hits_left == total - n and defeats == 0, "Boss alive after hit %d region %s" % [n, area])
			if n == expected_phase_hit:
				check(phases.size() >= 1 and phases[0] == 2, "Phase 2 at hit %d region %s" % [n, area])
			if n == expected_phase_hit - 1:
				check(phases.is_empty(), "No early phase change region %s" % area)
		if area == 4:
			check(phases == [2, 3], "Final boss phases 2 then 3: %s" % str(phases))
		else:
			check(phases == [2], "Boss single phase change region %s: %s" % [area, str(phases)])
		check(boss.state == boss.State.DEAD and defeats == 1 and not boss.is_in_group("enemies"), "Boss dies after exactly BOSS_HITS region %s" % area)
		boss.hit_guard = 0.0
		check(not boss.hit_by(stub, behind, "reflect"), "Dead boss ignores hits %s" % area)
		boss.free()
		var resumed := make_enemy(0, area, true, 2)
		check(resumed.hits_left == total - half and resumed.phase == 2, "start_phase 2 hits_left region %s" % area)
		resumed.free()
	var guarded := make_enemy(0, 0, true)
	check(guarded.hit_by(stub, behind, "reflect") and guarded.hits_left == 2, "Guard: first boss hit lands")
	check(not guarded.hit_by(stub, behind, "reflect") and guarded.hits_left == 2, "Guard: same-frame second hit rejected")
	guarded.hit_guard = 0.0
	check(guarded.hit_by(stub, behind, "reflect") and guarded.hits_left == 1, "Guard: hit lands again after 0.25 s")
	guarded.free()
	var final3 := make_enemy(0, 4, true, 3)
	check(final3.hits_left == 1 and final3.phase == 3, "Final boss start_phase 3")
	final3.free()
	for kind in ["normal", "heavy", "arc", "spread", "beam", "shockwave", "dark", "explosive"]:
		check(kinds.has(kind), "Attack vocabulary contains %s" % kind)
	print("ENEMY TESTS: %d checks, %d failures" % [checks, failures])
	arena.free()
	quit(1 if failures else 0)
