extends Area2D
## Toplanabilir ışık parçaları (Light Wisp & Starlight Shard).

@export var is_star_shard: bool = false
@export var score_value: int = 25
@export var fuel_restore: float = 16.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _scroll_speed: float = 70.0
var _sway_phase: float = 0.0
var _base_x: float = 0.0
var _collected: bool = false


func setup(pos: Vector2, speed: float, star_mode: bool = false) -> void:
	position = pos
	_base_x = pos.x
	_scroll_speed = speed
	_sway_phase = randf() * TAU
	is_star_shard = star_mode
	if is_star_shard:
		score_value = 75
		fuel_restore = 32.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	if sprite != null:
		sprite.play("star" if is_star_shard else "wisp")


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	_sway_phase += delta * 3.2
	position.y += _scroll_speed * delta
	position.x = _base_x + sin(_sway_phase) * 7.0

	if position.y > 350.0:
		queue_free()


func _on_area_entered(other: Area2D) -> void:
	if _collected or not other.is_in_group("player"):
		return
	_collected = true
	GameManager.register_wisp_pickup(score_value, fuel_restore)
	AudioManager.play_sfx("star_collect" if is_star_shard else "collect", 0.08)
	queue_free()
