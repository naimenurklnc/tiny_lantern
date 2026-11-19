extends Area2D
## Fener taşıyan ana karakter. Dokunmatik sürükleme ve klavye ile hareket eder, Fener Parlaması (Flare) kullanır.

signal flare_activated(origin: Vector2, radius: float)
signal player_hit

const MOVE_SPEED := 125.0
const MIN_X := 14.0
const MAX_X := 166.0
const MIN_Y := 44.0
const MAX_Y := 284.0

const FLARE_COST := 14.0
const FLARE_MIN_FUEL := 18.0
const FLARE_RADIUS := 74.0
const FLARE_COOLDOWN := 1.4
const BOLT_COST := 5.0
const BOLT_COOLDOWN := 0.28

@export var light_bolt_scene: PackedScene

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var lantern_light: PointLight2D = $LanternLight
@onready var flare_particles: CPUParticles2D = $FlareParticles
@onready var walk_particles: CPUParticles2D = $WalkParticles

var _is_dragging: bool = false
var _drag_touch_id: int = -1
var _last_drag_pos: Vector2 = Vector2.ZERO
var _invuln_timer: float = 0.0
var _flare_cooldown_timer: float = 0.0
var _flare_boost: float = 0.0
var _flicker_time: float = 0.0


func _ready() -> void:
	add_to_group("player")
	if sprite != null:
		sprite.play("walk")


func reset_player() -> void:
	position = Vector2(90.0, 232.0)
	_is_dragging = false
	_drag_touch_id = -1
	_invuln_timer = 0.0
	_flare_cooldown_timer = 0.0
	_flare_boost = 0.0
	if sprite != null:
		sprite.modulate = Color.WHITE
		sprite.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	if event is InputEventScreenTouch:
		if event.pressed and _drag_touch_id == -1:
			_is_dragging = true
			_drag_touch_id = event.index
			_last_drag_pos = event.position
		elif not event.pressed and event.index == _drag_touch_id:
			_is_dragging = false
			_drag_touch_id = -1
	elif event is InputEventScreenDrag and event.index == _drag_touch_id:
		var delta_pos: Vector2 = event.position - _last_drag_pos
		_last_drag_pos = event.position
		position += delta_pos * 0.52
		_clamp_position()

	if event.is_action_pressed("lantern_flare"):
		try_flare()


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	_flicker_time += delta

	# Klavye hareketi
	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir != Vector2.ZERO:
		position += input_dir * MOVE_SPEED * delta
		_clamp_position()
		if sprite != null and absf(input_dir.x) > 0.1:
			sprite.flip_h = input_dir.x < 0.0

	# Zamanlayıcılar
	if _invuln_timer > 0.0:
		_invuln_timer -= delta
		if sprite != null:
			sprite.visible = int(_invuln_timer * 14.0) % 2 == 0
		if _invuln_timer <= 0.0 and sprite != null:
			sprite.visible = true

	if _flare_cooldown_timer > 0.0:
		_flare_cooldown_timer -= delta

	if _flare_boost > 0.0:
		_flare_boost = maxf(0.0, _flare_boost - delta * 2.2)

	_update_lantern_light()


func _clamp_position() -> void:
	position.x = clampf(position.x, MIN_X, MAX_X)
	position.y = clampf(position.y, MIN_Y, MAX_Y)


func _update_lantern_light() -> void:
	if lantern_light == null:
		return
	var fuel_ratio := clampf(GameManager.fuel / maxf(GameManager.max_fuel, 1.0), 0.15, 1.0)
	var cap_bonus := (GameManager.max_fuel - GameManager.BASE_MAX_FUEL) * 0.004
	var flicker := 0.05 * sin(_flicker_time * 8.5) + 0.025 * cos(_flicker_time * 13.0)
	lantern_light.texture_scale = lerpf(1.4, 3.2, fuel_ratio) + cap_bonus + _flare_boost + flicker
	lantern_light.energy = lerpf(1.0, 1.75, fuel_ratio) + _flare_boost * 0.6


func try_flare() -> bool:
	if GameManager.current_state != GameManager.State.PLAYING:
		return false

	if GameManager.boss_active:
		if _flare_cooldown_timer > 0.0 or GameManager.fuel <= BOLT_COST + 2.0:
			return false
		_flare_cooldown_timer = BOLT_COOLDOWN
		_flare_boost = 0.65
		GameManager.change_fuel(-BOLT_COST)
		AudioManager.play_sfx("flare", 0.12)
		if light_bolt_scene != null and get_parent() != null:
			var bolt := light_bolt_scene.instantiate()
			bolt.global_position = global_position + Vector2(0.0, -10.0)
			get_parent().add_child(bolt)
		flare_activated.emit(global_position, FLARE_RADIUS * 0.75)
		return true

	if _flare_cooldown_timer > 0.0 or GameManager.fuel <= FLARE_MIN_FUEL:
		return false

	_flare_cooldown_timer = FLARE_COOLDOWN
	_flare_boost = 1.4
	GameManager.change_fuel(-FLARE_COST)
	AudioManager.play_sfx("flare", 0.06)

	if flare_particles != null:
		flare_particles.restart()
		flare_particles.emitting = true

	flare_activated.emit(global_position, FLARE_RADIUS)
	return true


func take_damage(fuel_penalty: float = 24.0) -> void:
	if _invuln_timer > 0.0 or GameManager.current_state != GameManager.State.PLAYING:
		return
	_invuln_timer = 1.1
	AudioManager.play_sfx("hurt", 0.06)
	player_hit.emit()
	GameManager.change_fuel(-fuel_penalty)
