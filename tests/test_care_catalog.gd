extends GutTest
## data/care.json: every animal has foods with pictures, care notes, and a 3–4 fact card, in
## short, kind words.

const UNKIND_WORDS: Array[String] = ["wrong", "bad", "fail", "stupid", "dead", "die"]
## Short enough for a 2nd grader to read on one line.
const MAX_FACT_WORDS: int = 14
const MAX_NOTE_WORDS: int = 10

var catalog: CareCatalog


func before_each() -> void:
	catalog = CareCatalog.new()


func _check_kind(text: String) -> void:
	for word: String in UNKIND_WORDS:
		assert_false(text.to_lower().contains(word), "'%s' avoids '%s'" % [text, word])


func test_every_rescued_animal_can_be_cared_for() -> void:
	for id: String in AnimalCatalog.new().ids():
		assert_true(catalog.has_animal(id), "%s has care data" % id)


func test_foods_have_a_word_and_a_picture() -> void:
	for id: String in catalog.food_ids():
		var food: Dictionary = catalog.food(id)
		var word: String = str(food.get("word", ""))
		assert_true(word.length() >= 3 and word == word.to_lower(), "%s: lowercase word" % id)
		assert_true(ResourceLoader.exists(str(food.get("picture", ""))), "%s: picture exists" % id)
	assert_gte(catalog.food_ids().size(), 3, "enough foods for a 3-picture match")


func test_each_animal_has_foods_notes_and_facts() -> void:
	for id: String in catalog.animal_ids():
		assert_false(catalog.foods_for(id).is_empty(), "%s eats something" % id)
		for food_id: String in catalog.foods_for(id):
			assert_false(catalog.food(food_id).is_empty(), "%s: food '%s' is listed in foods" % [id, food_id])
		var notes: Array = catalog.notes_for(id)
		assert_gte(notes.size(), 2, "%s has care notes" % id)
		for note: Dictionary in notes:
			for key: String in ["text", "question", "good", "others"]:
				assert_true(note.has(key), "%s note has %s" % [id, key])
			assert_lte(str(note["text"]).split(" ").size(), MAX_NOTE_WORDS, "short note: %s" % note["text"])
			assert_false((note["others"] as Array).has(note["good"]))
			_check_kind(str(note["text"]) + " " + str(note["question"]) + " " + str(note["good"]) + " " + " ".join(note["others"]))
		var facts: Array[String] = catalog.facts_for(id)
		assert_between(facts.size(), 3, 4, "%s has 3–4 facts" % id)
		for fact: String in facts:
			assert_lte(fact.split(" ").size(), MAX_FACT_WORDS, "short fact: %s" % fact)
			_check_kind(fact)


func test_feeding_rules_per_grade() -> void:
	assert_eq(catalog.grades(), ["K", "1", "2", "3"] as Array[String])
	var k_modes: Array = catalog.feeding_rules("K")["modes"]
	assert_true(k_modes.has(CareVisit.PICTURE_MATCH) and k_modes.has(CareVisit.FIRST_LETTER))
	assert_eq(catalog.feeding_rules("2")["modes"], [CareVisit.SPELL])
	assert_eq(catalog.feeding_rules("unknown"), catalog.feeding_rules(CareCatalog.DEFAULT_GRADE))
	assert_lt(int(catalog.feeding_rules("1")["extra_letters"]), int(catalog.feeding_rules("3")["extra_letters"]),
		"older grades get more decoy letters")
	assert_gt(catalog.hint_after_misses(), 0)
