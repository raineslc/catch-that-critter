class_name ChaseScreen
extends CanvasLayer
## The chase (PLAN.md 3.6–3.7): the critter runs along a path with the ranger behind it.
## Each problem shows big answer buttons. Right answers speed the ranger up and close the gap;
## misses let the critter pull ahead a little. Enough right answers → net toss → caught!
## The sidekick (Henrito) cheers, and after enough misses on one problem gives a spoken hint
## with a hint picture. Race mode adds a timer (the critter can get away; "Chase again" retries)
## and a sprint boost for fast right answers.
## Emits `finished(caught)` when the player leaves the chase.

signal finished(caught: bool)

const RANGER_X: float = 200.0
const SPRITE_SCALE: float = 4.0
const TILE: int = 16
const TRACK_TOP: float = 24.0
## Track rows from top: grass, grass, path (where they run), grass.
const TRACK_ROWS: int = 4
const RUN_ROW: int = 2
const GRASS_ATLAS: Vector2i = Vector2i(0, 12)
## Middle piece of the 1-wide horizontal path in floor.png (light grass set).
const PATH_ATLAS: Vector2i = Vector2i(1, 10)
const FLOOR_TEXTURE: Texture2D = preload("res://assets/tilesets/floor.png")
const HAPPY_EMOTE: Texture2D = preload("res://assets/ui/emotes/happy.png")

const SFX_CORRECT: AudioStream = preload("res://assets/audio/sfx/correct.wav")
const SFX_TRY_AGAIN: AudioStream = preload("res://assets/audio/sfx/try_again.wav")
const SFX_NET: AudioStream = preload("res://assets/audio/sfx/net_toss.wav")
const SFX_CAUGHT: AudioStream = preload("res://assets/audio/sfx/caught.wav")

const PROMPT_FONT_SIZE: int = 56
const BUTTON_FONT_SIZE: int = 44
const FEEDBACK_FONT_SIZE: int = 34
const BUBBLE_FONT_SIZE: int = 26
const TIMER_FONT_SIZE: int = 34
const BUTTON_MIN_SIZE: Vector2 = Vector2(190, 110)
const WIDE_BUTTON_MIN_SIZE: Vector2 = Vector2(360, 110)
const PICTURE_HEIGHT: float = 150.0
const METER_DOT_SIZE: float = 34.0
const NET_TOSS_SECONDS: float = 0.5
const ESCAPE_RUN_SECONDS: float = 0.8
const PORTRAIT_SIZE: float = 192.0
const SIDEKICK_FACE_SIZE: float = 88.0
const BUBBLE_WIDTH: float = 640.0
const TIMER_BAR_WIDTH: float = 260.0
const SPRINT_BURST_MULTIPLIER: float = 1.5

const PRAISE: Array[String] = ["Great job!", "You got it!", "Nice! Keep going!", "Getting closer!"]
const TRY_AGAIN: String = "Try again. You've got this."
const CAUGHT_TEXT: String = "You caught the %s!"
const ESCAPED_TEXT: String = "The %s got away!"
const SPRINT_TEXT: String = "Sprint boost! +%ds"
const CHASE_AGAIN: String = "Chase again"
const BACK_TO_MAP: String = "Back to the map"

## Turn off in tests so nothing advances on a timer.
var auto_advance: bool = true

var animal: Dictionary = {}
var skill_id: String = ""
var chase: ChaseState
var config: Dictionary = {}
var problem: MathProblem
var sidekick: Sidekick
## False while waiting for the next problem, celebrating, or after an escape.
var accepting: bool = false
## Misses on the current problem (for when the hint appears).
var misses_this_problem: int = 0
var hint_shown: bool = false

var track: Control
var ranger_sprite: AnimatedSprite2D
var critter_sprite: AnimatedSprite2D
var critter_emote: Sprite2D
var net: Node2D
var prompt_label: Label
var picture: ProblemPicture
var hint_picture: HintPicture
var choices_box: HBoxContainer
var feedback: Label
var meter: HBoxContainer
## Big portrait of the rescued animal, shown after the catch.
var portrait: TextureRect
var bubble: PanelContainer
var bubble_label: Label
var bubble_face: TextureRect
var timer_box: VBoxContainer
var timer_label: Label
var timer_bar: ProgressBar

