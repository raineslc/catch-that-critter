extends GutTest
## One good answer among a few choices; other picks are gentle misses.


func test_good_answer_is_among_the_shuffled_choices() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var first_positions: Dictionary = {}
	for seed: int in 50:
		rng.seed = seed
		var choice: CareChoice = CareChoice.make("What will help?", "A warm bath", ["A big hat", "A drum"], rng)
		assert_eq(choice.choices.size(), 3)
		assert_true(choice.choices.has("A warm bath"))
		first_positions[choice.choices.find("A warm bath")] = true
	assert_gt(first_positions.size(), 1, "the good answer isn't always in the same spot")


func test_picking() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var choice: CareChoice = CareChoice.make("Q", "yes", ["no"], rng)
	assert_false(choice.pick("no"))
	assert_eq(choice.misses, 1)
	assert_false(choice.solved)
	assert_true(choice.pick("yes"))
	assert_true(choice.solved)
