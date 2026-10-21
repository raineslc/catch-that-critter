class_name ChaseScreen
extends CanvasLayer
## The chase (PLAN.md 3.6): the critter runs along a path with the ranger behind it.
## Each problem shows big answer buttons. Right answers speed the ranger up and close the gap;
## misses let the critter pull ahead a little. Enough right answers → net toss → caught!
## Emits `finished(true)` after the catch celebration.

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
const BUTTON_MIN_SIZE: Vector2 = Vector2(190, 110)
const PICTURE_HEIGHT: float = 150.0
const METER_DOT_SIZE: float = 34.0
const NET_TOSS_SECONDS: float = 0.5
const PORTRAIT_SIZE: float = 192.0

const PRAISE: Array[String] = ["Great job!", "You got it!", "Nice! Keep going!", "Getting closer!"]
const TRY_AGAIN: String = "Try again. You've got this."
const CAUGHT_TEXT: String = "You caught the %s!"

## Turn off in tests so nothing advances on a timer.
var auto_advance: bool = true

var animal: Dictionary = {}
var skill_id: String = ""
var chase: ChaseState
var config: Dictionary = {}
var problem: MathProblem
## False while waiting for the next problem or celebrating.
var accepting: bool = false

var track: Control
var ranger_sprite: AnimatedSprite2D
var critter_sprite: AnimatedSprite2D
var critter_emote: Sprite2D
var net: Node2D
var prompt_label: Label
var picture: ProblemPicture
var choices_box: HBoxContainer
var feedback: Label
var meter: HBoxContainer
## Big portrait of the rescued animal, shown after the catch.
var portrait: TextureRect

var _track_rows: Array[TextureRect] = []
var _scroll: float = 0.0
var _burst_left: float = 0.0
var _first_try_recorded: bool = false
var _shown_at_msec: int = 0
var _catching: bool = false
var _praise_index: int = 0
var _sfx: AudioStreamPlayer


func _ready() -> void:
	layer = 10
	_build()


## Begin a chase after `animal` (AnimalCatalog data) using problems from `chase_skill`.
func start(chase_animal: Dictionary, chase_skill: String, chase_config: Dictionary = {}) -> void:
	animal = chase_animal
	skill_id = chase_skill
	config = chase_config if not chase_config.is_empty() else ChaseState.load_config()
	chase = ChaseState.new(config)
	critter_sprite.sprite_frames = Critter.build_frames(animal)
	critter_sprite.flip_h = str(animal.get("faces", "right")) != "right"
	critter_sprite.play("walk")
	ranger_sprite.play("walk_right")
	critter_sprite.position.x = _critter_x()
	_update_meter()
	next_problem()


func next_problem() -> void:
	if chase == null or chase.caught:
		return
	problem = GameState.factory.generate(skill_id, GameState.engine.level(skill_id), GameState.rng)
	_first_try_recorded = false
	_shown_at_msec = Time.get_ticks_msec()
	prompt_label.text = problem.prompt
	picture.show_problem(problem, critter_sprite.sprite_frames.get_frame_texture("walk", 0))
	feedback.text = ""
	for child: Node in choices_box.get_children():
		choices_box.remove_child(child)
		child.free()
	for choice: String in problem.choices:
		var button: Button = Button.new()
		button.text = choice
		button.custom_minimum_size = BUTTON_MIN_SIZE
		button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(answer.bind(choice))
		choices_box.add_child(button)
	accepting = true
	if GameState.read_aloud:
		Speech.say(problem.spoken)


