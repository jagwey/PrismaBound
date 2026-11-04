extends Node2D

const Save = preload("res://scripts/save_manager.gd")
const Audio = preload("res://scripts/audio_manager.gd")
const INK := Color("0c1222")
const PALE := Color("e3e8e9")
const MUTE := Color("869aac")
const TEAL := Color("6de0cc")
const RESTART_DELAY := 0.3
const AUTO_RESTART := 1.0
const ACTION_LABELS := {"move_left":"Sola hareket", "move_right":"Sağa hareket", "jump":"Zıpla", "dash":"Atıl", "reflect":"Yansıt", "throw":"Kalkan fırlat", "slow":"Zamanı yavaşlat", "restart":"Odayı yenile", "interact":"Etkileşim", "pause":"Duraklat"}
const AIM_ACTIONS := ["aim_left", "aim_right", "aim_up", "aim_down"]
var progress: Dictionary = Save.fresh()
var settings: Dictionary = Save.defaults()
var audio: Node
var world: Node2D
var layer: CanvasLayer
var ui: Control
var hud: Control
var time_label: Label
var death_label: Label
var meter_bar: ProgressBar
var objective_label: Label
var boss_bar: ProgressBar
var boss_name: Label
var toast_label: Label
var toast_until_ms := 0
var death_ms := 0
var hooked_player: Node
var page := "menu"
var clock_time := 0.0
var stories: Dictionary = {}
var seen_stories: Dictionary = {}
var skip_stories := false
var dialogue_lines: Array = []
var dialogue_index := 0
var dialogue_done: Callable
var remap_action := ""
var settings_return := "menu"
var notice := ""
var boot_args := OS.get_cmdline_user_args()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	settings = Save.load_settings()
	setup_input()
	var story_file := FileAccess.open("res://data/dialogues_tr.json", FileAccess.READ)
	if story_file:
		var data: Variant = JSON.parse_string(story_file.get_as_text())
		if data is Dictionary: stories = data
	audio = Audio.new()
	add_child(audio)
	audio.apply(settings)
	apply_display()
	layer = CanvasLayer.new()
	add_child(layer)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layer.add_child(ui)
	show_menu()
	if "--smoke" in boot_args:
		skip_stories = true
		start_world(0)

func setup_input() -> void:
	var keys := {"move_left": KEY_A, "move_right": KEY_D, "jump": KEY_SPACE, "dash": KEY_CTRL, "slow": KEY_SHIFT, "restart": KEY_R, "interact": KEY_E, "pause": KEY_ESCAPE}
	var mice := {"reflect": MOUSE_BUTTON_LEFT, "throw": MOUSE_BUTTON_RIGHT}
	var all_actions: Array = ACTION_LABELS.keys() + AIM_ACTIONS
	for action in all_actions:
		if not InputMap.has_action(action): InputMap.add_action(action, 0.2 if action in AIM_ACTIONS else 0.5)
		InputMap.action_erase_events(action)
	for action in ACTION_LABELS:
		var event: InputEvent
		if mice.has(action):
			event = InputEventMouseButton.new()
			event.button_index = mice[action]
		else:
			event = InputEventKey.new()
			event.physical_keycode = keys[action]
		var binding: Variant = settings.bindings.get(action)
		if binding is Dictionary:
			if binding.get("type") == "key":
				event = InputEventKey.new(); event.physical_keycode = int(binding.get("code", 0))
			elif binding.get("type") == "mouse":
				event = InputEventMouseButton.new(); event.button_index = int(binding.get("code", 1))
		InputMap.action_add_event(action, event)
	var buttons := {"jump": JOY_BUTTON_A, "dash": JOY_BUTTON_B, "reflect": JOY_BUTTON_RIGHT_SHOULDER, "throw": JOY_BUTTON_LEFT_SHOULDER, "interact": JOY_BUTTON_X, "restart": JOY_BUTTON_Y, "pause": JOY_BUTTON_START}
	for action in buttons:
		var button := InputEventJoypadButton.new()
		button.button_index = buttons[action]
		InputMap.action_add_event(action, button)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0], "slow": [JOY_AXIS_TRIGGER_LEFT, 1.0], "aim_left": [JOY_AXIS_RIGHT_X, -1.0], "aim_right": [JOY_AXIS_RIGHT_X, 1.0], "aim_up": [JOY_AXIS_RIGHT_Y, -1.0], "aim_down": [JOY_AXIS_RIGHT_Y, 1.0]}
	for action in axes:
		var axis := InputEventJoypadMotion.new()
		axis.axis = axes[action][0]; axis.axis_value = axes[action][1]
		InputMap.action_add_event(action, axis)

