class_name DifficultyManager
extends RefCounted
## Geçen süreye ve Buz Mantarı etkisine göre oyun hızını ve sıklığını dengeli biçimde hesaplar.

static func get_scroll_speed(elapsed: float) -> float:
	var base := minf(68.0 + elapsed * 1.05, 140.0)
	if GameManager.slow_timer > 0.0:
		base *= 0.65
	return base


static func get_spawn_interval(elapsed: float) -> float:
	return maxf(1.12 - elapsed * 0.008, 0.50)


static func get_shadow_wisp_chance(elapsed: float) -> float:
	if elapsed < 10.0:
		return 0.0
	return minf(0.12 + (elapsed - 10.0) * 0.004, 0.34)


static func get_star_shard_chance() -> float:
	return 0.16
