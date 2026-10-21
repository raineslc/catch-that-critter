class_name AnimalCatalog
extends RefCounted
## Reads data/animals.json. Each animal gets the shared "defaults" filled in for anything it doesn't set.

const ANIMALS_PATH: String = "res://data/animals.json"

var _defaults: Dictionary = {}
## id -> animal Dictionary (with defaults merged in), in file order.
var _animals: Dictionary = {}


func _init(path: String = ANIMALS_PATH) -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("AnimalCatalog: could not read %s" % path)
		return
	_defaults = parsed.get("defaults", {})
	for entry: Variant in parsed.get("animals", []):
		var animal: Dictionary = _defaults.duplicate(true)
		animal.merge(entry, true)
		_animals[str(animal["id"])] = animal


func ids() -> Array[String]:
	var out: Array[String] = []
	for id: Variant in _animals:
		out.append(str(id))
	return out


func has_animal(id: String) -> bool:
	return _animals.has(id)


## The animal's data, or {} if unknown.
func get_animal(id: String) -> Dictionary:
	return _animals.get(id, {})
