class_name Rewards
extends RefCounted
## Reads data/rewards.json (PLAN.md 3.10): how many stars each thing earns, the care visits
## needed for animal levels 1–5, the pen decorations in the shop, and the collection book pages.

const REWARDS_PATH: String = "res://data/rewards.json"
const MAX_LEVEL: int = 5

var _data: Dictionary = {}


func _init(path: String = REWARDS_PATH) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("Rewards: could not read %s" % path)
		return
	_data = parsed


func stars_for(reason: String) -> int:
	return int(_data.get("stars", {}).get(reason, 0))


## Stars for a catch: the catch itself, plus a bonus when the chase had no misses.
func catch_stars(misses: int) -> int:
	return stars_for("catch") + (stars_for("no_miss_bonus") if misses == 0 else 0)


## Animal level 1–5 from finished care visits (level 1 = rescued, never cared for yet).
func level_for(care_visits: int) -> int:
	var level: int = 1
	for needed: Variant in _data.get("level_visits", []):
		if care_visits >= int(needed):
			level += 1
	return mini(level, MAX_LEVEL)


## Pen decorations in shop order: [{"id", "name", "price", "object", "spot"}].
func decorations() -> Array:
	return _data.get("decorations", [])


func decoration(id: String) -> Dictionary:
	for item: Dictionary in decorations():
		if item["id"] == id:
			return item
	return {}


## Collection book pages: [{"habitat", "animals": [ids], "special": id}].
func book_pages() -> Array:
	return _data.get("book", [])
