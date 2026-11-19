extends Node
## Oyuncu ilerlemesini ve ayarlarını JSON olarak user://save_data.json dosyasında saklar.

const SAVE_PATH := "user://save_data.json"

var data: Dictionary = {
	"best_score": 0,
	"best_stage": 1,
	"total_wisps": 0,
	"music_volume": 0.8,
	"sfx_volume": 0.9,
	"muted": false,
}


func _ready() -> void:
	load_data()


func load_data() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		save_data()
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) == TYPE_DICTIONARY:
		for key in data.keys():
			if parsed.has(key):
				data[key] = parsed[key]
	else:
		save_data()


func save_data() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func update_best_score(score: int, stage: int) -> bool:
	var is_new_best := false
	if score > int(data["best_score"]):
		data["best_score"] = score
		is_new_best = true
	if stage > int(data["best_stage"]):
		data["best_stage"] = stage
	save_data()
	return is_new_best


func add_wisps(count: int) -> void:
	data["total_wisps"] = int(data["total_wisps"]) + count
	save_data()


func set_audio_settings(music_vol: float, sfx_vol: float, muted: bool) -> void:
	data["music_volume"] = clampf(music_vol, 0.0, 1.0)
	data["sfx_volume"] = clampf(sfx_vol, 0.0, 1.0)
	data["muted"] = muted
	save_data()
