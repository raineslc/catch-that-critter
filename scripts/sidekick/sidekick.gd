class_name Sidekick
extends RefCounted
## The ranger's brother who cheers and gives hints (PLAN.md 3.3). Data-driven from
## data/sidekicks.json so Henrito and Loganator share one hint system.

const SIDEKICKS_PATH: String = "res://data/sidekicks.json"
## Events a sidekick has lines for.
const EVENTS: Array[String] = ["chase_start", "hint_intro", "caught", "escaped", "sprint"]

var data: Dictionary = {}
var _rng: RandomNumberGenerator


static func load_all(path: String = SIDEKICKS_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	var by_id: Dictionary = {}
	if not parsed is Dictionary:
		push_error("Sidekick: could not read %s" % path)
		return by_id
	for entry: Variant in parsed.get("sidekicks", []):
		by_id[str(entry["id"])] = entry
	return by_id


static func load_by_id(id: String, rng: RandomNumberGenerator) -> Sidekick:
	var sidekick: Sidekick = Sidekick.new()
	sidekick.data = load_all().get(id, {})
	sidekick._rng = rng
	if sidekick.data.is_empty():
		push_error("Sidekick: unknown sidekick '%s'" % id)
	return sidekick


func display_name() -> String:
	return str(data.get("name", ""))


func faceset() -> Texture2D:
	return load(str(data["faceset"])) if data.has("faceset") else null


## A random line for an event, e.g. line("caught").
func line(event: String) -> String:
	var lines: Array = data.get("lines", {}).get(event, [])
	if lines.is_empty():
		return ""
	return str(lines[_rng.randi_range(0, lines.size() - 1)])


func voice_rate() -> float:
	return float(data.get("voice", {}).get("rate", Speech.RATE))


func voice_pitch() -> float:
	return float(data.get("voice", {}).get("pitch", Speech.PITCH))
