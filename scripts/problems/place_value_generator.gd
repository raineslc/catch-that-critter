class_name PlaceValueGenerator
extends RefCounted
## Swamp problems (grades 1–2, 1.NBT / 2.NBT.1–4): tens and ones, digit values,
## comparing with <, >, =, and skip counting.

## Comparison buttons always appear in this order so kids learn where each sign is.
const COMPARE_SIGNS: Array[String] = ["<", "=", ">"]


static func generate(type: String, params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	match type:
		"tens_ones":
			return _tens_ones(params, choice_count, rng)
		"digit_value":
			return _digit_value(choice_count, rng)
		"compare":
			return _compare(params, rng)
		"skip_count":
			return _skip_count(params, choice_count, rng)
	push_error("PlaceValueGenerator: unknown problem type '%s'" % type)
	return null


## "How many tens are in 47?" or "How many ones are in 47?"
static func _tens_ones(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var n: int = rng.randi_range(int(params.get("min", 10)), int(params.get("max", 99)))
	var tens: int = n / 10
	var ones: int = n % 10
	var ask_tens: bool = rng.randi_range(0, 1) == 0
	var place: String = "tens" if ask_tens else "ones"
	var answer: int = tens if ask_tens else ones
	var other: int = ones if ask_tens else tens
	var candidates: Array[int] = [other, answer + 1, answer - 1]
	var values: Array[int] = ChoiceBuilder.numeric(answer, choice_count, 0, 9, rng, 2, candidates)
	var text: String = "How many %s are in %d?" % [place, n]
	return MathProblem.create("tens_ones", text, text, str(answer), ChoiceBuilder.to_strings(values),
		{"n": n, "place": place, "tens": tens, "ones": ones})


## "What is the 4 worth in 347?" Three different digits, so the question is never ambiguous.
static func _digit_value(choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var hundreds: int = rng.randi_range(1, 9)
	var tens: int = rng.randi_range(0, 8)
	if tens >= hundreds:
		tens += 1
	var ones: int = rng.randi_range(0, 7)
	for used: int in [mini(hundreds, tens), maxi(hundreds, tens)]:
		if ones >= used:
			ones += 1
	var n: int = hundreds * 100 + tens * 10 + ones
	var places: Array[int] = [100]
	if tens != 0:
		places.append(10)
	if ones != 0:
		places.append(1)
	var place_value: int = places[rng.randi_range(0, places.size() - 1)]
	var digit: int = (n / place_value) % 10
	var answer: int = digit * place_value
	var candidates: Array[int] = [digit, digit * 10, digit * 100, hundreds * 100, tens * 10, ones]
	var values: Array[int] = ChoiceBuilder.numeric(answer, choice_count, 0, 999, rng, 3, candidates)
	var text: String = "What is the %d worth in %d?" % [digit, n]
	return MathProblem.create("digit_value", text, text, str(answer), ChoiceBuilder.to_strings(values),
		{"n": n, "digit": digit, "place_value": place_value})


## "47 ? 52": pick <, =, or >. Often uses close numbers so kids look at every digit.
static func _compare(params: Dictionary, rng: RandomNumberGenerator) -> MathProblem:
	var low: int = int(params.get("min", 10))
	var high: int = int(params.get("max", 99))
	var spread: int = int(params.get("spread", 5))
	var equal_chance: float = float(params.get("equal_chance", 0.15))
	var a: int = rng.randi_range(low, high)
	var b: int = a
	if rng.randf() >= equal_chance:
		while b == a:
			if rng.randi_range(0, 1) == 0:
				b = clampi(a + rng.randi_range(-spread, spread), low, high)
			else:
				b = rng.randi_range(low, high)
	var answer: String = "=" if a == b else ("<" if a < b else ">")
	var choices: Array[String] = COMPARE_SIGNS.duplicate()
	return MathProblem.create("compare", "%d  ?  %d" % [a, b], "Which sign goes between %d and %d?" % [a, b],
		answer, choices, {"a": a, "b": b})


## "5, 10, 15, ?" counting by 5s, 10s, or 100s.
static func _skip_count(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var steps: Array = params.get("steps", [10])
	var step: int = int(steps[rng.randi_range(0, steps.size() - 1)])
	var high: int = int(params.get("max", 100))
	var shown: int = int(params.get("shown", 3))
	var start: int = step * rng.randi_range(0, high / step - shown)
	var sequence: Array[int] = []
	var parts: Array[String] = []
	for i: int in shown:
		sequence.append(start + i * step)
		parts.append(str(start + i * step))
	var answer: int = start + shown * step
	var candidates: Array[int] = [answer + step, answer + 1, answer - 1, answer + 10]
	var values: Array[int] = ChoiceBuilder.numeric(answer, choice_count, 0, high + step, rng, 3, candidates)
	var listed: String = ", ".join(parts)
	return MathProblem.create("skip_count", listed + ", ?", "What comes next: %s?" % listed,
		str(answer), ChoiceBuilder.to_strings(values), {"sequence": sequence, "step": step})
