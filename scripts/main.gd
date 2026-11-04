extends Node2D

const Save = preload("res://scripts/save_manager.gd")
const Audio = preload("res://scripts/audio_manager.gd")
const INK := Color("0c1222")
const PALE := Color("e3e8e9")
const MUTE := Color("869aac")
const TEAL := Color("6de0cc")
var progress: Dictionary = Save.fresh()
var settings: Dictionary = Save.defaults()
var audio: Node
var world: Node2D
var layer: CanvasLayer
var ui: Control
var hud: Control
var health_bar: ProgressBar
var stamina_bar: ProgressBar
var energy_bar: ProgressBar
var status_label: Label
var objective_label: Label
var boss_bar: ProgressBar
var boss_name: Label
var page := "menu"
var clock_time := 0.0
var stories: Dictionary = {}
var dialogue_lines: Array = []
var dialogue_index := 0
var dialogue_done: Callable
var remap_action := ""
var settings_return := "menu"
var notice := ""
var boot_args := OS.get_cmdline_user_args()
const ACTION_LABELS := {"move_left":"Sola hareket", "move_right":"Sağa hareket", "jump":"Zıpla", "dash":"Atıl", "guard":"Savun", "reflect":"Yansıt", "bash":"Kalkan itişi", "mode":"Ayna değiştir", "absorb":"Enerji depola (tut)", "release":"Enerjiyi bırak", "interact":"Etkileşim", "pause":"Duraklat"}

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
		start_world(0)

func setup_input() -> void:
	var defaults := {"move_left": KEY_A, "move_right": KEY_D, "jump": KEY_SPACE, "dash": KEY_SHIFT, "bash": KEY_F, "mode": KEY_Q, "absorb": KEY_R, "release": KEY_C, "interact": KEY_E, "pause": KEY_ESCAPE}
	for action in ACTION_LABELS:
		if not InputMap.has_action(action): InputMap.add_action(action)
		InputMap.action_erase_events(action)
		var event: InputEvent
		if action == "guard" or action == "reflect":
			event = InputEventMouseButton.new()
			event.button_index = MOUSE_BUTTON_RIGHT if action == "guard" else MOUSE_BUTTON_LEFT
		else:
			event = InputEventKey.new()
			event.physical_keycode = defaults[action]
		var binding: Variant = settings.bindings.get(action)
		if binding is Dictionary:
			if binding.get("type") == "key":
				event = InputEventKey.new(); event.physical_keycode = int(binding.get("code", 0))
			elif binding.get("type") == "mouse":
				event = InputEventMouseButton.new(); event.button_index = int(binding.get("code", 1))
		InputMap.action_add_event(action, event)
	var buttons := {"jump": JOY_BUTTON_A, "dash": JOY_BUTTON_B, "mode": JOY_BUTTON_Y, "reflect": JOY_BUTTON_RIGHT_SHOULDER, "interact": JOY_BUTTON_X, "pause": JOY_BUTTON_START, "bash": JOY_BUTTON_LEFT_SHOULDER, "release": JOY_BUTTON_DPAD_UP}
	for action in buttons:
		var button := InputEventJoypadButton.new()
		button.button_index = buttons[action]
		InputMap.action_add_event(action, button)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0], "guard": [JOY_AXIS_TRIGGER_RIGHT, 1.0], "absorb": [JOY_AXIS_TRIGGER_LEFT, 1.0], "aim_left": [JOY_AXIS_RIGHT_X, -1.0], "aim_right": [JOY_AXIS_RIGHT_X, 1.0], "aim_up": [JOY_AXIS_RIGHT_Y, -1.0], "aim_down": [JOY_AXIS_RIGHT_Y, 1.0]}
	for action in axes:
		if not InputMap.has_action(action): InputMap.add_action(action, 0.2)
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

