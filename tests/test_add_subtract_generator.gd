extends GutTest

const SAMPLES: int = 300

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 2


func test_add_is_correct_and_within_limits() -> void:
	var params: Dictionary = {"min": 2, "max": 10, "min_part": 1}
	for i: int in SAMPLES:
		var p: MathProblem = AddSubtractGenerator.generate("add", params, 3, rng)
		var a: int = p.data["a"]
		var b: int = p.data["b"]
		assert_eq(p.answer, str(a + b))
		assert_between(a + b, 2, 10)
		assert_gte(a, 1)
		assert_gte(b, 1)
		assert_eq(p.prompt, "%d + %d = ?" % [a, b])


func test_subtract_never_goes_negative() -> void:
	var params: Dictionary = {"min": 30, "max": 100, "min_part": 10}
	for i: int in SAMPLES:
		var p: MathProblem = AddSubtractGenerator.generate("subtract", params, 4, rng)
		var a: int = p.data["a"]
		var b: int = p.data["b"]
		assert_eq(p.answer, str(a - b))
		assert_between(a, 30, 100)
		assert_gte(b, 10)
		assert_gte(a - b, 10)


func test_mixed_makes_both_operations() -> void:
	var params: Dictionary = {"min": 6, "max": 20, "min_part": 1}
	var seen: Dictionary = {}
	for i: int in SAMPLES:
		var p: MathProblem = AddSubtractGenerator.generate("mixed", params, 4, rng)
		seen[p.data["op"]] = true
		var a: int = p.data["a"]
		var b: int = p.data["b"]
		var expected: int = a + b if p.data["op"] == "+" else a - b
		assert_eq(p.answer, str(expected))
	assert_true(seen.has("+") and seen.has("-"), "mixed should include + and -")


func test_missing_addend_fills_the_gap() -> void:
	var params: Dictionary = {"min": 6, "max": 20, "min_part": 1}
	for i: int in SAMPLES:
		var p: MathProblem = AddSubtractGenerator.generate("missing_addend", params, 4, rng)
		var a: int = p.data["a"]
		var total: int = p.data["total"]
		assert_eq(int(p.answer) + a, total)
		assert_eq(p.prompt, "%d + ? = %d" % [a, total])


func test_spoken_text_uses_words_for_operators() -> void:
	var add: MathProblem = AddSubtractGenerator.generate("add", {"max": 10}, 3, rng)
	var sub: MathProblem = AddSubtractGenerator.generate("subtract", {"max": 10}, 3, rng)
	assert_string_contains(add.spoken, "plus")
	assert_string_contains(sub.spoken, "minus")
