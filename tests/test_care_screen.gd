extends GutTest
## The care screen: spell the food (or match the picture), pick what helps, see the fact card.

const UNKIND_WORDS: Array[String] = ["wrong", "bad", "fail"]

var screen: CareScreen
var catalog: CareCatalog
var rng: RandomNumberGenerator


func before_each() -> void:
	GameState.reset()
	GameState.read_aloud = false
	catalog = CareCatalog.new()
	rng = RandomNumberGenerator.new()
	rng.seed = 11


func _open(visit: CareVisit) -> CareScreen:
	screen = CareScreen.new()
	add_child_autofree(screen)
	screen.start(AnimalCatalog.new().get_animal("raccoon"), visit, catalog)
	return screen


func _visit(grade: String, mode: String = "", visits_before: int = 0) -> CareVisit:
	for seed: int in 200:
		rng.seed = seed
		var visit: CareVisit = CareVisit.make(catalog, "raccoon", grade, visits_before, rng)
		if mode == "" or visit.feed_mode == mode:
			return visit
	return null


func _spell_it(care: CareScreen) -> void:
	while not care.visit.spelling.is_done():
		care.press_tile(care.visit.spelling.hint_tile())


func _tile_not(care: CareScreen, letter: String) -> int:
	for i: int in care.visit.spelling.tiles.size():
		if care.visit.spelling.tiles[i] != letter:
			return i
	return -1


func test_spelling_fills_the_boxes_and_feeds_the_animal() -> void:
	_open(_visit("2"))
	assert_eq(screen.title_label.text, "Feed the Raccoon")
	assert_eq(screen.letter_labels.size(), screen.visit.food_word.length())
	assert_eq(screen.tile_buttons.size(), screen.visit.food_word.length() + 1)
	assert_false(screen.next_button.visible)
	screen.press_tile(screen.visit.spelling.hint_tile())
	assert_eq(screen.letter_labels[0].text, screen.visit.food_word[0])
	_spell_it(screen)
	assert_true(screen.next_button.visible)
	assert_string_contains(screen.feedback.text, "loves %s" % screen.visit.food_word)


func test_two_misses_bring_a_letter_hint() -> void:
	_open(_visit("2"))
	var first: String = screen.visit.spelling.next_letter()
	var other: int = _tile_not(screen, first)
	screen.press_tile(other)
	assert_eq(screen.feedback.text, CareScreen.TRY_AGAIN)
	assert_false(screen.tile_buttons[other].disabled, "a missed tile stays available")
	screen.press_tile(other)
	assert_true(screen.bubble.visible)
	assert_string_contains(screen.bubble_label.text, "letter %s" % first)
	screen.press_tile(screen.visit.spelling.hint_tile())
	assert_false(screen.bubble.visible, "the hint goes away after the right letter")
	_spell_it(screen)
	for tile: Button in screen.tile_buttons:
		assert_true(tile.disabled, "leftover tiles are done too")


func test_care_note_then_fact_card_then_done() -> void:
	_open(_visit("2"))
	_spell_it(screen)
	screen.next_step()
	assert_eq(screen.title_label.text, "Care for the Raccoon")
	assert_eq(screen.choice_buttons.size(), 2)
	assert_false(screen.next_button.visible)
	var good: String = screen.visit.note_choice.answer
	var other: String = screen.visit.note_choice.choices[0 if screen.visit.note_choice.choices[1] == good else 1]
	screen.pick_note(other)
	assert_true(screen.bubble.visible, "Henrito helps")
	assert_false(screen.next_button.visible)
	screen.pick_note(good)
	assert_true(screen.next_button.visible)
	screen.next_step()
	assert_eq(screen.title_label.text, "Raccoon Facts")
	assert_eq(screen.fact_labels.size(), 1)
	assert_string_starts_with(screen.fact_labels[0].text, CareScreen.NEW_FACT_TAG)
	assert_eq(screen.next_button.text, CareScreen.DONE)
	watch_signals(screen)
	screen.next_step()
	assert_signal_emitted_with_parameters(screen, "finished", [true])


func test_next_does_nothing_before_the_step_is_done() -> void:
	_open(_visit("2"))
	screen.next_step()
	assert_eq(screen.visit.step, CareVisit.Step.FEED)


func test_later_visits_show_more_facts() -> void:
	_open(_visit("2", "", 2))
	_spell_it(screen)
	screen.next_step()
	screen.pick_note(screen.visit.note_choice.answer)
	screen.next_step()
	assert_eq(screen.fact_labels.size(), 3)
	assert_false(screen.fact_labels[0].text.begins_with(CareScreen.NEW_FACT_TAG))
	assert_string_starts_with(screen.fact_labels[2].text, CareScreen.NEW_FACT_TAG)


