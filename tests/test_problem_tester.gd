extends GutTest
## The debug problem tester screen: wiring between buttons, problems, and the adaptive engine.

const SCENE: PackedScene = preload("res://scenes/debug/problem_tester.tscn")
const FAST: float = 2.0
const UNKIND_WORDS: Array[String] = ["wrong", "bad", "fail"]

var tester: Control


func before_each() -> void:
	tester = SCENE.instantiate()
	tester.auto_advance = false
	add_child_autofree(tester)
	tester.rng.seed = 7
	tester.select_skill("counting")


func _wrong_choice() -> String:
	for choice: String in tester.problem.choices:
		if choice != tester.problem.answer:
			return choice
	return ""


func test_shows_one_button_per_choice() -> void:
	var labels: Array[String] = []
	for button: Button in tester.choice_buttons():
		labels.append(button.text)
	assert_eq(labels, tester.problem.choices)


func test_correct_answer_is_recorded_and_locks_buttons() -> void:
	tester.answer(tester.problem.answer, FAST)
	assert_true(tester.solved)
	assert_eq(tester.engine.window_count("counting"), 1)
	assert_eq(tester.engine.window_accuracy("counting"), 1.0)
	for button: Button in tester.choice_buttons():
		assert_true(button.disabled)


func test_only_first_try_counts() -> void:
	tester.answer(_wrong_choice(), FAST)
	tester.answer(tester.problem.answer, FAST)
	assert_eq(tester.engine.window_count("counting"), 1)
	assert_eq(tester.engine.window_accuracy("counting"), 0.0)


func test_feedback_is_kind() -> void:
	tester.answer(_wrong_choice(), FAST)
	var text: String = tester._feedback.text.to_lower()
	assert_ne(text, "")
	for word: String in UNKIND_WORDS:
		assert_false(text.contains(word), "feedback says '%s'" % word)


func test_hint_appears_after_enough_misses() -> void:
	var needed: int = tester.engine.misses_before_hint("counting")
	var wrong: Array[String] = []
	for choice: String in tester.problem.choices:
		if choice != tester.problem.answer:
			wrong.append(choice)
	assert_gte(wrong.size(), needed, "level 1 counting should have enough wrong choices")
	for i: int in needed - 1:
		tester.answer(wrong[i], FAST)
		assert_eq(tester._hint.text, "", "no hint yet")
	tester.answer(wrong[needed - 1], FAST)
	assert_string_contains(tester._hint.text, "Hint")


func test_ten_fast_correct_answers_level_up() -> void:
	for i: int in 10:
		tester.answer(tester.problem.answer, FAST)
		tester.next_problem()
	assert_eq(tester.engine.level("counting"), 2)
	assert_eq(int(tester._level_picker.value), 2)
	assert_eq(tester.problem.level, 2)


func test_select_skill_switches_problems() -> void:
	tester.select_skill("time_money")
	assert_eq(tester.problem.skill_id, "time_money")
	assert_eq(int(tester._level_picker.max_value), tester.factory.level_count("time_money"))


func test_every_level_has_a_hint_description() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for id: String in tester.factory.skill_ids():
		for level: int in range(1, tester.factory.level_count(id) + 1):
			for i: int in 20:
				var p: MathProblem = tester.factory.generate(id, level, rng)
				var text: String = tester.describe_hint(p)
				assert_ne(text, "(no hint)", "%s level %d" % [id, level])


func test_picture_problems_describe_their_picture() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var cases: Dictionary = {"counting": 1, "time_money": 5, "multiply_divide": 1}
	for id: String in cases:
		for level: int in [cases[id], 1]:
			var p: MathProblem = tester.factory.generate(id, level, rng)
			assert_ne(tester.describe_picture(p), "", "%s level %d needs a picture" % [id, level])


func test_status_updates_after_correct_answer() -> void:
	tester.answer(tester.problem.answer, FAST)
	assert_string_contains(tester._status.text, "Lifetime: 1 answers")


func test_missing_factor_hint_does_not_give_away_the_answer() -> void:
	var p: MathProblem = MathProblem.create("missing_factor", "4 × ? = 28", "", "7", ["7"] as Array[String], {"a": 4, "b": 7, "product": 28})
	p.hint = "groups"
	assert_false(tester.describe_hint(p).contains("7"))
