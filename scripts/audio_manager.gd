extends Node
class_name PrismAudio

var music_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var music_gain := 0.5
var sfx_gain := 0.75
var current_track := -99
var samples: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player = AudioStreamPlayer.new()
	add_child(music_player)
	for i in 8:
		var voice := AudioStreamPlayer.new()
		add_child(voice)
		voices.append(voice)

func apply(settings: Dictionary) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(0.0001, settings.master)))
	music_gain = settings.music
	sfx_gain = settings.sfx
	music_player.volume_db = linear_to_db(maxf(0.0001, music_gain * 0.45))

func play_effect(event: String, _position: Vector2 = Vector2.ZERO) -> void:
	var pitch := 440.0
	var length := 0.13
	match event:
		"reflect": pitch = 783.99; length = 0.2
		"throw": pitch = 523.25; length = 0.16
		"catch": pitch = 880.0; length = 0.12
		"death": pitch = 92.5; length = 0.4
		"jump": pitch = 330.0
		"dash": pitch = 180.0
		"checkpoint", "victory": pitch = 659.25; length = 0.45
		"step", "footstep": pitch = 70.0; length = 0.045
	if not samples.has(event):
		samples[event] = tone(pitch, length)
	for voice in voices:
		if not voice.playing:
			voice.stream = samples[event]
			voice.volume_db = linear_to_db(maxf(0.0001, sfx_gain * 0.5))
			voice.play()
			return

func tone(freq: float, duration: float) -> AudioStreamWAV:
	var rate := 22050
	var count := int(rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	for i in count:
		var t := float(i) / rate
		var env := minf(t * 100.0, 1.0) * pow(1.0 - float(i) / count, 2)
		var wave := sin(TAU * freq * t) * 0.7 + sin(TAU * freq * 2.01 * t) * 0.2
		pcm.encode_s16(i * 2, int(wave * env * 18000.0))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = pcm
	return stream

func set_region(region: int, boss_music: bool = false) -> void:
	var track := region + (10 if boss_music else 0)
	if track == current_track:
		return
	current_track = track
	var key := "track_%d" % track
	if not samples.has(key):
		samples[key] = compose(region, boss_music)
	music_player.stream = samples[key]
	music_player.play()

func compose(region: int, boss_music: bool) -> AudioStreamWAV:
	# Original algorithmic temporary score; no samples or external copyrights.
	var rate := 22050
	var beat := 0.32 if boss_music else 0.65
	var duration := beat * 32
	var count := int(rate * duration)
	var pcm := PackedByteArray()
	pcm.resize(count * 2)
	var scales := [[0, 7, 10, 14, 12, 7, 3, 5], [0, 3, 7, 14, 10, 7, 5, 3], [0, 1, 7, 3, 0, 10, 7, 5], [0, 6, 7, 10, 3, 6, 2, 0], [0, 7, 12, 14, 10, 7, 5, 12]]
	var notes: Array = scales[posmod(region, 5)]
	var base := 146.832 * pow(2.0, float(posmod(region, 5)) / 12.0)
	for i in count:
		var t := float(i) / rate
		var step := int(t / beat)
		var local := fmod(t, beat)
		var freq := base * pow(2.0, float(notes[step % 8]) / 12.0)
		var envelope := minf(local * 80.0, 1.0) * exp(-local * (6.0 if boss_music else 3.0))
		var value := (sin(TAU * freq * t) + 0.3 * sin(TAU * freq * 2.002 * t)) * envelope * 0.20
		value += sin(TAU * base * 0.5 * t) * 0.10 * (0.7 + 0.3 * sin(t * 0.4))
		if boss_music:
			value += sin(TAU * (48.0 * local + 25.0 * (1.0 - exp(-local * 18.0)))) * exp(-local * 24.0) * 0.3
		var edge := minf(1.0, minf(t * 5.0, (duration - t) * 5.0))
		pcm.encode_s16(i * 2, int(clampf(value * edge, -1, 1) * 24000))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = pcm
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = count
	return stream

func _exit_tree() -> void:
	if is_instance_valid(music_player): music_player.stop()
	for voice in voices:
		if is_instance_valid(voice): voice.stop()
	samples.clear()
