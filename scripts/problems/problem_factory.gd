class_name ProblemFactory
extends RefCounted
## Reads skill levels from data/skills.json and makes a problem for any skill + level.
## Levels are 1-based. Change difficulty by editing the JSON, not the code.

const SKILLS_PATH: String = "res://data/skills.json"
const DEFAULT_CHOICES: int = 3

## skill id -> skill Dictionary (as in the JSON), in file order.
var _skills: Dictionary = {}


func _init(path: String = SKILLS_PATH) -> void:
	_skills = load_skills(path)


static func load_skills(path: String) -> Dictionary:
	var text: String = FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	var by_id: Dictionary = {}
	if not parsed is Dictionary or not (parsed as Dictionary).has("skills"):
		push_error("ProblemFactory: could not read skills from %s" % path)
		return by_id
	for skill: Variant in (parsed as Dictionary)["skills"]:
		var skill_dict: Dictionary = skill
		by_id[str(skill_dict["id"])] = skill_dict
	return by_id


func skill_ids() -> Array[String]:
	var ids: Array[String] = []
	for id: Variant in _skills.keys():
		ids.append(str(id))
	return ids


func has_skill(skill_id: String) -> bool:
	return _skills.has(skill_id)


func level_count(skill_id: String) -> int:
	if not has_skill(skill_id):
		return 0
	var levels: Array = _skills[skill_id]["levels"]
	return levels.size()


func skill_info(skill_id: String) -> Dictionary:
	return _skills.get(skill_id, {})


## The JSON entry for one level (1-based), or {} if it doesn't exist.
func level_info(skill_id: String, level: int) -> Dictionary:
	if level < 1 or level > level_count(skill_id):
		return {}
	var levels: Array = _skills[skill_id]["levels"]
	return levels[level - 1]


func generate(skill_id: String, level: int, rng: RandomNumberGenerator) -> MathProblem:
	var info: Dictionary = level_info(skill_id, level)
	if info.is_empty():
		push_error("ProblemFactory: no level %d for skill '%s'" % [level, skill_id])
		return null
	var type: String = str(info["type"])
	var params: Dictionary = info.get("params", {})
	var choice_count: int = int(info.get("choices", DEFAULT_CHOICES))
	var problem: MathProblem = null
	match str(_skills[skill_id]["generator"]):
		"counting":
			problem = CountingGenerator.generate(type, params, choice_count, rng)
		"add_subtract":
			problem = AddSubtractGenerator.generate(type, params, choice_count, rng)
		"place_value":
			problem = PlaceValueGenerator.generate(type, params, choice_count, rng)
		"time_money":
			problem = TimeMoneyGenerator.generate(type, params, choice_count, rng)
		"multiply_divide":
			problem = MultiplyDivideGenerator.generate(type, params, choice_count, rng)
		_:
			push_error("ProblemFactory: unknown generator for skill '%s'" % skill_id)
	if problem == null:
		return null
	problem.skill_id = skill_id
	problem.level = level
	problem.hint = str(info.get("hint", ""))
	for code: Variant in info.get("standards", []):
		problem.standards.append(str(code))
	return problem
