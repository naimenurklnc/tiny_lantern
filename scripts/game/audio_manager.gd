extends Node
## Müzik ve ses efektlerini yönetir; hızlı tekrarlanan seslerin birbirini kesmesini önler.

var _music_player: AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
const SFX_POOL_SIZE := 8

var _sfx_streams: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_player = AudioStreamPlayer.new()
	_music_player.bus = &"Music"
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_sfx_players.append(p)

	_load_streams()
	apply_settings()
	play_music()


func _load_streams() -> void:
	var sfx_paths := {
		"collect": "res://assets/audio/sfx/collect.wav",
		"star_collect": "res://assets/audio/sfx/star_collect.wav",
		"flare": "res://assets/audio/sfx/flare.wav",
		"hurt": "res://assets/audio/sfx/hurt.wav",
		"banish": "res://assets/audio/sfx/banish.wav",
		"button": "res://assets/audio/sfx/button.wav",
		"game_over": "res://assets/audio/sfx/game_over.wav",
		"mushroom": "res://assets/audio/sfx/mushroom.wav",
		"boss_hit": "res://assets/audio/sfx/boss_hit.wav",
		"victory": "res://assets/audio/sfx/victory.wav",
	}
	for key in sfx_paths:
		if ResourceLoader.exists(sfx_paths[key]):
			_sfx_streams[key] = load(sfx_paths[key])

	var music_path := "res://assets/audio/music/night_forest.wav"
	if ResourceLoader.exists(music_path):
		var stream := load(music_path)
		if stream is AudioStreamWAV:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_begin = 0
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
		_music_player.stream = stream


func play_music() -> void:
	if _music_player.stream != null and not _music_player.playing:
		_music_player.play()


func play_sfx(sfx_name: String, pitch_jitter: float = 0.05) -> void:
	if not _sfx_streams.has(sfx_name):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = _sfx_streams[sfx_name]
			p.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
			p.play()
			return
	# Havuz doluysa ilk oynatıcıyı kullan
	_sfx_players[0].stream = _sfx_streams[sfx_name]
	_sfx_players[0].pitch_scale = 1.0
	_sfx_players[0].play()


func apply_settings() -> void:
	var music_vol := float(SaveManager.data.get("music_volume", 0.8))
	var sfx_vol := float(SaveManager.data.get("sfx_volume", 0.9))
	var muted := bool(SaveManager.data.get("muted", false))

	var master_idx := AudioServer.get_bus_index(&"Master")
	var music_idx := AudioServer.get_bus_index(&"Music")
	var sfx_idx := AudioServer.get_bus_index(&"SFX")

	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, muted)
	if music_idx >= 0:
		AudioServer.set_bus_volume_db(music_idx, linear_to_db(maxf(music_vol, 0.0001)))
		AudioServer.set_bus_mute(music_idx, music_vol <= 0.001)
	if sfx_idx >= 0:
		AudioServer.set_bus_volume_db(sfx_idx, linear_to_db(maxf(sfx_vol, 0.0001)))
		AudioServer.set_bus_mute(sfx_idx, sfx_vol <= 0.001)
