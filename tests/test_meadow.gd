extends GutTest
## The Meadow scene: map building, ranger movement, collisions, and camera.

const SCENE: PackedScene = preload("res://scenes/world/meadow.tscn")
const TILE: int = 16

var meadow: HabitatMap


func before_each() -> void:
	meadow = SCENE.instantiate()
	add_child_autofree(meadow)
	await wait_physics_frames(2)


func _cell_of(node: Node2D) -> Vector2i:
	return Vector2i(floori(node.position.x / TILE), floori((node.position.y - 1) / TILE))


func test_every_cell_gets_a_ground_tile() -> void:
	assert_eq(meadow.ground.get_used_cells().size(), meadow.map.width * meadow.map.height)


func test_objects_are_placed_for_trees_bushes_rocks_flowers() -> void:
	var expected: int = 0
	for row: String in meadow.map.rows:
		for c: String in row:
			if meadow.map.objects.has(c):
				expected += 1
	# +1 for the ranger, who lives in the same y-sorted layer
	assert_eq(meadow.objects.get_child_count(), expected + 1)
	assert_true(meadow.objects.y_sort_enabled)


func test_ranger_starts_at_spawn_with_camera_limited_to_map() -> void:
	assert_eq(_cell_of(meadow.ranger), meadow.map.spawn_cell())
	var camera: Camera2D = meadow.ranger.camera
	assert_eq(camera.limit_right, meadow.map.width * TILE)
	assert_eq(camera.limit_bottom, meadow.map.height * TILE)
	assert_true(camera.is_current() or camera.enabled)


func test_water_tiles_have_collision() -> void:
	var water_cell: Vector2i = meadow.map.find_char("w")
	var data: TileData = meadow.ground.get_cell_tile_data(water_cell)
	assert_not_null(data)
	assert_eq(data.get_collision_polygons_count(HabitatMap.PHYSICS_LAYER), 1)


func test_ranger_walks_with_input() -> void:
	var start: Vector2 = meadow.ranger.position
	meadow.ranger.input_override = Vector2.RIGHT
	await wait_physics_frames(20)
	meadow.ranger.input_override = Vector2.ZERO
	assert_gt(meadow.ranger.position.x, start.x + 10.0)
	assert_eq(meadow.ranger.facing, "right")
	assert_eq(meadow.ranger.sprite.animation, &"walk_right")


func test_ranger_cannot_walk_into_the_pond() -> void:
	# The pond's bottom tip: walk straight up into it from the grass below.
	var pond_bottom: Vector2i = Vector2i(-1, -1)
	for y: int in range(meadow.map.height - 1, -1, -1):
		var x: int = meadow.map.rows[y].find("w")
		if x >= 0:
			pond_bottom = Vector2i(x, y)
			break
	var below: Vector2i = pond_bottom + Vector2i.DOWN
	assert_true(meadow.map.is_walkable(below), "test needs grass under the pond")
	meadow.ranger.position = meadow.map.cell_to_feet(below)
	await wait_physics_frames(2)
	meadow.ranger.input_override = Vector2.UP
	await wait_physics_frames(60)
	meadow.ranger.input_override = Vector2.ZERO
	assert_gt(meadow.ranger.position.y, float((pond_bottom.y + 1) * TILE) - 1.0, "stopped at the shore")


func test_click_to_move_walks_to_the_spot_and_stops() -> void:
	var goal: Vector2 = meadow.ranger.position + Vector2(-48, 0)
	meadow.ranger.walk_to(goal)
	await wait_physics_frames(90)
	assert_false(meadow.ranger.has_target, "should arrive and stop")
	assert_almost_eq(meadow.ranger.position.x, goal.x, 3.0)
	assert_eq(meadow.ranger.sprite.animation, &"idle_left")


func test_click_walking_gives_up_when_blocked() -> void:
	var water_feet: Vector2 = meadow.map.cell_to_feet(meadow.map.find_char("w")) + Vector2(0, -8)
	meadow.ranger.walk_to(water_feet)
	await wait_physics_frames(400)
	assert_false(meadow.ranger.has_target, "should stop trying once stuck")


func test_input_actions_exist_for_arrows_and_wasd() -> void:
	for action: String in ["move_up", "move_down", "move_left", "move_right"]:
		assert_true(InputMap.has_action(action), action)
		assert_eq(InputMap.action_get_events(action).size(), 2, action + " should have arrow + WASD")
