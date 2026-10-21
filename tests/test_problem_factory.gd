extends GutTest
## Checks every level of every skill in data/skills.json makes sound problems.

const SAMPLES_PER_LEVEL: int = 300
const EXPECTED_SKILLS: Array[String] = ["counting", "add_subtract", "place_value", "time_money", "multiply_divide"]
const UNKIND_WORDS: Array[String] = ["wrong", "bad", "fail"]

var factory: ProblemFactory
var rng: RandomNumberGenerator
var standard_pattern: RegEx


func before_all() -> void:
	factory = ProblemFactory.new()
	standard_pattern = RegEx.new()
	standard_pattern.compile("^(K|[1-3])\\.(CC|OA|NBT|MD)\\.\\d+$")


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 2026


func test_all_five_skills_load() -> void:
	for id: String in EXPECTED_SKILLS:
		assert_true(factory.has_skill(id), "missing skill " + id)
		assert_gt(factory.level_count(id), 0, id + " has no levels")


func test_every_level_has_description_standards_and_hint() -> void:
	for id: String in factory.skill_ids():
		for level: int in range(1, factory.level_count(id) + 1):
			var info: Dictionary = factory.level_info(id, level)
			var label: String = "%s level %d" % [id, level]
			assert_ne(str(info.get("description", "")), "", label + " needs a description")
			assert_ne(str(info.get("hint", "")), "", label + " needs a hint")
			var standards: Array = info.get("standards", [])
			assert_gt(standards.size(), 0, label + " needs Common Core standards")
			for code: Variant in standards:
				assert_not_null(standard_pattern.search(str(code)), "%s: bad standard code '%s'" % [label, code])


func test_every_level_generates_sound_problems() -> void:
	var checked: int = 0
	var bad_levels: Array[String] = []
	for id: String in factory.skill_ids():
		for level: int in range(1, factory.level_count(id) + 1):
			var expected_choices: int = int(factory.level_info(id, level)["choices"])
			for i: int in SAMPLES_PER_LEVEL:
				var problem: MathProblem = factory.generate(id, level, rng)
				checked += 1
				if not _check_problem(problem, id, level, expected_choices):
					bad_levels.append("%s level %d" % [id, level])
					break
	assert_eq(bad_levels, [] as Array[String], "levels with bad problems")
	assert_gt(checked, 0)


func test_same_seed_gives_same_problem() -> void:
	for id: String in factory.skill_ids():
		var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
		var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
		rng_a.seed = 99
		rng_b.seed = 99
		var a: MathProblem = factory.generate(id, 1, rng_a)
		var b: MathProblem = factory.generate(id, 1, rng_b)
		assert_eq(a.prompt, b.prompt)
		assert_eq(a.choices, b.choices)


func test_unknown_skill_or_level_returns_null() -> void:
	assert_null(factory.generate("juggling", 1, rng))
	assert_null(factory.generate("counting", 0, rng))
	assert_null(factory.generate("counting", 999, rng))
	assert_push_error_count(3)


## Returns false (after logging what's wrong) so a bad level stops early instead of flooding the log.
func _check_problem(problem: MathProblem, id: String, level: int, expected_choices: int) -> bool:
	var label: String = "%s level %d" % [id, level]
	if problem == null:
		gut.p(label + " returned null")
		return false
	var detail: String = "%s: '%s' -> %s %s" % [label, problem.prompt, problem.answer, problem.choices]
	var problems: Array[String] = []
	if problem.skill_id != id or problem.level != level:
		problems.append("skill/level not set")
	if problem.prompt == "" or problem.spoken == "":
		problems.append("missing prompt or spoken text")
	if problem.choices.size() != expected_choices:
		problems.append("expected %d choices" % expected_choices)
	if not problem.choices.has(problem.answer):
		problems.append("answer not among choices")
	for choice: String in problem.choices:
		if problem.choices.count(choice) != 1:
			problems.append("duplicate choice " + choice)
		if choice.begins_with("-"):
			problems.append("negative choice " + choice)
	if not problem.is_correct(problem.answer):
		problems.append("is_correct(answer) is false")
	for word: String in UNKIND_WORDS:
		if problem.prompt.to_lower().contains(word) or problem.spoken.to_lower().contains(word):
			problems.append("kid text contains '%s'" % word)
	if problem.standards.is_empty():
		problems.append("no standards")
	if problems.is_empty():
		return true
	gut.p(detail + " — " + ", ".join(problems))
	return false
