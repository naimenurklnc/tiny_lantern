extends Node
## Oyunun genel durumunu, skoru, dinamik fener kapasitesini, komboyu, bölüm ilerlemesini, mantar temalarını ve Boss savaşını yönetir.

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

signal state_changed(new_state: State)
signal score_changed(new_score: int)
signal fuel_changed(new_fuel: float, max_fuel: float)
signal combo_changed(new_combo: int)
signal stage_changed(new_stage: int, stage_name: String)
signal theme_changed(theme_title: String, bg_tint: Color, dark_tint: Color)
signal boss_started(max_hp: int)
signal boss_hp_changed(hp: int, max_hp: int)
signal game_over_triggered(final_score: int, is_new_best: bool, is_victory: bool)

const BASE_MAX_FUEL := 100.0
const FUEL_DRAIN_PER_SEC := 4.4
const COMBO_TIMEOUT := 3.2

const STAGE_NAMES := [
	"Sessiz Orman",
	"Sisli Harabeler",
	"Karanlık Kökler",
	"Yıldızsız Geçit",
	"Gölge Tahtı",
]

var current_state: State = State.MENU
var score: int = 0
var run_wisps: int = 0
var max_fuel: float = BASE_MAX_FUEL
var fuel: float = BASE_MAX_FUEL
var combo: int = 1
var stage: int = 1
var elapsed_time: float = 0.0
var boss_active: bool = false
var slow_timer: float = 0.0
var current_theme: int = -1

var _combo_timer: float = 0.0
var _distance_accum: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if current_state != State.PLAYING:
		return

	elapsed_time += delta
	if slow_timer > 0.0:
		slow_timer = maxf(0.0, slow_timer - delta)

	var pace := 20.0 if stage == 4 else 11.0
	_distance_accum += delta * pace
	if _distance_accum >= 1.0:
		var pts := int(_distance_accum)
		_distance_accum -= pts
		add_score(pts, false)

	var drain_mult := 1.0 + (stage - 1) * 0.08
	if stage == 4:
		drain_mult = 0.65  # Yıldızsız Geçit (~20 sn): depolanan ışıkla geçilebilir
	change_fuel(-FUEL_DRAIN_PER_SEC * drain_mult * delta)

	if _combo_timer > 0.0:
		_combo_timer -= delta
		if _combo_timer <= 0.0 and combo > 1:
			combo = 1
			combo_changed.emit(combo)


func start_game() -> void:
	score = 0
	run_wisps = 0
	max_fuel = BASE_MAX_FUEL
	fuel = BASE_MAX_FUEL
	combo = 1
	stage = 1
	elapsed_time = 0.0
	boss_active = false
	slow_timer = 0.0
	current_theme = -1
	_combo_timer = 0.0
	_distance_accum = 0.0

	get_tree().paused = false
	current_state = State.PLAYING
	state_changed.emit(current_state)
	score_changed.emit(score)
	fuel_changed.emit(fuel, max_fuel)
	combo_changed.emit(combo)
	stage_changed.emit(stage, get_stage_name(stage))


func pause_game() -> void:
	if current_state != State.PLAYING:
		return
	current_state = State.PAUSED
	get_tree().paused = true
	state_changed.emit(current_state)


func resume_game() -> void:
	if current_state != State.PAUSED:
		return
	get_tree().paused = false
	current_state = State.PLAYING
	state_changed.emit(current_state)


func return_to_menu() -> void:
	get_tree().paused = false
	boss_active = false
	current_state = State.MENU
	state_changed.emit(current_state)


func trigger_game_over(is_victory: bool = false) -> void:
	if current_state == State.GAME_OVER:
		return
	current_state = State.GAME_OVER
	boss_active = false
	get_tree().paused = true
	AudioManager.play_sfx("victory" if is_victory else "game_over", 0.0)
	SaveManager.add_wisps(run_wisps)
	var is_new_best := SaveManager.update_best_score(score, stage)
	state_changed.emit(current_state)
	game_over_triggered.emit(score, is_new_best, is_victory)


func add_score(amount: int, apply_combo: bool = true) -> void:
	var final_amount := amount * combo if apply_combo else amount
	score += final_amount
	score_changed.emit(score)

	if boss_active:
		return

	var target_stage := 1
	if score >= 4900:
		target_stage = 5
	elif score >= 4500:
		target_stage = 4
	elif score >= 2500:
		target_stage = 3
	elif score >= 1000:
		target_stage = 2

	if target_stage > stage:
		stage = target_stage
		stage_changed.emit(stage, get_stage_name(stage))


func register_wisp_pickup(base_points: int, fuel_gain: float) -> void:
	run_wisps += 1
	combo = mini(combo + 1, 8)
	_combo_timer = COMBO_TIMEOUT
	combo_changed.emit(combo)
	change_fuel(fuel_gain)
	add_score(base_points, true)


func increase_max_fuel(amount: float) -> void:
	max_fuel = minf(max_fuel + amount, 240.0)
	change_fuel(amount + 15.0)
	fuel_changed.emit(fuel, max_fuel)


func apply_mushroom_theme(theme_id: int) -> void:
	current_theme = theme_id
	AudioManager.play_sfx("mushroom", 0.05)
	match theme_id:
		0:  # Lav Mantarı
			change_fuel(18.0)
			theme_changed.emit("LAV ORMANI!", Color(1.35, 0.72, 0.55, 1.0), Color(0.55, 0.36, 0.34, 1.0))
		1:  # Buz Mantarı
			slow_timer = 6.5
			change_fuel(18.0)
			theme_changed.emit("BUZ ORMANI!", Color(0.75, 1.15, 1.45, 1.0), Color(0.42, 0.54, 0.72, 1.0))
		2:  # Yeşillik Mantarı
			change_fuel(30.0)
			theme_changed.emit("YEŞİLLİK ORMANI!", Color(0.75, 1.32, 0.85, 1.0), Color(0.38, 0.56, 0.44, 1.0))
		_:  # Ayışığı Mantarı
			add_score(120, false)
			change_fuel(18.0)
			theme_changed.emit("AYIŞIĞI ORMANI!", Color(1.05, 0.85, 1.35, 1.0), Color(0.45, 0.40, 0.68, 1.0))


func change_fuel(delta_fuel: float) -> void:
	if current_state != State.PLAYING:
		return
	fuel = clampf(fuel + delta_fuel, 0.0, max_fuel)
	fuel_changed.emit(fuel, max_fuel)
	if fuel <= 0.0:
		trigger_game_over(false)


func get_stage_name(s: int) -> String:
	var idx := clampi(s - 1, 0, STAGE_NAMES.size() - 1)
	return STAGE_NAMES[idx]
