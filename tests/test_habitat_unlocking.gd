extends GutTest
## Habitat unlocking (PLAN 3.4, Chris 2026-11-05): the Meadow and Forest start open; each
## habitat's hidden snake opens the next one (Forest → Swamp → Desert → Mountains).

const HUB: PackedScene = preload("res://scenes/world/rescue_center.tscn")
const FOREST: PackedScene = preload("res://scenes/world/forest.tscn")


func before_each() -> void:
	GameState.reset()


func test_meadow_and_forest_start_open() -> void:
	for area: String in ["rescue_center", "meadow", "forest"]:
		assert_true(GameState.is_area_open(area), area)
	for area: String in ["swamp", "desert", "mountains"]:
		assert_false(GameState.is_area_open(area), area)
	assert_eq(GameState.travel_to("swamp", "1"), "", "can't travel into a closed habitat")


func test_each_snake_opens_the_next_habitat() -> void:
	GameState.rescued.append("ball_python")
	assert_true(GameState.is_area_open("swamp"))
	assert_false(GameState.is_area_open("desert"))
	GameState.rescued.append("green_anaconda")
	assert_true(GameState.is_area_open("desert"))
	assert_false(GameState.is_area_open("mountains"))
	GameState.rescued.append("rattlesnake")
	assert_true(GameState.is_area_open("mountains"))


func test_chain_lookups() -> void:
	assert_eq(GameState.hidden_snake_id("forest"), "ball_python")
	assert_eq(GameState.area_opened_by("forest"), "swamp")
	assert_eq(GameState.area_opened_by("mountains"), "", "the last snake opens nothing")
	assert_eq(GameState.opens_after("meadow"), "")


func test_closed_gate_is_fenced_and_says_which_snake_to_find() -> void:
	var hub: RescueCenter = HUB.instantiate()
	hub.auto_travel = false
	add_child_autofree(hub)
	await wait_physics_frames(2)
	assert_true(hub.gates["3"] is StaticBody2D, "Swamp gate is fenced")
	assert_false(hub.gates["2"] is StaticBody2D, "Forest gate is open")
	watch_signals(hub)
	hub.use_gate("3")
	assert_signal_not_emitted(hub, "gate_used")


func test_catching_the_forest_snake_says_the_swamp_is_open() -> void:
	var forest: HabitatMap = FOREST.instantiate()
	forest.auto_open_chase = false
	forest.auto_travel = false
	add_child_autofree(forest)
	await wait_physics_frames(2)
	forest.peek_rock(forest.snake_hunt.hiding_cell())
	forest.snake_screen.answer(forest.snake_screen.problem.answer)
	forest.snake_screen.finish()
	assert_true(GameState.is_area_open("swamp"))
	assert_string_contains(forest.banner.text, "The Swamp is open now!")
