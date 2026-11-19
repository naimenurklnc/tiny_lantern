extends Control
## Ana menü ekranı.

signal settings_requested

@onready var best_score_label: Label = $CenterBox/BestScoreLabel
@onready var play_button: Button = $CenterBox/PlayButton
@onready var settings_button: Button = $CenterBox/SettingsButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	refresh_stats()


func refresh_stats() -> void:
	var best := int(SaveManager.data.get("best_score", 0))
	var best_stage := int(SaveManager.data.get("best_stage", 1))
	best_score_label.text = "EN IYI: %d  |  BOLUM %d" % [best, best_stage]


func _on_play_pressed() -> void:
	AudioManager.play_sfx("button", 0.02)
	GameManager.start_game()


func _on_settings_pressed() -> void:
	AudioManager.play_sfx("button", 0.02)
	settings_requested.emit()
