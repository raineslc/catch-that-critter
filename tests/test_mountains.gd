extends GutTest
## The Mountains: its gate from the Rescue Center, its animals, and its hidden king cobra.

const MOUNTAINS: PackedScene = preload("res://scenes/world/mountains.tscn")
const HUB: PackedScene = preload("res://scenes/world/rescue_center.tscn")

var mountains: HabitatMap


func before_each() -> void:
	GameState.reset()
	# Earlier habitats' snakes open the way here.
	GameState.rescued.append("ball_python")
	GameState.rescued.append("green_anaconda")
	GameState.rescued.append("rattlesnake")


func _open_mountains() -> HabitatMap:
	mountains = MOUNTAINS.instantiate()
	mountains.auto_open_chase = false
	mountains.auto_travel = false
	add_child_autofree(mountains)
	await wait_physics_frames(2)
	return mountains


func test_hub_mountains_gate_leads_to_the_mountains_and_back() -> void:
	var hub: RescueCenter = HUB.instantiate()
	hub.auto_travel = false
	add_child_autofree(hub)
	await wait_physics_frames(2)
	watch_signals(hub)
	hub.use_gate("5")
	assert_signal_emitted_with_parameters(hub, "gate_used", ["mountains", "res://scenes/world/mountains.tscn"])
	# Only one map at a time: both maps' walls share the physics world.
	hub.queue_free()
	await wait_frames(2)
	await _open_mountains()
	var cell: Vector2i = mountains.map.pixel_to_cell(mountains.ranger.position - Vector2(0, 1))
	assert_eq(cell, mountains.map.arrival_cell("1"), "arrives at the Mountains gate")
	watch_signals(mountains)
	mountains.arrived_gate = ""
	mountains.use_gate("1")
	assert_signal_emitted_with_parameters(mountains, "gate_used", ["rescue_center", "res://scenes/world/rescue_center.tscn"])
	assert_eq(GameState.arrival_gate, "5", "back at the hub's Mountains gate")


func test_mountains_has_goats_snow_leopards_and_eagles() -> void:
	await _open_mountains()
	var kinds: Dictionary = {}
	for critter: Critter in mountains.critters:
		kinds[critter.animal["id"]] = true
		assert_eq(str(critter.animal["habitat"]), "mountains")
	assert_eq(kinds.keys().size(), 3)
	for id: String in ["mountain_goat", "snow_leopard", "eagle"]:
		assert_true(kinds.has(id), id)


func test_mountains_animals_practice_multiplying_and_dividing() -> void:
	for id: String in ["mountain_goat", "snow_leopard", "eagle"]:
		assert_eq(str(GameState.catalog.get_animal(id)["skill"]), "multiply_divide", id)


func test_king_cobra_hides_under_a_mountains_rock() -> void:
	await _open_mountains()
	assert_gte(mountains.rock_cells.size(), 4)
	assert_eq(mountains.hidden_snake.get("id", ""), "king_cobra")
	assert_has(mountains.rock_cells, mountains.snake_hunt.hiding_cell())
	mountains.peek_rock(mountains.snake_hunt.hiding_cell())
	var screen: SnakeScreen = mountains.snake_screen
	assert_not_null(screen)
	assert_string_contains(screen.title_label.text, "King Cobra")
	screen.answer(screen.problem.answer)
	screen.finish()
	assert_true(GameState.rescued.has("king_cobra"))


func test_mountains_animals_can_be_cared_for() -> void:
	for id: String in ["mountain_goat", "snow_leopard", "eagle", "king_cobra"]:
		assert_true(GameState.care_catalog.has_animal(id), id)
		assert_eq(GameState.care_catalog.facts_for(id).size(), 4, id)
