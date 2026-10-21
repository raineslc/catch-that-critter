extends GutTest
## Speech never interrupts the voice (that froze/crashed the game on Windows): a line asked for while
## the voice is busy waits and is spoken once it's quiet.

var speaking: bool = false
var spoken: Array[String] = []


func before_each() -> void:
	speaking = false
	spoken.clear()
	Speech.force_available = true
	Speech.is_speaking_fn = func() -> bool: return speaking
	Speech.speak_fn = func(text: String, _voice: String, _rate: float, _pitch: float) -> void:
		spoken.append(text)
		speaking = true


func after_each() -> void:
	Speech.use_real_voice()


func test_speaks_right_away_when_quiet() -> void:
	Speech.say("What is 5 plus 1?")
	assert_eq(spoken, ["What is 5 plus 1?"] as Array[String])
	assert_eq(Speech.pending_text(), "")


func test_waits_instead_of_interrupting() -> void:
	Speech.say("What is 5 plus 1?")
	Speech.say("What is 8 plus 1?")
	assert_eq(spoken.size(), 1, "second line must not cut off the first")
	assert_eq(Speech.pending_text(), "What is 8 plus 1?")
	Speech.poll()
	assert_eq(spoken.size(), 1, "still talking: keep waiting")
	speaking = false
	Speech.poll()
	assert_eq(spoken, ["What is 5 plus 1?", "What is 8 plus 1?"] as Array[String])
	assert_eq(Speech.pending_text(), "")


func test_only_the_newest_waiting_line_is_kept() -> void:
	Speech.say("one")
	Speech.say("two")
	Speech.say("three")
	speaking = false
	Speech.poll()
	assert_eq(spoken, ["one", "three"] as Array[String], "fast answers don't build a backlog")


func test_stop_drops_the_waiting_line_without_touching_the_voice() -> void:
	Speech.say("one")
	Speech.say("two")
	Speech.stop()
	speaking = false
	Speech.poll()
	assert_eq(spoken, ["one"] as Array[String])


func test_game_state_polls_the_waiting_line() -> void:
	Speech.say("one")
	Speech.say("two")
	speaking = false
	await wait_seconds(GameState.SPEECH_POLL_SECONDS * 3)
	assert_eq(spoken, ["one", "two"] as Array[String])


func test_voice_is_off_by_default_so_chases_stay_silent() -> void:
	GameState.reset()
	assert_false(GameState.read_aloud, "voice paused (DECISIONS.md 2026-10-21)")
	var screen: ChaseScreen = ChaseScreen.new()
	screen.auto_advance = false
	add_child_autofree(screen)
	screen.start(GameState.catalog.get_animal("raccoon"), "counting")
	screen.show_hint()
	assert_eq(spoken, [] as Array[String], "no question, cheer, or hint is spoken")
	assert_true(screen.bubble.visible, "Henrito's words still show in his bubble")


func test_no_code_stops_or_interrupts_the_voice() -> void:
	var offenders: Array[String] = []
	for dir: String in ["res://scripts"]:
		_scan(dir, offenders)
	assert_eq(offenders, [] as Array[String], "tts_stop / interrupting tts_speak can freeze the game on Windows")


func _scan(dir: String, offenders: Array[String]) -> void:
	for sub: String in DirAccess.get_directories_at(dir):
		_scan(dir.path_join(sub), offenders)
	for file: String in DirAccess.get_files_at(dir):
		if not file.ends_with(".gd"):
			continue
		var path: String = dir.path_join(file)
		var lines: PackedStringArray = FileAccess.get_file_as_string(path).split("\n")
		for i: int in lines.size():
			var code: String = lines[i].split("#")[0]
			if code.contains("tts_stop(") or (code.contains("tts_speak(") and code.contains("true)")):
				offenders.append("%s:%d" % [path, i + 1])