var _track_rows: Array[TextureRect] = []
var _scroll: float = 0.0
var _burst_left: float = 0.0
var _burst_speed: float = 0.0
var _first_try_recorded: bool = false
var _shown_at_msec: int = 0
var _catching: bool = false
var _praise_index: int = 0
var _bubble_hide_at_msec: int = -1
var _sfx: AudioStreamPlayer
var later_button: Button
var _delay_tween: Tween
var _motion_tween: Tween
var _finished: bool = false


func _ready() -> void:
	layer = 10
	_build()


## Begin a chase after `animal` (AnimalCatalog data) using problems from `chase_skill`.
## `chase_mode` is ChaseState.EXPLORE or ChaseState.RACE (default: GameState's current mode).
func start(chase_animal: Dictionary, chase_skill: String, chase_mode: String = "", chase_config: Dictionary = {}) -> void:
	_cancel_transitions()
	_finished = false
	_catching = false
	animal = chase_animal
	skill_id = chase_skill
	config = chase_config if not chase_config.is_empty() else ChaseState.load_config()
	chase = ChaseState.new(config, chase_mode if chase_mode != "" else GameState.chase_mode())
	sidekick = Sidekick.load_by_id(GameState.sidekick_id, GameState.rng)
	bubble_face.texture = sidekick.faceset()
	critter_sprite.sprite_frames = Critter.build_frames(animal)
	critter_sprite.flip_h = str(animal.get("faces", "right")) != "right"
	timer_box.visible = chase.is_race()
	_reset_runners()
	say_sidekick(sidekick.line("chase_start"), float(config.get("sidekick_line_seconds", 2.5)))
	next_problem()


func next_problem() -> void:
	if _finished or chase == null or chase.is_over():
		return
	GameState.breadcrumb("chase: next problem (level %d)" % GameState.engine.level(skill_id))
	problem = GameState.factory.generate(skill_id, GameState.engine.level(skill_id), GameState.rng)
	GameState.breadcrumb("chase: made '%s'" % problem.prompt)
	_first_try_recorded = false
	misses_this_problem = 0
	hint_shown = false
	_shown_at_msec = Time.get_ticks_msec()
	prompt_label.text = problem.prompt
	picture.show_problem(problem, critter_sprite.sprite_frames.get_frame_texture("walk", 0))
	picture.visible = true
	hint_picture.visible = false
	feedback.text = ""
	if _bubble_hide_at_msec < 0:
		bubble.visible = false
	var buttons: Array[Button] = []
	for choice: String in problem.choices:
		var button: Button = _big_button(choice, BUTTON_MIN_SIZE)
		button.pressed.connect(answer.bind(choice), CONNECT_DEFERRED)
		buttons.append(button)
	_set_buttons(buttons)
	accepting = true
	GameState.breadcrumb("chase: buttons ready")
	if GameState.read_aloud:
		Speech.say(problem.spoken)


