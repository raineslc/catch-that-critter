extends Control
## Debug screen (grown-ups only): answer generated problems and watch the adaptive engine react.
## Open scenes/debug/problem_tester.tscn in Godot and press F6 (Run Current Scene).

const PROMPT_FONT_SIZE: int = 56
const BUTTON_FONT_SIZE: int = 40
const INFO_FONT_SIZE: int = 20
const BUTTON_MIN_SIZE: Vector2 = Vector2(180, 110)
const LOG_LINES: int = 10
const NEXT_PROBLEM_DELAY: float = 0.8
const TTS_LANGUAGE: String = "en"

const PRAISE: String = "Nice! You got it."
const TRY_AGAIN: String = "Try again. You've got this."

## Turn off in tests so the next problem only comes when asked.
var auto_advance: bool = true
## Read prompts aloud with text-to-speech (toggled on screen).
var speak_enabled: bool = false

var factory: ProblemFactory
var engine: AdaptiveEngine
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var problem: MathProblem
var skill_id: String = ""
var misses: int = 0
var solved: bool = false

var _first_try_recorded: bool = false
var _shown_at_msec: int = 0
var _log_lines: Array[String] = []
var _tts_voice: String = ""

var _skill_picker: OptionButton
var _level_picker: SpinBox
var _speak_toggle: CheckBox
var _status: Label
var _prompt: Label
var _picture: Label
var _spoken: Label
var _hint: Label
var _feedback: Label
var _choices_box: HBoxContainer
var _log: Label


func _ready() -> void:
	rng.randomize()
	factory = ProblemFactory.new()
	engine = AdaptiveEngine.new(AdaptiveEngine.level_counts_from(factory))
	_tts_voice = _find_voice()
	_build_ui()
	select_skill(factory.skill_ids()[0])


## Switches skill and shows a fresh problem at that skill's current level.
func select_skill(id: String) -> void:
	skill_id = id
	_skill_picker.select(factory.skill_ids().find(id))
	_level_picker.set_value_no_signal(engine.level(id))
	_level_picker.max_value = factory.level_count(id)
	next_problem()


func next_problem() -> void:
	problem = factory.generate(skill_id, engine.level(skill_id), rng)
	misses = 0
	solved = false
	_first_try_recorded = false
	_shown_at_msec = Time.get_ticks_msec()
	_prompt.text = problem.prompt
	var picture: String = describe_picture(problem)
	_picture.text = "Picture: " + picture if picture != "" else ""
	_spoken.text = "Says: \"%s\"" % problem.spoken
	_hint.text = ""
	_feedback.text = ""
	# Safe to free now: answer buttons never call next_problem() directly (the timer or toolbar does).
	for child: Node in _choices_box.get_children():
		_choices_box.remove_child(child)
		child.free()
	for choice: String in problem.choices:
		var button: Button = Button.new()
		button.text = choice
		button.custom_minimum_size = BUTTON_MIN_SIZE
		button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
		button.pressed.connect(answer.bind(choice))
		_choices_box.add_child(button)
	_refresh_status()
	_speak(problem.spoken)


## Handles one button press. `seconds` overrides the measured time (for tests).
func answer(choice: String, seconds: float = -1.0) -> void:
	if problem == null or solved:
		return
	var correct: bool = problem.is_correct(choice)
	if not _first_try_recorded:
		_first_try_recorded = true
		var elapsed: float = seconds if seconds >= 0.0 else (Time.get_ticks_msec() - _shown_at_msec) / 1000.0
		_report_change(engine.record_answer(skill_id, correct, elapsed))
		_refresh_status()
	if correct:
		solved = true
		_feedback.text = PRAISE
		for button: Button in choice_buttons():
			button.disabled = true
		_speak(PRAISE)
		if auto_advance:
			get_tree().create_timer(NEXT_PROBLEM_DELAY).timeout.connect(next_problem)
		return
	misses += 1
	_feedback.text = TRY_AGAIN
	for button: Button in choice_buttons():
		if button.text == choice:
			button.disabled = true
	if misses >= engine.misses_before_hint(skill_id):
		_hint.text = "Hint (%s): %s" % [problem.hint, describe_hint(problem)]


