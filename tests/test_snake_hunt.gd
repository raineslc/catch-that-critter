extends GutTest
## The hidden snakes: rock rules, story problems, and finding/catching one in the Meadow.

const MEADOW: PackedScene = preload("res://scenes/world/meadow.tscn")
const ROCKS: Array[Vector2i] = [Vector2i(2, 2), Vector2i(10, 2), Vector2i(2, 10), Vector2i(10, 10)]
const UNKIND_WORDS: Array[String] = ["wrong", "bad", "fail"]

var rng: RandomNumberGenerator
var meadow: HabitatMap


func before_each() -> void:
	GameState.reset()
	rng = RandomNumberGenerator.new()
	rng.seed = 5


func test_one_rock_hides_the_snake() -> void:
	var hunt: SnakeHunt = SnakeHunt.new(ROCKS, rng)
	assert_has(ROCKS, hunt.hiding_cell())
	for cell: Vector2i in ROCKS:
		var expected: SnakeHunt.Peek = SnakeHunt.Peek.FOUND if cell == hunt.hiding_cell() else SnakeHunt.Peek.EMPTY
		assert_eq(hunt.peek(cell), expected)


func test_clue_after_three_different_empty_rocks() -> void:
	var hunt: SnakeHunt = SnakeHunt.new(ROCKS, rng)
	var empty: Array[Vector2i] = []
	for cell: Vector2i in ROCKS:
		if cell != hunt.hiding_cell():
			empty.append(cell)
	hunt.peek(empty[0])
	hunt.peek(empty[0])
	assert_false(hunt.wants_clue(), "the same rock twice counts once")
	hunt.peek(empty[1])
	assert_false(hunt.wants_clue())
	hunt.peek(empty[2])
	assert_true(hunt.wants_clue())


func test_missed_snake_moves_to_a_different_rock() -> void:
	for seed: int in 40:
		rng.seed = seed
		var hunt: SnakeHunt = SnakeHunt.new(ROCKS, rng)
		var before: Vector2i = hunt.hiding_cell()
		hunt.peek(ROCKS[0])
		hunt.move(rng)
		assert_ne(hunt.hiding_cell(), before)
		assert_has(ROCKS, hunt.hiding_cell())
		assert_true(hunt.peeked.is_empty(), "peeking starts fresh")


func test_clue_points_toward_the_snake() -> void:
	var hunt: SnakeHunt = SnakeHunt.new([Vector2i(10, 5)] as Array[Vector2i], rng)
	assert_eq(hunt.direction_from(Vector2i(2, 5)), "right")
	assert_eq(hunt.direction_from(Vector2i(15, 6)), "left")
	assert_eq(hunt.direction_from(Vector2i(10, 0)), "down")
	assert_eq(hunt.direction_from(Vector2i(9, 20)), "up")


func test_snake_level_is_one_harder_but_not_past_the_end() -> void:
	assert_eq(WordProblem.snake_level(2, 6), 3)
	assert_eq(WordProblem.snake_level(6, 6), 6)
	assert_eq(WordProblem.snake_level(0, 6), 1)


func test_every_snake_asks_its_habitats_skill() -> void:
	var skills: Dictionary = {}
	var snakes: Array[Dictionary] = []
	for id: String in GameState.catalog.ids():
		var animal: Dictionary = GameState.catalog.get_animal(id)
		if animal.get("hides_under_rocks", false):
			snakes.append(animal)
		else:
			skills[animal["habitat"]] = animal["skill"]
	assert_eq(snakes.size(), 5)
	for snake: Dictionary in snakes:
		assert_eq(snake["skill"], skills[snake["habitat"]], "%s asks its habitat's skill" % snake["id"])


func test_every_skill_and_level_has_a_story_with_the_right_answer() -> void:
	var factory: ProblemFactory = ProblemFactory.new()
	var stories: WordProblem = WordProblem.new()
	for skill: String in ["counting", "add_subtract", "place_value", "time_money", "multiply_divide"]:
		for level: int in range(1, factory.level_count(skill) + 1):
			for seed: int in 30:
				rng.seed = seed
				var problem: MathProblem = stories.make(factory, skill, level, "Green Vine Snake", rng)
				var where: String = "%s level %d seed %d" % [skill, level, seed]
				assert_not_null(problem, where + " has a story")
				if problem == null:
					continue
				assert_false(problem.prompt.contains("{"), "all blanks filled: " + problem.prompt)
				assert_eq(problem.spoken, problem.prompt)
				assert_true(problem.choices.has(problem.answer), where)
				assert_true(problem.type.begins_with("word_"), where)
				var expected: Variant = _story_answer(problem)
				if expected != null:
					assert_eq(problem.answer, str(expected), problem.prompt)
				for noun: String in _story_nouns():
					for small: String in ["0 ", "1 "]:
						assert_false((" " + problem.prompt + " ").contains(" " + small + noun + " "), "stories count 2 or more: " + problem.prompt)
				for word: String in UNKIND_WORDS:
					assert_false(problem.prompt.to_lower().contains(word))


