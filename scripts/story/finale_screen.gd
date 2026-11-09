class_name FinaleScreen
extends CanvasLayer
## The finale (PLAN.md 3.1, Chris 2026-11-05): shown once at the Rescue Center when every
## habitat's snake is home plus enough of its other animals. Clear sky, rainbow, confetti,
## every rescued kind of animal hopping, and the sidekick's thanks. Emits `closed`.

signal closed

const SKY_TOP: Color = Color(0.45, 0.75, 1.0)
const SKY_BOTTOM: Color = Color(0.75, 0.9, 1.0)
const SUN_COLOR: Color = Color(1.0, 0.86, 0.3)
const INK: Color = Color(0.12, 0.16, 0.3)
const RAINBOW: Array[Color] = [Color(0.93, 0.3, 0.3), Color(0.98, 0.6, 0.25), Color(0.98, 0.88, 0.3),
	Color(0.4, 0.8, 0.4), Color(0.35, 0.6, 0.95), Color(0.6, 0.45, 0.85)]
const RAINBOW_CENTER: Vector2 = Vector2(640, 520)
const RAINBOW_RADIUS: float = 420.0
const RAINBOW_WIDTH: float = 16.0
const TITLE_FONT_SIZE: int = 72
const TEXT_FONT_SIZE: int = 34
const FACE_SIZE: Vector2 = Vector2(76, 76)
const FACE_ROW_WIDTH: float = 880.0
const HOP_HEIGHT: float = 14.0
const HOP_SECONDS: float = 0.35
const BUTTON_SIZE: Vector2 = Vector2(260, 90)
const SFX_CHEER: AudioStream = preload("res://assets/audio/sfx/caught.wav")

const TITLE: String = "You did it!"
const MESSAGE: String = "Every habitat is safe, and all the snakes are home.\nThe storm is over!"
const THANKS: String = "%s: Thank you, %s! You saved them all!"
## Used until the player has typed a name.
const DEFAULT_NAME: String = "Ranger"
const BUTTON_TEXT: String = "Hooray!"

var faces: Array[TextureRect] = []
var close_button: Button


func _ready() -> void:
	layer = 10
	_build()


## One of each kind of animal rescued so far (in the order they were first rescued).
static func rescued_kinds() -> Array[String]:
	var kinds: Array[String] = []
	for id: String in GameState.rescued:
		if not kinds.has(id) and GameState.catalog.get_animal(id).has("faceset"):
			kinds.append(id)
	return kinds


func close() -> void:
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


func _build() -> void:
	var sky: TextureRect = TextureRect.new()
	var gradient: Gradient = Gradient.new()
	gradient.set_color(0, SKY_TOP)
	gradient.set_color(1, SKY_BOTTOM)
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	sky.texture = texture
	sky.stretch_mode = TextureRect.STRETCH_SCALE
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)
	_add_sun()
	_add_rainbow()
	_add_confetti()

	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 22)
	add_child(column)
	column.add_child(_label(TITLE, TITLE_FONT_SIZE))
	column.add_child(_label(MESSAGE, TEXT_FONT_SIZE))
	var row: HFlowContainer = HFlowContainer.new()
	row.alignment = FlowContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("h_separation", 10)
	row.add_theme_constant_override("v_separation", 10)
	row.custom_minimum_size.x = FACE_ROW_WIDTH
	row.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(row)
	for id: String in rescued_kinds():
		var face: TextureRect = TextureRect.new()
		face.texture = load(str(GameState.catalog.get_animal(id)["faceset"]))
		face.custom_minimum_size = FACE_SIZE
		face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(face)
		faces.append(face)
	var helper: String = Sidekick.load_by_id(GameState.sidekick_id, GameState.rng).display_name()
	column.add_child(_label(THANKS % [helper, GameState.player_name if GameState.player_name != "" else DEFAULT_NAME], TEXT_FONT_SIZE))
	close_button = Button.new()
	close_button.text = BUTTON_TEXT
	close_button.custom_minimum_size = BUTTON_SIZE
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	close_button.pressed.connect(close, CONNECT_DEFERRED)
	column.add_child(close_button)
	close_button.grab_focus()
	_start_hops.call_deferred()
	var cheer: AudioStreamPlayer = AudioStreamPlayer.new()
	cheer.stream = SFX_CHEER
	add_child(cheer)
	cheer.play()


## Each face hops up and down, a little after the one before it.
func _start_hops() -> void:
	for i: int in faces.size():
		var face: TextureRect = faces[i]
		var tween: Tween = face.create_tween().set_loops()
		tween.tween_interval(HOP_SECONDS * 0.3 * i)
		tween.tween_property(face, "position:y", face.position.y - HOP_HEIGHT, HOP_SECONDS).set_trans(Tween.TRANS_SINE)
		tween.tween_property(face, "position:y", face.position.y, HOP_SECONDS).set_trans(Tween.TRANS_SINE)


func _add_sun() -> void:
	var sun: Panel = Panel.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = SUN_COLOR
	style.set_corner_radius_all(70)
	sun.add_theme_stylebox_override("panel", style)
	sun.position = Vector2(1080, 40)
	sun.size = Vector2(140, 140)
	add_child(sun)


func _add_rainbow() -> void:
	for i: int in RAINBOW.size():
		var arc: Line2D = Line2D.new()
		arc.width = RAINBOW_WIDTH
		arc.default_color = RAINBOW[i]
		var radius: float = RAINBOW_RADIUS - i * RAINBOW_WIDTH
		for step: int in 41:
			arc.add_point(RAINBOW_CENTER + Vector2.from_angle(PI + PI * step / 40.0) * radius)
		add_child(arc)


func _add_confetti() -> void:
	var confetti: CPUParticles2D = CPUParticles2D.new()
	confetti.position = Vector2(640, -10)
	confetti.amount = 120
	confetti.lifetime = 4.0
	confetti.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	confetti.emission_rect_extents = Vector2(660, 4)
	confetti.direction = Vector2.DOWN
	confetti.spread = 20.0
	confetti.gravity = Vector2(0, 60)
	confetti.initial_velocity_min = 60.0
	confetti.initial_velocity_max = 140.0
	confetti.angular_velocity_min = -180.0
	confetti.angular_velocity_max = 180.0
	confetti.scale_amount_min = 4.0
	confetti.scale_amount_max = 7.0
	var colors: Gradient = Gradient.new()
	colors.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	colors.colors = PackedColorArray([RAINBOW[0], RAINBOW[2], RAINBOW[3], RAINBOW[4]])
	confetti.color_initial_ramp = colors
	add_child(confetti)


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	label.add_theme_color_override("font_outline_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 8)
	return label