func choice_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in _choices_box.get_children():
		if child is Button:
			buttons.append(child)
	return buttons


## The picture that goes with the question, in words (real art comes in Phase 2).
static func describe_picture(p: MathProblem) -> String:
	var d: Dictionary = p.data
	match p.type:
		"count_objects":
			return "● ".repeat(int(d["count"])).strip_edges()
		"clock":
			return "clock face: short hand at %d, long hand at %d minutes" % [int(d["hour"]), int(d["minute"])]
		"coins":
			var parts: PackedStringArray = []
			for coin: Variant in d["coins"]:
				var count: int = int(d["coins"][coin])
				var name: String = str(coin)
				if count != 1:
					name = "pennies" if name == "penny" else name + "s"
				parts.append("%d %s" % [count, name])
			return "coins: " + ", ".join(parts)
		"equal_groups":
			var group: String = "(" + "●".repeat(int(d["size"])) + ") "
			return group.repeat(int(d["groups"])).strip_edges()
	return ""


## What the sidekick's visual hint would show, in words (the real pictures come in Phase 2).
static func describe_hint(p: MathProblem) -> String:
	var d: Dictionary = p.data
	match p.hint:
		"dots":
			if d.has("count"):
				return "● ".repeat(int(d["count"])).strip_edges()
			return "%s dots %s %s dots" % [d.get("a", "?"), d.get("op", "+"), d.get("b", "?")]
		"number_line":
			if d.has("n"):
				return "start at %d, hop one to the right" % int(d["n"])
			if d.has("total"):
				return "start at %d, count hops up to %d" % [int(d["a"]), int(d["total"])]
			if d.has("sequence"):
				return "each hop is %d" % int(d["step"])
			if d.has("a") and d.has("b") and not d.has("op"):
				return "%d and %d on a number line; more is further right" % [int(d["a"]), int(d["b"])]
			return "start at %d, hop %s %d" % [int(d["a"]), "forward" if d.get("op") == "+" else "back", int(d["b"])]
		"base_ten_blocks":
			var n: int = int(d.get("n", d.get("a", 0)))
			return "%d = %d hundreds, %d tens, %d ones" % [n, n / 100, (n / 10) % 10, n % 10]
		"clock":
			return "short hand near %d, long hand at minute %d" % [int(d["hour"]), int(d["minute"])]
		"coins":
			var parts: PackedStringArray = []
			for coin: Variant in d["coins"]:
				parts.append("%d %s" % [int(d["coins"][coin]), coin])
			return "count by coin: " + ", ".join(parts)
		"groups":
			if d.has("groups"):
				return "%d groups of %d" % [int(d["groups"]), int(d["size"])]
			if d.has("divisor"):
				return "share %d into %d equal groups" % [int(d["dividend"]), int(d["divisor"])]
			if d.has("product"):
				return "%d equal groups make %d; how many in each?" % [int(d["a"]), int(d["product"])]
			return "%d groups of %d" % [int(d["a"]), int(d["b"])]
	return "(no hint)"


func _report_change(change: AdaptiveEngine.Change) -> void:
	match change:
		AdaptiveEngine.Change.LEVEL_UP:
			_add_log("⬆ %s up to level %d" % [skill_id, engine.level(skill_id)])
		AdaptiveEngine.Change.LEVEL_DOWN:
			_add_log("⬇ %s down to level %d (extra help on)" % [skill_id, engine.level(skill_id)])
	_level_picker.set_value_no_signal(engine.level(skill_id))


func _end_session() -> void:
	var mastered: Array[Dictionary] = engine.end_session()
	if mastered.is_empty():
		_add_log("Session ended. No new mastery yet.")
	for entry: Dictionary in mastered:
		_add_log("★ Mastered %s level %d" % [entry["skill"], entry["level"]])
	_refresh_status()


