extends GutTest
## Critters in the Meadow: wandering, startling when the ranger is near, cooldown.

const SCENE: PackedScene = preload("res://scenes/world/meadow.tscn")

var meadow: HabitatMap
var raccoon: Critter


func before_each() -> void:
	meadow = SCENE.instantiate()
	add_child_autofree(meadow)
	raccoon = meadow.critters[0]
	await wait_physics_frames(2)


func _put_ranger_near(critter: Critter, offset: Vector2) -> void:
	meadow.ranger.global_position = critter.global_position + offset


func test_meadow_spawns_one_critter_per_map_marker() -> void:
	var markers: int = 0
	for row: String in meadow.map.rows:
		markers += row.count("a")
	assert_eq(meadow.critters.size(), markers)
	assert_gt(markers, 0)
	assert_eq(raccoon.animal["id"], "raccoon")
	assert_eq(raccoon.get_parent(), meadow.objects, "critters are y-sorted with trees and the ranger")


func test_critter_wanders_but_stays_near_home() -> void:
	var start: Vector2 = raccoon.global_position
	var radius: float = raccoon.brain.radius
	var moved: bool = false
	for i: int in 8:
		raccoon.time_left = 0.0
		await wait_physics_frames(45)
		moved = moved or raccoon.global_position.distance_to(start) > 4.0
		assert_lte(raccoon.global_position.distance_to(raccoon.brain.home), radius + 8.0)
	assert_true(moved, "raccoon should stroll around")


func test_ranger_coming_close_startles_and_requests_a_chase() -> void:
	watch_signals(raccoon)
	watch_signals(meadow)
	_put_ranger_near(raccoon, Vector2(20, 0))
	await wait_physics_frames(3)
	assert_signal_emitted(raccoon, "startled")
	assert_signal_emitted_with_parameters(meadow, "chase_requested", [raccoon])
	assert_eq(meadow.chase_target, raccoon)
	assert_true(raccoon.emote.visible, "shows the ! bubble")
	assert_true(meadow.banner.visible)
	assert_string_contains(meadow.banner.text, "Raccoon")


func test_far_away_ranger_does_not_startle() -> void:
	watch_signals(raccoon)
	_put_ranger_near(raccoon, Vector2(120, 0))
	await wait_physics_frames(10)
	assert_signal_not_emitted(raccoon, "startled")


func test_startled_critter_darts_away_then_cools_down() -> void:
	watch_signals(raccoon)
	_put_ranger_near(raccoon, Vector2(20, 0))
	var start_x: float = raccoon.global_position.x
	await wait_physics_frames(3)
	assert_eq(raccoon.state, Critter.State.STARTLED)
	await wait_seconds(float(raccoon.animal["startle_seconds"]) + 0.3)
	assert_eq(raccoon.state, Critter.State.FLEE)
	await wait_seconds(float(raccoon.animal["flee_seconds"]))
	assert_lt(raccoon.global_position.x, start_x - 10.0, "fled away from the ranger (who was to the right)")
	assert_false(raccoon.emote.visible)
	assert_gt(raccoon.cooldown_left, 0.0)
	# Still close? Cooldown means no second startle right away.
	_put_ranger_near(raccoon, Vector2(10, 0))
	await wait_physics_frames(5)
	assert_signal_emit_count(raccoon, "startled", 1)


func test_critters_and_ranger_do_not_block_each_other() -> void:
	assert_eq(raccoon.collision_mask & PhysicsLayers.RANGER, 0)
	assert_eq(meadow.ranger.collision_mask & PhysicsLayers.CRITTERS, 0)
	assert_ne(raccoon.collision_mask & PhysicsLayers.WORLD, 0)