func show_menu() -> void:
	get_tree().paused = false
	if is_instance_valid(world):
		remove_child(world); world.queue_free(); world = null
	page = "menu"
	clear_ui()
	audio.set_region(-1)
	label_at("T O R I M O N   /   BİR YANSIMA HİKÂYESİ", Vector2(42, 36), 10, TEAL)
	label_at("PRISMBOUND", Vector2(39, 61), 42)
	label_at("Her saldırı, yeni bir ihtimal.", Vector2(43, 113), 13, MUTE)
	button("YENİ OYUN", Vector2(44, 161), confirm_new, 210).grab_focus()
	var cont := button("DEVAM ET", Vector2(44, 197), continue_game, 210)
	cont.disabled = Save.load_game().is_empty()
	button("AYARLAR", Vector2(44, 233), func(): show_settings("menu"), 102)
	button("EKİP", Vector2(152, 233), show_credits, 102)
	button("ÇIKIŞ", Vector2(44, 269), func(): get_tree().quit(), 210)
	label_at("GELİŞTİRME SÜRÜMÜ  /  ÖZGÜN GEÇİCİ GÖRSEL VE SESLER", Vector2(43, 328), 9, MUTE)
	if not notice.is_empty(): label_at(notice, Vector2(280, 292), 11, TEAL, 330)

func confirm_new() -> void:
	if Save.load_game().is_empty(): new_game(); return
	clear_ui()
	label_at("Yeni yolculuk", Vector2(64, 76), 28)
	label_at("Mevcut ilerleme yeni oyunun ilk kaydıyla değiştirilecek.", Vector2(64, 130), 14)
	button("YENİ OYUNU BAŞLAT", Vector2(64, 195), new_game)
	button("GERİ", Vector2(64, 233), show_menu)

func new_game() -> void:
	progress = Save.fresh()
	play_story("intro", func(): start_world(0))

func continue_game() -> void:
	progress = Save.load_game()
	if progress.is_empty(): notice = "Geçerli kayıt bulunamadı."; show_menu(); return
	if not str(progress.ending).is_empty():
		show_ending_summary(str(progress.ending))
	else: start_world(int(progress.region))

func start_world(area: int) -> void:
	get_tree().paused = false
	if is_instance_valid(world):
		remove_child(world); world.queue_free()
	progress.region = area
	progress.unlocked = maxi(int(progress.unlocked), area)
	world = load("res://scripts/world.gd").new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.configure(area, progress)
	world.region_completed.connect(on_region_completed)
	world.checkpoint_reached.connect(on_checkpoint)
	world.story_requested.connect(on_story_requested)
	world.player_died.connect(on_player_died)
	add_child(world)
	apply_player_settings()
	if world.player.has_signal("combat_event"): world.player.combat_event.connect(audio.play_effect)
	audio.set_region(area)
	page = "game"
	show_hud()
	save_progress()
	var key := "region_%d" % area
	if not progress.flags.get(key, false):
		progress.flags[key] = true
		play_story(key, func(): show_hud(); save_progress())

func apply_player_settings() -> void:
	if not is_instance_valid(world) or not is_instance_valid(world.player): return
	world.player.set("snap_aim", bool(settings.snap))
	world.player.set("effects_intensity", float(settings.effects))

func save_progress() -> void:
	if is_instance_valid(world) and is_instance_valid(world.player):
		progress.flags["checkpoint_region"] = world.region
		progress.flags["checkpoint_id"] = world.checkpoint_id
	if not Save.save_game(progress): notice = "Kayıt yazılamadı. Klasör erişimini kontrol et."

func on_checkpoint(area: int) -> void:
	progress.region = area
	save_progress()
	audio.play_effect("checkpoint")
	show_altar()

func on_story_requested(key: String) -> void:
	if stories.has(key) and not progress.flags.get(key, false):
		progress.flags[key] = true
		play_story(key, show_hud)

func on_region_completed(area: int) -> void:
	if not progress.cleared.has(area): progress.cleared.append(area)
	progress.flags.erase("checkpoint_region")
	progress.flags.erase("checkpoint_id")
	progress.region = mini(area + 1, 4)
	progress.unlocked = maxi(int(progress.unlocked), int(progress.region))
	Save.save_game(progress)
	audio.play_effect("victory")
	play_story("boss_%d" % area, func():
		if area == 4: show_final_choice()
		else: start_world(area + 1))