## The answer worked out from the numbers in the story (null for kinds without arithmetic to redo).
func _story_answer(problem: MathProblem) -> Variant:
	var d: Dictionary = problem.data
	match problem.type:
		"word_add":
			return int(d["a"]) + int(d["b"])
		"word_subtract":
			return int(d["a"]) - int(d["b"])
		"word_missing_addend":
			return int(d["total"]) - int(d["a"])
		"word_multiply":
			return int(d["a"]) * int(d["b"])
		"word_equal_groups":
			return int(d["groups"]) * int(d["size"])
		"word_divide":
			return int(d["dividend"]) / int(d["divisor"])
		"word_missing_factor":
			return int(d["product"]) / int(d["a"])
		"word_next_number":
			return int(d["n"]) + 1
	return null


func _story_nouns() -> Array[String]:
	var nouns: Array[String] = []
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WordProblem.WORD_PROBLEMS_PATH))
	for thing: Dictionary in data["things"]:
		nouns.append(str(thing["one"]))
		nouns.append(str(thing["many"]))
	return nouns


func test_divide_story_reads_right() -> void:
	# Known answer: 12 shared among 3 is 4 each.
	var problem: MathProblem = MathProblem.create("divide", "12 ÷ 3 = ?", "", "4", ["4", "3", "5", "6"] as Array[String], {"dividend": 12, "divisor": 3})
	var story: MathProblem = WordProblem.new().retell(problem, "King Cobra", rng)
	assert_string_contains(story.prompt, "12 ")
	assert_string_contains(story.prompt, "3 ")
	assert_string_contains(story.prompt, "king cobra")
	assert_eq(story.answer, "4")
	assert_eq(story.type, "word_divide")


func test_snake_screen_shows_a_picture_for_clock_stories() -> void:
	var screen: SnakeScreen = SnakeScreen.new()
	add_child_autofree(screen)
	var snake: Dictionary = GameState.catalog.get_animal("rattlesnake")
	var stories: WordProblem = WordProblem.new()
	screen.start(snake, stories.make(GameState.factory, "time_money", 1, "Rattlesnake", rng))
	assert_true(screen.picture.visible, "the clock is drawn")
	screen.start(snake, stories.make(GameState.factory, "add_subtract", 1, "Rattlesnake", rng))
	assert_false(screen.picture.visible, "a plain story needs no picture")


func _open_meadow() -> HabitatMap:
	meadow = MEADOW.instantiate()
	meadow.auto_open_chase = false
	meadow.auto_travel = false
	add_child_autofree(meadow)
	await wait_physics_frames(2)
	return meadow


func _stand_by(cell: Vector2i) -> void:
	meadow.ranger.global_position = meadow.map.cell_to_feet(cell) + Vector2(0, 12)
	await wait_physics_frames(2)


func test_meadow_hides_the_green_vine_snake_under_a_rock() -> void:
	await _open_meadow()
	assert_gte(meadow.rock_cells.size(), 4)
	assert_eq(meadow.hidden_snake.get("id", ""), "green_vine_snake")
	assert_has(meadow.rock_cells, meadow.snake_hunt.hiding_cell())
	assert_false(meadow.look_button.visible, "not next to a rock yet")
	await _stand_by(meadow.rock_cells[0])
	assert_true(meadow.look_button.visible)


func test_empty_rock_then_found_then_one_try_to_catch() -> void:
	await _open_meadow()
	var hiding: Vector2i = meadow.snake_hunt.hiding_cell()
	for cell: Vector2i in meadow.rock_cells:
		if cell != hiding:
			meadow.peek_rock(cell)
			break
	assert_string_contains(meadow.banner.text, "Try another rock")
	assert_null(meadow.snake_screen)
	meadow.peek_rock(hiding)
	assert_not_null(meadow.snake_screen)
	assert_eq(meadow.objects.process_mode, Node.PROCESS_MODE_DISABLED, "the world waits")
	var screen: SnakeScreen = meadow.snake_screen
	assert_true(screen.problem.type.begins_with("word_"))
	screen.answer(screen.problem.answer)
	assert_string_contains(screen.title_label.text, "You caught")
	screen.finish()
	assert_null(meadow.snake_screen)
	assert_true(GameState.rescued.has("green_vine_snake"))
	assert_eq(GameState.stars, GameState.rewards.stars_for("snake"))
	assert_string_contains(meadow.banner.text, "safe at the Rescue Center")
	assert_null(meadow.snake_hunt, "no more snake to find")


func test_a_miss_lets_it_hide_under_another_rock() -> void:
	await _open_meadow()
	var hiding: Vector2i = meadow.snake_hunt.hiding_cell()
	meadow.peek_rock(hiding)
	var screen: SnakeScreen = meadow.snake_screen
	var other: String = ""
	for choice: String in screen.problem.choices:
		if choice != screen.problem.answer:
			other = choice
	screen.answer(other)
	assert_string_contains(screen.title_label.text, "slid away")
	screen.answer(screen.problem.answer)
	assert_false(screen.caught, "only one try")
	screen.finish()
	assert_false(GameState.rescued.has("green_vine_snake"))
	assert_ne(meadow.snake_hunt.hiding_cell(), hiding)
	assert_string_contains(meadow.banner.text, "another rock")


func test_no_snake_once_it_is_caught() -> void:
	GameState.record_rescue("green_vine_snake", "meadow", "meadow")
	await _open_meadow()
	assert_null(meadow.snake_hunt)
	await _stand_by(meadow.rock_cells[0])
	assert_false(meadow.look_button.visible)
