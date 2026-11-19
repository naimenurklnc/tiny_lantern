extends Control
## Oyun sonu (Game Over / Zafer) ekranı.

@onready var title_label: Label = $Panel/VBox/Title
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var best_label: Label = $Panel/VBox/BestLabel
@onready var new_best_badge: Label = $Panel/VBox/NewBestLabel
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var menu_button: Button = $Panel/VBox/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart)
	menu_button.pressed.connect(_on_menu)


func show_results(final_score: int, is_new_best: bool, is_victory: bool = false) -> void:
	if is_victory:
		title_label.text = "ZAFER!"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.35))
	else:
		title_label.text = "FENER SÖNDÜ"
		title_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.42))
	score_label.text = "SKOR: %d" % final_score
	best_label.text = "EN İYİ: %d" % int(SaveManager.data.get("best_score", 0))
	new_best_badge.visible = is_new_best


func _on_restart() -> void:
	AudioManager.play_sfx("button", 0.02)
	GameManager.start_game()


func _on_menu() -> void:
	AudioManager.play_sfx("button", 0.02)
	GameManager.return_to_menu()