func apply_display() -> void:
	if DisplayServer.get_name() == "headless": return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	if not settings.fullscreen: DisplayServer.window_set_size(Vector2i(640, 360) * int(settings.resolution))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if settings.vsync else DisplayServer.VSYNC_DISABLED)

func clear_ui() -> void:
	for child in ui.get_children():
		ui.remove_child(child)
		child.queue_free()
	hud = null
	toast_label = null
	remap_action = ""

func label_at(text: String, pos: Vector2, size: int = 14, color: Color = PALE, width: float = 580) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size.x = width
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(label)
	return label

func panel(rect: Rect2, color: Color = INK) -> ColorRect:
	var node := ColorRect.new()
	node.position = rect.position
	node.size = rect.size
	node.color = color
	ui.add_child(node)
	return node

func button(text: String, pos: Vector2, callback: Callable, width: float = 220) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = Vector2(width, 30)
	b.add_theme_font_size_override("font_size", 13)
	for kind in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color("1a2e40") if kind == "hover" or kind == "focus" else Color("111d2d")
		style.border_color = TEAL if kind == "hover" or kind == "focus" else Color("2b4556")
		style.set_border_width_all(1)
		style.content_margin_left = 12
		b.add_theme_stylebox_override(kind, style)
	b.pressed.connect(func(): audio.play_effect("menu"); callback.call())
	ui.add_child(b)
	return b

func has_save() -> bool:
	return FileAccess.file_exists(Save.PATH) or FileAccess.file_exists(Save.BACKUP)

func reset_time() -> void:
	if is_instance_valid(world) and world.get("time_control") != null: world.time_control.reset()
	Engine.time_scale = 1.0

func show_menu() -> void:
	reset_time()
	get_tree().paused = false
	if is_instance_valid(world):
		remove_child(world); world.queue_free(); world = null
	hooked_player = null
	page = "menu"
	clear_ui()
	audio.set_region(-1)
	label_at("T O R I M O N   /   BİR YANSIMA HİKÂYESİ", Vector2(42, 36), 10, TEAL)
	label_at("PRISMBOUND", Vector2(39, 61), 42)
	label_at("Tek vuruş. Tek yansıma.", Vector2(43, 113), 13, MUTE)
	button("YENİ OYUN", Vector2(44, 161), confirm_new, 210).grab_focus()
	var cont := button("DEVAM ET", Vector2(44, 197), continue_game, 210)
	cont.disabled = not has_save()
	button("AYARLAR", Vector2(44, 233), func(): show_settings("menu"), 102)
	button("EKİP", Vector2(152, 233), show_credits, 102)
	button("ÇIKIŞ", Vector2(44, 269), func(): get_tree().quit(), 210)
	label_at("GELİŞTİRME SÜRÜMÜ  /  ÖZGÜN GEÇİCİ GÖRSEL VE SESLER", Vector2(43, 328), 9, MUTE)
	if not notice.is_empty(): label_at(notice, Vector2(280, 292), 11, TEAL, 330)

func confirm_new() -> void:
	if not has_save(): new_game(); return
	clear_ui()
	label_at("Yeni yolculuk", Vector2(64, 76), 28)
	label_at("Mevcut ilerleme yeni oyunun ilk kaydıyla değiştirilecek.", Vector2(64, 130), 14)
	button("YENİ OYUNU BAŞLAT", Vector2(64, 195), new_game)
	button("GERİ", Vector2(64, 233), show_menu)

func new_game() -> void:
	progress = Save.fresh()
	seen_stories.clear()
	play_story("intro", func(): start_world(0))

func continue_game() -> void:
	progress = Save.load_game()
	seen_stories.clear()
	start_world(clampi(int(progress.get("unlocked_chapter", 0)), 0, 4))

func start_world(area: int) -> void:
	reset_time()
	get_tree().paused = false
	if is_instance_valid(world):
		remove_child(world); world.queue_free()
	hooked_player = null
	world = load("res://scripts/world.gd").new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.configure(area, 0)
	world.chapter_completed.connect(on_chapter_completed)
	world.room_completed.connect(on_room_completed)
	world.story_requested.connect(on_story_requested)
	world.player_died.connect(on_player_died)
	add_child(world)
	hook_player()
	audio.set_region(area)
	show_hud()
	play_story_once("region_%d" % area, show_hud)

# A new player node is built per room: hook it on every build and restart.
func hook_player() -> void:
	if not is_instance_valid(world) or not is_instance_valid(world.player): return
	var p: Node = world.player
	if p == hooked_player: return
	hooked_player = p
	apply_player_settings()
	if p.has_signal("combat_event") and not p.combat_event.is_connected(audio.play_effect):
		p.combat_event.connect(audio.play_effect)

