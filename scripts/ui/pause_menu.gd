extends Control
## Duraklatma menüsü.

signal settings_requested

@onready var resume_button: Button = $Panel/VBox/ResumeButton
@onready var restart_button: Button = $Panel/VBox/RestartButton
@onready var settings_button: Button = $Panel/VBox/SettingsButton
@onready var menu_button: Button = $Panel/VBox/MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(_on_resume)
	restart_button.pressed.connect(_on_restart)
	settings_button.pressed.connect(_on_settings)
	menu_button.pressed.connect(_on_menu)


func _on_resume() -> void:
	AudioManager.play_sfx("button", 0.02)
	GameManager.resume_game()


func _on_restart() -> void:
	AudioManager.play_sfx("button", 0.02)
	GameManager.start_game()


func _on_settings() -> void:
	AudioManager.play_sfx("button", 0.02)
	settings_requested.emit()


func _on_menu() -> void:
	AudioManager.play_sfx("button", 0.02)
	GameManager.return_to_menu()
