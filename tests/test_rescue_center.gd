extends GutTest
## The Rescue Center hub: pens, fence repairs, residents, the sidekick, and gates both ways.

const HUB: PackedScene = preload("res://scenes/world/rescue_center.tscn")
const MEADOW: PackedScene = preload("res://scenes/world/meadow.tscn")
const HABITATS: Array[String] = ["meadow", "forest", "mountains", "swamp", "desert"]

var hub: RescueCenter


func before_each() -> void:
	GameState.reset()
	GameState.read_aloud = false


func _open_hub() -> RescueCenter:
	hub = HUB.instantiate()
	hub.auto_travel = false
	add_child_autofree(hub)
	await wait_physics_frames(2)
	return hub


func _rescue(count: int, habitat_id: String = "meadow") -> void:
	for i: int in count:
		GameState.record_rescue("raccoon", habitat_id, habitat_id, Vector2i(i, 0))


func test_one_pen_per_kind_grouped_by_habitat_all_broken_at_the_start() -> void:
	await _open_hub()
	var kinds_by_habitat: Dictionary = {}
	for pen: Dictionary in hub.pens:
		if not bool(pen.get("special", false)):
			if not kinds_by_habitat.has(pen["habitat"]):
				kinds_by_habitat[pen["habitat"]] = []
			kinds_by_habitat[pen["habitat"]].append(pen["kind"])
		for fence: StaticBody2D in pen["fences"]:
			assert_false(RescueCenter.is_fixed(fence), "%s fence starts knocked over" % pen["habitat"])
		assert_eq(pen["residents"].size(), 0)
	assert_eq(kinds_by_habitat.keys(), HABITATS as Array)
	assert_eq(kinds_by_habitat["meadow"], ["raccoon", "fox", "rabbit"])
	assert_eq(kinds_by_habitat["forest"], ["deer", "bear", "owl"])
	assert_eq(kinds_by_habitat["mountains"], ["mountain_goat", "snow_leopard", "eagle"])
	assert_eq(hub.newly_repaired, 0)
	for a: Dictionary in hub.pens:
		for b: Dictionary in hub.pens:
			if a != b:
				assert_false(RescueCenter.pen_rect(a).grow(-1).intersects(RescueCenter.pen_rect(b)), "pens don't overlap")


func test_each_kind_lives_in_its_own_pen_and_fixes_it_as_they_come_home() -> void:
	# Forest map: 3 deer, 2 bears, 2 owls. Each pen has 4 sections.
	for id: String in ["deer", "deer", "bear"]:
		GameState.record_rescue(id, "forest", "forest")
	await _open_hub()
	assert_eq(hub.pen_for("forest", "deer")["residents"].size(), 2)
	assert_eq(hub.pen_for("forest", "bear")["residents"].size(), 1)
	assert_eq(hub.pen_for("forest", "owl")["residents"].size(), 0)
	assert_eq(RescueCenter.repaired_sections(hub.pen_for("forest", "deer")), 3, "2 of 3 deer: ceil(2 * 4 / 3)")
	assert_eq(RescueCenter.repaired_sections(hub.pen_for("forest", "bear")), 2, "1 of 2 bears: half")
	assert_eq(RescueCenter.repaired_sections(hub.pen_for("forest", "owl")), 0)
	assert_eq(hub.newly_repaired, 5)
	assert_string_contains(hub.banner.text, "You fixed 5 fences at the Forest pens!")
	await _stand_by_pen("forest", "bear")
	assert_true(hub.care_button.visible)
	assert_eq(hub.care_button.text, "Care for the Bear")
	assert_not_null(hub.care_button.icon, "with the bear's face")
	await _stand_by_pen("forest", "owl")
	assert_false(hub.care_button.visible, "no owls home yet")


func test_each_rescue_fixes_one_section_of_its_pen() -> void:
	_rescue(2)
	await _open_hub()
	var pen: Dictionary = hub.pen_for("meadow")
	var fixed: int = 0
	for fence: StaticBody2D in pen["fences"]:
		if RescueCenter.is_fixed(fence):
			fixed += 1
	assert_eq(fixed, 2, "2 of 6 raccoons: ceil(2 * 4 / 6)")
	assert_eq(hub.newly_repaired, 2, "both repairs happen while you watch")
	assert_string_contains(hub.banner.text, "Meadow pens")
	for fence: StaticBody2D in hub.pen_for("forest")["fences"]:
		assert_false(RescueCenter.is_fixed(fence), "other pens stay broken")


