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


func test_one_pen_per_habitat_all_broken_at_the_start() -> void:
	await _open_hub()
	var names: Array[String] = []
	for pen: Dictionary in hub.pens:
		names.append(str(pen["habitat"]))
		for fence: StaticBody2D in pen["fences"]:
			assert_false(RescueCenter.is_fixed(fence), "%s fence starts knocked over" % pen["habitat"])
		assert_eq(pen["residents"].size(), 0)
	assert_eq(names, HABITATS)
	assert_eq(hub.newly_repaired, 0)


func test_each_rescue_fixes_one_section_of_its_pen() -> void:
	_rescue(2)
	await _open_hub()
	var pen: Dictionary = hub.pen_for("meadow")
	var fixed: int = 0
	for fence: StaticBody2D in pen["fences"]:
		if RescueCenter.is_fixed(fence):
			fixed += 1
	assert_eq(fixed, 2)
	assert_eq(hub.newly_repaired, 2, "both repairs happen while you watch")
	assert_string_contains(hub.banner.text, "Meadow pen: 2 of 6")
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


func test_unbuilt_habitats_are_locked_and_say_so() -> void:
	await _open_hub()
	watch_signals(hub)
	for gate: String in ["2", "3", "4", "5"]:
		assert_true(hub.gates[gate] is StaticBody2D, "gate %s is fenced off" % gate)
		hub.use_gate(gate)
	assert_signal_not_emitted(hub, "gate_used")
	assert_string_contains(hub.banner.text, "opens soon")


func test_arriving_from_the_meadow_puts_you_at_the_west_gate() -> void:
	GameState.travel_to("rescue_center", "1")
	await _open_hub()
	var cell: Vector2i = hub.map.pixel_to_cell(hub.ranger.position - Vector2(0, 1))
	assert_eq(cell, hub.map.arrival_cell("1"))
	assert_eq(GameState.arrival_map, "", "arrival is used up")


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
	meadow.queue_free()
	await wait_frames(2)
	var again: HabitatMap = MEADOW.instantiate()
	again.auto_open_chase = false
	add_child_autofree(again)
	await wait_physics_frames(2)
	assert_eq(again.critters.size(), count - 1, "the rescued raccoon doesn't come back")
