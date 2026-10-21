extends GutTest
## Checks the text map files are well-formed and fully explorable.

const MAPS: Array[String] = ["res://data/maps/meadow.txt", "res://data/maps/rescue_center.txt"]


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


func test_map_edges_are_blocked_except_at_gates() -> void:
	for path: String in MAPS:
		var map: MapData = MapData.load_map(path)
		for y: int in map.height:
			for x: int in map.width:
				var cell: Vector2i = Vector2i(x, y)
				var on_edge: bool = x == 0 or y == 0 or x == map.width - 1 or y == map.height - 1
				if on_edge and not map.is_gate(cell):
					assert_false(map.is_walkable(cell), "%s edge open at %s" % [path, cell])


func test_gates_are_on_the_edge_and_lead_somewhere_real() -> void:
	var world: Dictionary = GameState.load_world()
	for path: String in MAPS:
		var map: MapData = MapData.load_map(path)
		assert_ne(map.id(), "", path + " needs an info file with an id")
		assert_true(world["maps"].has(map.id()), path + " is listed in world.json")
		var gates: Dictionary = map.gate_cells()
		for gate: String in gates:
			var cell: Vector2i = gates[gate]
			assert_true(cell.x == 0 or cell.y == 0 or cell.x == map.width - 1 or cell.y == map.height - 1, "%s gate %s on the edge" % [path, gate])
			assert_true(map.is_walkable(map.arrival_cell(gate)), "%s gate %s arrival spot is open" % [path, gate])
			var info: Dictionary = map.gate_info(gate)
			assert_false(info.is_empty(), "%s gate %s is described in the info file" % [path, gate])
			var to: String = str(info.get("to", ""))
			if world["maps"].has(to):
				var target: MapData = MapData.load_map("res://data/maps/%s.txt" % to)
				var back: String = str(info.get("arrive", ""))
				assert_true(target.gate_cells().has(back), "%s gate %s arrives at %s gate %s" % [path, gate, to, back])
			else:
				assert_true(bool(info.get("locked", false)), "%s gate %s leads to unbuilt %s, so it must be locked" % [path, gate, to])


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
