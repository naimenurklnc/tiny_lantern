extends Area2D
## Statik veya hafif yatay hareketli engel. Mantar temasına göre buza veya lav kayasına dönüşebilir.

@export var fuel_penalty: float = 24.0
@export var is_rock: bool = true

const TEX_ROCK := preload("res://assets/sprites/environment/thorn_obstacle.png")
const TEX_ICE := preload("res://assets/sprites/environment/ice_obstacle.png")

@onready var sprite: Sprite2D = $Sprite2D

var _scroll_speed: float = 70.0
var _drift_speed: float = 0.0


func setup(pos: Vector2, speed: float, drift: float = 0.0) -> void:
	position = pos
	_scroll_speed = speed
	_drift_speed = drift


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	GameManager.theme_changed.connect(_on_theme_changed)
	_apply_theme(GameManager.current_theme)


func _on_theme_changed(_title: String, _bg: Color, _dark: Color) -> void:
	_apply_theme(GameManager.current_theme)


func _apply_theme(theme_id: int) -> void:
	if sprite == null:
		return
	if theme_id == 1:  # Buz Mantarı: kayalar buza dönsün
		if is_rock:
			sprite.texture = TEX_ICE
			sprite.modulate = Color.WHITE
		else:
			sprite.modulate = Color(0.7, 0.95, 1.2)
	elif theme_id == 0:  # Lav Mantarı
		if is_rock:
			sprite.texture = TEX_ROCK
		sprite.modulate = Color(1.35, 0.65, 0.45)
	else:
		if is_rock:
			sprite.texture = TEX_ROCK
		sprite.modulate = Color.WHITE


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	position.y += _scroll_speed * delta
	if _drift_speed != 0.0:
		position.x += _drift_speed * delta
		if position.x < 18.0 or position.x > 162.0:
			_drift_speed = -_drift_speed

	if position.y > 355.0:
		queue_free()


func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("player") and other.has_method("take_damage"):
		other.take_damage(fuel_penalty)
