extends GutTest

const CONFIG: Dictionary = {"correct_to_catch": 3, "start_gap": 3.0, "close_per_correct": 1.0, "pull_per_miss": 0.5, "max_gap": 4.0}


func test_config_file_has_the_chase_rules() -> void:
	var config: Dictionary = ChaseState.load_config()
	for key: String in ["correct_to_catch", "start_gap", "close_per_correct", "pull_per_miss", "max_gap"]:
		assert_true(config.has(key), "chase.json missing " + key)


func test_three_right_answers_catch() -> void:
	var chase: ChaseState = ChaseState.new(CONFIG)
	chase.answer(true)
	chase.answer(true)
	assert_false(chase.caught)
	assert_almost_eq(chase.gap, 1.0, 0.001)
	assert_almost_eq(chase.progress(), 2.0 / 3.0, 0.001)
	chase.answer(true)
	assert_true(chase.caught)
	assert_eq(chase.gap, 0.0)


func test_misses_let_the_critter_pull_ahead_up_to_a_limit() -> void:
	var chase: ChaseState = ChaseState.new(CONFIG)
	chase.answer(false)
	assert_almost_eq(chase.gap, 3.5, 0.001)
	for i: int in 10:
		chase.answer(false)
	assert_eq(chase.gap, 4.0)
	assert_eq(chase.misses, 11)
	assert_false(chase.caught, "misses never end an explore chase")


func test_misses_do_not_stop_the_catch() -> void:
	var chase: ChaseState = ChaseState.new(CONFIG)
	for i: int in 3:
		chase.answer(false)
		chase.answer(true)
	assert_true(chase.caught)


func test_answers_after_the_catch_are_ignored() -> void:
	var chase: ChaseState = ChaseState.new(CONFIG)
	for i: int in 3:
		chase.answer(true)
	chase.answer(false)
	assert_eq(chase.misses, 0)
	assert_eq(chase.gap, 0.0)
