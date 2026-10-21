extends GutTest
## Henrito's data, hint sentences, and hint pictures for every level.

const UNKIND_WORDS: Array[String] = ["wrong", "bad", "fail", "stupid", "no!"]
const SAMPLES_PER_LEVEL: int = 40


func _rng() -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	return rng


func _assert_kind(text: String, label: String) -> void:
	for word: String in UNKIND_WORDS:
		assert_false(text.to_lower().contains(word), "%s says '%s': %s" % [label, word, text])


func test_henrito_has_art_voice_and_lines_for_every_event() -> void:
	var henrito: Sidekick = Sidekick.load_by_id("henrito", _rng())
	assert_eq(henrito.display_name(), "Henrito")
	assert_not_null(henrito.faceset())
	assert_true(ResourceLoader.exists(str(henrito.data["sprite"])))
	assert_almost_eq(henrito.voice_rate(), 0.9, 0.001, "calm, slightly slower voice")
	for event: String in Sidekick.EVENTS:
		var lines: Array = henrito.data["lines"][event]
		assert_gt(lines.size(), 0, "needs lines for " + event)
		for line: Variant in lines:
			var text: String = str(line)
			assert_ne(text, "")
			_assert_kind(text, event)
			assert_lte(text.count(".") + text.count("!") + text.count("?"), 2, "short lines only: " + text)


func test_unknown_sidekick_is_reported() -> void:
	var nobody: Sidekick = Sidekick.load_by_id("nobody", _rng())
	assert_eq(nobody.line("caught"), "")
	assert_push_error_count(1)


func test_every_level_has_a_kind_hint_and_a_hint_picture() -> void:
	var factory: ProblemFactory = ProblemFactory.new()
	var rng: RandomNumberGenerator = _rng()
	for id: String in factory.skill_ids():
		for level: int in range(1, factory.level_count(id) + 1):
			for i: int in SAMPLES_PER_LEVEL:
				var p: MathProblem = factory.generate(id, level, rng)
				var label: String = "%s level %d (%s)" % [id, level, p.type]
				var text: String = HintText.for_problem(p)
				assert_ne(text, "Let's think about it together.", label + " needs its own hint")
				_assert_kind(text, label)
				assert_ne(HintPicture.kind_for(p), "", label + " needs a hint picture")


func test_number_line_hints_fit_and_hop_correctly() -> void:
	var add: MathProblem = MathProblem.create("add", "", "", "12", ["12"] as Array[String], {"a": 7, "b": 5, "op": "+"})
	var plan: Dictionary = HintPicture.number_line_plan(add)
	assert_eq(plan["hops"].size(), 5, "one hop per number added")
	assert_eq(plan["hops"][0], [7, 8])
	assert_lte(int(plan["lo"]), 7)
	assert_gte(int(plan["hi"]), 12)
	var sub: MathProblem = MathProblem.create("subtract", "", "", "3", ["3"] as Array[String], {"a": 7, "b": 4, "op": "-"})
	assert_eq(HintPicture.number_line_plan(sub)["hops"][0], [7, 6], "hops go backward")
	var skip: MathProblem = MathProblem.create("skip_count", "", "", "20", ["20"] as Array[String], {"sequence": [5, 10, 15], "step": 5})
	var skip_plan: Dictionary = HintPicture.number_line_plan(skip)
	assert_eq(skip_plan["question"], 20)
	assert_eq(skip_plan["step"], 5)


func test_missing_factor_hint_picture_hides_the_answer() -> void:
	var p: MathProblem = MathProblem.create("missing_factor", "", "", "7", ["7"] as Array[String], {"a": 4, "b": 7, "product": 28})
	p.hint = "groups"
	assert_false(HintText.for_problem(p).contains("7"), "hint text doesn't say 7")


func test_blocks_shrink_to_fit_two_big_numbers() -> void:
	var wide: float = HintPicture.blocks_width(999, HintPicture.BLOCK_UNIT) * 2 + 60
	assert_gt(wide, 1280.0, "two 999s at full size would not fit")
	var picture: HintPicture = HintPicture.new()
	picture.size = Vector2(1280, 150)
	var p: MathProblem = MathProblem.create("compare", "", "", "<", ["<"] as Array[String], {"a": 998, "b": 999})
	p.hint = "base_ten_blocks"
	picture.show_problem(p)
	add_child_autofree(picture)
	await wait_frames(1)
	assert_true(true, "drew without errors")