func test_kindergarten_picture_match() -> void:
	_open(_visit("K", CareVisit.PICTURE_MATCH))
	assert_eq(screen.picture_buttons.size(), 3)
	for button: Button in screen.picture_buttons:
		assert_not_null(button.icon, "every choice is a picture")
	var other: String = ""
	for food_id: String in screen.visit.picture_choice.choices:
		if food_id != screen.visit.food_id:
			other = food_id
	screen.pick_picture(other)
	screen.pick_picture(other)
	assert_string_contains(screen.bubble_label.text, screen.visit.food_word)
	screen.pick_picture(screen.visit.food_id)
	assert_true(screen.next_button.visible)


func test_kindergarten_first_letter() -> void:
	_open(_visit("K", CareVisit.FIRST_LETTER))
	assert_eq(screen.tile_buttons.size(), 3)
	assert_eq(screen.letter_labels[1].text, screen.visit.food_word[1], "the rest of the word is shown")
	screen.press_tile(screen.visit.spelling.hint_tile())
	assert_true(screen.next_button.visible)


func test_later_leaves_without_finishing() -> void:
	_open(_visit("2"))
	watch_signals(screen)
	screen.finish(false)
	assert_signal_emitted_with_parameters(screen, "finished", [false])


func test_read_aloud_button_only_when_voice_is_on() -> void:
	_open(_visit("2"))
	screen.visit.step = CareVisit.Step.FACT
	screen._show_step()
	assert_null(screen.content.find_child("ReadAloud", true, false))
	GameState.read_aloud = true
	screen._show_step()
	assert_not_null(screen.content.find_child("ReadAloud", true, false))
	GameState.read_aloud = false


func test_kid_text_is_kind() -> void:
	var texts: Array[String] = [CareScreen.TRY_AGAIN, CareScreen.NOTE_GOOD, CareScreen.FED_TEXT,
		CareScreen.SPELL_PROMPT, CareScreen.FIRST_LETTER_PROMPT, CareScreen.PICTURE_PROMPT]
	for text: String in texts:
		for word: String in UNKIND_WORDS:
			assert_false(text.to_lower().contains(word), "'%s' avoids '%s'" % [text, word])


func _key(code: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await wait_frames(2)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await wait_frames(2)


func test_keyboard_finishes_spelling_note_and_fact_card() -> void:
	_open(_visit("2"))
	await wait_frames(2)
	assert_eq(screen.get_viewport().gui_get_focus_owner(), screen.tile_buttons[0])
	# Arrow keys move among tiles; Enter activates the focused tile.
	await _key(KEY_RIGHT)
	assert_eq(screen.get_viewport().gui_get_focus_owner(), screen.tile_buttons[1])
	while not screen.visit.spelling.is_done():
		var tile: Button = screen.tile_buttons[screen.visit.spelling.hint_tile()]
		for move: int in screen.tile_buttons.size() + 4:
			if screen.get_viewport().gui_get_focus_owner() == tile:
				break
			await _key(KEY_TAB)
		assert_eq(screen.get_viewport().gui_get_focus_owner(), tile)
		await _key(KEY_ENTER)
	assert_eq(screen.get_viewport().gui_get_focus_owner(), screen.next_button)
	await _key(KEY_ENTER)
	assert_eq(screen.visit.step, CareVisit.Step.NOTE)
	for move: int in 4:
		var focused: Button = screen.get_viewport().gui_get_focus_owner()
		if focused.text == screen.visit.note_choice.answer:
			break
		await _key(KEY_RIGHT)
	await _key(KEY_ENTER)
	assert_true(screen.visit.note_choice.solved)
	await _key(KEY_ENTER)
	assert_eq(screen.visit.step, CareVisit.Step.FACT)
	watch_signals(screen)
	await _key(KEY_ENTER)
	assert_signal_emitted_with_parameters(screen, "finished", [true])


func test_word_clue_is_optional_and_does_not_fill_letters() -> void:
	_open(_visit("2"))
	assert_ne(screen.food_hint_label.text, screen.visit.food_word)
	screen._toggle_word_clue()
	assert_eq(screen.food_hint_label.text, screen.visit.food_word)
	assert_eq(screen.visit.spelling.placed, 0)
	screen._toggle_word_clue()
	assert_ne(screen.food_hint_label.text, screen.visit.food_word)
	assert_false(GameState.read_aloud)


func test_escape_leaves_care_and_duplicate_finish_is_ignored() -> void:
	_open(_visit("2"))
	watch_signals(screen)
	await _key(KEY_ESCAPE)
	screen.finish(false)
	assert_signal_emitted_with_parameters(screen, "finished", [false])
	assert_signal_emit_count(screen, "finished", 1)
