extends GutTest
## The finale (Chris 2026-11-05): all five snakes home plus at least 6 other animals from
## each habitat. It plays once at the Rescue Center.

const HUB: PackedScene = preload("res://scenes/world/rescue_center.tscn")
const CRITTERS: Dictionary = {"meadow": "raccoon", "forest": "deer", "swamp": "turtle", "desert": "lizard", "mountains": "mountain_goat"}


func before_each() -> void:
	GameState.reset()


func _rescue_everyone(per_habitat: int) -> void:
	for habitat: String in CRITTERS:
		GameState.record_rescue(GameState.hidden_snake_id(habitat), habitat, habitat)
		for i: int in per_habitat:
			GameState.record_rescue(CRITTERS[habitat], habitat, habitat)


func _open_hub() -> RescueCenter:
	var hub: RescueCenter = HUB.instantiate()
	hub.auto_travel = false
	add_child_autofree(hub)
	await wait_physics_frames(2)
	return hub


func test_not_ready_at_the_start() -> void:
	assert_false(GameState.finale_ready())


func test_needs_six_animals_from_every_habitat() -> void:
	_rescue_everyone(5)
	assert_eq(GameState.critters_home("forest"), 5, "the snake doesn't count")
	assert_false(GameState.finale_ready(), "5 each isn't enough")
	GameState.record_rescue("deer", "forest", "forest")
	assert_false(GameState.finale_ready(), "every habitat needs 6")
	_rescue_everyone(1)
	assert_true(GameState.finale_ready())


func test_needs_every_snake() -> void:
	for habitat: String in CRITTERS:
		for i: int in 6:
			GameState.record_rescue(CRITTERS[habitat], habitat, habitat)
	assert_false(GameState.finale_ready(), "no snakes yet")


func test_hub_plays_the_finale_once() -> void:
	_rescue_everyone(6)
	var hub: RescueCenter = await _open_hub()
	assert_not_null(hub.finale_screen, "finale shows at the hub")
	assert_true(hub.screen_open())
	assert_eq(hub.finale_screen.faces.size(), 5 + CRITTERS.size(), "one face per kind rescued")
	hub.finale_screen.close()
	await wait_frames(2)
	assert_null(hub.finale_screen)
	assert_true(GameState.finale_seen)
	hub.show_finale_if_ready()
	assert_null(hub.finale_screen, "only once")


func test_no_finale_before_everyone_is_home() -> void:
	_rescue_everyone(2)
	var hub: RescueCenter = await _open_hub()
	assert_null(hub.finale_screen)


func test_finale_seen_is_saved_and_optional() -> void:
	GameState.finale_seen = true
	var data: Dictionary = GameState.snapshot()
	assert_true(ProfileStore.valid(data))
	data.erase("finale_seen")
	assert_true(ProfileStore.valid(data), "older saves without it still load")
	data["finale_seen"] = "yes"
	assert_false(ProfileStore.valid(data))
