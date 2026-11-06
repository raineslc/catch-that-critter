class_name WordProblem
extends RefCounted
## Story ("word") problems for the hidden snakes (PLAN 3.4): a normal problem from ProblemFactory in
## the snake's habitat skill, one level harder than the player's current level, retold as a short story.
## The numbers, answer, and choices stay exactly the generator's, so the answer is always right.

const WORD_PROBLEMS_PATH: String = "res://data/word_problems.json"
## Numbers that count things in a story; a story with 0 or 1 of them reads oddly, so it's redrawn.
const COUNT_KEYS: Array[String] = ["a", "b", "n", "count", "total", "groups", "size", "dividend", "divisor", "product"]
const MIN_COUNT: int = 2
const MAX_TRIES: int = 30

var _data: Dictionary = {}


func _init(path: String = WORD_PROBLEMS_PATH) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("WordProblem: could not read %s" % path)
		return
	_data = parsed


## The level a snake asks: one above the player's current level, but not past the last one.
static func snake_level(current: int, level_count: int) -> int:
	return clampi(current + 1, 1, maxi(level_count, 1))


## A story problem from `skill_id` at `level`, starring `snake_name`. Null if that kind of problem
## has no story template.
func make(factory: ProblemFactory, skill_id: String, level: int, snake_name: String, rng: RandomNumberGenerator) -> MathProblem:
	var problem: MathProblem = null
	for i: int in MAX_TRIES:
		problem = factory.generate(skill_id, level, rng)
		if problem == null or _counts_are_big_enough(problem):
			break
	if problem == null:
		return null
	return retell(problem, snake_name, rng)


## Retells `problem` as a story (changes and returns it). Null if its kind has no template.
func retell(problem: MathProblem, snake_name: String, rng: RandomNumberGenerator) -> MathProblem:
	var kind: String = problem.type
	if kind == "mixed":
		kind = "add" if str(problem.data.get("op", "+")) == "+" else "subtract"
	var templates: Array = _data.get("templates", {}).get(kind, [])
	if templates.is_empty():
		return null
	var things: Array = _data.get("things", [])
	var noun: Dictionary = things[rng.randi_range(0, things.size() - 1)] if not things.is_empty() else {"one": "frog", "many": "frogs"}
	var text: String = str(templates[rng.randi_range(0, templates.size() - 1)])
	text = text.replace("{snake}", snake_name.to_lower()).replace("{things}", str(noun["many"]))
	for key: Variant in problem.data:
		var value: Variant = problem.data[key]
		if value is Array:
			var parts: PackedStringArray = []
			for part: Variant in value:
				parts.append(str(int(part)))
			text = text.replace("{%s}" % key, ", ".join(parts))
		elif value is int or value is float:
			text = text.replace("{%s_things}" % key, _count(int(value), noun)).replace("{%s}" % key, str(int(value)))
		else:
			text = text.replace("{%s}" % key, str(value))
	problem.prompt = text
	problem.spoken = text
	problem.type = "word_" + kind
	problem.data["story_icon"] = str(noun.get("icon", ""))
	return problem


static func _counts_are_big_enough(problem: MathProblem) -> bool:
	for key: String in COUNT_KEYS:
		if problem.data.has(key) and int(problem.data[key]) < MIN_COUNT:
			return false
	return true


## "1 cricket", "3 crickets".
static func _count(n: int, noun: Dictionary) -> String:
	return "%d %s" % [n, noun["one"] if n == 1 else noun["many"]]
