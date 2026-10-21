extends GutTest
## From the Meadow into a chase and back: world freezes, chase opens, a catch rescues the critter.

const SCENE: PackedScene = preload("res://scenes/world/meadow.tscn")

var meadow: HabitatMap
var raccoon: Critter


func before_each() -> void:
	GameState.reset()
	GameState.read_aloud = false
	meadow = SCENE.instantiate()
	meadow.auto_open_chase = false
	add_child_autofree(meadow)
	raccoon = meadow.critters[0]
	await wait_physics_frames(2)
	meadow.ranger.global_position = raccoon.global_position + Vector2(20, 0)
	await wait_physics_frames(3)


func test_startle_freezes_the_world_and_opens_the_chase() -> void:
	assert_eq(meadow.chase_target, raccoon)
	assert_eq(meadow.objects.process_mode, Node.PROCESS_MODE_DISABLED)
	meadow.open_chase()
	assert_not_null(meadow.chase_screen)
	assert_eq(meadow.chase_screen.skill_id, "counting", "raccoon chases use its skill")
	assert_false(meadow.banner.visible)


func test_second_critter_cannot_start_another_chase() -> void:
	var other: Critter = meadow.critters[1]
	meadow._on_critter_startled(other)
	assert_eq(meadow.chase_target, raccoon)


func test_catching_rescues_the_critter_and_unfreezes_the_world() -> void:
	watch_signals(meadow)
	var count: int = meadow.critters.size()
	meadow.open_chase()
	var screen: ChaseScreen = meadow.chase_screen
	for i: int in 3:
		screen.answer(screen.problem.answer, 2.0)
		screen.next_problem()
	screen.finish()
	assert_signal_emitted_with_parameters(meadow, "chase_ended", ["raccoon", true])
	assert_eq(GameState.rescued, ["raccoon"] as Array[String])
	assert_eq(meadow.critters.size(), count - 1)
	assert_null(meadow.chase_target)
	assert_null(meadow.chase_screen)
	assert_eq(meadow.objects.process_mode, Node.PROCESS_MODE_INHERIT)
	await wait_frames(2)
	assert_false(is_instance_valid(raccoon), "caught raccoon leaves the meadow")
