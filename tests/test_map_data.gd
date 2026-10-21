extends GutTest
## Checks the text map files are well-formed and fully explorable.

const MAPS: Array[String] = ["res://data/maps/meadow.txt"]


func test_maps_are_rectangular_and_use_known_characters() -> void:
	for path: String in MAPS:
		var map: MapData = MapData.load_map(path)
		assert_gt(map.width, 0, path)
		for y: int in map.height:
			assert_eq(map.rows[y].length(), map.width, "%s row %d width" % [path, y + 1])
			for x: int in map.width:
				var c: String = map.rows[y][x]
				assert_true(map.ground.has(c), "%s: unknown character '%s' at %d,%d" % [path, c, x, y])


func test_maps_have_one_spawn_on_walkable_ground() -> void:
	for path: String in MAPS:
		var map: MapData = MapData.load_map(path)
		var count: int = 0
		for row: String in map.rows:
			count += row.count(map.spawn_char)
		assert_eq(count, 1, path + " needs exactly one spawn")
		assert_true(map.is_walkable(map.spawn_cell()), path + " spawn must be walkable")


func test_map_edges_are_blocked() -> void:
	for path: String in MAPS:
		var map: MapData = MapData.load_map(path)
		for x: int in map.width:
			assert_false(map.is_walkable(Vector2i(x, 0)), "%s top edge open at %d" % [path, x])
			assert_false(map.is_walkable(Vector2i(x, map.height - 1)), "%s bottom edge open at %d" % [path, x])
		for y: int in map.height:
			assert_false(map.is_walkable(Vector2i(0, y)), "%s left edge open at %d" % [path, y])
			assert_false(map.is_walkable(Vector2i(map.width - 1, y)), "%s right edge open at %d" % [path, y])


func test_every_open_tile_can_be_reached_from_spawn() -> void:
	for path: String in MAPS:
		var map: MapData = MapData.load_map(path)
		var reached: Dictionary = {map.spawn_cell(): true}
		var queue: Array[Vector2i] = [map.spawn_cell()]
		while not queue.is_empty():
			var cell: Vector2i = queue.pop_back()
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var next: Vector2i = cell + step
				if map.is_walkable(next) and not reached.has(next):
					reached[next] = true
					queue.append(next)
		var unreachable: Array[Vector2i] = []
		for y: int in map.height:
			for x: int in map.width:
				if map.is_walkable(Vector2i(x, y)) and not reached.has(Vector2i(x, y)):
					unreachable.append(Vector2i(x, y))
		assert_eq(unreachable, [] as Array[Vector2i], path + " has tiles you can't walk to")


## The pond tiles have no inside-corner pieces, so water areas must be convex:
## wherever two side-by-side neighbors are water, the diagonal between them must be too.
func test_ponds_have_no_inside_corners() -> void:
	var pairs: Array = [[Vector2i.UP, Vector2i.RIGHT], [Vector2i.RIGHT, Vector2i.DOWN], [Vector2i.DOWN, Vector2i.LEFT], [Vector2i.LEFT, Vector2i.UP]]
	for path: String in MAPS:
		var map: MapData = MapData.load_map(path)
		for y: int in map.height:
			for x: int in map.width:
				var cell: Vector2i = Vector2i(x, y)
				if map.ground_at(cell) != "water":
					continue
				for pair: Array in pairs:
					var a: Vector2i = cell + pair[0]
					var b: Vector2i = cell + pair[1]
					if map.ground_at(a) == "water" and map.ground_at(b) == "water":
						assert_eq(map.ground_at(cell + pair[0] + pair[1]), "water", "%s: inside corner near %s" % [path, cell])


func test_lookups() -> void:
	var map: MapData = MapData.load_map(MAPS[0])
	assert_eq(map.char_at(Vector2i(-1, 0)), "")
	assert_eq(map.ground_at(map.find_char("w")), "water")
	assert_false(map.is_walkable(map.find_char("w")))
	assert_true(map.is_walkable(map.find_char("f")), "flowers can be walked over")
	assert_false(map.is_walkable(map.find_char("b")), "bushes block")
	assert_eq(map.cell_to_feet(Vector2i(2, 3)), Vector2(40, 64))