func apply_player_settings() -> void:
	if not is_instance_valid(world) or not is_instance_valid(world.player): return
	world.player.set("snap_aim", bool(settings.snap))
	world.player.set("effects_intensity", float(settings.effects))

func save_progress() -> void:
	if not Save.save_game(progress): notice = "Kayıt yazılamadı. Klasör erişimini kontrol et."

func on_room_completed(room_id: String, time: float) -> void:
	progress = Save.record_room(progress, room_id, time)
	save_progress()
	audio.play_effect("checkpoint")
	var best: float = float(progress.best_times.get(room_id, time))
	show_toast("Süre %.2f · En iyi %.2f" % [time, best])

func show_toast(text: String) -> void:
	if not is_instance_valid(ui): return
	if is_instance_valid(toast_label): toast_label.queue_free()
	toast_label = label_at(text, Vector2(170, 150), 16, TEAL, 300)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_until_ms = Time.get_ticks_msec() + 2500

func on_story_requested(key: String) -> void:
	play_story_once(key, show_hud)

func on_chapter_completed(area: int) -> void:
	progress.unlocked_chapter = clampi(maxi(int(progress.get("unlocked_chapter", 0)), area + 1), 0, 4)
	save_progress()
	audio.play_effect("victory")
	if area >= 4:
		play_story("ending_a", show_credits)
	else:
		start_world(area + 1)

func on_player_died() -> void:
	if page != "game": return
	progress.total_deaths = int(progress.get("total_deaths", 0)) + 1
	death_ms = Time.get_ticks_msec()
	page = "death"
	var shade := panel(Rect2(0, 0, 640, 360), Color(0.025, 0.035, 0.07, 0.6))
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var text := label_at("ÖLDÜN — R / tık: tekrar", Vector2(120, 150), 26, PALE, 400)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func death_elapsed() -> float:
	return (Time.get_ticks_msec() - death_ms) / 1000.0

func restart_room() -> void:
	if not is_instance_valid(world): return
	world.restart_room()
	hook_player()
	show_hud()

func bar(pos: Vector2, size: Vector2, color: Color) -> ProgressBar:
	var b := ProgressBar.new()
	b.position = pos; b.size = size; b.show_percentage = false
	var bg := StyleBoxFlat.new(); bg.bg_color = Color("192637")
	var fill := StyleBoxFlat.new(); fill.bg_color = color
	b.add_theme_stylebox_override("background", bg)
	b.add_theme_stylebox_override("fill", fill)
	ui.add_child(b)
	return b

func show_hud() -> void:
	get_tree().paused = false
	page = "game"
	clear_ui()
	hud = ui
	panel(Rect2(8, 8, 140, 58), Color(0.03, 0.05, 0.09, 0.88))
	time_label = label_at("0.00", Vector2(14, 8), 18, PALE, 120)
	death_label = label_at("Ölüm: %d" % int(progress.get("total_deaths", 0)), Vector2(14, 32), 11, MUTE, 120)
	meter_bar = bar(Vector2(14, 53), Vector2(128, 6), TEAL)
	meter_bar.max_value = PrismTimeControl.MAX_METER
	meter_bar.value = PrismTimeControl.MAX_METER
	objective_label = label_at("", Vector2(14, 327), 11, TEAL, 612)
	boss_name = label_at("", Vector2(216, 9), 11, PALE, 400)
	boss_bar = bar(Vector2(216, 29), Vector2(408, 5), Color("d49ce9"))
	boss_bar.visible = false

func show_pause() -> void:
	reset_time()
	get_tree().paused = true
	page = "pause"
	clear_ui()
	panel(Rect2(0, 0, 640, 360), Color(0.025, 0.035, 0.07, 0.88))
	label_at("BİR NEFES", Vector2(215, 52), 30)
	button("DEVAM ET", Vector2(210, 114), show_hud).grab_focus()
	button("AYARLAR", Vector2(210, 153), func(): show_settings("pause"))
	button("KONTROLLER", Vector2(210, 192), show_controls)
	button("ANA MENÜ", Vector2(210, 231), show_menu)
	label_at("Kayıt, oda tamamlanınca yazılır.", Vector2(210, 280), 11, MUTE)

func play_story_once(key: String, done: Callable) -> void:
	if skip_stories or seen_stories.has(key) or not stories.has(key): return
	seen_stories[key] = true
	play_story(key, done)

