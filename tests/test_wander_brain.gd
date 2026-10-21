extends GutTest


func _brain(radius: float) -> WanderBrain:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	return WanderBrain.new(Vector2(100, 100), radius, rng)


func test_targets_stay_near_home_and_on_open_ground() -> void:
	var brain: WanderBrain = _brain(64.0)
	var right_half_only: Callable = func(p: Vector2) -> bool: return p.x >= 100.0
	for i: int in 200:
		var target: Vector2 = brain.pick_target(right_half_only)
		assert_lte(target.distance_to(brain.home), 64.0 + 0.001)
		assert_gte(target.x, 100.0)


func test_goes_home_when_nowhere_is_open() -> void:
	var brain: WanderBrain = _brain(64.0)
	assert_eq(brain.pick_target(func(_p: Vector2) -> bool: return false), Vector2(100, 100))