## One button press. `seconds` overrides the measured answer time (tests).
func answer(choice: String, seconds: float = -1.0) -> void:
	if _finished or not accepting:
		return
	GameState.breadcrumb("chase: pressed '%s'" % choice)
	var correct: bool = problem.is_correct(choice)
	var elapsed: float = seconds if seconds >= 0.0 else (Time.get_ticks_msec() - _shown_at_msec) / 1000.0
	var first_try: bool = not _first_try_recorded
	GameState.log_event("answer", {"skill": skill_id, "level": problem.level, "type": problem.type,
		"prompt": problem.prompt, "answer": problem.answer, "choice": choice, "correct": correct,
		"first_try": first_try, "seconds": snappedf(elapsed, 0.1), "hint_shown": hint_shown, "mode": chase.mode})
	if first_try:
		_first_try_recorded = true
		var change: AdaptiveEngine.Change = GameState.engine.record_answer(skill_id, correct, elapsed)
		if change != AdaptiveEngine.Change.NONE:
			GameState.log_event("level_change", {"skill": skill_id, "to": GameState.engine.level(skill_id),
				"direction": "up" if change == AdaptiveEngine.Change.LEVEL_UP else "down"})
		GameState.save_progress()
	chase.answer(correct, elapsed)
	_update_meter()
	if not correct:
		_play(SFX_TRY_AGAIN)
		feedback.text = TRY_AGAIN
		misses_this_problem += 1
		for button: Button in choice_buttons():
			if button.text == choice:
				button.disabled = true
		if not hint_shown and misses_this_problem >= GameState.engine.misses_before_hint(skill_id):
			show_hint()
		_refresh_focus()
		return
	accepting = false
	_play(SFX_CORRECT)
	_burst_left = float(config.get("burst_seconds", 0.6))
	_burst_speed = float(config.get("burst_scroll_speed", 420.0)) * (SPRINT_BURST_MULTIPLIER if chase.last_sprint else 1.0)
	for button: Button in choice_buttons():
		button.disabled = true
	_refresh_focus()
	if chase.caught:
		_begin_catch()
		return
	if chase.last_sprint:
		feedback.text = SPRINT_TEXT % roundi(chase.sprint_time_bonus)
		say_sidekick(sidekick.line("sprint"), float(config.get("sidekick_line_seconds", 2.5)))
	else:
		feedback.text = PRAISE[_praise_index % PRAISE.size()]
		_praise_index += 1
	if auto_advance:
		_schedule(float(config.get("next_problem_delay", 0.9)), next_problem)


## The sidekick's spoken hint and hint picture for the current problem.
func show_hint() -> void:
	hint_shown = true
	GameState.log_event("hint", {"skill": skill_id, "level": problem.level, "type": problem.type, "prompt": problem.prompt})
	picture.visible = false
	hint_picture.show_problem(problem)
	hint_picture.visible = HintPicture.kind_for(problem) != ""
	if not hint_picture.visible:
		picture.visible = true
	say_sidekick(HintText.for_problem(problem), 0.0)


## Shows the sidekick's speech bubble (and says it aloud). `seconds` 0 = stays until the next problem.
func say_sidekick(text: String, seconds: float) -> void:
	if text == "":
		return
	bubble_label.text = text
	bubble.visible = true
	_bubble_hide_at_msec = Time.get_ticks_msec() + int(seconds * 1000.0) if seconds > 0.0 else -1
	if GameState.read_aloud and sidekick != null:
		Speech.say(text, sidekick.voice_rate(), sidekick.voice_pitch())


func choice_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in choices_box.get_children():
		if child is Button:
			buttons.append(child)
	return buttons


## After an escape: start the same chase over.
func retry() -> void:
	if _finished:
		return
	_cancel_transitions()
	GameState.log_event("chase_again", {"animal": animal.get("id", "")})
	chase.restart()
	_catching = false
	_update_meter()
	_reset_runners()
	say_sidekick(sidekick.line("chase_start"), float(config.get("sidekick_line_seconds", 2.5)))
	next_problem()


## Leaves the chase (called automatically after the catch celebration).
func finish() -> void:
	if _finished:
		return
	_finished = true
	accepting = false
	_cancel_transitions()
	Speech.stop()
	finished.emit(chase != null and chase.caught)


func _unhandled_input(event: InputEvent) -> void:
	if not _finished and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		finish()


func _schedule(seconds: float, action: Callable) -> void:
	if _delay_tween != null:
		_delay_tween.kill()
	_delay_tween = create_tween()
	_delay_tween.tween_interval(seconds)
	_delay_tween.tween_callback(action)


func _cancel_transitions() -> void:
	if _delay_tween != null:
		_delay_tween.kill()
		_delay_tween = null
	if _motion_tween != null:
		_motion_tween.kill()
		_motion_tween = null


func _refresh_focus() -> void:
	var buttons: Array[Button] = choice_buttons()
	buttons.append(later_button)
	KeyboardFocus.connect_group(buttons)


