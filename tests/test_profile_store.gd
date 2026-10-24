extends GutTest
## Disk round trips, corruption recovery, isolated profiles and session mastery.

var directory: String
var path: String

func before_each() -> void:
	GameState.reset()
	directory = "user://test_review_profiles_" + str(Time.get_ticks_usec())
	path = directory.path_join("profile.json")
	DirAccess.make_dir_recursive_absolute(directory)


func after_each() -> void:
	GameState.reset()
	for file: String in DirAccess.get_files_at(directory):
		DirAccess.remove_absolute(directory.path_join(file))
	DirAccess.remove_absolute(directory)


func _raw(text: String, destination: String = "") -> void:
	var file: FileAccess = FileAccess.open(path if destination == "" else destination, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_save_restores_rescues_care_settings_and_pending_session() -> void:
	assert_true(GameState.start_profile(path))
	GameState.finish_intro()
	GameState.record_rescue("raccoon", "meadow", "meadow", Vector2i(3, 4))
	GameState.record_care("raccoon")
	GameState.pen_repairs_shown["meadow"] = 1
	GameState.grade = "3"
	GameState.sidekick_id = "loganator"
	GameState.mode = ChaseState.RACE
	GameState.explore_locked = true
	GameState.engine.record_answer("counting", true, 20.0)
	assert_true(GameState.save_progress())
	GameState.reset()
	assert_true(GameState.start_profile(path))
	assert_true(GameState.intro_seen)
	assert_true(GameState.is_spot_rescued("meadow", Vector2i(3, 4)))
	assert_eq(GameState.rescued, ["raccoon"] as Array[String])
	assert_eq(GameState.care_visits_for("raccoon"), 1)
	assert_eq(int(GameState.pen_repairs_shown.meadow), 1)
	assert_eq(GameState.grade, "3")
	assert_eq(GameState.sidekick_id, "loganator")
	assert_eq(GameState.mode, ChaseState.RACE)
	assert_true(GameState.explore_locked)
	assert_false(GameState.read_aloud, "voice stays off")
	assert_eq(GameState.engine.to_dict().counting.session["1"].answers, 1)


func test_three_saved_sessions_master_a_level_without_double_counting() -> void:
	for session: int in 3:
		GameState.reset()
		GameState.start_profile(path)
		for answer: int in 5:
			GameState.engine.record_answer("counting", true, 20.0)
		assert_true(GameState.finish_session())
		assert_true(GameState.finish_session(), "closing again does not count twice")
		assert_eq(int(GameState.engine.to_dict().counting.streaks["1"]), session + 1)
	GameState.reset()
	GameState.start_profile(path)
	assert_true(GameState.engine.is_level_mastered("counting", 1))
	GameState.finish_session()
	assert_eq(int(GameState.engine.to_dict().counting.streaks["1"]), 3, "empty reopen gives no mastery credit")


func test_interrupted_session_is_resumed_until_explicit_completion() -> void:
	GameState.start_profile(path)
	for answer: int in 3:
		GameState.engine.record_answer("counting", true, 20.0)
	GameState.save_progress()
	GameState.reset() # Simulate process termination without finish_session.
	GameState.start_profile(path)
	for answer: int in 2:
		GameState.engine.record_answer("counting", true, 20.0)
	GameState.finish_session()
	assert_eq(int(GameState.engine.to_dict().counting.streaks["1"]), 1)


func test_failed_session_save_preserves_answers_until_retry_succeeds() -> void:
	GameState.start_profile(path)
	GameState.save_progress()
	GameState.profile_path = path.path_join("impossible.json")
	for answer: int in 3:
		GameState.engine.record_answer("counting", true, 20.0)
	assert_false(GameState.finish_session())
	assert_eq(GameState.engine.to_dict().counting.session["1"].answers, 3)
	GameState.profile_path = path
	for answer: int in 2:
		GameState.engine.record_answer("counting", true, 20.0)
	assert_true(GameState.finish_session())
	assert_true(GameState.finish_session())
	GameState.reset()
	GameState.start_profile(path)
	assert_eq(int(GameState.engine.to_dict().counting.streaks["1"]), 1)
	assert_true(GameState.engine.to_dict().counting.session.is_empty())


func test_bad_primary_recovers_backup_and_keeps_damaged_copy() -> void:
	GameState.start_profile(path)
	GameState.record_rescue("raccoon", "meadow", "meadow", Vector2i(1, 2))
	GameState.record_care("raccoon") # backup now includes the rescue
	_raw("truncated {")
	GameState.reset()
	assert_true(GameState.start_profile(path))
	assert_eq(GameState.rescued_count(), 1)
	assert_string_contains(GameState.save_message, "recovered")
	assert_true(GameState.save_progress())
	assert_eq(ProfileStore.read_profile(path).status, "ok")
	var damaged: bool = false
	for file: String in DirAccess.get_files_at(directory):
		damaged = damaged or file.contains(".damaged-")
	assert_true(damaged)


func test_missing_primary_recovers_backup_after_interrupted_rotation() -> void:
	var data: Dictionary = GameState.snapshot()
	_raw(JSON.stringify(data), path + ".bak")
	assert_eq(ProfileStore.read_profile(path).status, "recovered")
	assert_eq(ProfileStore.write_profile(path, data), OK)
	assert_eq(ProfileStore.read_profile(path).status, "ok")


func test_invalid_or_newer_save_is_not_overwritten() -> void:
	for contents: String in ["broken", '{"version": 999}']:
		_raw(contents)
		GameState.reset()
		assert_false(GameState.start_profile(path))
		assert_false(GameState.can_start())
		assert_false(GameState.save_progress())
		assert_eq(FileAccess.get_file_as_string(path), contents)


func test_newer_primary_does_not_roll_back_to_old_backup() -> void:
	_raw(JSON.stringify(GameState.snapshot()), path + ".bak")
	_raw('{"version": 999}')
	assert_eq(ProfileStore.read_profile(path).status, "newer")


func test_nested_malformed_values_are_rejected_before_restore() -> void:
	var bad: Array[Dictionary] = []
	var data: Dictionary = GameState.snapshot()
	data.rescues = [{"animal": "raccoon", "habitat": "meadow", "map": "meadow", "cell": "oops"}]
	bad.append(data)
	data = GameState.snapshot()
	data.progress.counting.window = ["oops"]
	bad.append(data)
	data = GameState.snapshot()
	data.progress.counting.session = {"1": {"answers": 2, "correct": 9}}
	bad.append(data)
	data = GameState.snapshot()
	data.care_visits = {"raccoon": -1}
	bad.append(data)
	for snapshot: Dictionary in bad:
		_raw(JSON.stringify(snapshot))
		assert_eq(ProfileStore.read_profile(path).status, "invalid")


func test_reset_disables_automatic_writes_without_deleting_progress() -> void:
	GameState.start_profile(path)
	GameState.record_care("raccoon")
	var saved: String = FileAccess.get_file_as_string(path)
	GameState.reset()
	GameState.record_care("raccoon")
	assert_false(GameState.persistence_enabled)
	assert_eq(FileAccess.get_file_as_string(path), saved)


func test_full_playtest_uses_separate_profile_and_preserves_start_level() -> void:
	GameState.start_profile(path)
	GameState.record_rescue("raccoon", "meadow", "meadow", Vector2i(3, 4))
	var saved: String = FileAccess.get_file_as_string(path)
	GameState.reset()
	var config: Dictionary = GameState.load_playtest_config(GameState.FULL_PLAYTEST_PATH)
	config.log = false
	GameState.enable_playtest(config)
	assert_eq(GameState.engine.level(GameState.playtest_skill()), 3)
	assert_eq(GameState.respawn_seconds(), 0.0)
	assert_true(GameState.start_profile(directory.path_join("playtest.json"), "playtest-2"))
	GameState.engine.set_level(GameState.playtest_skill(), 4)
	GameState.record_care("raccoon")
	GameState.reset()
	GameState.enable_playtest(config)
	GameState.start_profile(directory.path_join("playtest.json"), "playtest-2")
	assert_eq(GameState.engine.level(GameState.playtest_skill()), 4)
	assert_eq(FileAccess.get_file_as_string(path), saved)


func test_wrong_profile_identity_and_unwritable_path_report_errors() -> void:
	_raw(JSON.stringify(GameState.snapshot()))
	assert_false(GameState.start_profile(path, "playtest-2"))
	GameState.reset()
	assert_true(GameState.start_profile(path.path_join("impossible.json")))
	assert_false(GameState.save_progress())
	assert_ne(GameState.save_message, "")
