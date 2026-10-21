extends GutTest
## The chase screen on its own: problems, answers, catch meter, net toss, finish.

const UNKIND_WORDS: Array[String] = ["wrong", "bad", "fail"]

var screen: ChaseScreen


func before_each() -> void:
	GameState.reset()
	GameState.read_aloud = false
	GameState.rng.seed = 5
	screen = ChaseScreen.new()
	screen.auto_advance = false
	add_child_autofree(screen)
	screen.start(GameState.catalog.get_animal("raccoon"), "counting")


func _wrong_choice() -> String:
	for choice: String in screen.problem.choices:
		if choice != screen.problem.answer:
			return choice
	return ""


func _answer_right() -> void:
	screen.answer(screen.problem.answer, 2.0)
	screen.next_problem()


func test_shows_a_counting_problem_with_a_picture_and_buttons() -> void:
	assert_eq(screen.problem.skill_id, "counting")
	assert_eq(screen.prompt_label.text, screen.problem.prompt)
	assert_eq(ProblemPicture.kind_for(screen.picture.problem), "critters")
	assert_not_null(screen.picture.count_icon, "counts little copies of the chased animal")
	assert_eq(screen.choice_buttons().size(), screen.problem.choices.size())
	for button: Button in screen.choice_buttons():
		assert_gte(button.custom_minimum_size.x, 64.0, "big kid-sized buttons")


func test_right_answer_closes_the_gap_and_fills_the_meter() -> void:
	var gap: float = screen.chase.gap
	screen.answer(screen.problem.answer, 2.0)
	assert_lt(screen.chase.gap, gap)
	assert_eq(screen.chase.correct, 1)
	assert_false(screen.accepting, "waits before the next problem")
	var first_dot: Panel = screen.meter.get_child(0)
	var style: StyleBoxFlat = first_dot.get_theme_stylebox("panel")
	assert_eq(style.bg_color, Color(1, 0.8, 0.2))


func test_miss_pulls_ahead_keeps_the_same_problem_and_is_kind() -> void:
	var prompt: String = screen.problem.prompt
	var wrong: String = _wrong_choice()
	screen.answer(wrong, 2.0)
	assert_gt(screen.chase.gap, 3.0)
	assert_eq(screen.problem.prompt, prompt)
	assert_true(screen.accepting, "can try again")
	for button: Button in screen.choice_buttons():
		assert_eq(button.disabled, button.text == wrong)
	for word: String in UNKIND_WORDS:
		assert_false(screen.feedback.text.to_lower().contains(word))


func test_only_the_first_try_goes_to_the_difficulty_engine() -> void:
	screen.answer(_wrong_choice(), 2.0)
	screen.answer(screen.problem.answer, 2.0)
	assert_eq(GameState.engine.window_count("counting"), 1)
	assert_eq(GameState.engine.window_accuracy("counting"), 0.0)


func test_three_right_answers_toss_the_net_and_finish_caught() -> void:
	watch_signals(screen)
	_answer_right()
	_answer_right()
	screen.answer(screen.problem.answer, 2.0)
	assert_true(screen.chase.caught)
	assert_string_contains(screen.prompt_label.text, "You caught the Raccoon")
	assert_eq(screen.choice_buttons().size(), 0, "question cleared for the celebration")
	assert_true(screen.portrait.visible, "shows the rescued animal's portrait")
	assert_true(screen.net.visible)
	await wait_seconds(ChaseScreen.NET_TOSS_SECONDS + 0.2)
	assert_true(screen.critter_emote.visible, "happy heart after the catch")
	screen.finish()
	assert_signal_emitted_with_parameters(screen, "finished", [true])


func test_track_scrolls_while_running() -> void:
	var before: float = screen._track_rows[0].position.x
	await wait_frames(10)
	assert_ne(screen._track_rows[0].position.x, before)