func _refresh_status() -> void:
	var info: Dictionary = factory.level_info(skill_id, engine.level(skill_id))
	var stats: Dictionary = engine.stats(skill_id)
	_status.text = "Level %d of %d: %s   %s\nLast %d: %d%% right   Extra help: %s (hint after %d miss%s)   Lifetime: %d answers, %d%% right, avg %.1fs   Mastered levels: %s" % [
		engine.level(skill_id), factory.level_count(skill_id), info.get("description", ""), ", ".join(PackedStringArray(info.get("standards", []))),
		engine.window_count(skill_id), roundi(engine.window_accuracy(skill_id) * 100),
		"on" if engine.needs_extra_help(skill_id) else "off", engine.misses_before_hint(skill_id), "" if engine.misses_before_hint(skill_id) == 1 else "es",
		int(stats["answers"]), roundi(float(stats["accuracy"]) * 100), float(stats["average_seconds"]), stats["mastered_levels"],
	]


func _add_log(line: String) -> void:
	_log_lines.push_front(line)
	if _log_lines.size() > LOG_LINES:
		_log_lines.pop_back()
	_log.text = "\n".join(_log_lines)


func _find_voice() -> String:
	if not ProjectSettings.get_setting("audio/general/text_to_speech", false):
		return ""
	var voices: PackedStringArray = DisplayServer.tts_get_voices_for_language(TTS_LANGUAGE)
	return voices[0] if not voices.is_empty() else ""


func _speak(text: String) -> void:
	if speak_enabled and _tts_voice != "":
		DisplayServer.tts_stop()
		DisplayServer.tts_speak(text, _tts_voice)


func _build_ui() -> void:
	var margin: MarginContainer = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)

	var toolbar: HBoxContainer = HBoxContainer.new()
	toolbar.add_theme_constant_override("separation", 12)
	column.add_child(toolbar)
	toolbar.add_child(_info_label("DEBUG: Problem tester   Skill:"))
	_skill_picker = OptionButton.new()
	for id: String in factory.skill_ids():
		_skill_picker.add_item("%s (%s)" % [factory.skill_info(id).get("name", id), factory.skill_info(id).get("habitat", "")])
	_skill_picker.item_selected.connect(func(index: int) -> void: select_skill(factory.skill_ids()[index]))
	toolbar.add_child(_skill_picker)
	toolbar.add_child(_info_label("Level:"))
	_level_picker = SpinBox.new()
	_level_picker.min_value = 1
	_level_picker.value_changed.connect(func(value: float) -> void:
		engine.set_level(skill_id, int(value))
		next_problem())
	toolbar.add_child(_level_picker)
	var skip: Button = Button.new()
	skip.text = "New problem"
	skip.pressed.connect(next_problem)
	toolbar.add_child(skip)
	var end_session: Button = Button.new()
	end_session.text = "End session"
	end_session.pressed.connect(_end_session)
	toolbar.add_child(end_session)
	_speak_toggle = CheckBox.new()
	_speak_toggle.text = "Read aloud"
	_speak_toggle.disabled = _tts_voice == ""
	_speak_toggle.tooltip_text = "Text-to-speech voice: %s" % (_tts_voice if _tts_voice != "" else "none found")
	_speak_toggle.toggled.connect(func(on: bool) -> void:
		speak_enabled = on
		if on and problem != null:
			_speak(problem.spoken))
	toolbar.add_child(_speak_toggle)

	_status = _info_label("", true)
	column.add_child(_status)
	_prompt = Label.new()
	_prompt.add_theme_font_size_override("font_size", PROMPT_FONT_SIZE)
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_prompt)
	_picture = Label.new()
	_picture.add_theme_font_size_override("font_size", 28)
	_picture.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_picture.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_picture)
	_spoken = _info_label("")
	_spoken.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_spoken)
	_choices_box = HBoxContainer.new()
	_choices_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_choices_box.add_theme_constant_override("separation", 24)
	column.add_child(_choices_box)
	_feedback = Label.new()
	_feedback.add_theme_font_size_override("font_size", 32)
	_feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_feedback)
	_hint = _info_label("", true)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_hint)
	_log = _info_label("", true)
	column.add_child(_log)


## Wrapping labels must sit in a column (full width); in a row they shrink to one letter wide.
func _info_label(text: String, wrap: bool = false) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", INFO_FONT_SIZE)
	if wrap:
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label
