extends SceneTree

const Player = preload("res://scripts/player.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Combat = preload("res://scripts/combat.gd")
var failures: int = 0
var checks: int = 0
var world: Node2D
var player: PrismPlayer

class SplashTarget extends Node2D:
	var hp: float = 100.0
	var last_element: String = ""
	func _ready() -> void: add_to_group("enemies")
	func take_damage(amount: float, _from: Vector2, _perfect: bool = false) -> void: hp -= amount
	func apply_status(element: String) -> void: last_element = element

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func shot(pos: Vector2, velocity: Vector2, kind: String = "normal") -> PrismProjectile:
	var p = Projectile.spawn(world, pos, velocity, 10, kind)
	p.set_physics_process(false)
	return p

func run() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "guard", "reflect", "bash", "mode", "absorb", "release", "interact", "pause", "aim_left", "aim_right", "aim_up", "aim_down"]:
		if not InputMap.has_action(action): InputMap.add_action(action)
	world = Node2D.new()
	root.add_child(world)
	player = Player.new()
	world.add_child(player)
	player.position = Vector2(100, 100)
	player.set_physics_process(false)
	player.aim = Vector2.RIGHT
	check(Combat.reflected(Vector2.LEFT, Vector2.RIGHT).is_equal_approx(Vector2.RIGHT), "Head-on reflection")
	var angle_normal := Vector2(1, -1).normalized()
	check(Combat.reflected(Vector2.LEFT, angle_normal).is_equal_approx(Vector2.UP), "Angled reflection")
	for i in range(32):
		var normal := Vector2.from_angle(float(i) * TAU / 32.0)
		check(Combat.reflected(-normal, normal).is_equal_approx(normal), "Radial reflection %d" % i)
	player.reflect_timer = 0.05
	var p = shot(Vector2(125, 82), Vector2(-200, 0))
	check(player.handle_projectile(p), "Perfect reflect accepted")
	check(p.team == 1 and p.velocity.x > 0 and p.perfect and p.reflection_count == 1, "Reflection ownership and velocity")
	check(is_equal_approx(p.damage, 16.5) and is_equal_approx(player.energy, 18), "Perfect damage/energy")
	p.free()
	p = shot(Vector2(75, 82), Vector2(200, 0))
	check(not player.handle_projectile(p), "Rear shot must bypass shield")
	p.free()
	player.reflect_timer = 0.2
	p = shot(Vector2(125, 82), Vector2(-200, 0))
	check(player.handle_projectile(p) and not p.perfect, "Ordinary reflect timing")
	p.free()
	player.reflect_timer = -1
	player.guarding = true
	var old_stamina: float = player.stamina
	p = shot(Vector2(125, 82), Vector2(-200, 0))
	check(player.handle_projectile(p) and p.dead and player.stamina < old_stamina, "Guard consumes stamina/projectile")
	player.stamina = 1
	p = shot(Vector2(125, 82), Vector2(-200, 0))
	check(not player.handle_projectile(p) and player.guard_broken > 0, "Guard break exposes player")
	p.free()
	player.heal()
	player.stun_timer = 0
	player.configure_progress(3, 3)
	check(player.unlocked_modes == [0, 1, 2, 3, 4] and player.storage_capacity == 2, "Progression unlocks")
	player.mode = 0
	p = shot(Vector2(125, 82), Vector2(-200, 0), "dark")
	check(not player.handle_projectile(p), "Dark requires soul")
	player.mode = 4
	check(player.handle_projectile(p), "Soul guards dark")
	player.energy = 50
	Input.action_press("absorb")
	p = shot(Vector2(125, 82), Vector2(-200, 0), "arc")
	p.element = "fire"
	check(player.handle_projectile(p) and player.stored_attacks.size() == 1 and player.stored_attacks[0].element == "fire", "Absorb preserves element")
	Input.action_release("absorb")
	player.release_stored()
	check(player.stored_attacks.is_empty(), "Release empties storage")
	player.invulnerability = 0
	player.take_damage(10, Vector2.ZERO)
	player.take_damage(10, Vector2.ZERO)
	check(player.hp == 90, "I-frames prevent duplicate damage")
	# Guarding or absorbing explosives must neutralize the blast entirely.
	player.invulnerability = 0
	player.hp = 100
	player.stun_timer = 0
	player.stamina = 100
	player.guarding = true
	p = shot(Vector2(125, 82), Vector2(-200, 0), "explosive")
	check(player.handle_projectile(p) and player.hp == 100 and p.explosion_timer == 0, "Guard neutralizes explosive splash")
	# Player-owned explosions affect nearby other enemies once, preserving element.
	var primary := SplashTarget.new()
	primary.position = Vector2(300, 80)
	world.add_child(primary)
	var secondary := SplashTarget.new()
	secondary.position = Vector2(318, 80)
	world.add_child(secondary)
	var distant := SplashTarget.new()
	distant.position = Vector2(400, 80)
	world.add_child(distant)
	p = shot(Vector2(300, 80), Vector2.RIGHT * 200, "explosive")
	p.team = 1
	p.element = "fire"
	p.primary_hit = primary
	p.consume()
	check(primary.hp == 100, "Explosion excludes primary hit")
	check(secondary.hp == 95 and secondary.last_element == "fire", "Reflected splash damage and status")
	check(distant.hp == 100, "Explosion bounded radius")
	p.consume()
	check(secondary.hp == 95, "Explosion cannot hit twice")
	primary.free()
	secondary.free()
	distant.free()
	p.free()
	player.apply_status("fire")
	check(player.burn_timer > 0, "Fire applies finite burn")
	player.apply_status("ice")
	check(player.slow_timer > 0, "Ice applies slow")
	player.heal()
	check(player.burn_timer == 0 and player.slow_timer == 0, "Healing removes statuses")
	# I-frames suppress both health loss and new elemental ailments.
	player.guarding = false
	player.position = Vector2(100, 100)
	player.invulnerability = 0.5
	p = shot(Vector2(80, 82), Vector2.RIGHT * 200)
	p.element = "ice"
	p._physics_process(0.1)
	check(player.slow_timer == 0 and player.hp == 100, "Invulnerable contact applies no status")
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
	world.queue_free()
	await process_frame
	print("CORE TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


