extends GutTest
## Two profiles (PLAN 3.2, Chris 2026-11-05): big buttons on the title screen, a name typed
## once, a recolored ranger, and each slot's own sidekick, grade, and save.
## Uses its own test save files only (never the player's).

const TEST_DIR: String = "user://test_profiles/"
const MAIN: PackedScene = preload("res://scenes/main.tscn")

var slots: Array = []


func before_each() -> void:
	GameState.reset()
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_remove_test_saves()
	slots = [
		{"id": "default", "path": TEST_DIR + "one.json", "sidekick_id": "henrito", "grade": "2", "explore_locked": false},
		{"id": "ranger_2", "path": TEST_DIR + "two.json", "sidekick_id": "loganator", "grade": "K", "explore_locked": true},
	]


func after_each() -> void:
	_remove_test_saves()
	GameState.reset()


func _remove_test_saves() -> void:
	for file: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR + file)


func _open_title() -> Control:
	var title: Control = MAIN.instantiate()
	title.slots = slots
	title.auto_change_scene = false
	add_child_autofree(title)
	await wait_frames(1)
	return title


func test_real_profile_slots_are_two_with_their_own_sidekicks() -> void:
	var real: Array = GameState.profile_slots()
	assert_eq(real.size(), 2)
	assert_eq(str(real[0]["path"]), "user://profiles/default.json", "his existing save stays the first profile")
	assert_eq(str(real[0]["sidekick_id"]), "henrito")
	assert_eq(str(real[1]["sidekick_id"]), "loganator")


func test_new_slot_uses_its_sidekick_grade_and_explore_lock() -> void:
	assert_true(GameState.start_slot(slots[1]))
	assert_eq(GameState.sidekick_id, "loganator")
	assert_eq(GameState.grade, "K")
	assert_true(GameState.explore_locked)
	assert_eq(GameState.profile_id, "ranger_2")


func test_name_and_look_are_saved_and_loaded() -> void:
	GameState.start_slot(slots[1])
	GameState.player_name = "Sam"
	GameState.look = {"hair": "brown", "skin": "light", "outfit": "green"}
	GameState.record_rescue("raccoon", "meadow", "meadow")
	assert_true(GameState.save_progress())
	GameState.reset()
	assert_true(GameState.start_slot(slots[1]))
	assert_eq(GameState.player_name, "Sam")
	assert_eq(GameState.look["outfit"], "green")
	assert_eq(GameState.rescued, ["raccoon"] as Array[String])
	assert_eq(GameState.sidekick_id, "loganator", "an existing save keeps its own settings")


func test_slots_keep_separate_saves() -> void:
	GameState.start_slot(slots[0])
	GameState.player_name = "One"
	GameState.record_rescue("deer", "forest", "forest")
	GameState.save_progress()
	GameState.start_slot(slots[1])
	assert_eq(GameState.player_name, "")
	assert_eq(GameState.rescued.size(), 0)


func test_saves_check_name_and_look() -> void:
	var data: Dictionary = GameState.snapshot()
	assert_true(ProfileStore.valid(data))
	data.erase("name")
	data.erase("look")
	assert_true(ProfileStore.valid(data), "older saves without them still load")
	data["name"] = "x".repeat(ProfileStore.MAX_NAME_LENGTH + 1)
	assert_false(ProfileStore.valid(data))
	data["name"] = "Sam"
	data["look"] = {"hair": 3}
	assert_false(ProfileStore.valid(data))


func test_default_look_keeps_the_original_art() -> void:
	assert_eq(RangerLook.sheet({}), RangerLook.SHEET)
	assert_eq(RangerLook.complete({"hair": "purple"})["hair"], "red", "unknown options use the default")


func test_recolor_changes_hair_and_skin_shadow_separately() -> void:
	RangerLook.faceset({"hair": "blonde"})  # an earlier recolor must not change the original art
	var original: Image = RangerLook.FACESET.get_image()
	original.decompress()
	var recolored: Image = RangerLook.faceset({"hair": "black", "skin": "deep"}).get_image()
	var hair_red: Color = Color8(209, 75, 52)
	var black_hair: Color = RangerLook.swatch("hair", "black")
	var deep_shadow: Color = Color8(96, 60, 40)
	var saw_hair: bool = false
	var saw_shadow: bool = false
	for y: int in original.get_height():
		for x: int in original.get_width():
			if original.get_pixel(x, y).to_rgba32() != hair_red.to_rgba32():
				continue
			var now: int = recolored.get_pixel(x, y).to_rgba32()
			saw_hair = saw_hair or now == black_hair.to_rgba32()
			saw_shadow = saw_shadow or now == deep_shadow.to_rgba32()
	assert_true(saw_hair, "red hair turned black")
	assert_true(saw_shadow, "red next to skin became the skin's shadow")


func test_title_shows_a_big_button_per_slot() -> void:
	var title: Control = await _open_title()
	assert_eq(title.cards.size(), 2)
	assert_false(title.get_node("StartHint").visible)
	assert_string_contains(_texts(title.cards[0]), "New ranger")
	assert_string_contains(_texts(title.cards[1]), "with Loganator")


func test_new_profile_makes_a_ranger_first() -> void:
	var title: Control = await _open_title()
	title.choose(slots[0])
	var setup: RangerSetup = title.setup_screen
	assert_not_null(setup, "new profile opens Make your ranger")
	assert_true(setup.start_button.disabled, "needs a name")
	setup.name_edit.text = "Sam"
	setup.name_edit.text_changed.emit("Sam")
	setup.pick("hair", "blonde")
	assert_false(setup.start_button.disabled)
	setup.confirm()
	assert_eq(GameState.player_name, "Sam")
	assert_eq(GameState.look["hair"], "blonde")
	assert_true(FileAccess.file_exists(slots[0]["path"]), "saved right away")
	assert_null(title.setup_screen)


func test_named_profile_starts_right_away() -> void:
	GameState.start_slot(slots[0])
	GameState.player_name = "Sam"
	GameState.save_progress()
	GameState.reset()
	var title: Control = await _open_title()
	assert_string_contains(_texts(title.cards[0]), "Sam")
	title.choose(slots[0])
	assert_null(title.setup_screen)
	assert_eq(GameState.player_name, "Sam")


func test_loganator_is_a_sidekick() -> void:
	var loganator: Sidekick = Sidekick.load_by_id("loganator", GameState.rng)
	assert_eq(loganator.display_name(), "Loganator")
	assert_not_null(loganator.faceset())


func _texts(node: Node) -> String:
	var out: String = ""
	for child: Node in node.find_children("*", "Label", true, false):
		out += (child as Label).text + "\n"
	return out
