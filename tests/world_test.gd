extends SceneTree

const World = preload("res://scripts/world.gd")
const Projectile = preload("res://scripts/projectile.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func verify(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "guard", "reflect", "bash", "mode", "absorb", "release", "interact", "pause", "aim_left", "aim_right", "aim_up", "aim_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	for area in range(5):
		var world = World.new()
		world.configure(area, {"upgrades": 0, "shards": 0, "flags": {}})
		root.add_child(world)
		world.set_physics_process(false)
		world.player.set_physics_process(false)
		for enemy in world.encounter_nodes:
			enemy.set_physics_process(false)
		await physics_frame
		verify(world.info.name != "" and world.platforms.size() >= 8, "region %d has data and geometry" % area)
		verify(world.player.position.x == 140, "region %d starts at checkpoint" % area)
		verify(is_instance_valid(world.puzzle_gate), "region %d initially gated" % area)
		world.player.position = Vector2(1760, 300)
		world.player.aim = Vector2.RIGHT
		world.player.mode = 3 if area == 2 else (4 if area == 3 else 0)
		var needed: int = 3 if area == 4 else 1
		for shot_index in range(needed):
			var kind: String = "heavy" if area == 2 else ("dark" if area == 3 else "normal")
			var element: String = ["fire", "ice", "nature"][shot_index] if area == 4 else str(world.info.element)
			var shot = Projectile.spawn(world, world.EMITTER, Vector2(-160, 0), 10, kind, element, 0)
			shot.set_physics_process(false)
			world.player.reflect_timer = 0.03
			for frame in range(420):
				if shot.dead:
					break
				shot._physics_process(1.0 / 60.0)
			verify(shot.reflection_count >= (2 if area == 1 else 1), "region %d shot %d physically reflects" % [area, shot_index])
			verify(shot.dead, "region %d shot %d consumed by crystal" % [area, shot_index])
			verify(world.puzzle_step == shot_index + 1, "region %d target accepted correct trajectory" % area)
			await process_frame
		verify(world.puzzle_solved, "region %d puzzle solved by moving projectile" % area)
		verify(not is_instance_valid(world.puzzle_gate), "region %d gate removed" % area)
		world.player.position = Vector2(2250, 299)
		world._interact()
		verify(world.checkpoint_id == 1 and world.checkpoint.x == 2250, "region %d checkpoint records actual location" % area)
		world._spawn_boss()
		verify(is_instance_valid(world.boss) and world.boss.is_boss, "region %d boss spawned" % area)
		world.boss.set_physics_process(false)
		world.player.invulnerability = 0.0
		world.player.take_damage(200, world.player.position)
		verify(world.dead, "region %d death reaches world" % area)
		world.restart_checkpoint()
		verify(not world.dead and not world.player.dead and world.player.hp == world.player.max_hp, "region %d respawn heals and reenables player" % area)
		verify(world.player.position.x == 2250 and not world.boss_started, "region %d respawn resets boss and checkpoint" % area)
		world.queue_free()
		await process_frame
		var restored = World.new()
		restored.configure(area, {"flags": {"checkpoint_region": area, "checkpoint_id": 1}})
		root.add_child(restored)
		restored.set_physics_process(false)
		restored.player.set_physics_process(false)
		verify(restored.puzzle_solved and restored.player.position.x == 2250, "region %d saved checkpoint restores without seal softlock" % area)
		restored.queue_free()
		await process_frame
	print("WORLD TEST: %d checks, %d failures; five actual projectile routes and checkpoint recovery" % [checks, failures])
	quit(1 if failures else 0)