func _begin_catch() -> void:
	_cancel_transitions()
	GameState.breadcrumb("chase: net toss")
	_catching = true
	var caught_text: String = CAUGHT_TEXT % animal.get("name", "critter")
	_clear_question(caught_text)
	if animal.has("faceset"):
		portrait.texture = load(str(animal["faceset"]))
		portrait.visible = true
	_play(SFX_NET)
	net.position = ranger_sprite.position
	net.visible = true
	_motion_tween = create_tween()
	var tween: Tween = _motion_tween
	tween.tween_property(ranger_sprite, "position:x", critter_sprite.position.x - TILE * SPRITE_SCALE * 0.8, NET_TOSS_SECONDS)
	tween.parallel().tween_property(net, "position", critter_sprite.position + Vector2(0, -TILE * SPRITE_SCALE * 0.4), NET_TOSS_SECONDS)
	tween.tween_callback(_on_net_landed)


func _on_net_landed() -> void:
	GameState.breadcrumb("chase: net landed")
	critter_sprite.stop()
	ranger_sprite.play("idle_right")
	critter_emote.visible = true
	_play(SFX_CAUGHT)
	say_sidekick(sidekick.line("caught"), 0.0)
	if auto_advance:
		_schedule(float(config.get("caught_show_seconds", 2.5)), finish)


## Race timer ran out: the critter dashes off; offer to chase again.
func _begin_escape() -> void:
	_cancel_transitions()
	_catching = true
	GameState.log_event("escaped", {"animal": animal.get("id", ""), "correct": chase.correct, "misses": chase.misses})
	_clear_question(ESCAPED_TEXT % animal.get("name", "critter"))
	_motion_tween = create_tween()
	var tween: Tween = _motion_tween
	tween.tween_property(critter_sprite, "position:x", track.size.x + TILE * SPRITE_SCALE * 2, ESCAPE_RUN_SECONDS)
	ranger_sprite.play("idle_right")
	say_sidekick(sidekick.line("escaped"), 0.0)
	var again: Button = _big_button(CHASE_AGAIN, WIDE_BUTTON_MIN_SIZE)
	again.pressed.connect(retry, CONNECT_DEFERRED)
	var back: Button = _big_button(BACK_TO_MAP, WIDE_BUTTON_MIN_SIZE)
	back.pressed.connect(finish, CONNECT_DEFERRED)
	_set_buttons([again, back])


func _clear_question(headline: String) -> void:
	accepting = false
	prompt_label.text = headline
	feedback.text = ""
	picture.show_problem(null)
	picture.visible = false
	hint_picture.visible = false
	_set_buttons([])


func _process(delta: float) -> void:
	if _finished or chase == null:
		return
	if _bubble_hide_at_msec >= 0 and Time.get_ticks_msec() >= _bubble_hide_at_msec:
		bubble.visible = false
		_bubble_hide_at_msec = -1
	if chase.tick(delta):
		_begin_escape()
	if chase.is_race():
		timer_label.text = "%ds" % ceili(chase.time_left)
		timer_bar.max_value = maxf(chase.race_seconds, chase.time_left)
		timer_bar.value = chase.time_left
	_burst_left = maxf(_burst_left - delta, 0.0)
	var speed: float = 0.0
	if not _catching:
		speed = _burst_speed if _burst_left > 0.0 else float(config.get("run_scroll_speed", 160.0))
	_scroll += speed * delta
	var tile_px: float = TILE * SPRITE_SCALE
	for row: TextureRect in _track_rows:
		row.position.x = -fmod(_scroll, tile_px)
	if not _catching:
		critter_sprite.position.x = lerpf(critter_sprite.position.x, _critter_x(), minf(delta * 3.0, 1.0))
	critter_emote.position = critter_sprite.position + Vector2(0, -TILE * SPRITE_SCALE * 0.9)


func _critter_x() -> float:
	return RANGER_X + TILE * SPRITE_SCALE + chase.gap * float(config.get("gap_pixels", 170))


func _reset_runners() -> void:
	ranger_sprite.position.x = RANGER_X
	ranger_sprite.play("walk_right")
	critter_sprite.position.x = _critter_x()
	critter_sprite.play("walk")
	critter_emote.visible = false
	net.visible = false
	portrait.visible = false


