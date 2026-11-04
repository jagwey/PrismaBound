extends SceneTree

const Save = preload("res://scripts/save_manager.gd")
var failures: int = 0
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)

func write_raw(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()

func cleanup() -> void:
	for p in [Save.PATH, Save.BACKUP, Save.PATH + ".tmp"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(p)

func run() -> void:
	Save.PATH = "user://test_save.json"
	Save.BACKUP = "user://test_save.backup.json"
	cleanup()

	var f: Dictionary = Save.fresh()
	check(f == {"version": 2, "unlocked_chapter": 0, "best_times": {}, "total_deaths": 0}, "fresh shape")
	check(Save.valid(f), "fresh is valid")
	check(not Save.valid(null), "null invalid")
	check(not Save.valid({"version": 1}), "v1 shape invalid as v2")
	var bad := Save.fresh()
	bad.unlocked_chapter = 5
	check(not Save.valid(bad), "chapter 5 invalid")
	bad = Save.fresh()
	bad.best_times = {"r1": 0.0}
	check(not Save.valid(bad), "zero time invalid")
	bad = Save.fresh()
	bad.best_times = {"r1": "x"}
	check(not Save.valid(bad), "non-number time invalid")
	bad = Save.fresh()
	bad.total_deaths = -1
	check(not Save.valid(bad), "negative deaths invalid")

	var v1 := {"version": 1, "region": 3, "unlocked": 3, "upgrades": 2, "shards": 9, "cleared": [0, 1], "flags": {}, "ending": "", "checkpoint": 0, "hp": 100.0}
	var m: Dictionary = Save.migrate(v1)
	check(int(m.unlocked_chapter) == 3, "migrate unlocked_chapter")
	check(Save.valid(m), "migrated valid")
	check(int(m.version) == 2 and m.best_times.is_empty() and int(m.total_deaths) == 0, "migrate others fresh")
	v1.unlocked = 99
	check(int(Save.migrate(v1).unlocked_chapter) == 4, "migrate clamps high")
	var v2 := Save.fresh()
	v2.unlocked_chapter = 2
	check(Save.migrate(v2) == v2, "v2 returned as-is")

	var d := Save.fresh()
	d = Save.record_room(d, "r1", 12.5)
	check(is_equal_approx(float(d.best_times.r1), 12.5), "record first")
	d = Save.record_room(d, "r1", 9.1)
	check(is_equal_approx(float(d.best_times.r1), 9.1), "record lower wins")
	d = Save.record_room(d, "r1", 15.0)
	check(is_equal_approx(float(d.best_times.r1), 9.1), "record higher ignored")

	# round trip
	var rt := Save.fresh()
	rt.unlocked_chapter = 2
	rt.best_times = {"a": 3.5}
	rt.total_deaths = 7
	check(Save.save_game(rt), "save ok")
	check(Save.load_game() == rt, "round trip equal")

	# corrupt main + valid backup
	check(Save.save_game(rt), "second save creates backup")
	check(FileAccess.file_exists(Save.BACKUP), "backup exists")
	write_raw(Save.PATH, "{not json")
	check(Save.load_game() == rt, "backup used when main corrupt")

	# both corrupt
	write_raw(Save.BACKUP, "garbage")
	check(Save.load_game() == Save.fresh(), "both corrupt -> fresh")

	# v1 file on disk migrates
	write_raw(Save.PATH, JSON.stringify({"version": 1, "region": 1, "unlocked": 2, "upgrades": 0, "shards": 0}))
	check(int(Save.load_game().unlocked_chapter) == 2, "v1 file migrated on load")

	# unrecognized-but-parsable main must fall through to backup
	write_raw(Save.BACKUP, JSON.stringify(rt))
	for junk in ["{}", "{\"foo\":1}", "{\"version\":3}", "{\"version\":1,\"unlocked\":\"x\"}"]:
		write_raw(Save.PATH, junk)
		check(Save.load_game() == rt, "junk main falls to backup: " + junk)
	check(Save.migrate({}).is_empty() and Save.migrate({"version": 3}).is_empty(), "migrate rejects unknown")
	var nan_d := Save.fresh()
	nan_d.best_times = {"r": NAN}
	check(not Save.valid(nan_d), "NaN time invalid")
	nan_d.best_times = {"r": INF}
	check(not Save.valid(nan_d), "inf time invalid")
	check(not Save.record_room(Save.fresh(), "r", NAN).best_times.has("r"), "record ignores NaN")

	cleanup()
	print("SAVE TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
