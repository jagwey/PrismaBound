extends SceneTree

var failures: int = 0
var checks: int = 0
var world: PrismWorld
var cleared_count: int = 0
var exited_count: int = 0
var died_count: int = 0
var completed: Array = []
var chapters_done: Array = []
var stories: Array = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func frames(n: int = 2) -> void:
	for i in n:
		await physics_frame

func room_children() -> int:
	var n := 0
	for c in world.get_children():
		if c is PrismRoom:
			n += 1
	return n

func group_count(group: String) -> int:
	return get_nodes_in_group(group).size()

func make_world(chapter: int, start_room: int = 0) -> PrismWorld:
	var w := PrismWorld.new()
	w.configure(chapter, start_room)
	completed.clear()
	chapters_done.clear()
	stories.clear()
	died_count = 0
	w.room_completed.connect(func(id: String, t: float): completed.append([id, t]))
	w.chapter_completed.connect(func(c: int): chapters_done.append(c))
	w.story_requested.connect(func(k: String): stories.append(k))
	w.player_died.connect(func(): died_count += 1)
	root.add_child(w)
	return w

func drop_world() -> void:
	Engine.time_scale = 1.0
	for node in get_nodes_in_group("projectiles") + get_nodes_in_group("thrown_shields"):
		node.free()
	world.free()
	world = null

