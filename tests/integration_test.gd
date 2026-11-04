extends SceneTree

var failures: int = 0
var checks: int = 0
var main: Node

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

func skip_dialogue() -> void:
	var guard := 0
	while main.page == "dialogue" and guard < 40:
		main.next_dialogue()
		guard += 1
		await frames(1)

func wait_real(seconds: float) -> void:
	var end: int = Time.get_ticks_msec() + int(seconds * 1000.0)
	while Time.get_ticks_msec() < end:
		await process_frame

func has_key(action: String, keycode: int) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventKey and e.physical_keycode == keycode:
			return true
	return false

func has_mouse(action: String, index: int) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventMouseButton and e.button_index == index:
			return true
	return false

func has_axis(action: String, axis: int) -> bool:
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadMotion and e.axis == axis:
			return true
	return false

func cleanup_files() -> void:
	for path in [PrismSave.PATH, PrismSave.BACKUP, PrismSave.PATH + ".tmp", PrismSave.SETTINGS]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)

func run() -> void:
	PrismSave.PATH = "user://test_integration_save.json"
	PrismSave.BACKUP = "user://test_integration_save.backup.json"
	PrismSave.SETTINGS = "user://test_integration_settings.json"
	cleanup_files()
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(2)
	await test_input()
	await test_new_game_and_completion()
	await test_death()
	await test_continue_v1()
	await test_pause_slow()
	await test_pause_keeps_meter()
	await test_rooms_load_failure()
	await test_ending()
	Engine.time_scale = 1.0
	main.free()
	cleanup_files()
	print("INTEGRATION TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func test_input() -> void:
	for action in ["move_left", "move_right", "jump", "dash", "reflect", "throw", "slow", "restart", "interact", "pause", "aim_left", "aim_right", "aim_up", "aim_down"]:
		check(InputMap.has_action(action), "action exists: " + action)
	check(has_key("move_left", KEY_A) and has_key("move_right", KEY_D), "A/D default")
	check(has_key("jump", KEY_SPACE), "jump Space")
	check(has_key("dash", KEY_CTRL), "dash Left Ctrl")
	check(has_mouse("reflect", MOUSE_BUTTON_LEFT), "reflect LMB")
	check(has_mouse("throw", MOUSE_BUTTON_RIGHT), "throw RMB")
	check(has_key("slow", KEY_SHIFT), "slow Shift")
	check(has_axis("throw", JOY_AXIS_TRIGGER_RIGHT), "gamepad throw on RT")
	check(has_axis("slow", JOY_AXIS_TRIGGER_LEFT), "gamepad slow on LT")
	check(has_key("restart", KEY_R) and has_key("interact", KEY_E) and has_key("pause", KEY_ESCAPE), "R/E/Esc defaults")
	for action in ["guard", "bash", "mode", "absorb", "release"]:
		check(not InputMap.has_action(action), "old action removed: " + action)
	var before: int = InputMap.action_get_events("aim_left").size()
	main.setup_input()
	check(InputMap.action_get_events("aim_left").size() == before, "setup_input idempotent")
	check(not main.has_save(), "no save on disk at start")

func test_new_game_and_completion() -> void:
	main.new_game()
	check(main.page == "dialogue", "intro dialogue starts")
	await skip_dialogue()
	check(main.page == "game" and is_instance_valid(main.world), "game page after dialogue")
	check(main.world.chapter == 0 and main.world.room_index == 0, "chapter 0 room 0")
	check(main.world.room.data["id"] == "forest_1", "room id forest_1")
	check(not paused, "tree unpaused in game")
	check(main.hooked_player == main.world.player and main.world.player.combat_event.is_connected(main.audio.play_effect), "player hooked to audio")
	var room: PrismRoom = main.world.room
	for e in get_nodes_in_group("enemies").duplicate():
		e.hit_by(null, Vector2.ZERO, "shield")
	check(room.exit_open, "room cleared")
	room.player.global_position = Vector2(room.data["exit"][0], room.data["exit"][1])
	await frames(3)
	await process_frame
	check(FileAccess.file_exists(PrismSave.PATH), "save written on room completion")
	var saved: Dictionary = PrismSave.load_game()
	check(saved.best_times.has("forest_1") and float(saved.best_times["forest_1"]) > 0.0, "best_times.forest_1 saved")
	check(is_instance_valid(main.toast_label) and str(main.toast_label.text).begins_with("Süre "), "completion toast shown")
	check(main.world.room_index == 1, "advanced to room 1")
	await process_frame
	check(main.hooked_player == main.world.player, "re-hooked after advance")
	check(main.has_save(), "has_save true after write")

func test_death() -> void:
	var before: int = int(main.progress.total_deaths)
	main.world.player.kill(Vector2.ZERO)
	await frames(2)
	check(main.page == "death", "death page")
	check(int(main.progress.total_deaths) == before + 1, "death counted in memory")
	check(not paused, "tree not paused on death")
	check(Engine.time_scale == 1.0, "time scale 1 on death")
	var disk: Dictionary = PrismSave.load_game()
	check(int(disk.total_deaths) == 0, "death not persisted")
	var ev := InputEventAction.new()
	ev.action = "restart"
	ev.pressed = true
	main._input(ev)
	check(main.page == "death", "restart ignored before 0.3 s")
	await wait_real(0.4)
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	main._input(wheel)
	check(main.page == "death", "wheel does not restart from death screen")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	main._input(click)
	check(main.page == "game", "left click restarts from death screen")
	main.world.player.kill(Vector2.ZERO)
	await frames(2)
	await wait_real(0.4)
	main._input(ev)
	check(main.page == "game", "restart accepted after 0.3 s")
	check(main.death_label.text == "Ölüm: %d" % main.world.deaths, "HUD shows chapter deaths")
	check(main.hooked_player == main.world.player and not main.world.player.dead, "fresh player hooked after restart")
	main.world.player.kill(Vector2.ZERO)
	await frames(2)
	check(main.page == "death", "second death")
	await wait_real(1.2)
	check(main.page == "game" and not main.world.player.dead, "auto restart by 1.0 s")
	check(main.world.room_index == 1, "restart stays in same room")

func test_continue_v1() -> void:
	var f := FileAccess.open(PrismSave.PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": 1, "unlocked": 2}))
	f.close()
	DirAccess.remove_absolute(PrismSave.BACKUP)
	main.continue_game()
	await skip_dialogue()
	check(main.page == "game" and main.world.chapter == 2 and main.world.room_index == 0, "continue loads unlocked chapter 2")
	check(int(main.progress.unlocked_chapter) == 2, "v1 save migrated")

func test_pause_slow() -> void:
	Engine.time_scale = 0.3
	main.world.time_control.active = true
	main.show_pause()
	check(Engine.time_scale == 1.0, "pause resets time scale")
	check(paused and main.page == "pause", "paused")
	main.show_hud()
	check(not paused and main.page == "game", "resume")
	Engine.time_scale = 0.3
	main.show_menu()
	check(Engine.time_scale == 1.0 and not is_instance_valid(main.world), "menu resets time scale")

func test_pause_keeps_meter() -> void:
	main.start_world(0)
	await frames(1)
	main.world.time_control.meter = 1.25
	main.world.time_control.active = true
	main.show_pause()
	check(is_equal_approx(main.world.time_control.meter, 1.25), "pause does not refill meter")
	check(not main.world.time_control.active and Engine.time_scale == 1.0, "pause suspends slow-mo")
	main.show_hud()
	check(is_equal_approx(main.world.time_control.meter, 1.25), "meter unchanged after resume")
	main.play_story("region_0", main.show_hud)
	check(is_equal_approx(main.world.time_control.meter, 1.25), "dialogue does not refill meter")
	await skip_dialogue()

func test_rooms_load_failure() -> void:
	var bad_path := "user://test_bad_rooms.json"
	var f := FileAccess.open(bad_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"chapters": [[{"id": "broken", "size": [640, 360]}], [], [], [], []]}))
	f.close()
	var w: PrismWorld = PrismWorld.new()
	w.rooms_path = bad_path
	w.configure(0, 0)
	root.add_child(w)
	check(not w.is_ready() and not w.load_error.is_empty(), "invalid room data sets load_error")
	w.free()
	var w2: PrismWorld = PrismWorld.new()
	w2.rooms_path = "user://does_not_exist.json"
	root.add_child(w2)
	check(not w2.is_ready() and not w2.load_error.is_empty(), "missing rooms file sets load_error")
	w2.free()
	var w3: PrismWorld = PrismWorld.new()
	root.add_child(w3)
	check(w3.is_ready() and w3.load_error.is_empty(), "real rooms.json loads and validates")
	w3.free()
	main.rooms_path = bad_path
	main.start_world(0)
	check(main.page == "menu" and not is_instance_valid(main.world), "load failure returns to menu")
	check(main.notice == "Oda verisi okunamadı.", "load failure notice set")
	check(not paused and Engine.time_scale == 1.0, "load failure leaves tree running")
	main.rooms_path = "res://data/rooms.json"
	main.notice = ""
	DirAccess.remove_absolute(bad_path)

func test_ending() -> void:
	main.progress = PrismSave.fresh()
	main.on_chapter_completed(0)
	await skip_dialogue()
	check(int(main.progress.unlocked_chapter) == 1 and main.world.chapter == 1, "chapter 0 -> unlocks and enters 1")
	main.on_chapter_completed(4)
	check(int(main.progress.unlocked_chapter) == 4, "unlocked clamped to 4")
	check(main.page == "dialogue", "ending_a plays after chapter 4")
	await skip_dialogue()
	check(main.page == "credits", "credits after ending")
	main.show_menu()