func on_player_died() -> void:
	get_tree().paused = true
	page = "death"
	clear_ui()
	panel(Rect2(0, 0, 640, 360), Color(0.025, 0.035, 0.07, 0.90))
	label_at("IŞIK HENÜZ SÖNMEDİ", Vector2(130, 100), 27)
	label_at("Son sunaktan tekrar dene. Saldırının geliş yönüne dikkat et.", Vector2(110, 156), 13, MUTE)
	button("SON SUNAKTAN DEVAM", Vector2(210, 210), func():
		get_tree().paused = false
		world.restart_checkpoint()
		apply_player_settings()
		if not world.player.combat_event.is_connected(audio.play_effect): world.player.combat_event.connect(audio.play_effect)
		show_hud()).grab_focus()
	button("ANA MENÜ", Vector2(210, 249), show_menu)

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
	panel(Rect2(8, 8, 178, 57), Color(0.03, 0.05, 0.09, 0.88))
	label_at("CAN", Vector2(14, 10), 9, MUTE)
	label_at("DİRENÇ", Vector2(14, 26), 9, MUTE)
	label_at("PRİZMA", Vector2(14, 42), 9, MUTE)
	health_bar = bar(Vector2(58, 14), Vector2(119, 7), Color("e87d91"))
	stamina_bar = bar(Vector2(58, 30), Vector2(119, 7), TEAL)
	energy_bar = bar(Vector2(58, 46), Vector2(119, 7), Color("c5a0ee"))
	status_label = label_at("", Vector2(14, 69), 11, PALE)
	objective_label = label_at("", Vector2(14, 327), 11, TEAL, 612)
	boss_name = label_at("", Vector2(216, 9), 11, PALE, 400)
	boss_bar = bar(Vector2(216, 29), Vector2(408, 5), Color("d49ce9"))
	boss_bar.visible = false

func show_pause() -> void:
	get_tree().paused = true
	page = "pause"
	clear_ui()
	panel(Rect2(0, 0, 640, 360), Color(0.025, 0.035, 0.07, 0.88))
	label_at("BİR NEFES", Vector2(215, 52), 30)
	button("DEVAM ET", Vector2(210, 114), show_hud).grab_focus()
	button("AYARLAR", Vector2(210, 153), func(): show_settings("pause"))
	button("KONTROLLER", Vector2(210, 192), show_controls)
	button("KAYDET VE ANA MENÜ", Vector2(210, 231), func(): save_progress(); show_menu())
	label_at("Kayıt, son sunaktan devam eder.", Vector2(210, 280), 11, MUTE)

func show_altar() -> void:
	if page == "altar": return
	get_tree().paused = true
	page = "altar"
	clear_ui()
	panel(Rect2(40, 42, 560, 275))
	label_at("PRİZMA SUNAĞI", Vector2(66, 60), 25, TEAL)
	var cost := 15 + int(progress.upgrades) * 10
	label_at("İlerleme kaydedildi. Can ve direnç yenilendi.", Vector2(66, 105), 13)
	label_at("Gelişim: %d" % [progress.upgrades], Vector2(66, 139), 13, MUTE)
	var buy := button("DİRENÇ +12  /  %d PARÇA" % cost, Vector2(66, 182), func():
		progress.upgrades += 1
		save_progress(); show_altar_refresh(), 300)
	buy.disabled = true
	button("YOLA DEVAM", Vector2(66, 228), show_hud, 300).grab_focus()

func show_altar_refresh() -> void:
	page = "game"
	show_altar()

func show_final_choice() -> void:
	get_tree().paused = true
	page = "choice"
	clear_ui()
	panel(Rect2(0, 0, 640, 360), INK)
	label_at("KİMİN IŞIĞI OLACAKSIN?", Vector2(70, 60), 28)
	label_at("Ruhun gücü artık tamam. Son karar sana ait.", Vector2(70, 117), 14, MUTE)
	button("LANETİ KIR — EVE DÖN", Vector2(70, 179), func(): finish_game("a"), 490).grab_focus()
	button("PRİZMAYLA BİRLEŞ — ASTERRA'DA KAL", Vector2(70, 226), func(): finish_game("b"), 490)

func finish_game(ending: String) -> void:
	progress.ending = ending
	progress.flags["ending_" + ending] = true
	Save.save_game(progress)
	play_story("ending_" + ending, func(): show_ending_summary(ending))

