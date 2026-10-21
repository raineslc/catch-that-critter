class_name CountingGenerator
extends RefCounted
## Meadow problems (Kindergarten, K.CC): count critters, compare numbers, what comes next.


static func generate(type: String, params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	match type:
		"count_objects":
			return _count_objects(params, choice_count, rng)
		"compare_more":
			return _compare_more(params, rng)
		"next_number":
			return _next_number(params, choice_count, rng)
	push_error("CountingGenerator: unknown problem type '%s'" % type)
	return null


static func _count_objects(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var low: int = int(params.get("min", 1))
	var high: int = int(params.get("max", 5))
	var count: int = rng.randi_range(low, high)
	var values: Array[int] = ChoiceBuilder.numeric(count, choice_count, 1, high + 2, rng, 2)
	var text: String = "How many critters do you see?"
	return MathProblem.create("count_objects", text, text, str(count), ChoiceBuilder.to_strings(values), {"count": count})


## Two choices: the two numbers themselves.
static func _compare_more(params: Dictionary, rng: RandomNumberGenerator) -> MathProblem:
	var low: int = int(params.get("min", 1))
	var high: int = int(params.get("max", 10))
	var a: int = rng.randi_range(low, high)
	var b: int = rng.randi_range(low, high - 1)
	if b >= a:
		b += 1
	var choices: Array[String] = [str(a), str(b)]
	ChoiceBuilder.shuffle(choices, rng)
	var spoken: String = "Which number is more, %d or %d?" % [a, b]
	return MathProblem.create("compare_more", "Which number is more?", spoken, str(maxi(a, b)), choices, {"a": a, "b": b})


static func _next_number(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var low: int = int(params.get("min", 1))
	var high: int = int(params.get("max", 20))
	var n: int = rng.randi_range(low, high - 1)
	var answer: int = n + 1
	var candidates: Array[int] = [n, n + 2, n - 1]
	var values: Array[int] = ChoiceBuilder.numeric(answer, choice_count, maxi(0, low - 1), high + 2, rng, 2, candidates)
	var text: String = "What number comes after %d?" % n
	return MathProblem.create("next_number", text, text, str(answer), ChoiceBuilder.to_strings(values), {"n": n})
