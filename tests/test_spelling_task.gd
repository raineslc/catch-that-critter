extends GutTest
## Letter tiles: fill the blanks left to right, gentle misses, hints, decoys, first-letter mode.

var rng: RandomNumberGenerator


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 7


func _tile_for(task: SpellingTask, letter: String) -> int:
	for i: int in task.tiles.size():
		if not task.used.has(i) and task.tiles[i] == letter:
			return i
	return -1


func test_spelling_the_whole_word() -> void:
	var task: SpellingTask = SpellingTask.make("fish", 0, 0, rng)
	assert_eq(task.to_place, 4)
	assert_eq(task.tiles.size(), 4)
	assert_eq(task.shown(), ["", "", "", ""] as Array[String])
	assert_eq(task.press(_tile_for(task, "f")), SpellingTask.Result.RIGHT)
	assert_eq(task.press(_tile_for(task, "i")), SpellingTask.Result.RIGHT)
	assert_eq(task.press(_tile_for(task, "s")), SpellingTask.Result.RIGHT)
	assert_eq(task.shown(), ["f", "i", "s", ""] as Array[String])
	assert_eq(task.press(_tile_for(task, "h")), SpellingTask.Result.DONE)
	assert_true(task.is_done())
	assert_eq(task.misses, 0)


func test_other_letters_are_gentle_misses_and_stay_put() -> void:
	var task: SpellingTask = SpellingTask.make("nuts", 0, 0, rng)
	var t_tile: int = _tile_for(task, "t")
	assert_eq(task.press(t_tile), SpellingTask.Result.MISS)
	assert_eq(task.misses_here, 1)
	assert_false(task.used.has(t_tile), "a missed tile can be used later")
	assert_eq(task.press(_tile_for(task, "n")), SpellingTask.Result.RIGHT)
	assert_eq(task.misses_here, 0, "a right letter clears the hint counter")
	assert_eq(task.misses, 1)


func test_used_tiles_and_taps_after_done_are_ignored() -> void:
	var task: SpellingTask = SpellingTask.make("fish", 1, 2, rng)
	var f_tile: int = _tile_for(task, "f")
	assert_eq(task.press(f_tile), SpellingTask.Result.DONE)
	assert_eq(task.press(f_tile), SpellingTask.Result.IGNORED)
	assert_eq(task.press(99), SpellingTask.Result.IGNORED)


func test_hint_points_to_a_tile_with_the_next_letter() -> void:
	var task: SpellingTask = SpellingTask.make("fish", 0, 1, rng)
	assert_eq(task.tiles[task.hint_tile()], "f")
	task.press(task.hint_tile())
	assert_eq(task.next_letter(), "i")
	assert_eq(task.tiles[task.hint_tile()], "i")


func test_repeated_letters_work_with_either_tile() -> void:
	var task: SpellingTask = SpellingTask.make("eggs", 0, 0, rng)
	for letter: String in ["e", "g", "g", "s"]:
		assert_ne(task.press(_tile_for(task, letter)), SpellingTask.Result.MISS)
	assert_true(task.is_done())


func test_decoy_letters_are_extra_and_not_in_the_word() -> void:
	for seed: int in 200:
		rng.seed = seed
		var task: SpellingTask = SpellingTask.make("shrimp", 0, 2, rng)
		assert_eq(task.tiles.size(), 8)
		var extras: int = 0
		for letter: String in task.tiles:
			if not "shrimp".contains(letter):
				extras += 1
		assert_eq(extras, 2)


func test_tiles_are_mixed_up() -> void:
	for seed: int in 100:
		rng.seed = seed
		var task: SpellingTask = SpellingTask.make("fish", 0, 0, rng)
		assert_ne("".join(task.tiles), "fish", "tiles never spell the word in order")


func test_first_letter_mode() -> void:
	var task: SpellingTask = SpellingTask.make("Nuts", 1, 2, rng)
	assert_eq(task.word, "nuts", "words are lowercase")
	assert_eq(task.shown(), ["", "u", "t", "s"] as Array[String])
	assert_eq(task.tiles.size(), 3)
	assert_eq(task.tiles.count("n"), 1)
	assert_eq(task.press(_tile_for(task, "n")), SpellingTask.Result.DONE)
	assert_eq(task.shown(), ["n", "u", "t", "s"] as Array[String])
