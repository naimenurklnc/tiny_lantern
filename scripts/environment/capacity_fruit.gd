extends Area2D
## 3. Bölüm ürünü: Fener Meyvesi. Maksimum ışık/can kapasitesini kalıcı olarak artırır!

@export var capacity_bonus: float = 20.0
@export var score_value: int = 50

var _scroll_speed: float = 75.0
var _collected: bool = false
var _bob_phase: float = 0.0
var _base_x: float = 0.0


func setup(pos: Vector2, speed: float) -> void:
	position = pos
	_base_x = pos.x
	_scroll_speed = speed
	_bob_phase = randf() * TAU


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	_bob_phase += delta * 3.5
	position.y += _scroll_speed * 0.9 * delta
	position.x = _base_x + sin(_bob_phase) * 5.0
	if position.y > 350.0:
		queue_free()


func _on_area_entered(other: Area2D) -> void:
	if _collected or not other.is_in_group("player"):
		return
	_collected = true
	GameManager.increase_max_fuel(capacity_bonus)
	GameManager.add_score(score_value, true)
	AudioManager.play_sfx("star_collect", 0.05)
	queue_free()
