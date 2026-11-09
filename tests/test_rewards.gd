extends GutTest
## Stars, animal levels, pen decorations, and the book data (PLAN.md 3.10).


func before_each() -> void:
	GameState.reset()


func test_catch_stars_with_a_bonus_for_no_misses() -> void:
	var rewards: Rewards = Rewards.new()
	assert_eq(rewards.catch_stars(0), 4)
	assert_eq(rewards.catch_stars(1), 3)
	assert_eq(rewards.catch_stars(2), 3)


func test_levels_go_up_at_1_3_6_and_10_care_visits() -> void:
	var rewards: Rewards = Rewards.new()
	var expected: Dictionary = {0: 1, 1: 2, 2: 2, 3: 3, 5: 3, 6: 4, 9: 4, 10: 5, 40: 5}
	for visits: int in expected:
		assert_eq(rewards.level_for(visits), expected[visits], "%d visits" % visits)


func test_care_earns_stars_and_a_level_up_bonus() -> void:
	assert_true(GameState.record_care("raccoon"), "first visit: level 2")
	assert_eq(GameState.stars, 4, "2 for care + 2 for the level-up")
	assert_false(GameState.record_care("raccoon"), "second visit: still level 2")
	assert_eq(GameState.stars, 6)
	assert_eq(GameState.animal_level("raccoon"), 2)


func test_buying_decorations() -> void:
	GameState.add_stars(10, "test")
	assert_false(GameState.buy_decoration("meadow", "tree"), "15 stars is too many")
	assert_true(GameState.buy_decoration("meadow", "bush"))
	assert_eq(GameState.stars, 2)
	assert_true(GameState.has_decoration("meadow", "bush"))
	assert_false(GameState.has_decoration("forest", "bush"), "each pen has its own")
	GameState.add_stars(10, "test")
	assert_false(GameState.buy_decoration("meadow", "bush"), "only one bush per pen")
	assert_false(GameState.buy_decoration("meadow", "castle"), "unknown items can't be bought")
	assert_eq(GameState.stars, 12)


func test_stars_never_go_below_zero() -> void:
	GameState.add_stars(-5, "test")
	assert_eq(GameState.stars, 0)


func test_stars_and_decorations_are_saved() -> void:
	GameState.add_stars(20, "test")
	GameState.buy_decoration("meadow", "flowers")
	var saved: Dictionary = JSON.parse_string(JSON.stringify(GameState.snapshot()))
	assert_true(ProfileStore.valid(saved))
	GameState.reset()
	GameState._restore(saved)
	assert_eq(GameState.stars, 15)
	assert_true(GameState.has_decoration("meadow", "flowers"))


func test_saves_from_before_stars_still_load() -> void:
	var old_save: Dictionary = JSON.parse_string(JSON.stringify(GameState.snapshot()))
	old_save.erase("stars")
	old_save.erase("decorations")
	assert_true(ProfileStore.valid(old_save), "an older save without stars is kept")
	GameState._restore(old_save)
	assert_eq(GameState.stars, 0)
	var bad: Dictionary = old_save.duplicate(true)
	bad["stars"] = -3
	assert_false(ProfileStore.valid(bad))
	bad["stars"] = 3
	bad["decorations"] = {"meadow": [5]}
	assert_false(ProfileStore.valid(bad))


func test_decorations_use_real_map_objects_and_fit_in_the_pen() -> void:
	var legend: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MapData.LEGEND_PATH))
	for item: Dictionary in Rewards.new().decorations():
		assert_true(legend["objects"].has(item["object"]), "%s uses a map object" % item["id"])
		assert_gt(int(item["price"]), 0)
		assert_between(int(item["spot"][0]), 0, 5, "%s inside the 6-wide habitat pen (x)" % item["id"])
		assert_between(int(item["spot"][1]), 2, 3, "%s inside the pen, clear of the bottom fence (y)" % item["id"])


func test_book_has_every_habitat_with_three_animals_and_a_special() -> void:
	var pages: Array = Rewards.new().book_pages()
	var habitats: Array[String] = []
	for page: Dictionary in pages:
		habitats.append(str(page["habitat"]))
		assert_eq((page["animals"] as Array).size(), 3)
		assert_ne(str(page["special"]), "")
	assert_eq(habitats, ["meadow", "forest", "swamp", "desert", "mountains"] as Array[String])
	assert_true(pages[0]["animals"].has("raccoon"))


func test_every_book_animal_lives_on_its_habitats_map() -> void:
	# The 2026-11-05 review: fox and rabbit had Book slots but no animals, so they stayed "???".
	var catalog: AnimalCatalog = AnimalCatalog.new()
	for page: Dictionary in Rewards.new().book_pages():
		var habitat: String = str(page["habitat"])
		var map: MapData = MapData.load_map("res://data/maps/%s.txt" % habitat)
		var on_map: Array[String] = []
		for cell: Vector2i in map.critter_spots():
			on_map.append(map.critter_at(cell))
		for id: Variant in page["animals"]:
			assert_true(catalog.has_animal(str(id)), "%s is a real animal" % id)
			assert_eq(str(catalog.get_animal(str(id)).get("habitat", "")), habitat, "%s lives in the %s" % [id, habitat])
			assert_true(on_map.has(str(id)), "%s can be found in the %s" % [id, habitat])
