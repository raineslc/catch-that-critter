class_name SkillProgress
extends RefCounted
## Everything the adaptive engine remembers about one skill for one player.
## Plain data plus save/load; the rules live in AdaptiveEngine.

## Current level (1-based).
var level: int = 1
## Most recent answers, oldest first: [{"correct": bool, "seconds": float}, ...].
var window: Array[Dictionary] = []
## True after struggling; the sidekick hints sooner until the player recovers.
var extra_help: bool = false
## level -> consecutive good sessions.
var streaks: Dictionary = {}
## Levels the player has mastered (sticky once earned).
var mastered: Array[int] = []
## This session only: level -> {"answers": int, "correct": int}.
var session: Dictionary = {}
## Lifetime totals for the parent report.
var total_answers: int = 0
var total_correct: int = 0
var total_seconds: float = 0.0


func to_dict() -> Dictionary:
	var streak_data: Dictionary = {}
	for key: Variant in streaks:
		streak_data[str(key)] = streaks[key]
	return {
		"level": level,
		"window": window.duplicate(true),
		"extra_help": extra_help,
		"streaks": streak_data,
		"mastered": mastered.duplicate(),
		"total_answers": total_answers,
		"total_correct": total_correct,
		"total_seconds": total_seconds,
	}


## Rebuilds from to_dict() output, including after a JSON round trip
## (where ints come back as floats and keys as strings).
static func from_dict(data: Dictionary) -> SkillProgress:
	var progress: SkillProgress = SkillProgress.new()
	progress.level = int(data.get("level", 1))
	for entry: Variant in data.get("window", []):
		var answer: Dictionary = entry
		progress.window.append({"correct": bool(answer.get("correct", false)), "seconds": float(answer.get("seconds", 0.0))})
	progress.extra_help = bool(data.get("extra_help", false))
	var streak_data: Dictionary = data.get("streaks", {})
	for key: Variant in streak_data:
		progress.streaks[int(key)] = int(streak_data[key])
	for value: Variant in data.get("mastered", []):
		progress.mastered.append(int(value))
	progress.total_answers = int(data.get("total_answers", 0))
	progress.total_correct = int(data.get("total_correct", 0))
	progress.total_seconds = float(data.get("total_seconds", 0.0))
	return progress
