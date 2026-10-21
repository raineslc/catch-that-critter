class_name ChaseState
extends RefCounted
## The rules of one chase, with no visuals (PLAN.md 3.6–3.7):
## each right answer closes the gap, each miss lets the critter pull ahead a little,
## and `correct_to_catch` right answers means the net toss catches it.
## Race mode adds a timer (the critter escapes when it runs out) and a sprint boost
## for fast right answers (extra closing plus a few bonus seconds).
## "gap" is in steps; the chase screen turns it into pixels.

const CONFIG_PATH: String = "res://data/chase.json"
const EXPLORE: String = "explore"
const RACE: String = "race"

var mode: String = EXPLORE
var correct_to_catch: int = 3
var start_gap: float = 3.0
var close_per_correct: float = 1.0
var pull_per_miss: float = 0.5
var max_gap: float = 4.0
var race_seconds: float = 45.0
var sprint_seconds: float = 5.0
var sprint_time_bonus: float = 3.0
var sprint_extra_close: float = 0.5

var correct: int = 0
var misses: int = 0
var gap: float = 3.0
var caught: bool = false
var escaped: bool = false
## Race mode only: seconds left before the critter escapes.
var time_left: float = 0.0
## True if the most recent answer earned a sprint boost.
var last_sprint: bool = false


func _init(config: Dictionary = {}, chase_mode: String = EXPLORE) -> void:
	var settings: Dictionary = config if not config.is_empty() else load_config()
	mode = chase_mode
	correct_to_catch = int(settings.get("correct_to_catch", correct_to_catch))
	start_gap = float(settings.get("start_gap", start_gap))
	close_per_correct = float(settings.get("close_per_correct", close_per_correct))
	pull_per_miss = float(settings.get("pull_per_miss", pull_per_miss))
	max_gap = float(settings.get("max_gap", max_gap))
	race_seconds = float(settings.get("race_seconds", race_seconds))
	sprint_seconds = float(settings.get("sprint_seconds", sprint_seconds))
	sprint_time_bonus = float(settings.get("sprint_time_bonus", sprint_time_bonus))
	sprint_extra_close = float(settings.get("sprint_extra_close", sprint_extra_close))
	restart()


static func load_config(path: String = CONFIG_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Fresh chase with the same settings ("Chase again").
func restart() -> void:
	correct = 0
	misses = 0
	gap = start_gap
	caught = false
	escaped = false
	last_sprint = false
	time_left = race_seconds if is_race() else 0.0


func is_race() -> bool:
	return mode == RACE


func is_over() -> bool:
	return caught or escaped


## Apply one answer (every try counts for the chase, not just the first).
## `seconds` is how long the answer took; fast right answers sprint in Race mode.
func answer(is_correct: bool, seconds: float = INF) -> void:
	last_sprint = false
	if is_over():
		return
	if not is_correct:
		misses += 1
		gap = minf(gap + pull_per_miss, max_gap)
		return
	correct += 1
	var close: float = close_per_correct
	if is_race() and seconds <= sprint_seconds:
		last_sprint = true
		close += sprint_extra_close
		time_left += sprint_time_bonus
	gap = maxf(gap - close, 0.0)
	if correct >= correct_to_catch:
		caught = true
		gap = 0.0


## Race mode: count down. Returns true on the tick the critter escapes.
func tick(delta: float) -> bool:
	if not is_race() or is_over():
		return false
	time_left = maxf(time_left - delta, 0.0)
	if time_left <= 0.0:
		escaped = true
		return true
	return false


## 0.0 at the start, 1.0 when caught: how full the catch meter is.
func progress() -> float:
	return float(correct) / correct_to_catch