func test_repairs_you_already_saw_are_not_shown_again() -> void:
	_rescue(1)
	await _open_hub()
	assert_eq(hub.newly_repaired, 1)
	hub.queue_free()
	await wait_frames(2)
	_rescue(1)
	await _open_hub()
	assert_eq(hub.newly_repaired, 1, "only the new one stands up this time")


func test_pen_can_only_be_fixed_once() -> void:
	_rescue(20)
	await _open_hub()
	assert_eq(RescueCenter.repaired_sections(hub.pen_for("meadow")), RescueCenter.pen_sections(hub.pen_for("meadow")))


func test_rescued_animals_live_in_their_pen() -> void:
	_rescue(3)
	await _open_hub()
	var residents: Array = hub.pen_for("meadow")["residents"]
	assert_eq(residents.size(), 3)
	for resident: Critter in residents:
		assert_null(resident.ranger, "residents never get startled")
	await wait_seconds(1.5)
	var pen: Dictionary = hub.pen_for("meadow")
	var left: float = int(pen["cell"][0]) * 16
	var right: float = left + int(pen["pieces"]) * 3 * 16
	for resident: Critter in residents:
		assert_between(resident.global_position.x, left, right, "stays in the pen")


func test_new_game_starts_by_the_sidekick_who_points_to_the_meadow() -> void:
	await _open_hub()
	assert_eq(hub.map.pixel_to_cell(hub.ranger.position - Vector2(0, 1)), hub.map.spawn_cell())
	assert_false(hub.talk_bubble.visible)
	hub.ranger.global_position = hub.sidekick_sprite.global_position + Vector2(12, 0)
	await wait_frames(2)
	assert_true(hub.talk_bubble.visible)
	assert_string_contains(hub.talk_label.text, "Meadow")


func test_sidekick_cheers_progress_after_rescues() -> void:
	_rescue(4)
	await _open_hub()
	hub.ranger.global_position = hub.sidekick_sprite.global_position + Vector2(12, 0)
	await wait_frames(2)
	assert_string_contains(hub.talk_label.text, "4")


func test_meadow_gate_takes_you_to_the_meadow() -> void:
	await _open_hub()
	watch_signals(hub)
	hub.use_gate("1")
	assert_signal_emitted_with_parameters(hub, "gate_used", ["meadow", "res://scenes/world/meadow.tscn"])
	assert_eq(GameState.arrival_map, "meadow")
	assert_eq(GameState.arrival_gate, "1")


func test_walking_into_the_gate_uses_it() -> void:
	await _open_hub()
	watch_signals(hub)
	var gate_cell: Vector2i = hub.map.gate_cells()["1"]
	hub.ranger.global_position = hub.map.cell_to_feet(gate_cell + Vector2i(2, 0))
	hub.ranger.input_override = Vector2.LEFT
	await wait_physics_frames(60)
	assert_signal_emitted(hub, "gate_used")


func test_every_habitat_gate_is_open_once_the_snakes_are_caught() -> void:
	for snake: String in ["ball_python", "green_anaconda", "rattlesnake"]:
		GameState.rescued.append(snake)
	await _open_hub()
	for gate: String in ["1", "2", "3", "4", "5"]:
		assert_false(hub.gates[gate] is StaticBody2D, "gate %s is open" % gate)
	watch_signals(hub)
	hub.use_gate("5")
	assert_signal_emitted_with_parameters(hub, "gate_used", ["mountains", "res://scenes/world/mountains.tscn"])


func test_arriving_from_the_meadow_puts_you_at_the_west_gate() -> void:
	GameState.travel_to("rescue_center", "1")
	await _open_hub()
	var cell: Vector2i = hub.map.pixel_to_cell(hub.ranger.position - Vector2(0, 1))
	assert_eq(cell, hub.map.arrival_cell("1"))
	assert_eq(GameState.arrival_map, "", "arrival is used up")


func test_holding_the_key_after_arriving_does_not_bounce_you_back() -> void:
	GameState.travel_to("rescue_center", "1")
	await _open_hub()
	watch_signals(hub)
	hub.ranger.input_override = Vector2.LEFT
	await wait_physics_frames(90)
	assert_signal_not_emitted(hub, "gate_used", "the gate you came through waits until you walk away")
	hub.ranger.input_override = Vector2.RIGHT
	await wait_physics_frames(60)
	assert_eq(hub.arrived_gate, "", "walking away turns the gate back on")
	hub.ranger.input_override = Vector2.LEFT
	await wait_physics_frames(120)
	assert_signal_emitted(hub, "gate_used")


