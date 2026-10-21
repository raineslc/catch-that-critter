extends GutTest


func test_every_neighbor_combination_has_a_unique_piece() -> void:
	assert_eq(EdgeTiles.OFFSETS.size(), 16)
	var seen: Dictionary = {}
	for mask: int in 16:
		assert_true(EdgeTiles.OFFSETS.has(mask), "missing mask %d" % mask)
		var offset: Vector2i = EdgeTiles.OFFSETS[mask]
		assert_between(offset.x, 0, 3)
		assert_between(offset.y, 0, 3)
		seen[offset] = true
	assert_eq(seen.size(), 16, "each combination should use a different tile")


func test_known_pieces() -> void:
	var all: int = EdgeTiles.N | EdgeTiles.E | EdgeTiles.S | EdgeTiles.W
	assert_eq(EdgeTiles.atlas_coords(Vector2i(0, 7), all), Vector2i(1, 8), "center")
	assert_eq(EdgeTiles.atlas_coords(Vector2i(0, 7), EdgeTiles.S | EdgeTiles.E), Vector2i(0, 7), "top-left corner")
	assert_eq(EdgeTiles.atlas_coords(Vector2i(0, 7), 0), Vector2i(3, 10), "single piece")
	assert_eq(EdgeTiles.atlas_coords(Vector2i(0, 6), EdgeTiles.E | EdgeTiles.W), Vector2i(1, 9), "horizontal strip")


func test_neighbor_mask_reads_a_grid() -> void:
	var grid: Array[String] = [
		".p.",
		"ppp",
		"...",
	]
	var is_path: Callable = func(c: Vector2i) -> bool:
		return c.y >= 0 and c.y < grid.size() and c.x >= 0 and c.x < grid[c.y].length() and grid[c.y][c.x] == "p"
	assert_eq(EdgeTiles.neighbor_mask(is_path, Vector2i(1, 1)), EdgeTiles.N | EdgeTiles.E | EdgeTiles.W)
	assert_eq(EdgeTiles.neighbor_mask(is_path, Vector2i(0, 1)), EdgeTiles.E)
	assert_eq(EdgeTiles.neighbor_mask(is_path, Vector2i(1, 0)), EdgeTiles.S)
