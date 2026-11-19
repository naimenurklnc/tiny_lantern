extends Node2D
## Bölümlere göre taş, örümcek, ağaç, kapasite meyvesi, mantar, ışık parçası ve 5. Bölüm Boss'unu üretir.

@export var obstacle_scene: PackedScene
@export var tree_scene: PackedScene
@export var spider_scene: PackedScene
@export var collectible_scene: PackedScene
@export var capacity_fruit_scene: PackedScene
@export var mushroom_scene: PackedScene
@export var shadow_wisp_scene: PackedScene
@export var shadow_boss_scene: PackedScene
@export var player_node: Node2D

var _spawn_timer: float = 0.6
var _wisp_timer: float = 0.35
var _fruit_timer: float = 4.0
var _mushroom_pending: bool = false
var _mushroom_delay: float = 2.0
var _boss_spawned: bool = false
var _boss_delay: float = 2.2


func _ready() -> void:
	GameManager.stage_changed.connect(_on_stage_changed)


func reset_spawner() -> void:
	for child in get_children():
		child.queue_free()
	_spawn_timer = 0.65
	_wisp_timer = 0.30
	_fruit_timer = 3.2
	_mushroom_pending = true
	_mushroom_delay = 3.0
	_boss_spawned = false
	_boss_delay = 2.2


func _on_stage_changed(new_stage: int, _stage_name: String) -> void:
	_mushroom_pending = true
	_mushroom_delay = 2.2
	if new_stage == 3:
		_fruit_timer = 1.6
	elif new_stage == 5:
		_boss_delay = 2.2


func _process(delta: float) -> void:
	if GameManager.current_state != GameManager.State.PLAYING:
		return

	var elapsed := GameManager.elapsed_time
	var speed := DifficultyManager.get_scroll_speed(elapsed)
	var st := GameManager.stage

	# Her bölümde 1 rastgele mistik mantar
	if _mushroom_pending:
		_mushroom_delay -= delta
		if _mushroom_delay <= 0.0:
			_mushroom_pending = false
			_spawn_mushroom(speed)

	# 5. Bölümde Boss başlat
	if st == 5 and not _boss_spawned:
		_boss_delay -= delta
		if _boss_delay <= 0.0:
			_boss_spawned = true
			_spawn_boss()

	# Engeller (Boss aktifken Boss kendi saldırılarını üretir)
	if not GameManager.boss_active:
		_spawn_timer -= delta
		if _spawn_timer <= 0.0:
			_spawn_timer = DifficultyManager.get_spawn_interval(elapsed)
			_spawn_stage_hazard(st, elapsed, speed)

	# 3. Bölümde Kapasite Meyvesi
	if st == 3:
		_fruit_timer -= delta
		if _fruit_timer <= 0.0:
			_fruit_timer = randf_range(3.6, 5.2)
			_spawn_capacity_fruit(speed)

	# 4. Bölüm (Yıldızsız Geçit) hariç ışık parçaları; 5. Bölümde bolca ışık!
	if st != 4:
		_wisp_timer -= delta
		if _wisp_timer <= 0.0:
			_wisp_timer = randf_range(0.55, 0.88) if st == 5 else randf_range(0.70, 1.15)
			_spawn_collectible(speed)


func _spawn_stage_hazard(st: int, elapsed: float, speed: float) -> void:
	var x_pos := randf_range(22.0, 158.0)
	var spawn_pos := Vector2(x_pos, -24.0)

	match st:
		1:  # Bölüm 1: Taşlar
			_spawn_stone(spawn_pos, speed, elapsed)
		2:  # Bölüm 2: Örümcekler + Taşlar
			if randf() < 0.58 and spider_scene != null:
				var sp := spider_scene.instantiate()
				add_child(sp)
				sp.setup(spawn_pos, speed)
			else:
				_spawn_stone(spawn_pos, speed, elapsed)
		3:  # Bölüm 3: Ağaçlar + Taşlar
			if randf() < 0.65 and tree_scene != null:
				var tr := tree_scene.instantiate()
				add_child(tr)
				tr.setup(spawn_pos, speed, 0.0)
			else:
				_spawn_stone(spawn_pos, speed, elapsed)
		4:  # Bölüm 4: Yıldızsız Geçit (Taşlar, Örümcekler, Gölge Ruhları)
			var r := randf()
			if r < 0.35 and shadow_wisp_scene != null:
				var w := shadow_wisp_scene.instantiate()
				add_child(w)
				w.setup(spawn_pos, speed, player_node)
			elif r < 0.65 and spider_scene != null:
				var sp := spider_scene.instantiate()
				add_child(sp)
				sp.setup(spawn_pos, speed)
			else:
				_spawn_stone(spawn_pos, speed, elapsed)
		_:  # Bölüm 5 Boss öncesi geçiş
			if randf() < DifficultyManager.get_shadow_wisp_chance(elapsed) and shadow_wisp_scene != null:
				var w := shadow_wisp_scene.instantiate()
				add_child(w)
				w.setup(spawn_pos, speed, player_node)
			else:
				_spawn_stone(spawn_pos, speed, elapsed)


func _spawn_stone(spawn_pos: Vector2, speed: float, elapsed: float) -> void:
	if obstacle_scene == null:
		return
	var obs := obstacle_scene.instantiate()
	add_child(obs)
	var drift := 0.0
	if elapsed > 20.0 and randf() < 0.3:
		drift = randf_range(16.0, 30.0) * (-1.0 if randf() < 0.5 else 1.0)
	obs.setup(spawn_pos, speed, drift)


func _spawn_collectible(speed: float) -> void:
	if collectible_scene == null:
		return
	var col := collectible_scene.instantiate()
	add_child(col)
	var x_pos := _find_safe_x(34.0)
	var is_star := randf() < DifficultyManager.get_star_shard_chance()
	col.setup(Vector2(x_pos, -18.0), speed * 0.92, is_star)


func _spawn_capacity_fruit(speed: float) -> void:
	if capacity_fruit_scene == null:
		return
	var fruit := capacity_fruit_scene.instantiate()
	add_child(fruit)
	fruit.setup(Vector2(_find_safe_x(34.0), -18.0), speed)


func _spawn_mushroom(speed: float) -> void:
	if mushroom_scene == null:
		return
	var mush := mushroom_scene.instantiate()
	add_child(mush)
	mush.setup(Vector2(_find_safe_x(34.0), -18.0), speed)


func _spawn_boss() -> void:
	if shadow_boss_scene == null:
		return
	var boss := shadow_boss_scene.instantiate()
	add_child(boss)
	if boss.has_method("setup"):
		boss.setup(player_node)


func _find_safe_x(min_dist: float) -> float:
	# Kayalara ve ağaçlara çok yakın ışık doğmasını önler
	var best_x := randf_range(20.0, 160.0)
	var best_min_d := -1.0
	for _attempt in range(8):
		var cand := randf_range(20.0, 160.0)
		var closest := 999.0
		for child in get_children():
			if child is Area2D and child.position.y < 95.0 and child.collision_layer & 10 != 0:
				closest = minf(closest, absf(child.position.x - cand))
		if closest >= min_dist:
			return cand
		if closest > best_min_d:
			best_min_d = closest
			best_x = cand
	return best_x


func banish_in_radius(origin: Vector2, radius: float) -> void:
	for wisp in get_tree().get_nodes_in_group("shadow_wisps"):
		if is_instance_valid(wisp) and wisp.global_position.distance_to(origin) <= radius:
			if wisp.has_method("banish"):
				wisp.banish()
