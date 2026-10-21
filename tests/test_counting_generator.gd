extends GutTest

const SAMPLES: int = 300

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 1


func test_count_objects_answer_matches_count_and_range() -> void:
	var params: Dictionary = {"min": 3, "max": 7}
	for i: int in SAMPLES:
		var p: MathProblem = CountingGenerator.generate("count_objects", params, 3, rng)
		var count: int = p.data["count"]
		assert_between(count, 3, 7)
		assert_eq(p.answer, str(count))


func test_compare_more_picks_bigger_of_two_different_numbers() -> void:
	var params: Dictionary = {"min": 1, "max": 10}
	for i: int in SAMPLES:
		var p: MathProblem = CountingGenerator.generate("compare_more", params, 2, rng)
		var a: int = p.data["a"]
		var b: int = p.data["b"]
		assert_ne(a, b)
		assert_between(a, 1, 10)
		assert_between(b, 1, 10)
		assert_eq(p.answer, str(maxi(a, b)))
		assert_eq(p.choices.size(), 2)


func test_next_number_is_one_more() -> void:
	var params: Dictionary = {"min": 1, "max": 20}
	for i: int in SAMPLES:
		var p: MathProblem = CountingGenerator.generate("next_number", params, 3, rng)
		var n: int = p.data["n"]
		assert_eq(p.answer, str(n + 1))
		assert_lte(n + 1, 20)


func test_unknown_type_returns_null() -> void:
	assert_null(CountingGenerator.generate("juggle", {}, 3, rng))
	assert_push_error_count(1)
