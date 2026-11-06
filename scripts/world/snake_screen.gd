class_name SnakeScreen
extends CanvasLayer
## The hidden snake's challenge: one story problem, a little harder than usual. A right answer
## catches the snake; a miss lets it slide away under another rock to be found again.
## Emits `finished(caught)` when the player presses the button at the end.

signal finished(caught: bool)

const SFX_CAUGHT: AudioStream = preload("res://assets/audio/sfx/caught.wav")
const SFX_MISS: AudioStream = preload("res://assets/audio/sfx/try_again.wav")
const BACKGROUND: Color = Color(0.36, 0.55, 0.33)
const OUTLINE: Color = Color(0.15, 0.25, 0.1)
const TITLE_FONT_SIZE: int = 44
const STORY_FONT_SIZE: int = 40
const BUTTON_FONT_SIZE: int = 44
const FEEDBACK_FONT_SIZE: int = 34
const PORTRAIT_SIZE: float = 152.0
## Smaller face when the story has a picture, so everything fits on screen.
const SMALL_PORTRAIT_SIZE: float = 88.0
const BUTTON_SIZE: Vector2 = Vector2(190, 110)
const WIDE_BUTTON_SIZE: Vector2 = Vector2(360, 100)
const STORY_WIDTH: float = 1100.0
const PICTURE_HEIGHT: float = 150.0

const FOUND_TEXT: String = "You found a %s!"
const CAUGHT_TEXT: String = "You caught the %s!"
const ESCAPED_TEXT: String = "The %s slid away to hide under another rock!"
const ONE_TRY_TEXT: String = "Read carefully. You get one try!"
const HOORAY: String = "Hooray!"
const FIND_AGAIN: String = "Find it again"

var animal: Dictionary = {}
var problem: MathProblem
var caught: bool = false
var accepting: bool = false
var title_label: Label
var story_label: Label
## Clocks, coins, groups, or things to count, when the story needs them.
var picture: ProblemPicture
var feedback: Label
var choices_box: HBoxContainer
var _sfx: AudioStreamPlayer
var _done: bool = false


func _ready() -> void:
	layer = 10
	_build()


func start(snake: Dictionary, story_problem: MathProblem) -> void:
	animal = snake
	problem = story_problem
	title_label.text = FOUND_TEXT % snake_name()
	(get_node("Column/Portrait") as TextureRect).texture = load(str(snake["faceset"]))
	story_label.text = problem.prompt
	var icon_path: String = str(problem.data.get("story_icon", ""))
	picture.show_problem(problem, load(icon_path) as Texture2D if icon_path != "" else null)
	picture.visible = ProblemPicture.kind_for(problem) != ""
	var face: float = SMALL_PORTRAIT_SIZE if picture.visible else PORTRAIT_SIZE
	(get_node("Column/Portrait") as Control).custom_minimum_size = Vector2(face, face)
	feedback.text = ONE_TRY_TEXT
	var buttons: Array[Button] = []
	for choice: String in problem.choices:
		var button: Button = _button(choice, BUTTON_SIZE)
		button.pressed.connect(answer.bind(choice), CONNECT_DEFERRED)
		buttons.append(button)
	_set_buttons(buttons)
	accepting = true
	GameState.log_event("snake_problem", {"animal": snake.get("id", ""), "prompt": problem.prompt,
		"answer": problem.answer, "level": problem.level, "skill": problem.skill_id})


func snake_name() -> String:
	return str(animal.get("name", "snake"))


func answer(choice: String) -> void:
	if not accepting:
		return
	accepting = false
	caught = problem.is_correct(choice)
	GameState.log_event("snake_answer", {"animal": animal.get("id", ""), "choice": choice, "correct": caught})
	_sfx.stream = SFX_CAUGHT if caught else SFX_MISS
	_sfx.play()
	title_label.text = (CAUGHT_TEXT if caught else ESCAPED_TEXT) % snake_name()
	feedback.text = "" if caught else "The answer was %s. You'll get it next time!" % problem.answer
	var next: Button = _button(HOORAY if caught else FIND_AGAIN, WIDE_BUTTON_SIZE)
	next.pressed.connect(finish, CONNECT_DEFERRED)
	_set_buttons([next])
	next.grab_focus()


func finish() -> void:
	if _done:
		return
	_done = true
	finished.emit(caught)


func choice_buttons() -> Array[Button]:
	var out: Array[Button] = []
	for child: Node in choices_box.get_children():
		out.append(child as Button)
	return out


func _set_buttons(buttons: Array) -> void:
	for child: Node in choices_box.get_children():
		choices_box.remove_child(child)
		child.queue_free()
	for button: Variant in buttons:
		choices_box.add_child(button)
	if not buttons.is_empty():
		(buttons[0] as Button).grab_focus()


func _button(text: String, min_size: Vector2) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", BUTTON_FONT_SIZE)
	return button


func _label(font_size: int) -> Label:
	var label: Label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", 8)
	return label


func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column: VBoxContainer = VBoxContainer.new()
	column.name = "Column"
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	title_label = _label(TITLE_FONT_SIZE)
	column.add_child(title_label)
	var portrait: TextureRect = TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	column.add_child(portrait)
	story_label = _label(STORY_FONT_SIZE)
	story_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story_label.custom_minimum_size = Vector2(STORY_WIDTH, 0)
	story_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(story_label)
	picture = ProblemPicture.new()
	picture.custom_minimum_size = Vector2(STORY_WIDTH, PICTURE_HEIGHT)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture.visible = false
	column.add_child(picture)
	choices_box = HBoxContainer.new()
	choices_box.alignment = BoxContainer.ALIGNMENT_CENTER
	choices_box.add_theme_constant_override("separation", 28)
	column.add_child(choices_box)
	feedback = _label(FEEDBACK_FONT_SIZE)
	column.add_child(feedback)
	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)
