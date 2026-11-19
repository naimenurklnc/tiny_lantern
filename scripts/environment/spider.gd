extends Area2D
## 2. Bölüm düşmanı: Örümcek. Buz Mantarı yendiğinde yuvarlanan Kar Topuna dönüşür!

@export var fuel_penalty: float = 26.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var snowball_sprite: Sprite2D = $SnowballSprite

var _scroll_speed: float = 75.0
var _scuttle_speed: float = 54.0


func setup(pos: Vector2, speed: float) -> void:
	position = pos
	_scroll_speed = speed
	_scuttle_speed = randf_range(44.0, 68.0) * (-1.0 if randf() < 0.5 else 1.0)


func _ready() -> void:
	add_to_group("shadow_wisps")
	area_entered.connect(_on_area_entered)
	GameManager.theme_changed.connect(_on_theme_changed)
	if sprite != null:
		sprite.play("walk")
	_apply_theme(GameManager.current_theme)


func _on_theme_changed(_title: String, _bg: Color, _dark: Color) -> void:
	_apply_theme(GameManager.current_theme)


func _apply_theme(theme_id: int) -> void:
	var is_ice := theme_id == 1
	if sprite != null:
		sprite.visible = not is_ice
	if snowball_sprite != null:
		snowball_sprite.visible = is_ice


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	position.y += _scroll_speed * 0.95 * delta
	position.x += _scuttle_speed * delta
	if position.x < 16.0 or position.x > 164.0:
		_scuttle_speed = -_scuttle_speed
		position.x = clampf(position.x, 16.0, 164.0)

	if snowball_sprite != null and snowball_sprite.visible:
		snowball_sprite.rotation += signf(_scuttle_speed) * delta * 6.0

	if position.y > 355.0:
		queue_free()


func banish() -> void:
	AudioManager.play_sfx("banish", 0.08)
	GameManager.add_score(50, true)
	queue_free()


func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("player") and other.has_method("take_damage"):
		other.take_damage(fuel_penalty)
		queue_free()