## Puts the ranger just below a pen's bottom fence.
func _stand_by_pen(habitat_id: String, kind: String = "") -> void:
	var rect: Rect2 = RescueCenter.pen_rect(hub.pen_for(habitat_id, kind))
	hub.ranger.global_position = Vector2(rect.get_center().x, rect.end.y + 10)
	# Process frames: the hub updates its buttons in _process.
	await wait_process_frames(2)


func test_no_care_button_by_an_empty_pen() -> void:
	await _open_hub()
	await _stand_by_pen("meadow")
	assert_false(hub.care_button.visible)


func test_care_button_by_a_pen_with_animals() -> void:
	_rescue(1)
	await _open_hub()
	assert_false(hub.care_button.visible, "not while far away")
	await _stand_by_pen("meadow")
	assert_true(hub.care_button.visible)
	assert_eq(hub.care_button.text, "Care for the Raccoon")
	await _stand_by_pen("forest")
	assert_false(hub.care_button.visible, "the forest pen is empty")


func test_finishing_care_counts_a_visit_and_makes_the_animal_happy() -> void:
	_rescue(2)
	await _open_hub()
	await _stand_by_pen("meadow")
	hub.open_care(hub.care_target)
	assert_not_null(hub.care_screen)
	assert_eq(hub.objects.process_mode, Node.PROCESS_MODE_DISABLED, "the world waits")
	assert_false(hub.care_button.visible)
	hub.care_screen.finish(true)
	assert_null(hub.care_screen)
	assert_eq(hub.objects.process_mode, Node.PROCESS_MODE_INHERIT)
	assert_eq(GameState.care_visits_for("raccoon"), 1)
	assert_string_contains(hub.banner.text, "happy")
	for resident: Critter in hub.pen_for("meadow")["residents"]:
		assert_true(resident.emote.visible)


func test_care_earns_stars_and_shows_the_level_on_the_pen() -> void:
	_rescue(1)
	await _open_hub()
	assert_eq(hub.pen_for("meadow")["level_label"].text, "Level 1")
	assert_false(hub.pen_for("forest")["level_label"].visible, "empty pens show no level")
	await _stand_by_pen("meadow")
	hub.open_care(hub.care_target)
	hub.care_screen.finish(true)
	assert_eq(GameState.stars, 4)
	assert_string_contains(hub.banner.text, "Level 2!")
	assert_string_contains(hub.banner.text, "+4 stars")
	assert_eq(hub.pen_for("meadow")["level_label"].text, "Level 2")
	assert_string_contains(hub.stars_label.text, "4")


func test_decorate_button_opens_the_shop_and_the_decoration_appears() -> void:
	_rescue(1)
	GameState.add_stars(8, "test")
	await _open_hub()
	await _stand_by_pen("meadow")
	assert_true(hub.decorate_button.visible)
	hub.open_shop(hub.decorate_target)
	assert_not_null(hub.shop_screen)
	assert_eq(hub.objects.process_mode, Node.PROCESS_MODE_DISABLED, "the world waits")
	hub.shop_screen.buy("rock")
	hub.shop_screen.close()
	assert_null(hub.shop_screen)
	assert_not_null(hub.objects.get_node_or_null("Decoration_meadow_raccoon_rock"))
	hub.queue_free()
	await wait_frames(2)
	await _open_hub()
	assert_not_null(hub.objects.get_node_or_null("Decoration_meadow_raccoon_rock"), "still there next visit")


func test_book_opens_and_closes() -> void:
	await _open_hub()
	hub.open_book()
	assert_not_null(hub.book_screen)
	assert_false(hub.book_button.visible)
	hub.book_screen.close()
	assert_null(hub.book_screen)
	assert_true(hub.book_button.visible)


func _special_pen(habitat_id: String) -> Dictionary:
	for pen: Dictionary in hub.pens:
		if pen["habitat"] == habitat_id and bool(pen.get("special", false)):
			return pen
	return {}


