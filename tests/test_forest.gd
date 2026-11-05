extends GutTest
## The Forest: its gate from the Rescue Center, its animals, and its hidden ball python.

const FOREST: PackedScene = preload("res://scenes/world/forest.tscn")
const HUB: PackedScene = preload("res://scenes/world/rescue_center.tscn")

var forest: HabitatMap


func before_each() -> void:
	GameState.reset()


func _open_forest() -> HabitatMap:
	forest = FOREST.instantiate()
	forest.auto_open_chase = false
	forest.auto_travel = false
	add_child_autofree(forest)
	await wait_physics_frames(2)
	return forest


func test_hub_forest_gate_leads_to_the_forest_and_back() -> void:
	var hub: RescueCenter = HUB.instantiate()
	hub.auto_travel = false
	add_child_autofree(hub)
	await wait_physics_frames(2)
	watch_signals(hub)
	hub.use_gate("2")
	assert_signal_emitted_with_parameters(hub, "gate_used", ["forest", "res://scenes/world/forest.tscn"])
	# Only one map at a time: both maps' walls share the physics world.
	hub.queue_free()
	await wait_frames(2)
	await _open_forest()
	var cell: Vector2i = forest.map.pixel_to_cell(forest.ranger.position - Vector2(0, 1))
	assert_eq(cell, forest.map.arrival_cell("1"), "arrives at the Forest's gate")
	watch_signals(forest)
	forest.arrived_gate = ""
	forest.use_gate("1")
	assert_signal_emitted_with_parameters(forest, "gate_used", ["rescue_center", "res://scenes/world/rescue_center.tscn"])
	assert_eq(GameState.arrival_gate, "2", "back at the hub's Forest gate")


func test_forest_has_deer_bears_and_owls() -> void:
	await _open_forest()
	var kinds: Dictionary = {}
	for critter: Critter in forest.critters:
		kinds[critter.animal["id"]] = true
		assert_eq(str(critter.animal["habitat"]), "forest")
	assert_eq(kinds.keys().size(), 3)
	for id: String in ["deer", "bear", "owl"]:
		assert_true(kinds.has(id), id)


func test_grid_sheet_animals_walk_with_the_right_facing_column() -> void:
	var bear: Dictionary = GameState.catalog.get_animal("bear")
	var frames: SpriteFrames = Critter.build_frames(bear)
	assert_eq(frames.get_frame_count("walk"), 4)
	var first: AtlasTexture = frames.get_frame_texture("walk", 0)
	var second: AtlasTexture = frames.get_frame_texture("walk", 1)
	assert_eq(first.region.position, Vector2(Critter.GRID_RIGHT_COLUMN * 16, 0))
	assert_eq(second.region.position, Vector2(Critter.GRID_RIGHT_COLUMN * 16, 16), "frames go down the column")


func test_ball_python_hides_under_a_forest_rock() -> void:
	await _open_forest()
	assert_gte(forest.rock_cells.size(), 4)
	assert_eq(forest.hidden_snake.get("id", ""), "ball_python")
	assert_has(forest.rock_cells, forest.snake_hunt.hiding_cell())
	forest.peek_rock(forest.snake_hunt.hiding_cell())
	var screen: SnakeScreen = forest.snake_screen
	assert_not_null(screen)
	assert_string_contains(screen.title_label.text, "Ball Python")
	screen.answer(screen.problem.answer)
	screen.finish()
	assert_true(GameState.rescued.has("ball_python"))


func test_forest_animals_can_be_cared_for() -> void:
	for id: String in ["deer", "bear", "owl", "ball_python"]:
		assert_true(GameState.care_catalog.has_animal(id), id)
		assert_eq(GameState.care_catalog.facts_for(id).size(), 4, id)