func _update_meter() -> void:
	var filled: int = chase.correct if chase != null else 0
	var slots: Array[Node] = meter.get_children()
	for i: int in slots.size():
		var dot: Panel = slots[i]
		var style: StyleBoxFlat = dot.get_theme_stylebox("panel").duplicate()
		style.bg_color = Color(1, 0.8, 0.2) if i < filled else Color(1, 1, 1, 0.35)
		dot.add_theme_stylebox_override("panel", style)


func _big_button(text: String, min_size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	KeyboardFocus.style(button)
	return button


## Replaces the answer buttons. Old buttons are freed right away; that's safe because every
## button's `pressed` is connected deferred (see _big_button), so none is mid-signal here.
func _set_buttons(buttons: Array) -> void:
	for child: Node in choices_box.get_children():
		choices_box.remove_child(child)
		child.free()
	for button: Variant in buttons:
		choices_box.add_child(button)
	var preferred: Button = buttons[0] if not buttons.is_empty() else later_button
	var focus_buttons: Array[Button] = choice_buttons()
	focus_buttons.append(later_button)
	KeyboardFocus.connect_group(focus_buttons, preferred)


func _play(stream: AudioStream) -> void:
	GameState.breadcrumb("sound: %s" % stream.resource_path.get_file())
	_sfx.stream = stream
	_sfx.play()


func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.36, 0.55, 0.33)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var tile_px: float = TILE * SPRITE_SCALE
	track = Control.new()
	track.name = "Track"
	track.clip_contents = true
	track.position = Vector2(0, TRACK_TOP)
	track.size = Vector2(1280, TRACK_ROWS * tile_px)
	add_child(track)
	for r: int in TRACK_ROWS:
		var row: TextureRect = TextureRect.new()
		var tile: AtlasTexture = AtlasTexture.new()
		tile.atlas = FLOOR_TEXTURE
		tile.region = Rect2((PATH_ATLAS if r == RUN_ROW else GRASS_ATLAS) * TILE, Vector2(TILE, TILE))
		row.texture = tile
		row.stretch_mode = TextureRect.STRETCH_TILE
		row.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.size = Vector2(1280.0 / SPRITE_SCALE + TILE * 2, TILE)
		row.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
		row.position = Vector2(0, r * tile_px)
		track.add_child(row)
		_track_rows.append(row)
	var run_y: float = RUN_ROW * tile_px + tile_px * 0.75
	ranger_sprite = _actor_sprite(Ranger.build_frames(Ranger.DEFAULT_SHEET), Vector2(RANGER_X, run_y))
	ranger_sprite.name = "Ranger"
	critter_sprite = _actor_sprite(null, Vector2(RANGER_X + 400, run_y))
	critter_sprite.name = "Critter"
	critter_emote = Sprite2D.new()
	critter_emote.texture = HAPPY_EMOTE
	critter_emote.scale = Vector2(SPRITE_SCALE * 0.75, SPRITE_SCALE * 0.75)
	critter_emote.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	critter_emote.visible = false
	track.add_child(critter_emote)
	net = ChaseNet.new()
	net.visible = false
	track.add_child(net)

	meter = HBoxContainer.new()
	meter.name = "CatchMeter"
	meter.position = Vector2(1280 - 24 - 3 * (METER_DOT_SIZE + 8), TRACK_TOP + 12)
	meter.add_theme_constant_override("separation", 8)
	add_child(meter)
	for i: int in int(ChaseState.load_config().get("correct_to_catch", 3)):
		var dot: Panel = Panel.new()
		dot.custom_minimum_size = Vector2(METER_DOT_SIZE, METER_DOT_SIZE)
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.set_corner_radius_all(int(METER_DOT_SIZE / 2.0))
		style.border_color = Color(0.25, 0.2, 0.1)
		style.set_border_width_all(3)
		dot.add_theme_stylebox_override("panel", style)
		meter.add_child(dot)

	_build_timer()
	_build_bubble()
	later_button = _big_button("Later (Esc)", Vector2(220, 64))
	later_button.add_theme_font_size_override("font_size", 28)
	later_button.position = Vector2(16, 210)
	later_button.pressed.connect(finish, CONNECT_DEFERRED)
	add_child(later_button)

	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(0, TRACK_TOP + TRACK_ROWS * tile_px + 6)
	column.size = Vector2(1280, 720 - column.position.y)
	column.add_theme_constant_override("separation", 6)
	add_child(column)
	prompt_label = Label.new()
	prompt_label.add_theme_font_size_override("font_size", PROMPT_FONT_SIZE)
	prompt_label.add_theme_color_override("font_outline_color", Color(0.15, 0.25, 0.1))
	prompt_label.add_theme_constant_override("outline_size", 10)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(prompt_label)
	picture = ProblemPicture.new()
	picture.custom_minimum_size = Vector2(1280, PICTURE_HEIGHT)
	column.add_child(picture)
	hint_picture = HintPicture.new()
	hint_picture.name = "HintPicture"
	hint_picture.custom_minimum_size = Vector2(1280, PICTURE_HEIGHT)
	hint_picture.visible = false
	column.add_child(hint_picture)
	portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.visible = false
	column.add_child(portrait)
	choices_box = HBoxContainer.new()
	choices_box.alignment = BoxContainer.ALIGNMENT_CENTER
	choices_box.add_theme_constant_override("separation", 28)
	column.add_child(choices_box)
	feedback = Label.new()
	feedback.add_theme_font_size_override("font_size", FEEDBACK_FONT_SIZE)
	feedback.add_theme_color_override("font_outline_color", Color(0.15, 0.25, 0.1))
	feedback.add_theme_constant_override("outline_size", 8)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(feedback)

	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)


