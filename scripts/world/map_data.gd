class_name MapData
extends RefCounted
## A habitat map read from a plain-text grid (data/maps/*.txt), one character per tile.
## What each character means is in data/maps/legend.json.

const LEGEND_PATH: String = "res://data/maps/legend.json"

var rows: Array[String] = []
var width: int = 0
var height: int = 0
var tile_size: int = 16
## char -> ground kind ("grass", "path", "water").
var ground: Dictionary = {}
## char -> object definition (name, atlas, size, blocks).
var objects: Dictionary = {}
## char -> animal id (data/animals.json) that starts at that tile.
var critters: Dictionary = {}
var spawn_char: String = "S"
var sidekick_char: String = "H"
## Characters that mark gates on the map edge ("1".."5").
var gate_chars: String = ""
## The map's info file (data/maps/<name>.json): id, name, habitat, gates, pens. {} if there is none.
var meta: Dictionary = {}


static func load_map(map_path: String, legend_path: String = LEGEND_PATH) -> MapData:
	var map: MapData = MapData.new()
	var legend: Variant = JSON.parse_string(FileAccess.get_file_as_string(legend_path))
	if not legend is Dictionary:
		push_error("MapData: could not read legend %s" % legend_path)
		return map
	map.tile_size = int(legend.get("tile_size", 16))
	map.ground = legend.get("ground", {})
	map.objects = legend.get("objects", {})
	map.critters = legend.get("critters", {})
	map.spawn_char = str(legend.get("spawn", "S"))
	map.sidekick_char = str(legend.get("sidekick_spot", "H"))
	map.gate_chars = str(legend.get("gates", ""))
	var meta_path: String = map_path.get_basename() + ".json"
	if FileAccess.file_exists(meta_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(meta_path))
		if parsed is Dictionary:
			map.meta = parsed
	for line: String in FileAccess.get_file_as_string(map_path).split("\n"):
		var row: String = line.strip_edges(false, true)
		if row != "":
			map.rows.append(row)
	map.height = map.rows.size()
	map.width = map.rows[0].length() if map.height > 0 else 0
	return map


func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


## The map character at a cell ("" outside the map or past a short row).
func char_at(cell: Vector2i) -> String:
	if not in_bounds(cell) or cell.x >= rows[cell.y].length():
		return ""
	return rows[cell.y][cell.x]


func ground_at(cell: Vector2i) -> String:
	return str(ground.get(char_at(cell), ""))


func object_at(cell: Vector2i) -> Dictionary:
	return objects.get(char_at(cell), {})


## Animal id that starts at this tile, or "".
func critter_at(cell: Vector2i) -> String:
	return str(critters.get(char_at(cell), ""))


func pixel_to_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / tile_size), floori(point.y / tile_size))


## Can the ranger stand here? (No water, no blocking objects, inside the map.)
func is_walkable(cell: Vector2i) -> bool:
	if not in_bounds(cell) or ground_at(cell) == "water":
		return false
	return not bool(object_at(cell).get("blocks", false))


func find_char(c: String) -> Vector2i:
	for y: int in height:
		var x: int = rows[y].find(c)
		if x >= 0:
			return Vector2i(x, y)
	return Vector2i(-1, -1)


func spawn_cell() -> Vector2i:
	return find_char(spawn_char)


## Pixel position of the bottom-center of a cell (where feet stand).
func cell_to_feet(cell: Vector2i) -> Vector2:
	return Vector2((cell.x + 0.5) * tile_size, (cell.y + 1) * tile_size)


func pixel_size() -> Vector2i:
	return Vector2i(width, height) * tile_size


## The map's id from its info file ("" if it has none).
func id() -> String:
	return str(meta.get("id", ""))


func habitat() -> String:
	return str(meta.get("habitat", ""))


## gate char -> cell, for every gate character found on the map.
func gate_cells() -> Dictionary:
	var gates: Dictionary = {}
	for c: String in gate_chars:
		var cell: Vector2i = find_char(c)
		if cell.x >= 0:
			gates[c] = cell
	return gates


## The gate's settings from the info file ({} if none): to, arrive, label, locked.
func gate_info(gate: String) -> Dictionary:
	return meta.get("gates", {}).get(gate, {})


## Where you appear when you come in through a gate: two steps in from the edge.
func arrival_cell(gate: String) -> Vector2i:
	var cell: Vector2i = find_char(gate)
	var inward: Vector2i = Vector2i.ZERO
	if cell.x == 0:
		inward = Vector2i.RIGHT
	elif cell.x == width - 1:
		inward = Vector2i.LEFT
	elif cell.y == 0:
		inward = Vector2i.DOWN
	elif cell.y == height - 1:
		inward = Vector2i.UP
	return cell + inward * 2


func is_gate(cell: Vector2i) -> bool:
	var c: String = char_at(cell)
	return c != "" and gate_chars.contains(c)
