extends Area2D
## 5. Bölümün sonundaki Gölge Lordu (Boss): Sağ-sol süzülür, gölge ruhu/diken fırlatır, ışık mızraklarıyla vurulur!

signal boss_defeated

@export var max_hp: int = 16
@export var obstacle_scene: PackedScene
@export var shadow_wisp_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D

var hp: int = 16
var _move_dir: float = 1.0
var _attack_timer: float = 1.4
var _hit_flash: float = 0.0
var _player_ref: Node2D = null


func setup(player: Node2D) -> void:
	_player_ref = player


func _ready() -> void:
	add_to_group("boss")
	hp = max_hp
	position = Vector2(90.0, -30.0)
	GameManager.boss_active = true
	GameManager.boss_started.emit(max_hp)
	GameManager.boss_hp_changed.emit(hp, max_hp)


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	if position.y < 64.0:
		position.y = minf(64.0, position.y + 42.0 * delta)
	else:
		position.x += _move_dir * 46.0 * delta
		if position.x < 28.0 or position.x > 152.0:
			_move_dir = -_move_dir
			position.x = clampf(position.x, 28.0, 152.0)

	if _hit_flash > 0.0:
		_hit_flash -= delta
		if sprite != null:
			sprite.modulate = Color(2.2, 2.2, 2.2, 1.0) if _hit_flash > 0.0 else Color.WHITE

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = randf_range(0.95, 1.45)
		_spawn_attack()


func _spawn_attack() -> void:
	var parent := get_parent()
	if parent == null:
		return
	if randf() < 0.45 and shadow_wisp_scene != null:
		var wisp := shadow_wisp_scene.instantiate()
		parent.add_child(wisp)
		if wisp.has_method("setup"):
			wisp.setup(position + Vector2(0, 14), 88.0, _player_ref)
	elif obstacle_scene != null:
		var obs := obstacle_scene.instantiate()
		parent.add_child(obs)
		if obs.has_method("setup"):
			obs.setup(position + Vector2(randf_range(-16, 16), 14), 96.0, randf_range(-18, 18))


func take_hit(dmg: int = 1) -> void:
	hp = maxi(0, hp - dmg)
	_hit_flash = 0.12
	AudioManager.play_sfx("boss_hit", 0.06)
	GameManager.add_score(40, true)
	GameManager.boss_hp_changed.emit(hp, max_hp)
	if hp <= 0:
		GameManager.add_score(1000, false)
		boss_defeated.emit()
		GameManager.trigger_game_over(true)
		queue_free()
