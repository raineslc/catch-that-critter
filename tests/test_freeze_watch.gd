extends GutTest
## The playtest freeze detector writes "freeze" (with the last steps) when the main loop stalls,
## and "recovered" when it wakes up.

const LOG_DIR: String = "user://test_freeze_logs"

var log_file: PlaytestLog
var watch: FreezeWatch


func before_each() -> void:
	log_file = PlaytestLog.new()
	log_file.open(LOG_DIR)
	watch = FreezeWatch.new()
	add_child_autofree(watch)


func after_each() -> void:
	watch.stop()
	log_file.close()
	for file: String in DirAccess.get_files_at(LOG_DIR):
		DirAccess.remove_absolute(LOG_DIR.path_join(file))


func _events() -> Array:
	var out: Array = []
	for line: String in FileAccess.get_file_as_string(log_file.path).split("\n", false):
		out.append(JSON.parse_string(line))
	return out


func test_stalled_main_loop_is_reported_with_the_last_steps() -> void:
	watch.start(log_file, 300)
	await wait_frames(2)
	watch.mark("tts: speak 'What is 5 plus 1?'")
	OS.delay_msec(900)  # freeze the main thread on purpose
	await wait_process_frames(3)  # process frames: physics catch-up after the stall runs first
	var events: Array = _events()
	var freezes: Array = events.filter(func(e: Dictionary) -> bool: return e["event"] == "freeze")
	assert_eq(freezes.size(), 1, "one freeze report per stall")
	assert_gte(int(freezes[0]["stuck_ms"]), 300)
	var steps: Array = freezes[0]["last_steps"]
	assert_string_contains(str(steps[steps.size() - 1]), "tts: speak")
	var recovered: Array = events.filter(func(e: Dictionary) -> bool: return e["event"] == "recovered")
	assert_eq(recovered.size(), 1)
	assert_gte(int(recovered[0]["stuck_ms"]), 800)


func test_no_report_while_the_game_runs_normally() -> void:
	watch.start(log_file, 300)
	await wait_seconds(0.8)
	assert_eq(_events().size(), 0)


func test_keeps_only_recent_breadcrumbs() -> void:
	for i: int in FreezeWatch.KEEP_BREADCRUMBS + 5:
		watch.mark("step %d" % i)
	var crumbs: Array[String] = watch.breadcrumbs()
	assert_eq(crumbs.size(), FreezeWatch.KEEP_BREADCRUMBS)
	assert_string_contains(crumbs[crumbs.size() - 1], "step %d" % (FreezeWatch.KEEP_BREADCRUMBS + 4))


func test_playtest_mode_starts_the_watch() -> void:
	GameState.reset()
	GameState.enable_playtest(GameState.load_playtest_config(), LOG_DIR)
	assert_not_null(GameState.freeze_watch)
	GameState.breadcrumb("hello")
	assert_string_contains(GameState.freeze_watch.breadcrumbs()[-1], "hello")
	GameState.reset()
	assert_null(GameState.freeze_watch)