func play_story(key: String, done: Callable) -> void:
	dialogue_lines = stories.get(key, []).duplicate(true)
	dialogue_index = 0
	dialogue_done = done
	if dialogue_lines.is_empty(): done.call(); return
	reset_time()
	get_tree().paused = true
	page = "dialogue"
	draw_dialogue()

func draw_dialogue() -> void:
	clear_ui()
	panel(Rect2(0, 0, 640, 360), Color(0.02, 0.03, 0.06, 0.8))
	label_at("A S T E R R A   /   %02d" % (dialogue_index + 1), Vector2(46, 48), 11, MUTE)
	var line: Dictionary = dialogue_lines[dialogue_index]
	label_at(str(line.get("speaker", "")), Vector2(46, 105), 24, TEAL)
	var body := label_at(str(line.get("text", "")), Vector2(46, 153), 15, PALE, 548)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button("DEVAM  →", Vector2(46, 277), next_dialogue, 220).grab_focus()
	label_at("Konuşmaları kendi hızında ilerlet.", Vector2(46, 325), 10, MUTE)

func next_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		var callback := dialogue_done
		callback.call()
	else: draw_dialogue()

func show_credits() -> void:
	page = "credits"
	clear_ui()
	panel(Rect2(0, 0, 640, 360), INK)
	label_at("TORIMON", Vector2(64, 53), 32, TEAL)
	label_at("PRISMBOUND — özgün oyun dünyası\n\nGodot Engine / MIT lisansı (godotengine.org/license)\nKodla çizilen geçici piksel görseller\nÖzgün algoritmik geçici müzik ve ses tasarımı\nTürkçe hikâye ve arayüz\n\nÜçüncü taraf oyunlardan varlık alınmamıştır.\nTam sanat, müzik ve insan oynanış testleri sürmektedir.", Vector2(64, 108), 14)
	button("GERİ", Vector2(64, 292), show_menu)

func show_settings(back: String) -> void:
	settings_return = back
	page = "settings"
	clear_ui()
	panel(Rect2(0, 0, 640, 360), INK)
	label_at("AYARLAR", Vector2(26, 15), 24, TEAL)
	var scroll := ScrollContainer.new()
	scroll.position = Vector2(26, 52); scroll.size = Vector2(590, 248)
	ui.add_child(scroll)
	var box := VBoxContainer.new(); box.custom_minimum_size.x = 560
	box.add_theme_constant_override("separation", 10); scroll.add_child(box)
	for entry in [["master", "Ana ses"], ["music", "Müzik"], ["sfx", "Efekt sesi"], ["effects", "Görsel efekt yoğunluğu"]]:
		var row := HBoxContainer.new(); box.add_child(row)
		var title := Label.new(); title.text = entry[1]; title.custom_minimum_size.x = 200; row.add_child(title)
		var slider := HSlider.new(); slider.min_value = 0; slider.max_value = 1; slider.step = 0.05; slider.value = settings[entry[0]]; slider.custom_minimum_size.x = 300; row.add_child(slider)
		slider.value_changed.connect(func(value: float): settings[entry[0]] = value; audio.apply(settings); apply_player_settings(); Save.save_settings(settings))
	for entry in [["fullscreen", "Tam ekran"], ["vsync", "Dikey senkronizasyon"], ["snap", "8 yönlü kalkan nişanı"]]:
		var check := CheckButton.new(); check.text = entry[1]; check.button_pressed = settings[entry[0]]; box.add_child(check)
		check.toggled.connect(func(value: bool): settings[entry[0]] = value; apply_display(); apply_player_settings(); Save.save_settings(settings))
	var resolution := OptionButton.new()
	for scale in [1, 2, 3]: resolution.add_item("Pencere: %d × %d" % [640 * scale, 360 * scale])
	resolution.selected = int(settings.resolution) - 1; box.add_child(resolution)
	resolution.item_selected.connect(func(index: int): settings.resolution = index + 1; apply_display(); Save.save_settings(settings))
	var language := Label.new(); language.text = "Dil: Türkçe  /  İngilizce çeviri henüz hazır değil"; box.add_child(language)
	var info := Label.new(); info.text = "Ekran sarsıntısı kullanılmıyor. Metinler elle ilerler."; box.add_child(info)
	button("GERİ", Vector2(26, 314), func():
		if settings_return == "pause": show_pause()
		else: show_menu(), 180).grab_focus()
	button("TUŞ ATAMALARI", Vector2(220, 314), show_controls, 230)

