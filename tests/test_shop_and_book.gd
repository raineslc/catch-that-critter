extends GutTest
## The pen shop and the Rescue Book screens.

var shop: ShopScreen
var book: BookScreen


func before_each() -> void:
	GameState.reset()


func _open_shop() -> ShopScreen:
	shop = ShopScreen.new()
	add_child_autofree(shop)
	var legend: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MapData.LEGEND_PATH))
	shop.start("meadow", "Meadow", legend["objects"])
	return shop


func _item(id: String) -> Button:
	for button: Button in shop.item_buttons:
		if button.get_meta("id") == id:
			return button
	return null


func test_shop_shows_every_decoration_with_a_picture() -> void:
	_open_shop()
	assert_eq(shop.item_buttons.size(), GameState.rewards.decorations().size())
	for button: Button in shop.item_buttons:
		assert_not_null(button.icon)
		assert_true(button.disabled, "no stars yet")
	assert_string_contains(shop.stars_label.text, "0")


func test_buying_puts_it_in_the_pen_once() -> void:
	GameState.add_stars(9, "test")
	_open_shop()
	assert_false(_item("bush").disabled)
	assert_true(_item("tree").disabled, "can't afford 15 yet")
	shop.buy("bush")
	assert_true(GameState.has_decoration("meadow", "bush"))
	assert_string_contains(_item("bush").text, "In the pen")
	assert_true(_item("bush").disabled)
	assert_string_contains(shop.stars_label.text, "1")
	shop.buy("flowers")
	assert_eq(shop.feedback.text, ShopScreen.SAVE_UP_TEXT)


func test_shop_done_closes() -> void:
	_open_shop()
	watch_signals(shop)
	shop.close()
	assert_signal_emitted(shop, "closed")


func _open_book() -> BookScreen:
	book = BookScreen.new()
	add_child_autofree(book)
	return book


func test_book_hides_animals_not_rescued_yet() -> void:
	_open_book()
	assert_string_contains(book.title_label.text, "Meadow")
	assert_eq(book.slot_buttons.size(), 4, "3 animals and a special")
	for button: Button in book.slot_buttons:
		assert_string_starts_with(button.text, "???")
		assert_true(button.disabled)


func test_book_shows_rescued_animals_with_level_and_facts() -> void:
	GameState.record_rescue("raccoon", "meadow", "meadow", Vector2i(1, 1))
	GameState.record_rescue("raccoon", "meadow", "meadow", Vector2i(2, 1))
	_open_book()
	var slot: Button = book.slot_buttons[1]
	assert_string_contains(slot.text, "Raccoon")
	assert_string_contains(slot.text, "Level 1")
	assert_string_contains(slot.text, "2 home")
	assert_not_null(slot.icon)
	book.show_animal("raccoon")
	assert_string_contains(book.facts_label.text, "Care for the raccoon")
	GameState.record_care("raccoon")
	GameState.record_care("raccoon")
	book.show_animal("raccoon")
	var facts: Array[String] = GameState.care_catalog.facts_for("raccoon")
	assert_eq(book.facts_label.text, "\n".join(facts.slice(0, 2)), "one fact per care visit")


func test_book_pages_turn_and_stop_at_the_ends() -> void:
	_open_book()
	assert_true(book.previous_button.disabled)
	book.show_page(1)
	assert_string_contains(book.title_label.text, "Forest")
	book.show_page(99)
	assert_eq(book.page, 4)
	assert_true(book.next_button.disabled)
	assert_string_contains(book.slot_buttons[3].text, "Special")
