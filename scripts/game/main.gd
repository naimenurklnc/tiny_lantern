extends Node
## Ana sahne kontrolcüsü: Oyun dünyası ile tüm UI ekranları arasındaki görünürlük ve geçişleri yönetir.

@onready var world: Node2D = $World
@onready var main_menu: Control = $UILayer/MainMenu
@onready var hud: Control = $UILayer/HUD
@onready var pause_menu: Control = $UILayer/PauseMenu
@onready var game_over_screen: Control = $UILayer/GameOver
@onready var settings_menu: Control = $UILayer/SettingsMenu


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	main_menu.settings_requested.connect(_open_settings)
	pause_menu.settings_requested.connect(_open_settings)
	settings_menu.closed.connect(_on_settings_closed)
	hud.flare_pressed.connect(_on_hud_flare_pressed)

	GameManager.state_changed.connect(_on_state_changed)
	GameManager.game_over_triggered.connect(_on_game_over)

	_on_state_changed(GameManager.current_state)


func _on_state_changed(state: GameManager.State) -> void:
	main_menu.visible = state == GameManager.State.MENU
	hud.visible = state == GameManager.State.PLAYING or state == GameManager.State.PAUSED
	pause_menu.visible = state == GameManager.State.PAUSED
	game_over_screen.visible = state == GameManager.State.GAME_OVER
	settings_menu.visible = false

	if state == GameManager.State.MENU:
		main_menu.refresh_stats()


func _on_game_over(final_score: int, is_new_best: bool, is_victory: bool) -> void:
	game_over_screen.show_results(final_score, is_new_best, is_victory)


func _open_settings() -> void:
	settings_menu.sync_from_save()
	settings_menu.visible = true


func _on_settings_closed() -> void:
	settings_menu.visible = false


func _on_hud_flare_pressed() -> void:
	var player := world.get_node_or_null("Player")
	if player != null and player.has_method("try_flare"):
		player.try_flare()
