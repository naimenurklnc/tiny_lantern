extends Area2D
## 5. Bölüm Boss savaşında oyuncunun fırlattığı Işık Mızrağı.

const SPEED := 240.0
@export var damage: int = 1


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return
	position.y -= SPEED * delta
	if position.y < -20.0:
		queue_free()


func _on_area_entered(other: Area2D) -> void:
	if other.is_in_group("boss") and other.has_method("take_hit"):
		other.take_hit(damage)
		queue_free()
