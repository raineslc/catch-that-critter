class_name AdaptiveEngine
extends RefCounted
## Keeps each skill at the right level for one player (PLAN.md 3.11).
##
## - Looks at the last `window_size` answers per skill.
## - Level up: enough answers, >= level_up_accuracy correct, and correct answers are fast on average.
## - Level down: enough answers and < level_down_accuracy correct; also turns on extra help (earlier hints).
## - Mastery: `mastery_sessions` good sessions in a row. A good session at a harder level
##   also counts for the easier levels; a poor one resets that level and harder ones.
##
## Record one answer per problem: whether the FIRST try was correct, and how long it took.
## Tuning numbers live in data/adaptive.json.

enum Change { NONE, LEVEL_UP, LEVEL_DOWN }

const CONFIG_PATH: String = "res://data/adaptive.json"

var _config: Dictionary = {}
## skill id -> number of levels.
var _level_counts: Dictionary = {}
## skill id -> SkillProgress.
var _skills: Dictionary = {}


## `level_counts`: skill id -> number of levels, e.g. from ProblemFactory.level_count().
func _init(level_counts: Dictionary, config: Dictionary = {}) -> void:
	_config = config if not config.is_empty() else load_config()
	_level_counts = level_counts.duplicate()
	for skill_id: Variant in _level_counts:
		_skills[str(skill_id)] = SkillProgress.new()


