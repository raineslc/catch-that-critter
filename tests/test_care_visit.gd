extends GutTest
## One care visit: feed (by grade) → care note → fact card, one new fact per visit.

var catalog: CareCatalog
var rng: RandomNumberGenerator


func before_each() -> void:
	catalog = CareCatalog.new()
	rng = RandomNumberGenerator.new()
	rng.seed = 3


func test_second_grade_spells_the_whole_food_name() -> void:
	for seed: int in 30:
		rng.seed = seed
		var visit: CareVisit = CareVisit.make(catalog, "raccoon", "2", 0, rng)
		assert_eq(visit.feed_mode, CareVisit.SPELL)
		assert_true(catalog.foods_for("raccoon").has(visit.food_id))
		assert_eq(visit.spelling.word, visit.food_word)
		assert_eq(visit.spelling.to_place, visit.food_word.length())
		assert_eq(visit.spelling.tiles.size(), visit.food_word.length() + 1, "one decoy letter")


func test_kindergarten_gets_first_letter_or_picture_match() -> void:
	var modes: Dictionary = {}
	for seed: int in 40:
		rng.seed = seed
		var visit: CareVisit = CareVisit.make(catalog, "raccoon", "K", 0, rng)
		modes[visit.feed_mode] = true
		if visit.feed_mode == CareVisit.PICTURE_MATCH:
			assert_null(visit.spelling)
			assert_eq(visit.picture_choice.choices.size(), 3)
			assert_eq(visit.picture_choice.answer, visit.food_id)
			for food_id: String in visit.picture_choice.choices:
				assert_false(catalog.food(food_id).is_empty())
		else:
			assert_eq(visit.spelling.to_place, 1)
			assert_eq(visit.spelling.tiles.size(), 3)
	assert_eq(modes.size(), 2, "both K modes show up")


func test_steps_in_order() -> void:
	var visit: CareVisit = CareVisit.make(catalog, "raccoon", "2", 0, rng)
	assert_eq(visit.step, CareVisit.Step.FEED)
	assert_false(visit.is_fed())
	while not visit.spelling.is_done():
		visit.spelling.press(visit.spelling.hint_tile())
	assert_true(visit.is_fed())
	assert_eq(visit.advance(), CareVisit.Step.NOTE)
	assert_not_null(visit.note_choice)
	assert_eq(visit.advance(), CareVisit.Step.FACT)
	assert_eq(visit.advance(), CareVisit.Step.DONE)


func test_care_notes_take_turns() -> void:
	var notes: Array = catalog.notes_for("raccoon")
	for visits: int in notes.size() + 1:
		var visit: CareVisit = CareVisit.make(catalog, "raccoon", "2", visits, rng)
		assert_eq(visit.note, notes[visits % notes.size()])
		assert_eq(visit.note_choice.answer, notes[visits % notes.size()]["good"])


func test_one_new_fact_per_visit_until_all_are_known() -> void:
	var facts: Array[String] = catalog.facts_for("raccoon")
	var first: CareVisit = CareVisit.make(catalog, "raccoon", "2", 0, rng)
	assert_eq(first.facts_to_show(), facts.slice(0, 1))
	assert_eq(first.new_fact_index(), 0)
	var second: CareVisit = CareVisit.make(catalog, "raccoon", "2", 1, rng)
	assert_eq(second.facts_to_show().size(), 2)
	assert_eq(second.new_fact_index(), 1)
	var later: CareVisit = CareVisit.make(catalog, "raccoon", "2", facts.size() + 3, rng)
	assert_eq(later.facts_to_show(), facts)
	assert_eq(later.new_fact_index(), -1)
