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


const RACE_CONFIG: Dictionary = {"correct_to_catch": 3, "start_gap": 3.0, "close_per_correct": 1.0, "pull_per_miss": 0.5,
	"max_gap": 4.0, "race_seconds": 10.0, "sprint_seconds": 5.0, "sprint_time_bonus": 3.0, "sprint_extra_close": 0.5}


func test_explore_has_no_timer() -> void:
	var chase: ChaseState = ChaseState.new(CONFIG)
	assert_false(chase.tick(1000.0))
	assert_false(chase.escaped)


func test_race_timer_runs_out_and_the_critter_escapes() -> void:
	var chase: ChaseState = ChaseState.new(RACE_CONFIG, ChaseState.RACE)
	assert_eq(chase.time_left, 10.0)
	assert_false(chase.tick(9.0))
	assert_true(chase.tick(1.5), "escapes on the tick time runs out")
	assert_true(chase.escaped)
	assert_false(chase.tick(1.0), "only reports the escape once")
	chase.answer(true)
	assert_eq(chase.correct, 0, "answers after escaping are ignored")


func test_fast_right_answer_sprints_in_race_only() -> void:
	var race: ChaseState = ChaseState.new(RACE_CONFIG, ChaseState.RACE)
	race.answer(true, 2.0)
	assert_true(race.last_sprint)
	assert_almost_eq(race.gap, 1.5, 0.001, "closes extra")
	assert_almost_eq(race.time_left, 13.0, 0.001, "bonus seconds")
	race.answer(true, 9.0)
	assert_false(race.last_sprint, "slow answers don't sprint")
	var explore: ChaseState = ChaseState.new(RACE_CONFIG, ChaseState.EXPLORE)
	explore.answer(true, 1.0)
	assert_false(explore.last_sprint)


func test_catching_stops_the_race_clock() -> void:
	var chase: ChaseState = ChaseState.new(RACE_CONFIG, ChaseState.RACE)
	for i: int in 3:
		chase.answer(true, 9.0)
	assert_true(chase.caught)
	assert_false(chase.tick(100.0))
	assert_false(chase.escaped)


func test_restart_starts_fresh() -> void:
	var chase: ChaseState = ChaseState.new(RACE_CONFIG, ChaseState.RACE)
	chase.answer(true, 9.0)
	chase.tick(20.0)
	chase.restart()
	assert_false(chase.escaped)
	assert_eq(chase.correct, 0)
	assert_eq(chase.gap, 3.0)
	assert_eq(chase.time_left, 10.0)


func test_answers_after_the_catch_are_ignored() -> void:
	var chase: ChaseState = ChaseState.new(CONFIG)
	for i: int in 3:
		chase.answer(true)
	chase.answer(false)
	assert_eq(chase.misses, 0)
	assert_eq(chase.gap, 0.0)
