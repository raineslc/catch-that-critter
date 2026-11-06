extends GutTest
## Runaways (Playthrough fixes step 5): once a habitat's animals are all home, a few slip out again
## on later visits. Catching one gives stars and practice but is not a new rescue.

const MEADOW: PackedScene = preload("res://scenes/world/meadow.tscn")

var meadow: HabitatMap


func before_each() -> void:
	GameState.reset()
	GameState.read_aloud = false


func _rescue_every_spot() -> void:
	var map: MapData = MapData.load_map("res://data/maps/meadow.txt")
	for cell: Vector2i in map.critter_spots():
		GameState.record_rescue(map.critter_at(cell), "meadow", "meadow", cell)


func _open_meadow() -> HabitatMap:
	meadow = MEADOW.instantiate()
	meadow.auto_open_chase = false
	meadow.auto_travel = false
	add_child_autofree(meadow)
	await wait_physics_frames(2)
	return meadow


func test_no_runaways_until_every_animal_is_home() -> void:
	await _open_meadow()
	assert_false(meadow.is_cleared())
	var count: int = meadow.critters.size()
	meadow.release_runaways()
	assert_eq(meadow.critters.size(), count, "nobody slips out of a habitat with animals still out")


func test_cleared_habitat_lets_a_few_rescued_animals_slip_out() -> void:
	_rescue_every_spot()
	await _open_meadow()
	assert_true(meadow.is_cleared())
	assert_eq(meadow.critters.size(), 0, "all home when he arrives")
	meadow.release_runaways()
	var expected: int = int(ChaseState.load_config()["runaways_per_visit"])
	assert_eq(meadow.critters.size(), expected)
	for critter: Critter in meadow.critters:
		assert_true(critter.get_meta("runaway", false))
		assert_true(GameState.rescued.has(str(critter.animal["id"])), "only animals he rescued slip out")
	assert_true(meadow.banner.visible)
	meadow.release_runaways()
	assert_eq(meadow.critters.size(), expected, "once per visit")


func test_catching_a_runaway_gives_stars_but_is_not_a_new_rescue() -> void:
	_rescue_every_spot()
	await _open_meadow()
	meadow.release_runaways()
	var runaway: Critter = meadow.critters[0]
	var rescues: int = GameState.rescued_count()
	meadow.ranger.global_position = runaway.global_position + Vector2(20, 0)
	meadow._on_critter_startled(runaway)
	meadow.open_chase()
	var screen: ChaseScreen = meadow.chase_screen
	for i: int in 3:
		screen.answer(screen.problem.answer, 2.0)
		screen.next_problem()
	screen.finish()
	assert_eq(GameState.rescued_count(), rescues, "Book, fence, and finale counts don't change")
	assert_eq(GameState.stars, GameState.rewards.catch_stars(0), "stars like any catch")
	assert_gt(GameState.engine.stats(screen.skill_id)["answers"], 0, "the answers count as practice")
	assert_false(meadow.critters.has(runaway))
	assert_string_contains(meadow.banner.text, "back home")


func test_no_runaways_in_playtests_where_animals_already_come_back() -> void:
	_rescue_every_spot()
	GameState.playtest = {"respawn_seconds": 5.0}
	await _open_meadow()
	var count: int = meadow.critters.size()
	meadow.release_runaways()
	assert_eq(meadow.critters.size(), count, "no extra runaways on top of playtest respawns")
