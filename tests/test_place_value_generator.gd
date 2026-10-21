extends GutTest

const SAMPLES: int = 300

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 3


func test_tens_ones_reads_the_right_digit() -> void:
	for i: int in SAMPLES:
		var p: MathProblem = PlaceValueGenerator.generate("tens_ones", {"min": 10, "max": 99}, 3, rng)
		var n: int = p.data["n"]
		var expected: int = n / 10 if p.data["place"] == "tens" else n % 10
		assert_eq(p.answer, str(expected))
		assert_between(n, 10, 99)


func test_digit_value_has_distinct_digits_and_correct_worth() -> void:
	for i: int in SAMPLES:
		var p: MathProblem = PlaceValueGenerator.generate("digit_value", {}, 4, rng)
		var n: int = p.data["n"]
		var digits: Array[int] = [n / 100, (n / 10) % 10, n % 10]
		assert_between(n, 100, 999)
		assert_eq(digits.count(digits[0]) + digits.count(digits[1]) + digits.count(digits[2]), 3, "digits must differ: %d" % n)
		var digit: int = p.data["digit"]
		var place_value: int = p.data["place_value"]
		assert_ne(digit, 0)
		assert_eq((n / place_value) % 10, digit)
		assert_eq(p.answer, str(digit * place_value))


func test_compare_sign_is_correct_and_buttons_fixed() -> void:
	var params: Dictionary = {"min": 10, "max": 99, "spread": 5, "equal_chance": 0.15}
	var seen: Dictionary = {}
	for i: int in SAMPLES:
		var p: MathProblem = PlaceValueGenerator.generate("compare", params, 3, rng)
		var a: int = p.data["a"]
		var b: int = p.data["b"]
		var expected: String = "=" if a == b else ("<" if a < b else ">")
		assert_eq(p.answer, expected)
		assert_eq(p.choices, ["<", "=", ">"] as Array[String])
		seen[p.answer] = true
	assert_eq(seen.size(), 3, "should produce <, =, and >")


func test_skip_count_continues_the_pattern() -> void:
	var params: Dictionary = {"steps": [5, 10, 100], "max": 1000, "shown": 3}
	for i: int in SAMPLES:
		var p: MathProblem = PlaceValueGenerator.generate("skip_count", params, 4, rng)
		var sequence: Array = p.data["sequence"]
		var step: int = p.data["step"]
		assert_eq(sequence.size(), 3)
		assert_eq(int(sequence[0]) % step, 0)
		assert_eq(int(sequence[1]) - int(sequence[0]), step)
		assert_eq(p.answer, str(int(sequence[2]) + step))
		assert_lte(int(p.answer), 1000)