## Race timer, over the track between the sidekick's bubble and the catch meter.
func _build_timer() -> void:
	timer_box = VBoxContainer.new()
	timer_box.name = "RaceTimer"
	timer_box.position = Vector2(16 + BUBBLE_WIDTH + 40, TRACK_TOP + 6)
	timer_box.custom_minimum_size = Vector2(TIMER_BAR_WIDTH, 0)
	timer_box.visible = false
	add_child(timer_box)
	timer_label = Label.new()
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.add_theme_font_size_override("font_size", TIMER_FONT_SIZE)
	timer_label.add_theme_color_override("font_outline_color", Color(0.15, 0.25, 0.1))
	timer_label.add_theme_constant_override("outline_size", 8)
	timer_box.add_child(timer_label)
	timer_bar = ProgressBar.new()
	timer_bar.show_percentage = false
	timer_bar.custom_minimum_size = Vector2(TIMER_BAR_WIDTH, 16)
	var back: StyleBoxFlat = StyleBoxFlat.new()
	back.bg_color = Color(0.15, 0.25, 0.1, 0.6)
	back.set_corner_radius_all(8)
	timer_bar.add_theme_stylebox_override("background", back)
	var fill: StyleBoxFlat = StyleBoxFlat.new()
	fill.bg_color = Color(1, 0.8, 0.2)
	fill.set_corner_radius_all(8)
	timer_bar.add_theme_stylebox_override("fill", fill)
	timer_box.add_child(timer_bar)


## Sidekick portrait + speech bubble, top left over the track.
func _build_bubble() -> void:
	bubble = PanelContainer.new()
	bubble.name = "SidekickBubble"
	bubble.position = Vector2(16, TRACK_TOP + 8)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 0.97)
	style.border_color = Color(0.3, 0.25, 0.15)
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(10)
	bubble.add_theme_stylebox_override("panel", style)
	bubble.visible = false
	add_child(bubble)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	bubble.add_child(row)
	bubble_face = TextureRect.new()
	bubble_face.custom_minimum_size = Vector2(SIDEKICK_FACE_SIZE, SIDEKICK_FACE_SIZE)
	bubble_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bubble_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	bubble_face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(bubble_face)
	bubble_label = Label.new()
	bubble_label.custom_minimum_size = Vector2(BUBBLE_WIDTH - SIDEKICK_FACE_SIZE - 40, 0)
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_label.add_theme_font_size_override("font_size", BUBBLE_FONT_SIZE)
	bubble_label.add_theme_color_override("font_color", Color(0.2, 0.18, 0.12))
	row.add_child(bubble_label)


func _actor_sprite(frames: SpriteFrames, at: Vector2) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(0, -TILE / 2.0)
	sprite.position = at
	track.add_child(sprite)
	return sprite
