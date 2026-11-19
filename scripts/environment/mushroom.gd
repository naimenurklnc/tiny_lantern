extends Area2D
## Her bölümde rastgele çıkan 4 çeşit mistik mantardan biri: Ormanın temasını değiştirir!

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var glow: PointLight2D = $PointLight2D

var theme_id: int = 0
var _scroll_speed: float = 70.0
var _collected: bool = false


func setup(pos: Vector2, speed: float, forced_theme: int = -1) -> void:
	position = pos
	_scroll_speed = speed
	theme_id = forced_theme if forced_theme >= 0 else randi() % 4


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	var anim_names := ["lava", "ice", "emerald", "moonlight"]
	var colors := [
		Color(1.0, 0.45, 0.25),
		Color(0.45, 0.88, 1.0),
		Color(0.45, 1.0, 0.55),
		Color(0.82, 0.55, 1.0),
	]
	if sprite != null:
		sprite.play(anim_names[clampi(theme_id, 0, 3)])
	if glow != null:
		glow.color = colors[clampi(theme_id, 0, 3)]


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	position.y += _scroll_speed * 0.88 * delta
	if position.y > 350.0:
		queue_free()


func _on_area_entered(other: Area2D) -> void:
	if _collected or not other.is_in_group("player"):
		return
	_collected = true
	GameManager.apply_mushroom_theme(theme_id)
	queue_free()