func show_ending_summary(ending: String) -> void:
	get_tree().paused = true
	page = "ending"
	clear_ui()
	panel(Rect2(0, 0, 640, 360), INK)
	label_at("PRISMBOUND", Vector2(146, 61), 40)
	label_at("LANETİ KIRMAK" if ending == "a" else "PRİZMAYLA BİRLEŞMEK", Vector2(146, 127), 21, TEAL)
	label_at("Yolculuğa eşlik ettiğin için teşekkürler.\nTorimon / Geliştirme sürümü", Vector2(146, 176), 13, MUTE)
	button("DİĞER KARARI GÖR", Vector2(146, 238), show_final_choice, 340).grab_focus()
	button("ANA MENÜ", Vector2(146, 278), show_menu, 340)

func play_story(key: String, done: Callable) -> void:
	dialogue_lines = stories.get(key, []).duplicate(true)
	dialogue_index = 0
	dialogue_done = done
	if dialogue_lines.is_empty(): done.call(); return
	get_tree().paused = true
	page = "dialogue"
	draw_dialogue()

func draw_dialogue() -> void:
	clear_ui()
	panel(Rect2(0, 0, 640, 360), Color(0.02, 0.03, 0.06, 0.8))
	label_at("A S T E R R A   /   %02d" % (dialogue_index + 1), Vector2(46, 48), 11, MUTE)
	var line: Dictionary = dialogue_lines[dialogue_index]
	label_at(str(line.speaker), Vector2(46, 105), 24, TEAL)
	var body := label_at(str(line.text), Vector2(46, 153), 15, PALE, 548)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if line.get("choice", "") == "pact":
		button("ANLAŞMAYI KABUL EDİYORUM", Vector2(46, 265), next_dialogue, 310).grab_focus()
		button("BEDELİ NEDİR?", Vector2(367, 265), func():
			dialogue_lines.insert(dialogue_index + 1, {"speaker":"Prizma Ruhu", "text":"Elin başka bir silaha uzandığında lanet seni durduracak. Kalkan hem sınırın hem şansın olacak.\nYabancı: Yaşamak için başka yolum yoksa... kabul ediyorum."})
			next_dialogue(), 226)
	else:
		button("DEVAM  →", Vector2(46, 277), next_dialogue, 220).grab_focus()
	label_at("Konuşmaları kendi hızında ilerlet.", Vector2(46, 325), 10, MUTE)

func next_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		var callback := dialogue_done
		callback.call()
	else: draw_dialogue()

func show_credits() -> void:
	clear_ui()
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
	for entry in [["fullscreen", "Tam ekran"], ["vsync", "Dikey senkronizasyon"], ["assist", "Kolay yansıtma zamanlaması"], ["snap", "8 yönlü kalkan nişanı"]]:
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
		var col := index / 6
		var row := index % 6
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
	label_at("Gamepad: sol çubuk hareket / sağ çubuk nişan", Vector2(24, 296), 10, MUTE)

func _input(event: InputEvent) -> void:
	if not remap_action.is_empty() and event.is_pressed():
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			remap_action = ""; show_controls(); get_viewport().set_input_as_handled(); return
		if event is InputEventKey or event is InputEventMouseButton:
			var binding := {"type": "key" if event is InputEventKey else "mouse", "code": event.physical_keycode if event is InputEventKey else event.button_index}
			settings.bindings[remap_action] = binding
			Save.save_settings(settings); setup_input(); show_controls(); get_viewport().set_input_as_handled(); return
	if event.is_action_pressed("pause") and is_instance_valid(world):
		if page == "game": show_pause()
		elif page == "pause" or page == "altar": show_hud()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	clock_time += delta
	if page == "game" and is_instance_valid(world) and is_instance_valid(world.player) and is_instance_valid(health_bar):
		var p: Node = world.player
		status_label.text = "Prizma Kalkanı"
		objective_label.text = world.objective
		objective_label.visible = world.hint_timer <= 0
		var boss_alive: bool = is_instance_valid(world.boss) and world.boss.hits_left > 0
		boss_bar.visible = boss_alive
		boss_name.visible = boss_alive
		if boss_alive:
			boss_bar.max_value = world.boss.BOSS_HITS[world.boss.region]; boss_bar.value = world.boss.hits_left; boss_name.text = world.boss.display_name
		audio.set_region(world.region, boss_alive and p.position.x > 2400)
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



