extends Control
## Oyun içi HUD: Skor, Kombo, Dinamik Fener Yakıtı, Bölüm/Tema Bildirimi, Boss Canı ve Parlama/Ateş butonu.

signal flare_pressed

@onready var score_label: Label = $TopBar/ScoreLabel
@onready var combo_label: Label = $TopBar/ComboLabel
@onready var stage_label: Label = $StageLabel
@onready var fuel_text_label: Label = $FuelTextLabel
@onready var fuel_bar: ProgressBar = $FuelBar
@onready var boss_bar: ProgressBar = $BossBar
@onready var banner_label: Label = $BannerLabel
@onready var pause_button: Button = $TopBar/PauseButton
@onready var flare_button: Button = $FlareButton

var _banner_timer: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.pressed.connect(_on_pause_pressed)
	flare_button.pressed.connect(_on_flare_pressed)

	GameManager.score_changed.connect(_on_score_changed)
	GameManager.fuel_changed.connect(_on_fuel_changed)
	GameManager.combo_changed.connect(_on_combo_changed)
	GameManager.stage_changed.connect(_on_stage_changed)
	GameManager.theme_changed.connect(_on_theme_changed)
	GameManager.boss_started.connect(_on_boss_started)
	GameManager.boss_hp_changed.connect(_on_boss_hp_changed)
	GameManager.state_changed.connect(_on_state_changed)


func _process(delta: float) -> void:
	if _banner_timer > 0.0:
		_banner_timer -= delta
		if _banner_timer <= 0.0:
			banner_label.visible = false


func _on_state_changed(st: GameManager.State) -> void:
	if st == GameManager.State.PLAYING and GameManager.elapsed_time < 0.05:
		boss_bar.visible = false
		flare_button.text = "PARLA"


func _on_score_changed(new_score: int) -> void:
	score_label.text = "%d" % new_score


func _on_fuel_changed(new_fuel: float, max_fuel: float) -> void:
	fuel_bar.max_value = max_fuel
	fuel_bar.value = new_fuel
	fuel_text_label.text = "%d / %d" % [int(ceilf(new_fuel)), int(max_fuel)]
	if new_fuel < 25.0:
		fuel_bar.modulate = Color(1.0, 0.42, 0.35)
	else:
		fuel_bar.modulate = Color(1.0, 0.88, 0.45)


func _on_combo_changed(new_combo: int) -> void:
	combo_label.visible = new_combo > 1
	combo_label.text = "x%d" % new_combo


func _on_stage_changed(new_stage: int, stage_name: String) -> void:
	stage_label.text = "BÖLÜM %d: %s" % [new_stage, stage_name.to_upper()]
	if new_stage > 1:
		AudioManager.play_sfx("star_collect", 0.03)
		_show_banner("BÖLÜM GEÇİLDİ!\nBÖLÜM %d: %s" % [new_stage, stage_name.to_upper()], 3.0)


func _on_theme_changed(theme_title: String, _bg: Color, _dark: Color) -> void:
	_show_banner(theme_title)


func _on_boss_started(max_hp: int) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = max_hp
	boss_bar.visible = true
	flare_button.text = "ATEŞ"
	_show_banner("GÖLGE LORDU GELDİ!")


func _on_boss_hp_changed(hp: int, max_hp: int) -> void:
	boss_bar.max_value = max_hp
	boss_bar.value = hp


func _show_banner(msg: String, duration: float = 2.4) -> void:
	banner_label.text = msg
	banner_label.visible = true
	banner_label.modulate = Color(1, 1, 1, 1)
	banner_label.scale = Vector2(0.75, 0.75)
	_banner_timer = duration
	var tw := create_tween()
	tw.tween_property(banner_label, "scale", Vector2(1.06, 1.06), 0.18)
	tw.tween_property(banner_label, "scale", Vector2(1.0, 1.0), 0.12)


func _on_pause_pressed() -> void:
	AudioManager.play_sfx("button", 0.02)
	GameManager.pause_game()


func _on_flare_pressed() -> void:
	flare_pressed.emit()
