extends GutTest
## The Swamp: its gate from the Rescue Center, its animals, and its hidden green anaconda.

const SWAMP: PackedScene = preload("res://scenes/world/swamp.tscn")
const HUB: PackedScene = preload("res://scenes/world/rescue_center.tscn")

var swamp: HabitatMap


func before_each() -> void:
	GameState.reset()
	# Earlier habitats' snakes open the way here.
	GameState.rescued.append("ball_python")


func _open_swamp() -> HabitatMap:
	swamp = SWAMP.instantiate()
	swamp.auto_open_chase = false
	swamp.auto_travel = false
	add_child_autofree(swamp)
	await wait_physics_frames(2)
	return swamp


func test_hub_swamp_gate_leads_to_the_swamp_and_back() -> void:
	var hub: RescueCenter = HUB.instantiate()
	hub.auto_travel = false
	add_child_autofree(hub)
	await wait_physics_frames(2)
	watch_signals(hub)
	hub.use_gate("3")
	assert_signal_emitted_with_parameters(hub, "gate_used", ["swamp", "res://scenes/world/swamp.tscn"])
	# Only one map at a time: both maps' walls share the physics world.
	hub.queue_free()
	await wait_frames(2)
	await _open_swamp()
	var cell: Vector2i = swamp.map.pixel_to_cell(swamp.ranger.position - Vector2(0, 1))
	assert_eq(cell, swamp.map.arrival_cell("1"), "arrives at the Swamp's gate")
	watch_signals(swamp)
	swamp.arrived_gate = ""
	swamp.use_gate("1")
	assert_signal_emitted_with_parameters(swamp, "gate_used", ["rescue_center", "res://scenes/world/rescue_center.tscn"])
	assert_eq(GameState.arrival_gate, "3", "back at the hub's Swamp gate")


func test_swamp_has_turtles_frogs_and_alligators() -> void:
	await _open_swamp()
	var kinds: Dictionary = {}
	for critter: Critter in swamp.critters:
		kinds[critter.animal["id"]] = true
		assert_eq(str(critter.animal["habitat"]), "swamp")
	assert_eq(kinds.keys().size(), 3)
	for id: String in ["turtle", "frog", "alligator"]:
		assert_true(kinds.has(id), id)


func test_swamp_animals_practice_place_value() -> void:
	for id: String in ["turtle", "frog", "alligator"]:
		assert_eq(str(GameState.catalog.get_animal(id)["skill"]), "place_value", id)


func test_green_anaconda_hides_under_a_swamp_rock() -> void:
	await _open_swamp()
	assert_gte(swamp.rock_cells.size(), 4)
	assert_eq(swamp.hidden_snake.get("id", ""), "green_anaconda")
	assert_has(swamp.rock_cells, swamp.snake_hunt.hiding_cell())
	swamp.peek_rock(swamp.snake_hunt.hiding_cell())
	var screen: SnakeScreen = swamp.snake_screen
	assert_not_null(screen)
	assert_string_contains(screen.title_label.text, "Green Anaconda")
	screen.answer(screen.problem.answer)
	screen.finish()
	assert_true(GameState.rescued.has("green_anaconda"))


func test_swamp_animals_can_be_cared_for() -> void:
	for id: String in ["turtle", "frog", "alligator", "green_anaconda"]:
		assert_true(GameState.care_catalog.has_animal(id), id)
		assert_eq(GameState.care_catalog.facts_for(id).size(), 4, id)