func run() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "reflect", "throw", "slow", "restart", "interact", "pause", "aim_left", "aim_right", "aim_up", "aim_down"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	test_data()
	await test_flow()
	await test_death_restart()
	await test_focus_cases()
	await test_boss()
	await test_hardening()
	print("ROOM TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_data() -> void:
	var data: Dictionary = PrismRoom.load_rooms()
	check(data.has("chapters") and data["chapters"].size() == 5, "5 chapters")
	var total := 0
	for chapter in data["chapters"]:
		check(chapter.size() >= 1, "chapter has rooms")
		for room in chapter:
			total += 1
			var reason: String = PrismRoom.validate_room(room)
			check(reason == "", "room %s valid: %s" % [room.get("id", "?"), reason])
	check(total >= 10, "enough rooms")
	var forest: Array = data["chapters"][0]
	check(forest.size() == 6, "Forest has 6 rooms")
	check(forest[5].get("boss") != null and int(forest[5]["boss"]) == 0, "last Forest room is boss 0")
	check(forest[0]["id"] == "forest_1" and forest[5]["id"] == "forest_boss", "Forest ids")
	for i in 5:
		check(forest[i].get("boss") == null, "non-boss room %d" % i)
	check(PrismRoom.load_rooms("res://data/does_not_exist.json").is_empty(), "missing file -> {}")
	check(PrismRoom.load_rooms("res://project.godot").is_empty(), "malformed json -> {}")
	check(PrismRoom.validate_room({}) != "", "empty room invalid")
	var bad: Dictionary = forest[0].duplicate(true)
	bad["enemies"][0]["type"] = "ghost"
	check(PrismRoom.validate_room(bad) != "", "unknown enemy type invalid")
	bad = forest[0].duplicate(true)
	bad["enemies"][0]["pos"] = [bad["spawn"][0] + 50, bad["spawn"][1]]
	check(PrismRoom.validate_room(bad) != "", "enemy near spawn invalid")
	bad = forest[0].duplicate(true)
	bad["size"] = [2000, 360]
	check(PrismRoom.validate_room(bad) != "", "oversized room invalid")

func test_flow() -> void:
	world = make_world(0)
	await frames(1)
	var room: PrismRoom = world.room
	check(room != null and world.room_index == 0 and room.data["id"] == "forest_1", "world starts in forest_1")
	check(is_instance_valid(room.player) and room.player.is_in_group("player"), "room has player")
	check(room.enemies_left == room.data["enemies"].size() and room.enemies_left > 0, "enemies_left from data")
	check(not room.exit_open, "exit closed at start")
	var counts := {"cleared": 0, "exited": 0}
	room.cleared.connect(func(): counts["cleared"] += 1)
	room.exited.connect(func(): counts["exited"] += 1)
	# Exit stays shut while enemies live.
	room.player.global_position = Vector2(room.data["exit"][0], room.data["exit"][1])
	await frames(2)
	check(counts["exited"] == 0 and world.room_index == 0, "closed exit does nothing")
	room.player.global_position = Vector2(room.data["spawn"][0], room.data["spawn"][1])
	for e in get_nodes_in_group("enemies").duplicate():
		e.hit_by(null, Vector2.ZERO, "shield")
	check(counts["cleared"] == 1 and room.exit_open and room.enemies_left == 0, "cleared once, exit open")
	await frames(3)
	check(counts["cleared"] == 1, "cleared not repeated")
	room.player.global_position = Vector2(room.data["exit"][0], room.data["exit"][1])
	await frames(1)
	check(counts["exited"] == 1, "exited once")
	await frames(3)
	check(counts["exited"] == 1, "exited not repeated")
	check(world.room_index == 1 and world.room != room, "advanced to room 1")
	check(completed.size() == 1 and completed[0][0] == "forest_1" and completed[0][1] > 0.0, "room_completed id and time > 0")
	check(room_children() == 1, "one room after transition")
	drop_world()
	# Chapter completion on last room.
	world = make_world(0, 5)
	await frames(1)
	check(world.room_index == 5 and stories == ["boss_0"], "boss room requests story: %s" % str(stories))
	for e in get_nodes_in_group("enemies").duplicate():
		e.hit_by(null, Vector2.ZERO, "shield")
		e.hit_guard = 0.0
		e.hit_by(null, Vector2.ZERO, "shield")
		e.hit_guard = 0.0
		e.hit_by(null, Vector2.ZERO, "shield")
	check(world.room.exit_open, "boss kill opens exit")
	world.room.player.global_position = Vector2(world.room.data["exit"][0], world.room.data["exit"][1])
	await frames(3)
	check(chapters_done == [0], "chapter_completed(0): %s" % str(chapters_done))
	check(completed.size() == 1 and completed[0][0] == "forest_boss", "boss room completed")
	drop_world()

func test_death_restart() -> void:
	world = make_world(0)
	await frames(1)
	var room: PrismRoom = world.room
	var count: int = room.data["enemies"].size()
	var died := {"n": 0}
	room.player_died.connect(func(): died["n"] += 1)
	room.player.kill(Vector2(0, 0))
	check(died["n"] == 1 and died_count == 1 and world.deaths == 1, "player_died once, deaths counted")
	# Kill one enemy and fire a shot so restart has something to clean.
	PrismProjectile.spawn(room, Vector2(300, 100), Vector2(10, 0))
	check(group_count("projectiles") >= 1, "projectile exists before restart")
	world.restart_room()
	check(world.room != room and world.room.enemies_left == count, "restart: new room, enemies_left from data")
	check(group_count("projectiles") == 0, "restart: zero projectiles")
	check(group_count("player") == 1 and not world.room.player.dead, "restart: single fresh player")
	check(room_children() == 1, "restart: one room child")
	await frames(2)
	check(room_children() == 1 and group_count("enemies") == count, "after frames still one room / enemies correct")
	check(world.room_index == 0, "restart keeps room_index")
	drop_world()

func test_focus_cases() -> void:
	# Focus 1: slow-mo cleared by restart.
	world = make_world(0)
	await frames(1)
	world.time_control.update(0.5, true)
	check(is_equal_approx(Engine.time_scale, 0.3), "slow-mo active")
	world.room.player.kill(Vector2.ZERO)
	world.restart_room()
	check(is_equal_approx(Engine.time_scale, 1.0), "restart restores time_scale")
	check(is_equal_approx(world.time_control.meter, PrismTimeControl.MAX_METER), "restart refills meter")
	drop_world()
	# Focus 2: thrown shield cleaned, fresh player.
	world = make_world(0)
	await frames(1)
	var p: PrismPlayer = world.room.player
	p.aim = Vector2.RIGHT
	p.try_throw()
	check(p.shield_out and group_count("thrown_shields") == 1, "shield thrown")
	p.kill(Vector2.ZERO)
	world.restart_room()
	check(group_count("thrown_shields") == 0, "restart: zero thrown shields")
	check(world.room.player.shield_out == false and world.room.player != p, "restart: fresh player, shield_out false")
	drop_world()
	# Focus 4: death and exit in the same frame.
	world = make_world(0)
	await frames(1)
	var r: PrismRoom = world.room
	r.player.kill(Vector2.ZERO)
	r.exited.emit()
	await frames(2)
	check(room_children() == 1 and world.room_index == 0 and world.room == r, "death+exit same frame: one room, index unchanged")
	check(completed.is_empty(), "death+exit: no room_completed")
	drop_world()
	# Exit then death in the same frame: transition wins, no stray restart.
	world = make_world(0)
	await frames(1)
	r = world.room
	r.exited.emit()
	r.player.kill(Vector2.ZERO)
	await frames(2)
	check(room_children() == 1 and world.room_index == 1, "exit+death same frame: advanced once")
	drop_world()

func test_boss() -> void:
	world = make_world(0, 5)
	await frames(1)
	var room: PrismRoom = world.room
	check(room.boss != null and room.boss.is_boss and room.boss.hits_left == 3 and room.boss.phase == 1, "boss spawned")
	check(room.enemies_left == 1, "boss counts as one enemy")
	var seen: Array = []
	room.boss_phase_reached.connect(func(ph: int): seen.append(ph))
	room.boss.hit_by(null, Vector2.ZERO, "shield")
	room.boss.hit_guard = 0.0
	room.boss.hit_by(null, Vector2.ZERO, "shield")
	check(room.boss.phase == 2 and seen == [2] and world.boss_phase_checkpoint == 2, "phase 2 reached and checkpointed")
	var expected_hits: int = room.boss.hits_left
	room.player.kill(Vector2.ZERO)
	world.restart_room()
	check(world.room.boss.phase == 2 and world.room.boss.hits_left == expected_hits, "restart resumes boss at phase 2")
	check(stories == ["boss_0"], "restart does not repeat boss story")
	# Leaving the boss room resets the checkpoint for the next one.
	drop_world()

func test_hardening() -> void:
	# player.try_throw recovers when the shield vanished without `caught`.
	world = make_world(0)
	await frames(1)
	var p: PrismPlayer = world.room.player
	p.aim = Vector2.RIGHT
	p.try_throw()
	var s: Node = p.thrown_shield
	s.remove_from_group("thrown_shields")
	s.free()
	check(p.shield_out, "stuck state reproduced")
	p.try_throw()
	check(p.shield_out and is_instance_valid(p.thrown_shield) and p.thrown_shield != s, "try_throw recovers from freed shield")
	drop_world()
