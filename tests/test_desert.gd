extends GutTest
## The Desert: its gate from the Rescue Center, its animals, and its hidden rattlesnake.

const DESERT: PackedScene = preload("res://scenes/world/desert.tscn")
const HUB: PackedScene = preload("res://scenes/world/rescue_center.tscn")

var desert: HabitatMap


func before_each() -> void:
	GameState.reset()
	# Earlier habitats' snakes open the way here.
	GameState.rescued.append("ball_python")
	GameState.rescued.append("green_anaconda")


func _open_desert() -> HabitatMap:
	desert = DESERT.instantiate()
	desert.auto_open_chase = false
	desert.auto_travel = false
	add_child_autofree(desert)
	await wait_physics_frames(2)
	return desert


func test_hub_desert_gate_leads_to_the_desert_and_back() -> void:
	var hub: RescueCenter = HUB.instantiate()
	hub.auto_travel = false
	add_child_autofree(hub)
	await wait_physics_frames(2)
	watch_signals(hub)
	hub.use_gate("4")
	assert_signal_emitted_with_parameters(hub, "gate_used", ["desert", "res://scenes/world/desert.tscn"])
	# Only one map at a time: both maps' walls share the physics world.
	hub.queue_free()
	await wait_frames(2)
	await _open_desert()
	var cell: Vector2i = desert.map.pixel_to_cell(desert.ranger.position - Vector2(0, 1))
	assert_eq(cell, desert.map.arrival_cell("1"), "arrives at the Desert's gate")
	watch_signals(desert)
	desert.arrived_gate = ""
	desert.use_gate("1")
	assert_signal_emitted_with_parameters(desert, "gate_used", ["rescue_center", "res://scenes/world/rescue_center.tscn"])
	assert_eq(GameState.arrival_gate, "4", "back at the hub's Desert gate")


func test_desert_has_lizards_tortoises_and_roadrunners() -> void:
	await _open_desert()
	var kinds: Dictionary = {}
	for critter: Critter in desert.critters:
		kinds[critter.animal["id"]] = true
		assert_eq(str(critter.animal["habitat"]), "desert")
	assert_eq(kinds.keys().size(), 3)
	for id: String in ["lizard", "tortoise", "roadrunner"]:
		assert_true(kinds.has(id), id)


func test_desert_animals_practice_time_and_money() -> void:
	for id: String in ["lizard", "tortoise", "roadrunner"]:
		assert_eq(str(GameState.catalog.get_animal(id)["skill"]), "time_money", id)


func test_rattlesnake_hides_under_a_desert_rock() -> void:
	await _open_desert()
	assert_gte(desert.rock_cells.size(), 4)
	assert_eq(desert.hidden_snake.get("id", ""), "rattlesnake")
	assert_has(desert.rock_cells, desert.snake_hunt.hiding_cell())
	desert.peek_rock(desert.snake_hunt.hiding_cell())
	var screen: SnakeScreen = desert.snake_screen
	assert_not_null(screen)
	assert_string_contains(screen.title_label.text, "Rattlesnake")
	screen.answer(screen.problem.answer)
	screen.finish()
	assert_true(GameState.rescued.has("rattlesnake"))


func test_desert_animals_can_be_cared_for() -> void:
	for id: String in ["lizard", "tortoise", "roadrunner", "rattlesnake"]:
		assert_true(GameState.care_catalog.has_animal(id), id)
		assert_eq(GameState.care_catalog.facts_for(id).size(), 4, id)
