class_name AddSubtractGenerator
extends RefCounted
## Forest problems (grades 1–2, 1.OA / 2.OA / 2.NBT.5): add, subtract, missing addend.
##
## Params: "min"/"max" bound the biggest number in the problem (the sum or the
## starting number); "min_part" is the smallest addend or amount taken away;
## "spread" is how far off the random wrong choices can be; "choice_max" (optional)
## caps the biggest number shown on an addition button.


static func generate(type: String, params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	match type:
		"add":
			return _add(params, choice_count, rng)
		"subtract":
			return _subtract(params, choice_count, rng)
		"mixed":
			if rng.randi_range(0, 1) == 0:
				return _add(params, choice_count, rng)
			return _subtract(params, choice_count, rng)
		"missing_addend":
			return _missing_addend(params, choice_count, rng)
	push_error("AddSubtractGenerator: unknown problem type '%s'" % type)
	return null


static func _add(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var high: int = int(params.get("max", 10))
	var min_part: int = int(params.get("min_part", 0))
	var spread: int = int(params.get("spread", 3))
	var total: int = rng.randi_range(maxi(int(params.get("min", 0)), 2 * min_part), high)
	var a: int = rng.randi_range(min_part, total - min_part)
	var b: int = total - a
	var candidates: Array[int] = [absi(a - b), total + 10, total - 10]
	var choice_max: int = int(params.get("choice_max", high + spread))
	var values: Array[int] = ChoiceBuilder.numeric(total, choice_count, 0, choice_max, rng, spread, candidates)
	return MathProblem.create("add", "%d + %d = ?" % [a, b], "What is %d plus %d?" % [a, b],
		str(total), ChoiceBuilder.to_strings(values), {"a": a, "b": b, "op": "+"})


static func _subtract(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var high: int = int(params.get("max", 10))
	var min_part: int = int(params.get("min_part", 0))
	var spread: int = int(params.get("spread", 3))
	var a: int = rng.randi_range(maxi(int(params.get("min", 0)), 2 * min_part), high)
	var b: int = rng.randi_range(min_part, a - min_part)
	var difference: int = a - b
	var candidates: Array[int] = [a + b, difference + 10, difference - 10]
	var values: Array[int] = ChoiceBuilder.numeric(difference, choice_count, 0, high, rng, spread, candidates)
	return MathProblem.create("subtract", "%d - %d = ?" % [a, b], "What is %d minus %d?" % [a, b],
		str(difference), ChoiceBuilder.to_strings(values), {"a": a, "b": b, "op": "-"})


## "a + ? = total"; the answer is the missing addend.
static func _missing_addend(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var high: int = int(params.get("max", 20))
	var min_part: int = int(params.get("min_part", 1))
	var spread: int = int(params.get("spread", 3))
	var total: int = rng.randi_range(maxi(int(params.get("min", 0)), 2 * min_part), high)
	var a: int = rng.randi_range(min_part, total - min_part)
	var b: int = total - a
	var candidates: Array[int] = [total, total + a]
	var values: Array[int] = ChoiceBuilder.numeric(b, choice_count, 0, high, rng, spread, candidates)
	return MathProblem.create("missing_addend", "%d + ? = %d" % [a, total], "%d plus what makes %d?" % [a, total],
		str(b), ChoiceBuilder.to_strings(values), {"a": a, "b": b, "total": total, "op": "+"})
