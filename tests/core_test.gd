extends SceneTree

const Player = preload("res://scripts/player.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Combat = preload("res://scripts/combat.gd")
var failures: int = 0
var checks: int = 0
var world: Node2D
var player: PrismPlayer

class EnemyStub extends Node2D:
	var hurt_radius: float = 15.0
	var causes: Array[String] = []
	func _ready() -> void: add_to_group("enemies")
	func hit_by(_source: Node, _from: Vector2, cause: String) -> bool:
		causes.append(cause)
		return true

var died_count: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func shot(pos: Vector2, velocity: Vector2, kind: String = "normal") -> PrismProjectile:
	var p = Projectile.spawn(world, pos, velocity, kind)
	p.set_physics_process(false)
	return p

func _on_died() -> void:
	died_count += 1

func test_front_reflect() -> void:
	player.reflect_timer = 0.0
	player.shield_out = false
	var p = shot(player.position + Vector2(60, -18), Vector2(-200, 0))
	check(player.handle_projectile(p), "Front reflect accepted")
	check(p.team == 1 and p.velocity.x > 0 and absf(p.velocity.length() - 240.0) < 1.0, "Reflect ownership, direction, speed 240")
	check(p.reflection_count == 1 and p.owner_actor == player, "Reflect bookkeeping")
	p.free()
	var slow = shot(player.position + Vector2(60, -18), Vector2(-100, 0))
	player.handle_projectile(slow)
	check(absf(slow.velocity.length() - 180.0) < 1.0, "Reflect speed floor 180")
	slow.free()
	var fast = shot(player.position + Vector2(60, -18), Vector2(-800, 0))
	player.handle_projectile(fast)
	check(absf(fast.velocity.length() - 650.0) < 1.0, "Reflect speed cap 650")
	fast.free()

func test_reflect_window_expired() -> void:
	player.reflect_timer = 0.21
	var p = shot(player.position + Vector2(60, -18), Vector2(-200, 0))
	check(not player.handle_projectile(p), "Reflect window expired")
	p.free()

func test_rear_hit_kills() -> void:
	player.reflect_timer = 0.0
	player.dead = false
	died_count = 0
	var p = shot(player.position + Vector2(-60, -18), Vector2(200, 0))
	check(not player.handle_projectile(p), "Rear shot not reflected")
	p.set_physics_process(true)
	p._physics_process(0.3)
	check(player.dead, "Rear shot kills player")
	check(died_count == 1, "died emitted once on rear hit")
	player.dead = false
	player.state = "idle"
	p.free()

func test_no_reflect_while_shield_out() -> void:
	player.reflect_timer = 0.0
	player.shield_out = true
	var p = shot(player.position + Vector2(60, -18), Vector2(-200, 0))
	check(not player.handle_projectile(p), "No reflect while shield is out")
	p.free()
	player.shield_out = false

func test_kill_idempotent() -> void:
	player.dead = false
	died_count = 0
	player.kill(Vector2.ZERO)
	player.kill(Vector2.ZERO)
	check(died_count == 1, "kill twice emits died once")
	player.dead = false

func test_dash_iframes() -> void:
	player.dead = false
	player.dash_timer = 0.1
	player.kill(Vector2.ZERO)
	check(not player.dead, "Dash i-frames ignore kill")
	player.dash_timer = 0.0

func test_reflected_shot_kills_enemy() -> void:
	var enemy := EnemyStub.new()
	enemy.position = Vector2(300, 80)
	world.add_child(enemy)
	var p = shot(Vector2(280, 80), Vector2(200, 0))
	p.team = 1
	p.set_physics_process(true)
	p._physics_process(0.1)
	check(enemy.causes == ["reflect"], "Enemy received reflect cause")
	check(p.dead, "Reflected projectile consumed on enemy")
	enemy.free()
	p.free()

func test_slow_drains() -> void:
	var tc := PrismTimeControl.new()
	var s := tc.update(1.0, true)
	check(is_equal_approx(s, 0.3), "Slow returns 0.3")
	check(is_equal_approx(tc.meter, 2.0), "Slow drains 1 per real second")
	check(is_equal_approx(Engine.time_scale, 0.3), "Slow writes Engine.time_scale")
	tc.reset()

func test_slow_empties() -> void:
	var tc := PrismTimeControl.new()
	tc.update(1.0, true)
	var s := tc.update(3.0, true)
	check(is_zero_approx(tc.meter), "Meter empties")
	check(is_equal_approx(s, 1.0) and not tc.active, "Empty meter returns normal speed")
	var s2 := tc.update(0.1, true)
	check(is_equal_approx(s2, 1.0) and not tc.active, "No reactivation below 0.1")
	tc.reset()

func test_regen_delay() -> void:
	var tc := PrismTimeControl.new()
	tc.update(3.0, true)
	tc.update(1.4, false)
	check(is_zero_approx(tc.meter), "No regen during delay")
	tc.update(0.1 + 2.0, false)
	check(is_equal_approx(tc.meter, 3.0), "Full regen after delay")
	tc.reset()

func test_time_reset() -> void:
	var tc := PrismTimeControl.new()
	tc.update(0.5, true)
	check(tc.active and is_equal_approx(Engine.time_scale, 0.3), "Active before reset")
	tc.reset()
	check(is_equal_approx(Engine.time_scale, 1.0) and not tc.active and is_equal_approx(tc.meter, 3.0), "Reset restores time and meter")

func make_wall(x: float, y: float = 200.0, h: float = 200.0) -> StaticBody2D:
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(20, h)
	cs.shape = rs
	body.position = Vector2(x, y)
	body.add_child(cs)
	world.add_child(body)
	return body

func reset_player_for_shield() -> void:
	player.dead = false
	player.dash_timer = 0.0
	player.hit_stop = 0.0
	player.shield_out = false
	player.position = Vector2(180, 300)
	player.velocity = Vector2.ZERO
	player.aim = Vector2.RIGHT

func test_shield_bounces_and_returns() -> void:
	reset_player_for_shield()
	var caught_flag := [false]
	player.try_throw()
	check(player.shield_out, "Throw sets shield_out")
	var s: PrismThrownShield = player.thrown_shield
	s.caught.connect(func(): caught_flag[0] = true)
	var bounced_left := false
	var max_b := 0
	for i in range(300):
		await physics_frame
		if caught_flag[0]:
			break
		max_b = maxi(max_b, s.bounces)
		if s.bounces >= 1 and s.velocity.x < 0:
			bounced_left = true
	check(max_b >= 1, "Shield bounced off wall")
	check(bounced_left, "Velocity flipped after wall hit")
	check(caught_flag[0], "Shield caught")
	check(not player.shield_out, "shield_out cleared on catch")

func test_shield_max_bounces() -> void:
	var left := make_wall(150.0, 100.0, 400.0)
	var right := make_wall(250.0, 100.0, 400.0)
	await physics_frame
	var thrower := Node2D.new()
	thrower.position = Vector2(200, 118)
	world.add_child(thrower)
	var s := PrismThrownShield.launch(world, Vector2(200, 100), Vector2.RIGHT, thrower)
	var max_b := 0
	var returning_at_three := false
	for i in range(30):
		await physics_frame
		if not is_instance_valid(s) or s.is_queued_for_deletion():
			break
		max_b = maxi(max_b, s.bounces)
		if s.bounces == 3 and s.returning:
			returning_at_three = true
		if s.returning:
			break
	check(max_b <= 3, "Bounces never exceed 3")
	check(returning_at_three, "Returning at the 3rd bounce")
	if is_instance_valid(s): s.free()
	thrower.free()
	left.free()
	right.free()

func test_shield_kills_each_enemy_once() -> void:
	reset_player_for_shield()
	var e1 := EnemyStub.new()
	e1.position = Vector2(230, 282)
	var e2 := EnemyStub.new()
	e2.position = Vector2(265, 282)
	world.add_child(e1)
	world.add_child(e2)
	player.try_throw()
	var s: PrismThrownShield = player.thrown_shield
	var alive_after_first := false
	for i in range(300):
		await physics_frame
		if e1.causes.size() >= 1 and e2.causes.size() >= 1 and is_instance_valid(s) and not s.returning:
			alive_after_first = true
		if not player.shield_out:
			break
	check(e1.causes == ["shield"] and e2.causes == ["shield"], "Each enemy hit exactly once per throw")
	check(alive_after_first, "Shield keeps flying after kills")
	e1.free()
	e2.free()

func test_shield_recall() -> void:
	reset_player_for_shield()
	player.try_throw()
	var s: PrismThrownShield = player.thrown_shield
	await physics_frame
	check(not s.returning, "Not returning right after throw")
	player.try_throw()
	check(s.returning, "Second throw press recalls")
	for i in range(120):
		await physics_frame
		if not player.shield_out:
			break
	check(not player.shield_out, "Recalled shield caught")

func test_shield_point_blank_wall() -> void:
	reset_player_for_shield()
	player.position = Vector2(280, 300)
	player.try_throw()
	var s: PrismThrownShield = player.thrown_shield
	var frames := int((PrismThrownShield.OUT_TIME + 1.0) * 60.0)
	for i in range(frames):
		await physics_frame
		if not player.shield_out:
			break
	check(not player.shield_out, "Point-blank wall throw caught in time")
	check(not is_instance_valid(s) or s.is_queued_for_deletion(), "Point-blank shield freed")

func test_throw_blocks_reflect_and_kill_frees() -> void:
	reset_player_for_shield()
	player.position = Vector2(100, 300)
	player.try_throw()
	var s: PrismThrownShield = player.thrown_shield
	player.reflect_timer = 0.0
	var p = shot(player.position + Vector2(60, -18), Vector2(-200, 0))
	check(not player.handle_projectile(p), "Real throw blocks reflect")
	p.free()
	player.kill(Vector2(0, 0))
	check(not player.shield_out, "kill clears shield_out")
	await physics_frame
	check(not is_instance_valid(s) or s.is_queued_for_deletion(), "kill frees own shield")
	reset_player_for_shield()

func run_shield_tests() -> void:
	var wall := make_wall(300.0)
	await physics_frame
	await test_shield_bounces_and_returns()
	await test_shield_max_bounces()
	await test_shield_kills_each_enemy_once()
	await test_shield_recall()
	await test_shield_point_blank_wall()
	await test_throw_blocks_reflect_and_kill_frees()
	wall.free()

func run() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "reflect", "throw", "slow", "restart", "interact", "pause", "aim_left", "aim_right", "aim_up", "aim_down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	world = Node2D.new()
	root.add_child(world)
	player = Player.new()
	world.add_child(player)
	player.position = Vector2(100, 100)
	player.set_physics_process(false)
	player.aim = Vector2.RIGHT
	player.died.connect(_on_died)
	check(Combat.reflected(Vector2.LEFT, Vector2.RIGHT).is_equal_approx(Vector2.RIGHT), "Head-on reflection")
	var angle_normal := Vector2(1, -1).normalized()
	check(Combat.reflected(Vector2.LEFT, angle_normal).is_equal_approx(Vector2.UP), "Angled reflection")
	for i in range(32):
		var normal := Vector2.from_angle(float(i) * TAU / 32.0)
		check(Combat.reflected(-normal, normal).is_equal_approx(normal), "Radial reflection %d" % i)
	test_front_reflect()
	test_reflect_window_expired()
	test_rear_hit_kills()
	test_no_reflect_while_shield_out()
	test_kill_idempotent()
	test_dash_iframes()
	test_reflected_shot_kills_enemy()
	test_slow_drains()
	test_slow_empties()
	test_regen_delay()
	test_time_reset()
	player.effects_intensity = 0
	# Real physics: floor, buffered input, airborne jump and gravity landing.
	var floor_body := StaticBody2D.new()
	var collision := CollisionShape2D.new()
	var floor_shape := RectangleShape2D.new()
	floor_shape.size = Vector2(600, 32)
	collision.shape = floor_shape
	floor_body.position = Vector2(300, 316)
	floor_body.add_child(collision)
	world.add_child(floor_body)
	player.position = Vector2(100, 220)
	player.velocity = Vector2.ZERO
	player.hit_stop = 0
	player.set_physics_process(true)
	for frame in range(50): await physics_frame
	check(player.is_on_floor() and absf(player.position.y - 300) < 1, "Falls and lands on floor")
	Input.action_press("move_right")
	for frame in range(20): await physics_frame
	Input.action_release("move_right")
	check(player.position.x > 130, "Acceleration movement")
	Input.action_press("jump")
	await physics_frame
	await physics_frame
	Input.action_release("jump")
	for frame in range(8): await physics_frame
	check(player.position.y < 290, "Jump input lifts player")
	Input.action_press("dash")
	await physics_frame
	await physics_frame
	Input.action_release("dash")
	check(player.dash_cooldown > 0 and player.state == "dash", "Dash input")
	player.set_physics_process(false)
	await run_shield_tests()
	world.queue_free()
	await process_frame
	print("CORE TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


