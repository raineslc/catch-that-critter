class_name CareCatalog
extends RefCounted
## Reads data/care.json (PLAN.md 3.9): the foods (word + picture), and for each animal what it
## eats, its care notes, and its fact card. Also how feeding works at each grade.

const CARE_PATH: String = "res://data/care.json"
const DEFAULT_GRADE: String = "2"

var _data: Dictionary = {}


func _init(path: String = CARE_PATH) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("CareCatalog: could not read %s" % path)
		return
	_data = parsed


func has_animal(id: String) -> bool:
	return _data.get("animals", {}).has(id)


func animal_ids() -> Array[String]:
	var out: Array[String] = []
	for id: Variant in _data.get("animals", {}):
		out.append(str(id))
	return out


func food_ids() -> Array[String]:
	var out: Array[String] = []
	for id: Variant in _data.get("foods", {}):
		out.append(str(id))
	return out


## {"word", "picture"} for a food id, or {}.
func food(id: String) -> Dictionary:
	return _data.get("foods", {}).get(id, {})


## Food ids this animal eats.
func foods_for(animal_id: String) -> Array[String]:
	var out: Array[String] = []
	for id: Variant in _animal(animal_id).get("foods", []):
		out.append(str(id))
	return out


## Care notes: [{"text", "question", "good", "others"}].
func notes_for(animal_id: String) -> Array:
	return _animal(animal_id).get("care_notes", [])


func facts_for(animal_id: String) -> Array[String]:
	var out: Array[String] = []
	for fact: Variant in _animal(animal_id).get("facts", []):
		out.append(str(fact))
	return out


## Feeding rules for a grade ("K", "1", "2", "3"): {"modes", "extra_letters"?, "choices"?}.
## Unknown grades use DEFAULT_GRADE.
func feeding_rules(grade: String) -> Dictionary:
	var grades: Dictionary = _data.get("feeding", {}).get("grades", {})
	return grades.get(grade, grades.get(DEFAULT_GRADE, {"modes": [CareVisit.SPELL]}))


func grades() -> Array[String]:
	var out: Array[String] = []
	for grade: Variant in _data.get("feeding", {}).get("grades", {}):
		out.append(str(grade))
	return out


## Misses on one letter (or one picture) before the sidekick helps.
func hint_after_misses() -> int:
	return int(_data.get("feeding", {}).get("hint_after_misses", 2))


func _animal(id: String) -> Dictionary:
	return _data.get("animals", {}).get(id, {})