func test_every_habitat_row_ends_with_a_special_pen() -> void:
	await _open_hub()
	for habitat_id: String in HABITATS:
		var special: Dictionary = _special_pen(habitat_id)
		assert_false(special.is_empty(), "%s has a special pen" % habitat_id)
		for pen: Dictionary in hub.pens:
			if pen["habitat"] == habitat_id and pen != special:
				assert_eq(RescueCenter.pen_rect(pen).position.y, RescueCenter.pen_rect(special).position.y, "same row")
				assert_lt(RescueCenter.pen_rect(pen).end.x, RescueCenter.pen_rect(special).position.x + 1, "at the end of the row")
		assert_eq(RescueCenter.repaired_sections(special), 0, "broken until its snake is caught")


func test_caught_snake_fixes_its_special_pen_and_lives_there() -> void:
	_rescue(1)
	GameState.record_rescue("green_vine_snake", "meadow", "meadow")
	await _open_hub()
	var special: Dictionary = _special_pen("meadow")
	assert_eq(RescueCenter.repaired_sections(special), RescueCenter.pen_sections(special))
	assert_eq(RescueCenter.repaired_sections(hub.pen_for("meadow")), 1, "the snake doesn't fix a raccoon fence")
	assert_eq(special["residents"].size(), 1)
	assert_eq(str(special["residents"][0].animal["id"]), "green_vine_snake")
	for resident: Critter in hub.pen_for("meadow")["residents"]:
		assert_eq(str(resident.animal["id"]), "raccoon")
	assert_string_contains(hub.banner.text, "Meadow pens")


func test_caring_for_the_snake_is_one_grade_harder() -> void:
	GameState.record_rescue("green_vine_snake", "meadow", "meadow")
	await _open_hub()
	var rect: Rect2 = RescueCenter.pen_rect(_special_pen("meadow"))
	hub.ranger.global_position = Vector2(rect.get_center().x, rect.end.y + 10)
	await wait_process_frames(2)
	assert_eq(hub.care_button.text, "Care for the Green Vine Snake")
	assert_false(hub.decorate_button.visible, "special pens aren't decorated")
	hub.open_care(hub.care_target)
	var visit: CareVisit = hub.care_screen.visit
	assert_eq(visit.spelling.tiles.size(), visit.food_word.length() + 2, "grade 3: two extra letters")
	assert_true(GameState.care_catalog.foods_for("green_vine_snake").has(visit.food_id))
	hub.care_screen.finish(true)
	assert_eq(GameState.care_visits_for("green_vine_snake"), 1)


func test_leaving_care_early_does_not_count() -> void:
	_rescue(1)
	await _open_hub()
	await _stand_by_pen("meadow")
	hub.open_care(hub.care_target)
	hub.care_screen.finish(false)
	assert_eq(GameState.care_visits_for("raccoon"), 0)
	await wait_frames(2)
	assert_true(hub.care_button.visible, "you can try again right away")


func test_meadow_has_a_gate_back_and_remembers_rescues() -> void:
	GameState.travel_to("meadow", "1")
	var meadow: HabitatMap = MEADOW.instantiate()
	meadow.auto_open_chase = false
	meadow.auto_travel = false
	add_child_autofree(meadow)
	await wait_physics_frames(2)
	assert_eq(meadow.map.pixel_to_cell(meadow.ranger.position - Vector2(0, 1)), meadow.map.arrival_cell("1"), "arrives by the east gate")
	var count: int = meadow.critters.size()
	var raccoon: Critter = meadow.critters[0]
	var spot: Vector2i = raccoon.get_meta("spawn_cell")
	meadow.ranger.global_position = raccoon.global_position + Vector2(20, 0)
	await wait_physics_frames(3)
	meadow.open_chase()
	for i: int in 3:
		meadow.chase_screen.answer(meadow.chase_screen.problem.answer, 2.0)
		meadow.chase_screen.next_problem()
	meadow.chase_screen.finish()
	assert_true(GameState.is_spot_rescued("meadow", spot))
	assert_eq(GameState.rescued_count("meadow"), 1)
	assert_string_contains(meadow.banner.text, "safe at the Rescue Center")
	assert_eq(GameState.stars, 4, "3 for the catch + 1 for no misses")
	assert_string_contains(meadow.banner.text, "+4 stars")
	meadow.queue_free()
	await wait_frames(2)
	var again: HabitatMap = MEADOW.instantiate()
	again.auto_open_chase = false
	add_child_autofree(again)
	await wait_physics_frames(2)
	assert_eq(again.critters.size(), count - 1, "the rescued raccoon doesn't come back")
