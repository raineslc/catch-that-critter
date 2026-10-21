extends GutTest

const FAST: float = 3.0
const SLOW: float = 30.0
const LEVELS: Dictionary = {"counting": 5, "time_money": 6}

var engine: AdaptiveEngine


func before_each() -> void:
	engine = AdaptiveEngine.new(LEVELS)


## Records `correct` right answers then `wrong` misses, returning the last change.
func _answer(skill: String, correct: int, wrong: int = 0, seconds: float = FAST) -> AdaptiveEngine.Change:
	var change: AdaptiveEngine.Change = AdaptiveEngine.Change.NONE
	for i: int in correct:
		change = engine.record_answer(skill, true, seconds)
	for i: int in wrong:
		change = engine.record_answer(skill, false, seconds)
	return change


func test_config_file_loads() -> void:
	var config: Dictionary = AdaptiveEngine.load_config()
	for key: String in ["window_size", "level_up_accuracy", "level_down_accuracy", "fast_seconds", "mastery_sessions"]:
		assert_true(config.has(key), "adaptive.json missing " + key)


func test_level_counts_from_factory_covers_all_skills() -> void:
	var factory: ProblemFactory = ProblemFactory.new()
	var counts: Dictionary = AdaptiveEngine.level_counts_from(factory)
	assert_eq(counts.size(), factory.skill_ids().size())
	assert_eq(int(counts["counting"]), factory.level_count("counting"))


func test_starts_at_level_one() -> void:
	assert_eq(engine.level("counting"), 1)


func test_set_level_clamps() -> void:
	engine.set_level("counting", 99)
	assert_eq(engine.level("counting"), 5)
	engine.set_level("counting", -3)
	assert_eq(engine.level("counting"), 1)


func test_ten_fast_correct_levels_up_and_clears_window() -> void:
	assert_eq(_answer("counting", 9), AdaptiveEngine.Change.NONE, "needs a full window first")
	assert_eq(_answer("counting", 1), AdaptiveEngine.Change.LEVEL_UP)
	assert_eq(engine.level("counting"), 2)
	assert_eq(engine.window_count("counting"), 0)


func test_eight_of_ten_is_enough() -> void:
	_answer("counting", 2, 2)
	# window becomes 2 right, 2 wrong, 6 right = 8/10 on the 10th answer
	assert_eq(_answer("counting", 6), AdaptiveEngine.Change.LEVEL_UP)
	assert_eq(engine.level("counting"), 2)


func test_seven_of_ten_is_not_enough() -> void:
	_answer("counting", 0, 3)
	assert_eq(_answer("counting", 7), AdaptiveEngine.Change.NONE)
	assert_eq(engine.level("counting"), 1)


func test_accurate_but_slow_stays() -> void:
	_answer("counting", 10, 0, SLOW)
	assert_eq(engine.level("counting"), 1)


func test_fast_threshold_can_differ_per_skill() -> void:
	_answer("time_money", 10, 0, 11.0)
	assert_eq(engine.level("time_money"), 2, "11s is fast enough for clocks")
	_answer("counting", 10, 0, 11.0)
	assert_eq(engine.level("counting"), 1, "11s is slow for counting")


func test_no_level_up_past_the_top() -> void:
	engine.set_level("counting", 5)
	assert_eq(_answer("counting", 10), AdaptiveEngine.Change.NONE)
	assert_eq(engine.level("counting"), 5)


func test_struggling_levels_down_and_turns_on_extra_help() -> void:
	engine.set_level("counting", 3)
	assert_eq(engine.misses_before_hint("counting"), 2)
	assert_eq(_answer("counting", 2, 4), AdaptiveEngine.Change.LEVEL_DOWN)
	assert_eq(engine.level("counting"), 2)
	assert_true(engine.needs_extra_help("counting"))
	assert_eq(engine.misses_before_hint("counting"), 1)


func test_half_right_does_not_level_down() -> void:
	engine.set_level("counting", 3)
	assert_eq(_answer("counting", 3, 3), AdaptiveEngine.Change.NONE)
	assert_eq(engine.level("counting"), 3)


func test_struggling_at_level_one_still_gets_extra_help() -> void:
	assert_eq(_answer("counting", 1, 5), AdaptiveEngine.Change.NONE)
	assert_eq(engine.level("counting"), 1)
	assert_true(engine.needs_extra_help("counting"))