## One button press. `seconds` overrides the measured answer time (tests).
func answer(choice: String, seconds: float = -1.0) -> void:
	if not accepting:
		return
	var correct: bool = problem.is_correct(choice)
	if not _first_try_recorded:
		_first_try_recorded = true
		var elapsed: float = seconds if seconds >= 0.0 else (Time.get_ticks_msec() - _shown_at_msec) / 1000.0
		GameState.engine.record_answer(skill_id, correct, elapsed)
	chase.answer(correct)
	_update_meter()
	if not correct:
		_play(SFX_TRY_AGAIN)
		feedback.text = TRY_AGAIN
		for button: Button in choice_buttons():
			if button.text == choice:
				button.disabled = true
		return
	accepting = false
	_play(SFX_CORRECT)
	_burst_left = float(config.get("burst_seconds", 0.6))
	for button: Button in choice_buttons():
		button.disabled = true
	if chase.caught:
		_begin_catch()
		return
	feedback.text = PRAISE[_praise_index % PRAISE.size()]
	_praise_index += 1
	if auto_advance:
		get_tree().create_timer(float(config.get("next_problem_delay", 0.9))).timeout.connect(next_problem)


func choice_buttons() -> Array[Button]:
	var buttons: Array[Button] = []
	for child: Node in choices_box.get_children():
		if child is Button:
			buttons.append(child)
	return buttons


## Ends the chase (called automatically after the catch celebration).
func finish() -> void:
	Speech.stop()
	finished.emit(chase != null and chase.caught)


func _begin_catch() -> void:
	_catching = true
	var caught_text: String = CAUGHT_TEXT % animal.get("name", "critter")
	# Clear the question so the catch is the star.
	prompt_label.text = caught_text
	feedback.text = ""
	picture.show_problem(null)
	picture.visible = false
	if animal.has("faceset"):
		portrait.texture = load(str(animal["faceset"]))
		portrait.visible = true
	for child: Node in choices_box.get_children():
		choices_box.remove_child(child)
		child.free()
	_play(SFX_NET)
	net.position = ranger_sprite.position
	net.visible = true
	var tween: Tween = create_tween()
	tween.tween_property(ranger_sprite, "position:x", critter_sprite.position.x - TILE * SPRITE_SCALE * 0.8, NET_TOSS_SECONDS)
	tween.parallel().tween_property(net, "position", critter_sprite.position + Vector2(0, -TILE * SPRITE_SCALE * 0.4), NET_TOSS_SECONDS)
	tween.tween_callback(_on_net_landed.bind(caught_text))


func _on_net_landed(caught_text: String) -> void:
	critter_sprite.stop()
	ranger_sprite.play("idle_right")
	critter_emote.visible = true
	_play(SFX_CAUGHT)
	if GameState.read_aloud:
		Speech.say(caught_text)
	if auto_advance:
		get_tree().create_timer(float(config.get("caught_show_seconds", 2.5))).timeout.connect(finish)


func _process(delta: float) -> void:
	if chase == null:
		return
	_burst_left = maxf(_burst_left - delta, 0.0)
	var speed: float = 0.0
	if not _catching:
		speed = float(config.get("burst_scroll_speed" if _burst_left > 0.0 else "run_scroll_speed", 160.0))
	_scroll += speed * delta
	var tile_px: float = TILE * SPRITE_SCALE
	for row: TextureRect in _track_rows:
		row.position.x = -fmod(_scroll, tile_px)
	if not _catching:
		critter_sprite.position.x = lerpf(critter_sprite.position.x, _critter_x(), minf(delta * 3.0, 1.0))
	critter_emote.position = critter_sprite.position + Vector2(0, -TILE * SPRITE_SCALE * 0.9)


func _critter_x() -> float:
	return RANGER_X + TILE * SPRITE_SCALE + chase.gap * float(config.get("gap_pixels", 170))


func _update_meter() -> void:
	var filled: int = chase.correct if chase != null else 0
	var slots: Array[Node] = meter.get_children()
	for i: int in slots.size():
		var dot: Panel = slots[i]
		var style: StyleBoxFlat = dot.get_theme_stylebox("panel").duplicate()
		style.bg_color = Color(1, 0.8, 0.2) if i < filled else Color(1, 1, 1, 0.35)
		dot.add_theme_stylebox_override("panel", style)


func _play(stream: AudioStream) -> void:
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


func _actor_sprite(frames: SpriteFrames, at: Vector2) -> AnimatedSprite2D:
	var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.offset = Vector2(0, -TILE / 2.0)
	sprite.position = at
	track.add_child(sprite)
	return sprite
