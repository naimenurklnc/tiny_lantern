extends Area2D
## Karanlık yaratık (Shadow Wisp): Oyuncuya doğru süzülür, temas ederse yakıt azaltır. Fener Parlaması ile yok edilir!

@export var fuel_penalty: float = 30.0
@export var chase_speed: float = 24.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _scroll_speed: float = 70.0
var _player_ref: Node2D = null
var _banished: bool = false


func setup(pos: Vector2, speed: float, player: Node2D) -> void:
	position = pos
	_scroll_speed = speed
	_player_ref = player


func _ready() -> void:
	add_to_group("shadow_wisps")
	area_entered.connect(_on_area_entered)
	if sprite != null:
		sprite.play("float")


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	position.y += _scroll_speed * 0.92 * delta
	if is_instance_valid(_player_ref):
		var dir_x := signf(_player_ref.global_position.x - global_position.x)
		position.x += dir_x * chase_speed * delta

	if position.y > 355.0:
		queue_free()


func banish() -> void:
	if _banished:
		return
	_banished = true
	AudioManager.play_sfx("banish", 0.08)
	GameManager.add_score(60, true)
	queue_free()


func _on_area_entered(other: Area2D) -> void:
	if _banished:
		return
	if other.is_in_group("player") and other.has_method("take_damage"):
		other.take_damage(fuel_penalty)
		queue_free()
