class_name WordProblem
extends RefCounted
## Story ("word") problems for the hidden snakes (1.OA.1 / 2.OA.1): a normal add/subtract problem
## from ProblemFactory, one level harder than the player's current level, retold as a short story.
## The numbers, answer, and choices stay exactly the generator's, so the answer is always right.

const WORD_PROBLEMS_PATH: String = "res://data/word_problems.json"

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


## A story problem from `skill_id` at `level`, starring `snake_name`. Null if the skill's problem
## at that level has no story template (only add/subtract kinds do).
func make(factory: ProblemFactory, skill_id: String, level: int, snake_name: String, rng: RandomNumberGenerator) -> MathProblem:
	var problem: MathProblem = factory.generate(skill_id, level, rng)
	if problem == null:
		return null
	var kind: String = problem.type
	if kind == "mixed":
		kind = "add" if str(problem.data.get("op", "+")) == "+" else "subtract"
	var templates: Array = _data.get("templates", {}).get(kind, [])
	if templates.is_empty():
		return null
	var things: Array = _data.get("things", [["frog", "frogs"]])
	var noun: Array = things[rng.randi_range(0, things.size() - 1)]
	var text: String = str(templates[rng.randi_range(0, templates.size() - 1)])
	var a: int = int(problem.data.get("a", 0))
	var b: int = int(problem.data.get("b", 0))
	text = text.replace("{snake}", snake_name.to_lower())
	text = text.replace("{a_things}", _count(a, noun)).replace("{b_things}", _count(b, noun))
	text = text.replace("{a}", str(a)).replace("{b}", str(b)).replace("{total}", str(problem.data.get("total", 0)))
	text = text.replace("{things}", str(noun[1]))
	problem.prompt = text
	problem.spoken = text
	problem.type = "word_" + kind
	return problem


## "1 frog", "3 frogs".
static func _count(n: int, noun: Array) -> String:
	return "%d %s" % [n, noun[0] if n == 1 else noun[1]]
