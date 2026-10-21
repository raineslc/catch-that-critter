extends GutTest
## Playtest mode: the add/subtract-to-12 skill, raccoons coming back, and the answer log.

const LOG_DIR: String = "user://test_playtest_logs"
const SAMPLES_PER_LEVEL: int = 300
const MAX_NUMBER: int = 12

var config: Dictionary


func before_each() -> void:
	GameState.reset()
	GameState.read_aloud = false
	config = GameState.load_playtest_config()


func after_each() -> void:
	GameState.reset()
	for file: String in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute(LOG_DIR.path_join(file))


func _numbers_in(text: String) -> Array[int]:
	var found: Array[int] = []
	var regex: RegEx = RegEx.new()
	regex.compile("\\d+")
	for m: RegExMatch in regex.search_all(text):
		found.append(int(m.get_string()))
	return found


func test_playtest_skill_only_uses_numbers_up_to_12() -> void:
	var factory: ProblemFactory = ProblemFactory.new()
	factory.add_skill(config["skill"])
	var id: String = str(config["skill"]["id"])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 12
	for level: int in range(1, factory.level_count(id) + 1):
		var info: Dictionary = factory.level_info(id, level)
		for i: int in SAMPLES_PER_LEVEL:
			var p: MathProblem = factory.generate(id, level, rng)
			var label: String = "level %d: %s %s" % [level, p.prompt, p.choices]
			assert_has(["add", "subtract", "missing_addend"], p.type, label)
			for n: int in _numbers_in(p.prompt):
				assert_lte(n, MAX_NUMBER, label)
			for choice: String in p.choices:
				assert_lte(int(choice), MAX_NUMBER, label)
				assert_gte(int(choice), 0, label)
			assert_has(p.choices, p.answer, label)
			assert_eq(p.choices.size(), int(info["choices"]), label)


func test_playtest_skill_has_hints_for_every_level() -> void:
	var factory: ProblemFactory = ProblemFactory.new()
	factory.add_skill(config["skill"])
	var id: String = str(config["skill"]["id"])
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	for level: int in range(1, factory.level_count(id) + 1):
		var p: MathProblem = factory.generate(id, level, rng)
		assert_ne(HintPicture.kind_for(p), "", "level %d hint picture" % level)


func test_enable_playtest_switches_chases_to_the_playtest_skill() -> void:
	assert_false(GameState.is_playtest())
	assert_eq(GameState.chase_skill_for(GameState.catalog.get_animal("raccoon")), "counting")
	GameState.enable_playtest(config, LOG_DIR)
	assert_true(GameState.is_playtest())
	assert_eq(GameState.chase_skill_for(GameState.catalog.get_animal("raccoon")), "playtest_add_sub_12")
	assert_true(GameState.engine.has_skill("playtest_add_sub_12"))
	assert_gt(GameState.respawn_seconds(), 0.0)


func test_log_records_the_session_answers_and_summary() -> void:
	GameState.enable_playtest(config, LOG_DIR)
	var screen: ChaseScreen = ChaseScreen.new()
	screen.auto_advance = false
	add_child_autofree(screen)
	screen.start(GameState.catalog.get_animal("raccoon"), GameState.playtest_skill())
	var wrong: String = ""
	for c: String in screen.problem.choices:
		if c != screen.problem.answer:
			wrong = c
	screen.answer(wrong, 4.0)
	screen.answer(screen.problem.answer, 2.0)
	GameState.end_playtest_log()
	var path: String = ""
	for file: String in DirAccess.get_files_at(LOG_DIR):
		path = LOG_DIR.path_join(file)
	var events: Array = []
	for line: String in FileAccess.get_file_as_string(path).split("\n", false):
		events.append(JSON.parse_string(line))
	var kinds: Array = events.map(func(e: Dictionary) -> String: return e["event"])
	assert_eq(kinds[0], "session_start")
	assert_eq(kinds[kinds.size() - 1], "session_end")
	var answers: Array = events.filter(func(e: Dictionary) -> bool: return e["event"] == "answer")
	assert_eq(answers.size(), 2)
	assert_eq(answers[0]["first_try"], true)
	assert_eq(answers[0]["correct"], false)
	assert_eq(answers[1]["first_try"], false)
	assert_eq(answers[1]["correct"], true)
	assert_eq(answers[0]["seconds"], 4.0)


func test_caught_raccoons_come_back_in_playtests() -> void:
	var playtest: Dictionary = config.duplicate(true)
	playtest["respawn_seconds"] = 0.3
	playtest["log"] = false
	GameState.enable_playtest(playtest)
	var meadow: HabitatMap = preload("res://scenes/world/meadow.tscn").instantiate()
	meadow.auto_open_chase = false
	add_child_autofree(meadow)
	await wait_physics_frames(2)
	var count: int = meadow.critters.size()
	var raccoon: Critter = meadow.critters[0]
	var spot: Vector2 = raccoon.spawn_point
	meadow.ranger.global_position = raccoon.global_position + Vector2(20, 0)
	await wait_physics_frames(3)
	meadow.open_chase()
	var screen: ChaseScreen = meadow.chase_screen
	for i: int in 3:
		screen.answer(screen.problem.answer, 2.0)
		screen.next_problem()
	screen.finish()
	assert_eq(meadow.critters.size(), count - 1)
	meadow.ranger.global_position = spot + Vector2(200, 0)
	await wait_seconds(0.6)
	assert_eq(meadow.critters.size(), count, "raccoon came back")
	assert_eq(meadow.critters[meadow.critters.size() - 1].spawn_point, spot)


func test_no_respawn_outside_playtests() -> void:
	assert_eq(GameState.respawn_seconds(), 0.0)


func test_meadow_has_enough_raccoons_for_a_playtest() -> void:
	var map: MapData = MapData.load_map("res://data/maps/meadow.txt")
	var count: int = 0
	for row: String in map.rows:
		count += row.count("a")
	assert_gte(count, 6)
