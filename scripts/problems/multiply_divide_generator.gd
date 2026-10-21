class_name MultiplyDivideGenerator
extends RefCounted
## Mountain problems (grade 3, 3.OA): equal groups, multiply, divide, missing factor.


static func generate(type: String, params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	match type:
		"equal_groups":
			return _equal_groups(params, choice_count, rng)
		"multiply":
			return _multiply(params, choice_count, rng)
		"divide":
			return _divide(params, choice_count, rng)
		"missing_factor":
			return _missing_factor(params, choice_count, rng)
	push_error("MultiplyDivideGenerator: unknown problem type '%s'" % type)
	return null


## "3 groups of 5. How many in all?"
static func _equal_groups(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var sizes: Array = params.get("sizes", [2, 5, 10])
	var size: int = int(sizes[rng.randi_range(0, sizes.size() - 1)])
	var max_groups: int = int(params.get("max_groups", 5))
	var groups: int = rng.randi_range(int(params.get("min_groups", 1)), max_groups)
	var product: int = groups * size
	var candidates: Array[int] = [groups + size, product + size, product - size]
	var max_size: int = 0
	for s: Variant in sizes:
		max_size = maxi(max_size, int(s))
	var values: Array[int] = ChoiceBuilder.numeric(product, choice_count, 0, max_groups * max_size + max_size, rng, 3, candidates)
	return MathProblem.create("equal_groups", "%d groups of %d. How many in all?" % [groups, size],
		"There are %d groups with %d critters each. How many critters in all?" % [groups, size],
		str(product), ChoiceBuilder.to_strings(values), {"groups": groups, "size": size})


static func _multiply(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var low: int = int(params.get("min_factor", 0))
	var high: int = int(params.get("max_factor", 10))
	var a: int = rng.randi_range(low, high)
	var b: int = rng.randi_range(low, high)
	var product: int = a * b
	var candidates: Array[int] = [a + b, product + a, product - a, product + b, product - b]
	var values: Array[int] = ChoiceBuilder.numeric(product, choice_count, 0, high * high + high, rng, 3, candidates)
	return MathProblem.create("multiply", "%d × %d = ?" % [a, b], "What is %d times %d?" % [a, b],
		str(product), ChoiceBuilder.to_strings(values), {"a": a, "b": b, "op": "×"})


static func _divide(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var max_divisor: int = int(params.get("max_divisor", 5))
	var max_quotient: int = int(params.get("max_quotient", 10))
	var divisor: int = rng.randi_range(maxi(1, int(params.get("min_divisor", 1))), max_divisor)
	var quotient: int = rng.randi_range(int(params.get("min_quotient", 1)), max_quotient)
	var dividend: int = divisor * quotient
	var candidates: Array[int] = [quotient + 1, quotient - 1, divisor, dividend - divisor]
	var values: Array[int] = ChoiceBuilder.numeric(quotient, choice_count, 0, maxi(max_quotient, max_divisor) + 3, rng, 3, candidates)
	return MathProblem.create("divide", "%d ÷ %d = ?" % [dividend, divisor], "What is %d divided by %d?" % [dividend, divisor],
		str(quotient), ChoiceBuilder.to_strings(values), {"dividend": dividend, "divisor": divisor, "op": "÷"})


## "a × ? = product"; the answer is the missing factor.
static func _missing_factor(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var high: int = int(params.get("max_factor", 10))
	var a: int = rng.randi_range(maxi(1, int(params.get("min_factor", 1))), high)
	var b: int = rng.randi_range(maxi(0, int(params.get("min_factor", 1))), high)
	var product: int = a * b
	var candidates: Array[int] = [b + 1, b - 1, a, product - a]
	var values: Array[int] = ChoiceBuilder.numeric(b, choice_count, 0, high + 3, rng, 2, candidates)
	return MathProblem.create("missing_factor", "%d × ? = %d" % [a, product], "%d times what equals %d?" % [a, product],
		str(b), ChoiceBuilder.to_strings(values), {"a": a, "b": b, "product": product, "op": "×"})
