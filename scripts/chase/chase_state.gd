class_name ChaseState
extends RefCounted
## The rules of one chase, with no visuals (PLAN.md 3.6):
## each right answer closes the gap, each miss lets the critter pull ahead a little,
## and `correct_to_catch` right answers means the net toss catches it.
## "gap" is in steps; the chase screen turns it into pixels.

const CONFIG_PATH: String = "res://data/chase.json"

var correct_to_catch: int = 3
var close_per_correct: float = 1.0
var pull_per_miss: float = 0.5
var max_gap: float = 4.0

var correct: int = 0
var misses: int = 0
var gap: float = 3.0
var caught: bool = false


func _init(config: Dictionary = {}) -> void:
	var settings: Dictionary = config if not config.is_empty() else load_config()
	correct_to_catch = int(settings.get("correct_to_catch", correct_to_catch))
	close_per_correct = float(settings.get("close_per_correct", close_per_correct))
	pull_per_miss = float(settings.get("pull_per_miss", pull_per_miss))
	max_gap = float(settings.get("max_gap", max_gap))
	gap = float(settings.get("start_gap", gap))


static func load_config(path: String = CONFIG_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Apply one answer (every try counts for the chase, not just the first).
func answer(is_correct: bool) -> void:
	if caught:
		return
	if is_correct:
		correct += 1
		gap = maxf(gap - close_per_correct, 0.0)
		if correct >= correct_to_catch:
			caught = true
			gap = 0.0
	else:
		misses += 1
		gap = minf(gap + pull_per_miss, max_gap)


## 0.0 at the start, 1.0 when caught: how full the catch meter is.
func progress() -> float:
	return float(correct) / correct_to_catch
