extends Node2D
## Oyun dünyasını, kayan arka planı, lav çatlaklarını, hava parçacıklarını (kar/kor) ve kamera sarsıntısını yönetir.

@onready var bg_sprite_1: Sprite2D = $Background1
@onready var bg_sprite_2: Sprite2D = $Background2
@onready var lava_1: Sprite2D = $LavaCracks1
@onready var lava_2: Sprite2D = $LavaCracks2
@onready var weather_particles: CPUParticles2D = $WeatherParticles
@onready var darkness_modulate: CanvasModulate = $DarknessModulate
@onready var camera: Camera2D = $Camera2D
@onready var player: Area2D = $Player
@onready var spawn_manager: Node2D = $SpawnManager

var _shake_amount: float = 0.0


func _ready() -> void:
	if player.has_signal("flare_activated"):
		player.flare_activated.connect(_on_player_flare)
	if player.has_signal("player_hit"):
		player.player_hit.connect(_on_player_hit)
	GameManager.state_changed.connect(_on_state_changed)
	GameManager.stage_changed.connect(_on_stage_changed)
	GameManager.theme_changed.connect(_on_theme_changed)


func _process(delta: float) -> void:
	if _shake_amount > 0.0:
		_shake_amount = maxf(0.0, _shake_amount - delta * 18.0)
		camera.offset = Vector2(
			randf_range(-_shake_amount, _shake_amount),
			randf_range(-_shake_amount, _shake_amount)
		)
	else:
		camera.offset = Vector2.ZERO

	if GameManager.current_state != GameManager.State.PLAYING:
		return

	var speed := DifficultyManager.get_scroll_speed(GameManager.elapsed_time)
	bg_sprite_1.position.y += speed * delta
	bg_sprite_2.position.y += speed * delta

	if bg_sprite_1.position.y >= 480.0:
		bg_sprite_1.position.y = bg_sprite_2.position.y - 320.0
	if bg_sprite_2.position.y >= 480.0:
		bg_sprite_2.position.y = bg_sprite_1.position.y - 320.0

	lava_1.position.y = bg_sprite_1.position.y
	lava_2.position.y = bg_sprite_2.position.y


func _on_player_flare(origin: Vector2, radius: float) -> void:
	_shake_amount = 2.5
	spawn_manager.banish_in_radius(origin, radius)


func _on_player_hit() -> void:
	_shake_amount = 5.0


func _on_state_changed(new_state: GameManager.State) -> void:
	if new_state == GameManager.State.PLAYING and GameManager.elapsed_time < 0.05:
		player.reset_player()
		spawn_manager.reset_spawner()
		_reset_visuals()
	elif new_state == GameManager.State.MENU:
		spawn_manager.reset_spawner()
		player.reset_player()
		_reset_visuals()


func _reset_visuals() -> void:
	bg_sprite_1.modulate = Color.WHITE
	bg_sprite_2.modulate = Color.WHITE
	lava_1.visible = false
	lava_2.visible = false
	weather_particles.emitting = false
	darkness_modulate.color = Color(0.42, 0.46, 0.65, 1.0)


func _on_theme_changed(_title: String, bg_tint: Color, dark_tint: Color) -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(bg_sprite_1, "modulate", bg_tint, 0.8)
	tween.tween_property(bg_sprite_2, "modulate", bg_tint, 0.8)
	tween.tween_property(darkness_modulate, "color", dark_tint, 0.8)

	var t := GameManager.current_theme
	lava_1.visible = (t == 0)
	lava_2.visible = (t == 0)

	weather_particles.emitting = true
	match t:
		0:  # Lav: yükselen kor kıvılcımları
			weather_particles.gravity = Vector2(0, -34)
			weather_particles.color = Color(1.0, 0.55, 0.15, 0.9)
		1:  # Buz: yağan kar taneleri
			weather_particles.gravity = Vector2(0, 26)
			weather_particles.color = Color(0.88, 0.96, 1.0, 0.9)
		2:  # Yeşillik: orman polenleri
			weather_particles.gravity = Vector2(0, 8)
			weather_particles.color = Color(0.55, 1.0, 0.65, 0.8)
		_:  # Ayışığı: yıldız tozları
			weather_particles.gravity = Vector2(0, 5)
			weather_particles.color = Color(0.88, 0.72, 1.0, 0.85)


func _on_stage_changed(new_stage: int, _stage_name: String) -> void:
	if GameManager.current_theme >= 0:
		return
	match new_stage:
		1:
			darkness_modulate.color = Color(0.42, 0.46, 0.65, 1.0)
		2:
			darkness_modulate.color = Color(0.38, 0.42, 0.60, 1.0)
		3:
			darkness_modulate.color = Color(0.34, 0.38, 0.56, 1.0)
		_:
			darkness_modulate.color = Color(0.30, 0.34, 0.50, 1.0)
