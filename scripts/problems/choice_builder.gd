class_name ChoiceBuilder
extends RefCounted
## Builds answer choices: the correct answer plus believable near-misses, shuffled.
## Always uses the passed-in RNG so tests with a fixed seed are repeatable.

## Random-neighbor tries before falling back to filling values in order.
const MAX_ATTEMPTS: int = 200


## Numeric choices inside [min_value, max_value]: the answer, then likely
## mistakes from `candidates`, then random neighbors within `spread`.
static func numeric(answer: int, count: int, min_value: int, max_value: int, rng: RandomNumberGenerator, spread: int = 3, candidates: Array[int] = []) -> Array[int]:
	var values: Array[int] = [answer]
	var target: int = mini(count, max_value - min_value + 1)
	var pool: Array[int] = candidates.duplicate()
	shuffle(pool, rng)
	for candidate: int in pool:
		if values.size() >= target:
			break
		_add_if_valid(values, candidate, min_value, max_value)
	var attempts: int = 0
	while values.size() < target and attempts < MAX_ATTEMPTS:
		attempts += 1
		_add_if_valid(values, answer + rng.randi_range(-spread, spread), min_value, max_value)
	var next_value: int = min_value
	while values.size() < target:
		_add_if_valid(values, next_value, min_value, max_value)
		next_value += 1
	shuffle(values, rng)
	return values


## Text choices: the answer plus up to count - 1 distinct candidates.
static func from_strings(answer: String, candidates: Array[String], count: int, rng: RandomNumberGenerator) -> Array[String]:
	var values: Array[String] = [answer]
	var pool: Array[String] = candidates.duplicate()
	shuffle(pool, rng)
	for candidate: String in pool:
		if values.size() >= count:
			break
		if candidate != "" and not values.has(candidate):
			values.append(candidate)
	shuffle(values, rng)
	return values


static func to_strings(values: Array[int], suffix: String = "") -> Array[String]:
	var out: Array[String] = []
	for value: int in values:
		out.append(str(value) + suffix)
	return out


## Fisher-Yates shuffle with our own RNG (Array.shuffle() ignores seeds).
static func shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var temp: Variant = items[i]
		items[i] = items[j]
		items[j] = temp


static func _add_if_valid(values: Array[int], value: int, min_value: int, max_value: int) -> void:
	if value >= min_value and value <= max_value and not values.has(value):
		values.append(value)
