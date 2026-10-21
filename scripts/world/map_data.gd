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
var spawn_char: String = "S"


static func load_map(map_path: String, legend_path: String = LEGEND_PATH) -> MapData:
	var map: MapData = MapData.new()
	var legend: Variant = JSON.parse_string(FileAccess.get_file_as_string(legend_path))
	if not legend is Dictionary:
		push_error("MapData: could not read legend %s" % legend_path)
		return map
	map.tile_size = int(legend.get("tile_size", 16))
	map.ground = legend.get("ground", {})
	map.objects = legend.get("objects", {})
	map.spawn_char = str(legend.get("spawn", "S"))
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