func show_controls() -> void:
	page = "controls"
	clear_ui()
	panel(Rect2(0, 0, 640, 360), INK)
	label_at("KONTROLLER", Vector2(24, 12), 23, TEAL)
	var index := 0
	for action in ACTION_LABELS:
		var col := index / 5
		var row := index % 5
		var events := InputMap.action_get_events(action)
		var event_text := events[0].as_text().replace(" (Physical)", "") if not events.is_empty() else "—"
		var x := 24 + col * 310
		label_at(ACTION_LABELS[action], Vector2(x, 52 + row * 38), 11, MUTE, 150)
		button(event_text, Vector2(x + 147, 46 + row * 38), func():
			remap_action = action
			label_at("Yeni tuşa veya fare düğmesine bas. Esc: iptal", Vector2(24, 283), 12, TEAL), 135)
		index += 1
	button("GERİ", Vector2(24, 318), func():
		if is_instance_valid(world): show_pause()
		else: show_settings("menu"), 160)
	button("VARSAYILANLAR", Vector2(200, 318), func(): settings.bindings = {}; setup_input(); Save.save_settings(settings); show_controls(), 180)
	label_at("Gamepad: sol çubuk hareket / sağ çubuk nişan / LT yavaşlat", Vector2(24, 296), 10, MUTE)

func _input(event: InputEvent) -> void:
	if not remap_action.is_empty() and event.is_pressed():
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			remap_action = ""; show_controls(); get_viewport().set_input_as_handled(); return
		if event is InputEventKey or event is InputEventMouseButton:
			var binding := {"type": "key" if event is InputEventKey else "mouse", "code": event.physical_keycode if event is InputEventKey else event.button_index}
			settings.bindings[remap_action] = binding
			Save.save_settings(settings); setup_input(); show_controls(); get_viewport().set_input_as_handled(); return
	if page == "death" and death_elapsed() >= RESTART_DELAY:
		if event.is_action_pressed("restart") or (event is InputEventMouseButton and event.pressed):
			restart_room(); get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("pause") and is_instance_valid(world):
		if page == "game": show_pause()
		elif page == "pause": show_hud()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and page == "game" and is_instance_valid(world) and not world.transitioning:
		restart_room(); get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	clock_time += delta
	if page == "death" and death_elapsed() >= AUTO_RESTART:
		restart_room()
	if is_instance_valid(world): hook_player()
	if is_instance_valid(toast_label) and Time.get_ticks_msec() > toast_until_ms:
		toast_label.queue_free(); toast_label = null
	if page == "game" and is_instance_valid(world) and is_instance_valid(world.room) and is_instance_valid(time_label):
		time_label.text = "%.2f" % world.room.elapsed
		death_label.text = "Ölüm: %d" % int(progress.get("total_deaths", 0))
		meter_bar.value = world.time_control.meter
		objective_label.text = world.objective
		objective_label.visible = world.hint_timer <= 0
		var b: Node = world.boss
		var boss_alive: bool = is_instance_valid(b) and b.hits_left > 0
		boss_bar.visible = boss_alive
		boss_name.visible = boss_alive
		if boss_alive:
			boss_bar.max_value = PrismEnemy.BOSS_HITS[b.region]; boss_bar.value = b.hits_left; boss_name.text = b.display_name
		audio.set_region(world.chapter, boss_alive)
	queue_redraw()

func _draw() -> void:
	if is_instance_valid(world): return
	draw_rect(Rect2(0, 0, 640, 360), Color("080e1b"))
	for i in 40:
		var x := fmod(i * 91.7, 640)
		var y := fmod(i * 57.3 + clock_time * (2 + i % 3), 360)
		draw_rect(Rect2(x, y, 1, 1), Color(0.45, 0.72, 0.78, 0.2 + 0.2 * sin(clock_time + i)))
	for i in 7:
		var col := Color.from_hsv(float(i) / 7.0, 0.5, 0.7, 0.07)
		draw_line(Vector2(459, 159), Vector2(640, 70 + i * 36), col, 12)
	var center := Vector2(460, 170 + sin(clock_time * 0.8) * 6)
	var points := PackedVector2Array([center + Vector2(0, -79), center + Vector2(43, -8), center + Vector2(0, 75), center + Vector2(-43, 8)])
	draw_colored_polygon(points, Color("172d42"))
	draw_colored_polygon(PackedVector2Array([points[0], points[1], center]), Color("6cb6c6"))
	draw_colored_polygon(PackedVector2Array([points[1], points[2], center]), Color("7968a0"))
	draw_colored_polygon(PackedVector2Array([points[2], points[3], center]), Color("344c6d"))
	draw_colored_polygon(PackedVector2Array([points[3], points[0], center]), Color("b1d7d3"))
	for i in 4: draw_line(points[i], points[(i + 1) % 4], TEAL, 1)
	draw_line(center + Vector2(-70, 104), center + Vector2(70, 104), Color("22394b"), 1)
