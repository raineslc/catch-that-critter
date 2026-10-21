extends GutTest

const SAMPLES: int = 300

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 5


func test_equal_groups_multiplies_groups_by_size() -> void:
	var params: Dictionary = {"sizes": [2, 5, 10], "min_groups": 1, "max_groups": 5}
	for i: int in SAMPLES:
		var p: MathProblem = MultiplyDivideGenerator.generate("equal_groups", params, 3, rng)
		var groups: int = p.data["groups"]
		var size: int = p.data["size"]
		assert_has([2, 5, 10], size)
		assert_between(groups, 1, 5)
		assert_eq(p.answer, str(groups * size))


func test_multiply_is_correct_and_in_range() -> void:
	var params: Dictionary = {"min_factor": 0, "max_factor": 10}
	for i: int in SAMPLES:
		var p: MathProblem = MultiplyDivideGenerator.generate("multiply", params, 4, rng)
		var a: int = p.data["a"]
		var b: int = p.data["b"]
		assert_between(a, 0, 10)
		assert_between(b, 0, 10)
		assert_eq(p.answer, str(a * b))


func test_divide_has_no_remainder() -> void:
	var params: Dictionary = {"min_divisor": 2, "max_divisor": 10, "min_quotient": 1, "max_quotient": 10}
	for i: int in SAMPLES:
		var p: MathProblem = MultiplyDivideGenerator.generate("divide", params, 4, rng)
		var dividend: int = p.data["dividend"]
		var divisor: int = p.data["divisor"]
		assert_between(divisor, 2, 10)
		assert_eq(dividend % divisor, 0)
		assert_eq(p.answer, str(dividend / divisor))
		assert_lte(dividend, 100)


func test_missing_factor_completes_the_equation() -> void:
	var params: Dictionary = {"min_factor": 1, "max_factor": 10}
	for i: int in SAMPLES:
		var p: MathProblem = MultiplyDivideGenerator.generate("missing_factor", params, 4, rng)
		var a: int = p.data["a"]
		var product: int = p.data["product"]
		assert_eq(a * int(p.answer), product)
		assert_gte(a, 1)
