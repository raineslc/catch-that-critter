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


func _wrong_choices() -> Array[String]:
	var out: Array[String] = []
	for choice: String in screen.problem.choices:
		if choice != screen.problem.answer:
			out.append(choice)
	return out


func _start_race(seconds: float = 30.0) -> void:
	var config: Dictionary = ChaseState.load_config()
	config["race_seconds"] = seconds
	screen.start(GameState.catalog.get_animal("raccoon"), "counting", ChaseState.RACE, config)


func test_henrito_cheers_at_the_start() -> void:
	assert_true(screen.bubble.visible)
	assert_has(screen.sidekick.data["lines"]["chase_start"], screen.bubble_label.text)
	assert_not_null(screen.bubble_face.texture)


func test_hint_after_two_misses_with_picture() -> void:
	var wrong: Array[String] = _wrong_choices()
	screen.answer(wrong[0], 2.0)
	assert_false(screen.hint_shown, "no hint after one miss")
	screen.answer(wrong[1], 2.0)
	assert_true(screen.hint_shown)
	assert_true(screen.bubble.visible)
	assert_eq(screen.bubble_label.text, HintText.for_problem(screen.problem))
	assert_true(screen.hint_picture.visible)
	assert_false(screen.picture.visible, "hint picture replaces the problem picture")
	screen.answer(screen.problem.answer, 2.0)
	screen.next_problem()
	assert_false(screen.hint_picture.visible, "hint clears on the next problem")
	assert_true(screen.picture.visible)


func test_extra_help_hints_after_one_miss() -> void:
	# Struggle enough to turn on extra help (6 first-try misses at level 1).
	for i: int in 6:
		GameState.engine.record_answer("counting", false, 3.0)
	assert_true(GameState.engine.needs_extra_help("counting"))
	screen.next_problem()
	screen.answer(_wrong_choice(), 2.0)
	assert_true(screen.hint_shown)


func test_explore_has_no_timer() -> void:
	assert_false(screen.timer_box.visible)
	await wait_seconds(0.3)
	assert_false(screen.chase.escaped)


func test_race_shows_a_timer_and_the_critter_can_get_away() -> void:
	_start_race(0.5)
	assert_true(screen.timer_box.visible)
	await wait_seconds(0.8)
	assert_true(screen.chase.escaped)
	assert_string_contains(screen.prompt_label.text, "got away")
	assert_has(screen.sidekick.data["lines"]["escaped"], screen.bubble_label.text)
	var labels: Array[String] = []
	for button: Button in screen.choice_buttons():
		labels.append(button.text)
	assert_eq(labels, [ChaseScreen.CHASE_AGAIN, ChaseScreen.BACK_TO_MAP] as Array[String])


func test_chase_again_starts_over() -> void:
	_start_race(0.3)
	await wait_seconds(0.6)
	screen.retry()
	assert_false(screen.chase.escaped)
	assert_eq(screen.chase.correct, 0)
	assert_true(screen.accepting)
	assert_eq(screen.choice_buttons().size(), screen.problem.choices.size())


func test_back_to_map_after_escape_finishes_not_caught() -> void:
	watch_signals(screen)
	_start_race(0.3)
	await wait_seconds(0.6)
	screen.finish()
	assert_signal_emitted_with_parameters(screen, "finished", [false])


func test_fast_answers_sprint_in_race() -> void:
	_start_race(30.0)
	var before: float = screen.chase.time_left
	screen.answer(screen.problem.answer, 1.0)
	assert_true(screen.chase.last_sprint)
	assert_string_contains(screen.feedback.text, "Sprint boost")
	assert_gt(screen.chase.time_left, before)


func test_buttons_answer_when_clicked() -> void:
	var button: Button = null
	for b: Button in screen.choice_buttons():
		if b.text == screen.problem.answer:
			button = b
	button.pressed.emit()
	await wait_frames(2)
	assert_eq(screen.chase.correct, 1, "pressed is handled on the next frame")


func test_track_scrolls_while_running() -> void:
	var before: float = screen._track_rows[0].position.x
	await wait_frames(10)
	assert_ne(screen._track_rows[0].position.x, before)
