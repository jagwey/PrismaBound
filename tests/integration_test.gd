extends SceneTree

const Save = preload("res://scripts/save_manager.gd")
var failures := 0
var checks := 0
var main: Node

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)

func finish_story() -> void:
	var guard := 0
	while main.page == "dialogue" and guard < 20:
		main.next_dialogue()
		guard += 1

func run() -> void:
	Save.PATH = "res://tests/integration_save.tmp"
	Save.BACKUP = "res://tests/integration_backup.tmp"
	Save.SETTINGS = "res://tests/integration_settings.tmp"
	Save.reset_game()
	var fresh := Save.fresh()
	check(Save.save_game(fresh), "Fresh save succeeds")
	fresh.shards = 17
	check(Save.save_game(fresh), "Second save succeeds with backup")
	check(int(Save.load_game().shards) == 17, "Round-trip keeps shards")
	var corrupt := FileAccess.open(Save.PATH, FileAccess.WRITE)
	corrupt.store_string("{broken json"); corrupt.close()
	check(int(Save.load_game().shards) == 0, "Corrupt primary falls back to valid previous save")
	check(not Save.valid({"version": 1}), "Incomplete save rejected")
	fresh.region = 99
	check(not Save.save_game(fresh), "Out-of-range region rejected")
	fresh = Save.fresh()
	fresh.cleared = [99]
	check(not Save.valid(fresh), "Out-of-range boss progress rejected")
	Save.reset_game()
	main = load("res://scripts/main.gd").new()
	root.add_child(main)
	await process_frame
	check(main.page == "menu", "Main menu boots")
	check(main.stories.has("intro") and main.stories.has("ending_a") and main.stories.has("ending_b"), "Narrative resources loaded")
	main.show_settings("menu")
	check(main.page == "settings", "Settings opens")
	main.show_controls()
	check(main.page == "controls", "Remap UI opens")
	main.settings.bindings.jump = {"type":"key", "code": KEY_J}
	main.setup_input()
	check(InputMap.action_get_events("jump")[0].physical_keycode == KEY_J, "Remap applies through InputMap")
	main.settings.bindings = {}
	main.setup_input()
	main.new_game()
	check(main.page == "dialogue", "New game starts pact scene")
	finish_story()
	check(is_instance_valid(main.world) and main.world.region == 0, "Pact leads into forest")
	check(main.page == "game", "Region entry returns to gameplay")
	for area in 5:
		check(main.world.region == area, "Flow reaches region %d" % area)
		main.show_pause()
		check(paused and main.page == "pause", "Pause works %d" % area)
		main.show_hud()
		check(not paused, "Resume works %d" % area)
		main.world.player.position = Vector2(140, 299)
		main.world._interact()
		check(main.page == "altar", "Checkpoint opens upgrade panel %d" % area)
		check(not Save.load_game().is_empty(), "Checkpoint writes valid save %d" % area)
		main.show_hud()
		# World tests exercise real reflected projectiles. This fixture checks integration signals.
		main.world._solve_puzzle()
		main.world.player.position = Vector2(2250, 299)
		main.world.checkpoint_cooldown = 0
		main.world._interact()
		check(main.progress.flags.get("checkpoint_id") == 1, "Checkpoint ID persisted %d" % area)
		main.show_hud()
		main.world._spawn_boss()
		finish_story()
		check(is_instance_valid(main.world.boss), "Boss instantiated in region %d" % area)
		main.world.boss.take_damage(10000, main.world.player.position, true)
		# Temple requires Soul mode before taking damage.
		if not main.world.boss_defeated:
			main.world.player.mode = 4
			main.world.boss._hit_cooldown = 0
			main.world.boss.take_damage(10000, main.world.player.position, true)
		check(main.world.boss_defeated, "Boss defeat opens exit %d" % area)
		main.world.player.position = Vector2(3100, 280)
		main.world._interact()
		finish_story()
		await process_frame
	check(main.page == "choice", "All five exits reach ending choice")
	check(main.progress.cleared.size() == 5, "All five boss progress flags saved")
	main.finish_game("a")
	finish_story()
	check(main.page == "ending" and Save.load_game().ending == "a", "Ending A plays and saves")
	main.show_final_choice()
	main.finish_game("b")
	finish_story()
	check(main.page == "ending" and Save.load_game().ending == "b", "Ending B plays and saves")
	main.show_menu()
	check(main.page == "menu", "Return to menu frees world")
	main.continue_game()
	check(main.page == "ending", "Continue completed game restores ending")
	main.progress = Save.fresh()
	main.progress.flags = {"region_0":true, "checkpoint_region":0, "checkpoint_id":1}
	main.start_world(0)
	check(main.world.player.position.x == 2250 and main.world.puzzle_solved, "Reload starts at saved checkpoint with puzzle gate open")
	main.world.player.take_damage(1000, main.world.player.position)
	check(main.page == "death" and paused, "Death opens retry overlay")
	main.world.restart_checkpoint()
	main.show_hud()
	check(main.world.player.hp > 0 and not main.world.dead, "Checkpoint restart restores live player")
	main.show_menu()
	main.queue_free()
	paused = false
	await process_frame
	await process_frame
	Save.reset_game()
	if FileAccess.file_exists(Save.SETTINGS): DirAccess.remove_absolute(Save.SETTINGS)
	print("INTEGRATION TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