static func load_config(path: String = CONFIG_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("AdaptiveEngine: could not read config from %s" % path)
		return {}
	return parsed


## Builds level counts for every skill the factory knows.
static func level_counts_from(factory: ProblemFactory) -> Dictionary:
	var counts: Dictionary = {}
	for skill_id: String in factory.skill_ids():
		counts[skill_id] = factory.level_count(skill_id)
	return counts


func has_skill(skill_id: String) -> bool:
	return _skills.has(skill_id)


func level(skill_id: String) -> int:
	if not has_skill(skill_id):
		return 0
	return _progress(skill_id).level


## Sets a starting level (e.g. from the profile). Clamped to the skill's levels; clears recent answers.
func set_level(skill_id: String, new_level: int) -> void:
	if not _require_skill(skill_id):
		return
	var progress: SkillProgress = _progress(skill_id)
	progress.level = clampi(new_level, 1, int(_level_counts[skill_id]))
	progress.window.clear()


## Records the first try at one problem and returns whether the level changed.
func record_answer(skill_id: String, correct: bool, seconds: float) -> Change:
	if not _require_skill(skill_id):
		return Change.NONE
	var progress: SkillProgress = _progress(skill_id)
	var time_taken: float = maxf(seconds, 0.0)
	progress.window.append({"correct": correct, "seconds": time_taken})
	while progress.window.size() > _int("window_size"):
		progress.window.pop_front()
	_count_session_answer(progress, correct)
	progress.total_answers += 1
	progress.total_correct += 1 if correct else 0
	progress.total_seconds += time_taken
	return _evaluate(skill_id, progress)


## Share of recent answers that were correct (0.0 when there are none).
func window_accuracy(skill_id: String) -> float:
	if not has_skill(skill_id):
		return 0.0
	return _accuracy(_progress(skill_id).window)


func window_count(skill_id: String) -> int:
	if not has_skill(skill_id):
		return 0
	return _progress(skill_id).window.size()


func needs_extra_help(skill_id: String) -> bool:
	return has_skill(skill_id) and _progress(skill_id).extra_help


## How many misses on one problem before the sidekick shows a hint.
func misses_before_hint(skill_id: String) -> int:
	if needs_extra_help(skill_id):
		return _int("misses_before_hint_with_extra_help")
	return _int("misses_before_hint")


## Call once when a play session ends. Returns newly mastered levels: [{"skill": id, "level": n}, ...].
func end_session() -> Array[Dictionary]:
	var newly_mastered: Array[Dictionary] = []
	for skill_id: String in _skills:
		var progress: SkillProgress = _progress(skill_id)
		if progress.session.is_empty():
			continue
		var best_good: int = 0
		var lowest_poor: int = int(_level_counts[skill_id]) + 1
		for played: Variant in progress.session:
			var result: Dictionary = progress.session[played]
			if int(result["answers"]) < _int("min_answers_per_mastery_session"):
				continue
			var accuracy: float = float(result["correct"]) / float(result["answers"])
			if accuracy >= _float("mastery_accuracy"):
				best_good = maxi(best_good, int(played))
			else:
				lowest_poor = mini(lowest_poor, int(played))
		for lvl: int in range(1, int(_level_counts[skill_id]) + 1):
			if lvl >= lowest_poor:
				progress.streaks[lvl] = 0
			elif lvl <= best_good:
				progress.streaks[lvl] = int(progress.streaks.get(lvl, 0)) + 1
			if int(progress.streaks.get(lvl, 0)) >= _int("mastery_sessions") and not progress.mastered.has(lvl):
				progress.mastered.append(lvl)
				newly_mastered.append({"skill": skill_id, "level": lvl})
		progress.session.clear()
	return newly_mastered


func is_level_mastered(skill_id: String, lvl: int) -> bool:
	return has_skill(skill_id) and _progress(skill_id).mastered.has(lvl)


## A skill is mastered when its hardest level is.
func is_skill_mastered(skill_id: String) -> bool:
	return has_skill(skill_id) and is_level_mastered(skill_id, int(_level_counts[skill_id]))


## Lifetime numbers for the parent report.
func stats(skill_id: String) -> Dictionary:
	if not has_skill(skill_id):
		return {}
	var progress: SkillProgress = _progress(skill_id)
	var mastered: Array[int] = progress.mastered.duplicate()
	mastered.sort()
	return {
		"level": progress.level,
		"answers": progress.total_answers,
		"correct": progress.total_correct,
		"accuracy": float(progress.total_correct) / progress.total_answers if progress.total_answers > 0 else 0.0,
		"average_seconds": progress.total_seconds / progress.total_answers if progress.total_answers > 0 else 0.0,
		"mastered_levels": mastered,
		"extra_help": progress.extra_help,
	}


func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for skill_id: String in _skills:
		data[skill_id] = _progress(skill_id).to_dict()
	return data


## Restores saved progress. Skills missing from the save start fresh; unknown ones are ignored.
func load_dict(data: Dictionary) -> void:
	for skill_id: Variant in data:
		var id: String = str(skill_id)
		if not has_skill(id):
			continue
		var progress: SkillProgress = SkillProgress.from_dict(data[skill_id])
		progress.level = clampi(progress.level, 1, int(_level_counts[id]))
		_skills[id] = progress


func _evaluate(skill_id: String, progress: SkillProgress) -> Change:
	var accuracy: float = _accuracy(progress.window)
	var count: int = progress.window.size()
	if count >= _int("min_answers_to_level_down") and accuracy < _float("level_down_accuracy"):
		progress.extra_help = true
		if progress.level > 1:
			progress.level -= 1
			progress.window.clear()
			return Change.LEVEL_DOWN
		return Change.NONE
	if progress.extra_help and count >= _int("min_answers_to_level_down"):
		progress.extra_help = false
	if count >= _int("min_answers_to_level_up") and accuracy >= _float("level_up_accuracy") \
			and _average_correct_seconds(progress.window) <= _fast_seconds(skill_id):
		if progress.level < int(_level_counts[skill_id]):
			progress.level += 1
			progress.window.clear()
			progress.extra_help = false
			return Change.LEVEL_UP
	return Change.NONE


func _count_session_answer(progress: SkillProgress, correct: bool) -> void:
	var result: Dictionary = progress.session.get(progress.level, {"answers": 0, "correct": 0})
	result["answers"] = int(result["answers"]) + 1
	result["correct"] = int(result["correct"]) + (1 if correct else 0)
	progress.session[progress.level] = result


func _fast_seconds(skill_id: String) -> float:
	var table: Dictionary = _config.get("fast_seconds", {})
	return float(table.get(skill_id, table.get("default", 8.0)))


static func _accuracy(window: Array[Dictionary]) -> float:
	if window.is_empty():
		return 0.0
	var correct: int = 0
	for answer: Dictionary in window:
		if answer["correct"]:
			correct += 1
	return float(correct) / window.size()


static func _average_correct_seconds(window: Array[Dictionary]) -> float:
	var total: float = 0.0
	var count: int = 0
	for answer: Dictionary in window:
		if answer["correct"]:
			total += float(answer["seconds"])
			count += 1
	return total / count if count > 0 else INF


func _progress(skill_id: String) -> SkillProgress:
	return _skills[skill_id]


func _require_skill(skill_id: String) -> bool:
	if has_skill(skill_id):
		return true
	push_error("AdaptiveEngine: unknown skill '%s'" % skill_id)
	return false


func _int(key: String) -> int:
	return int(_config[key])


func _float(key: String) -> float:
	return float(_config[key])
