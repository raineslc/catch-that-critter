extends GutTest
## Playtest 3: the real game (profile buttons, real saves) with the playtest log on.
## Uses its own test save and log folders only.

const TEST_DIR: String = "user://test_playtest_3/"
const MAIN: PackedScene = preload("res://scenes/main.tscn")

var slot: Dictionary = {"id": "default", "path": TEST_DIR + "one.json", "sidekick_id": "henrito", "grade": "2"}


func before_each() -> void:
	GameState.reset()
	DirAccess.make_dir_recursive_absolute(TEST_DIR)
	_clean()


func after_each() -> void:
	GameState.reset()
	_clean()


func _clean() -> void:
	for file: String in DirAccess.get_files_at(TEST_DIR):
		DirAccess.remove_absolute(TEST_DIR + file)


func test_config_uses_profiles_and_each_animals_own_math() -> void:
	var config: Dictionary = GameState.load_playtest_config(GameState.PLAYTEST_3_PATH)
	assert_true(bool(config["profiles"]))
	assert_false(config.has("skill"), "no playtest skill: each habitat's own math")
	assert_false(config.has("respawn_seconds"), "caught animals stay home, like normal play")


func test_picking_a_profile_keeps_the_playtest_log() -> void:
	GameState.enable_playtest(GameState.load_playtest_config(GameState.PLAYTEST_3_PATH), TEST_DIR)
	assert_not_null(GameState.playtest_log)
	var log: PlaytestLog = GameState.playtest_log
	assert_true(GameState.start_slot(slot))
	assert_true(GameState.is_playtest())
	assert_eq(GameState.playtest_log, log, "same log keeps going")
	assert_eq(GameState.chase_skill_for(GameState.catalog.get_animal("turtle")), "place_value")


func test_title_shows_profile_buttons_in_playtest_3() -> void:
	GameState.playtest = GameState.load_playtest_config(GameState.PLAYTEST_3_PATH)
	var title: Control = MAIN.instantiate()
	title.slots = [slot]
	title.auto_change_scene = false
	add_child_autofree(title)
	await wait_frames(1)
	assert_eq(title.cards.size(), 1)
	assert_string_contains(title.get_node("StartHint").text, "Playtest 3")