func test_extra_help_turns_off_after_recovering() -> void:
	engine.set_level("counting", 3)
	_answer("counting", 0, 6)
	assert_true(engine.needs_extra_help("counting"))
	_answer("counting", 6)
	assert_false(engine.needs_extra_help("counting"))


func test_window_only_keeps_recent_answers() -> void:
	engine.set_level("counting", 3)
	_answer("counting", 0, 3)
	_answer("counting", 7)
	assert_eq(engine.level("counting"), 3, "7/10 so far")
	assert_eq(_answer("counting", 1), AdaptiveEngine.Change.LEVEL_UP, "oldest miss dropped out: 8/10")


func test_three_good_sessions_master_a_level() -> void:
	engine.set_level("counting", 5)
	for session: int in 2:
		_answer("counting", 5)
		assert_eq(engine.end_session(), [] as Array[Dictionary])
	_answer("counting", 5)
	var mastered: Array[Dictionary] = engine.end_session()
	assert_has(mastered, {"skill": "counting", "level": 5})
	assert_true(engine.is_level_mastered("counting", 5))
	assert_true(engine.is_skill_mastered("counting"), "top level mastered = skill mastered")


# Session tests answer slowly so the level stays put between sessions.
func test_good_session_at_harder_level_counts_for_easier_levels() -> void:
	engine.set_level("counting", 4)
	for session: int in 3:
		_answer("counting", 5, 0, SLOW)
		engine.end_session()
	assert_eq(engine.level("counting"), 4)
	assert_true(engine.is_level_mastered("counting", 1))
	assert_true(engine.is_level_mastered("counting", 4))
	assert_false(engine.is_level_mastered("counting", 5))


func test_poor_session_resets_the_streak() -> void:
	engine.set_level("counting", 2)
	_answer("counting", 5, 0, SLOW)
	engine.end_session()
	_answer("counting", 5, 0, SLOW)
	engine.end_session()
	_answer("counting", 2, 3, SLOW)
	engine.end_session()
	_answer("counting", 5, 0, SLOW)
	engine.end_session()
	assert_eq(engine.level("counting"), 2)
	assert_false(engine.is_level_mastered("counting", 2))


func test_short_session_neither_counts_nor_resets() -> void:
	engine.set_level("counting", 2)
	_answer("counting", 5, 0, SLOW)
	engine.end_session()
	_answer("counting", 0, 2, SLOW)
	engine.end_session()
	_answer("counting", 5, 0, SLOW)
	engine.end_session()
	_answer("counting", 5, 0, SLOW)
	engine.end_session()
	assert_true(engine.is_level_mastered("counting", 2))


func test_stats_for_parent_report() -> void:
	_answer("counting", 3, 1, 4.0)
	var stats: Dictionary = engine.stats("counting")
	assert_eq(stats["answers"], 4)
	assert_eq(stats["correct"], 3)
	assert_almost_eq(float(stats["accuracy"]), 0.75, 0.001)
	assert_almost_eq(float(stats["average_seconds"]), 4.0, 0.001)


func test_save_and_load_round_trip_through_json() -> void:
	engine.set_level("counting", 3)
	_answer("counting", 4, 1)
	engine.end_session()
	var json: String = JSON.stringify(engine.to_dict())
	var restored: AdaptiveEngine = AdaptiveEngine.new(LEVELS)
	restored.load_dict(JSON.parse_string(json))
	assert_eq(restored.level("counting"), 3)
	assert_eq(restored.window_count("counting"), 5)
	assert_almost_eq(restored.window_accuracy("counting"), 0.8, 0.001)
	assert_eq(restored.stats("counting"), engine.stats("counting"))
	assert_eq(JSON.stringify(restored.to_dict()), json)


func test_load_ignores_unknown_skills_and_clamps_levels() -> void:
	engine.load_dict({"juggling": {"level": 2}, "counting": {"level": 50}})
	assert_false(engine.has_skill("juggling"))
	assert_eq(engine.level("counting"), 5)


func test_unknown_skill_is_reported() -> void:
	assert_eq(engine.record_answer("juggling", true, 1.0), AdaptiveEngine.Change.NONE)
	assert_push_error_count(1)
