extends GutTest

const SEED: int = 12345
const SAMPLES: int = 200

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = SEED


func test_numeric_contains_answer_unique_and_in_range() -> void:
	for i: int in SAMPLES:
		var answer: int = rng.randi_range(0, 20)
		var values: Array[int] = ChoiceBuilder.numeric(answer, 4, 0, 23, rng)
		assert_eq(values.size(), 4)
		assert_has(values, answer)
		for v: int in values:
			assert_between(v, 0, 23)
			assert_eq(values.count(v), 1, "choices must be unique")


func test_numeric_prefers_candidates() -> void:
	var candidates: Array[int] = [50, 60]
	var values: Array[int] = ChoiceBuilder.numeric(5, 3, 0, 100, rng, 1, candidates)
	assert_has(values, 50)
	assert_has(values, 60)


func test_numeric_skips_out_of_range_candidates() -> void:
	var candidates: Array[int] = [-4, 999]
	var values: Array[int] = ChoiceBuilder.numeric(1, 3, 0, 9, rng, 2, candidates)
	assert_does_not_have(values, -4)
	assert_does_not_have(values, 999)
	assert_eq(values.size(), 3)


func test_numeric_with_tiny_range_returns_what_fits() -> void:
	var values: Array[int] = ChoiceBuilder.numeric(1, 4, 0, 1, rng)
	assert_eq(values.size(), 2)
	assert_has(values, 0)
	assert_has(values, 1)


func test_from_strings_dedupes_and_limits() -> void:
	var candidates: Array[String] = ["b", "b", "", "c", "a"]
	var values: Array[String] = ChoiceBuilder.from_strings("a", candidates, 3, rng)
	assert_eq(values.size(), 3)
	assert_has(values, "a")
	assert_has(values, "b")
	assert_has(values, "c")


func test_same_seed_same_shuffle() -> void:
	var first: Array = [1, 2, 3, 4, 5, 6]
	var second: Array = [1, 2, 3, 4, 5, 6]
	var rng_a: RandomNumberGenerator = RandomNumberGenerator.new()
	var rng_b: RandomNumberGenerator = RandomNumberGenerator.new()
	rng_a.seed = 7
	rng_b.seed = 7
	ChoiceBuilder.shuffle(first, rng_a)
	ChoiceBuilder.shuffle(second, rng_b)
	assert_eq(first, second)


func test_to_strings_adds_suffix() -> void:
	var values: Array[int] = [5, 25]
	assert_eq(ChoiceBuilder.to_strings(values, "¢"), ["5¢", "25¢"] as Array[String])
