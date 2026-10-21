class_name CareScreen
extends CanvasLayer
## Caring for a rescued animal at the Rescue Center (PLAN.md 3.9), one CareVisit at a time:
## 1. Feed: spell the food's name with letter tiles (K: first letter, or match the word to a picture).
## 2. Care note: read a short note and pick what helps.
## 3. Fact card: the animal's facts so far, with the new one marked.
## Henrito helps after a couple of misses. The kid presses Next when ready (no timers), and can
## leave any time with "Later" (the visit then doesn't count).
## Emits `finished(completed)`.

signal finished(completed: bool)

const SFX_CORRECT: AudioStream = preload("res://assets/audio/sfx/correct.wav")
const SFX_TRY_AGAIN: AudioStream = preload("res://assets/audio/sfx/try_again.wav")
const SFX_DONE: AudioStream = preload("res://assets/audio/sfx/caught.wav")

const BACKGROUND: Color = Color(0.93, 0.87, 0.72)
const INK: Color = Color(0.2, 0.18, 0.12)
const BORDER: Color = Color(0.3, 0.25, 0.15)
const PAPER: Color = Color(1, 1, 0.97)
const HINT_GLOW: Color = Color(1, 0.7, 0.2)
const NEW_FACT_COLOR: Color = Color(0.85, 0.5, 0.05)

const TITLE_FONT_SIZE: int = 52
const TEXT_FONT_SIZE: int = 40
const TILE_FONT_SIZE: int = 52
const BUTTON_FONT_SIZE: int = 36
const FEEDBACK_FONT_SIZE: int = 34
const BUBBLE_FONT_SIZE: int = 26
const FACT_FONT_SIZE: int = 30
const PORTRAIT_SIZE: float = 112.0
const SIDEKICK_FACE_SIZE: float = 72.0
const FOOD_SIZE: float = 120.0
const LETTER_BOX_SIZE: Vector2 = Vector2(84, 96)
const TILE_SIZE: Vector2 = Vector2(92, 92)
const PICTURE_BUTTON_SIZE: Vector2 = Vector2(180, 180)
const CHOICE_BUTTON_SIZE: Vector2 = Vector2(400, 100)
const NEXT_BUTTON_SIZE: Vector2 = Vector2(260, 84)
const LATER_BUTTON_SIZE: Vector2 = Vector2(150, 60)
const BUBBLE_WIDTH: float = 560.0
## The step area sits between the header and Henrito's bubble.
const CONTENT_TOP: float = 140.0
const CONTENT_BOTTOM: float = 600.0
const TILE_COLOR: Color = Color(0.98, 0.9, 0.7)
const TILE_HOVER_COLOR: Color = Color(1, 0.95, 0.8)
const USED_TILE_ALPHA: float = 0.25
const WIGGLE_DEGREES: float = 8.0
const WIGGLE_SECONDS: float = 0.08

const FEED_TITLE: String = "Feed the %s"
const NOTE_TITLE: String = "Care for the %s"
const FACT_TITLE: String = "%s Facts"
const SPELL_PROMPT: String = "Spell the food!"
const FIRST_LETTER_PROMPT: String = "What letter does it start with?"
const PICTURE_PROMPT: String = "Find the %s."
const FED_TEXT: String = "Yum! The %s loves %s!"
const TRY_AGAIN: String = "Try again. You've got this."
const NOTE_GOOD: String = "Good idea! The %s feels better."
const NEW_FACT_TAG: String = "New! "
const NEXT: String = "Next"
const DONE: String = "Done"
const LATER: String = "Later"
const READ_ALOUD: String = "Read to me"

var animal: Dictionary = {}
var visit: CareVisit
var catalog: CareCatalog
var sidekick: Sidekick

var title_label: Label
var portrait: TextureRect
var bubble: PanelContainer
var bubble_label: Label
var bubble_face: TextureRect
var content: VBoxContainer
var feedback: Label
var next_button: Button
var later_button: Button
## Feed step widgets (rebuilt each step).
var tile_buttons: Array[Button] = []
var letter_labels: Array[Label] = []
var picture_buttons: Array[Button] = []
var choice_buttons: Array[Button] = []
var fact_labels: Array[Label] = []

var _sfx: AudioStreamPlayer
var _glow_tween: Tween
## The bubble is showing a letter hint (hidden again after the next right letter).
var _hint_showing: bool = false


func _ready() -> void:
	layer = 10
	_build()


## Begin caring for `care_animal` (AnimalCatalog data) with a prepared visit.
func start(care_animal: Dictionary, care_visit: CareVisit, care_catalog: CareCatalog = null) -> void:
	animal = care_animal
	visit = care_visit
	catalog = care_catalog if care_catalog != null else GameState.care_catalog
	sidekick = Sidekick.load_by_id(GameState.sidekick_id, GameState.rng)
	bubble_face.texture = sidekick.faceset()
	if animal.has("faceset"):
		portrait.texture = load(str(animal["faceset"]))
	GameState.log_event("care_start", {"animal": visit.animal_id, "mode": visit.feed_mode, "food": visit.food_id})
	say_sidekick(_fill(sidekick.line("care_start")))
	_show_step()


func animal_name() -> String:
	return str(animal.get("name", "animal"))


## Tapped letter tile `index` (spelling and first-letter modes).
func press_tile(index: int) -> void:
	if visit.spelling == null or visit.step != CareVisit.Step.FEED:
		return
	var result: SpellingTask.Result = visit.spelling.press(index)
	match result:
		SpellingTask.Result.IGNORED:
			return
		SpellingTask.Result.MISS:
			_play(SFX_TRY_AGAIN)
			feedback.text = TRY_AGAIN
			_wiggle(tile_buttons[index])
			if visit.spelling.misses_here >= visit.hint_after:
				_show_letter_hint()
			return
	_play(SFX_CORRECT)
	feedback.text = ""
	_stop_glow()
	if _hint_showing:
		bubble.visible = false
		_hint_showing = false
	tile_buttons[index].disabled = true
	tile_buttons[index].modulate.a = USED_TILE_ALPHA
	_refresh_letters()
	if result == SpellingTask.Result.DONE:
		for tile: Button in tile_buttons:
			tile.disabled = true
			tile.modulate.a = USED_TILE_ALPHA
		_fed()


## Tapped a food picture (picture-match mode).
func pick_picture(food_id: String) -> void:
	if visit.picture_choice == null or visit.picture_choice.solved or visit.step != CareVisit.Step.FEED:
		return
	if visit.picture_choice.pick(food_id):
		_play(SFX_CORRECT)
		for button: Button in picture_buttons:
			button.disabled = button.get_meta("food_id") != food_id
		_fed()
		return
	_play(SFX_TRY_AGAIN)
	feedback.text = TRY_AGAIN
	for button: Button in picture_buttons:
		if button.get_meta("food_id") == food_id:
			_wiggle(button)
	if visit.picture_choice.misses >= visit.hint_after:
		say_sidekick(sidekick.line("feed_hint_picture").replace("{word}", visit.food_word))


## Picked a care note choice.
func pick_note(option: String) -> void:
	if visit.note_choice == null or visit.note_choice.solved or visit.step != CareVisit.Step.NOTE:
		return
	if visit.note_choice.pick(option):
		_play(SFX_CORRECT)
		feedback.text = NOTE_GOOD % animal_name().to_lower()
		for button: Button in choice_buttons:
			button.disabled = button.text != option
		next_button.visible = true
		return
	_play(SFX_TRY_AGAIN)
	feedback.text = ""
	say_sidekick(sidekick.line("care_note_retry"))
	for button: Button in choice_buttons:
		if button.text == option:
			button.disabled = true


## Next step (the Next/Done button).
func next_step() -> void:
	if not next_button.visible:
		return
	if visit.advance() == CareVisit.Step.DONE:
		finish(true)
		return
	_show_step()


## Leaves the care screen. `completed` = the whole visit was done.
func finish(completed: bool) -> void:
	_stop_glow()
	GameState.log_event("care_end", {"animal": visit.animal_id if visit != null else "", "completed": completed,
		"feed_misses": _feed_misses(), "note_misses": visit.note_choice.misses if visit != null and visit.note_choice != null else 0})
	finished.emit(completed)


## Shows the sidekick's bubble with `text` until the next line.
func say_sidekick(text: String) -> void:
	if text == "":
		return
	bubble_label.text = text
	bubble.visible = true
	if GameState.read_aloud and sidekick != null:
		Speech.say(text, sidekick.voice_rate(), sidekick.voice_pitch())


func _show_step() -> void:
	_clear_content()
	next_button.visible = false
	next_button.text = NEXT
	feedback.text = ""
	match visit.step:
		CareVisit.Step.FEED:
			title_label.text = FEED_TITLE % animal_name()
			if visit.feed_mode == CareVisit.PICTURE_MATCH:
				_build_picture_match()
			else:
				_build_spelling()
		CareVisit.Step.NOTE:
			title_label.text = NOTE_TITLE % animal_name()
			bubble.visible = false
			_build_note()
		CareVisit.Step.FACT:
			title_label.text = FACT_TITLE % animal_name()
			_build_fact_card()
			_play(SFX_DONE)
			say_sidekick(_fill(sidekick.line("care_done")))
			next_button.text = DONE
			next_button.visible = true


func _fed() -> void:
	feedback.text = FED_TEXT % [animal_name().to_lower(), visit.food_word]
	next_button.visible = true
	GameState.log_event("fed", {"animal": visit.animal_id, "food": visit.food_id, "mode": visit.feed_mode, "misses": _feed_misses()})


func _feed_misses() -> int:
	if visit == null:
		return 0
	if visit.spelling != null:
		return visit.spelling.misses
	return visit.picture_choice.misses if visit.picture_choice != null else 0


func _show_letter_hint() -> void:
	var letter: String = visit.spelling.next_letter()
	var event: String = "feed_hint_first" if visit.spelling.placed == 0 else "feed_hint_next"
	say_sidekick(sidekick.line(event).replace("{letter}", letter))
	_hint_showing = true
	var hint: int = visit.spelling.hint_tile()
	if hint < 0:
		return
	_stop_glow()
	var button: Button = tile_buttons[hint]
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(button, "modulate", HINT_GLOW, 0.4)
	_glow_tween.tween_property(button, "modulate", Color.WHITE, 0.4)


func _stop_glow() -> void:
	if _glow_tween != null:
		_glow_tween.kill()
		_glow_tween = null
	for button: Button in tile_buttons:
		if not button.disabled:
			button.modulate = Color.WHITE


func _refresh_letters() -> void:
	var shown: Array[String] = visit.spelling.shown()
	for i: int in letter_labels.size():
		letter_labels[i].text = shown[i]


func _build_spelling() -> void:
	var prompt: Label = _label(SPELL_PROMPT if visit.feed_mode == CareVisit.SPELL else FIRST_LETTER_PROMPT, TEXT_FONT_SIZE)
	content.add_child(prompt)
	content.add_child(_food_picture(visit.food_id, FOOD_SIZE))
	var boxes: HBoxContainer = _row(10)
	boxes.name = "LetterBoxes"
	content.add_child(boxes)
	for i: int in visit.spelling.word.length():
		var box: PanelContainer = PanelContainer.new()
		box.custom_minimum_size = LETTER_BOX_SIZE
		box.add_theme_stylebox_override("panel", _box_style(PAPER, 12))
		var letter: Label = _label("", TILE_FONT_SIZE)
		letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		box.add_child(letter)
		boxes.add_child(box)
		letter_labels.append(letter)
	_refresh_letters()
	var tiles: HBoxContainer = _row(16)
	tiles.name = "Tiles"
	content.add_child(tiles)
	for i: int in visit.spelling.tiles.size():
		var tile: Button = _letter_tile(visit.spelling.tiles[i])
		tile.pressed.connect(press_tile.bind(i), CONNECT_DEFERRED)
		tiles.add_child(tile)
		tile_buttons.append(tile)


func _build_picture_match() -> void:
	content.add_child(_label(PICTURE_PROMPT % visit.food_word, TITLE_FONT_SIZE))
	var row: HBoxContainer = _row(36)
	row.name = "Pictures"
	content.add_child(row)
	for food_id: String in visit.picture_choice.choices:
		var button: Button = _button("", PICTURE_BUTTON_SIZE, BUTTON_FONT_SIZE)
		button.icon = load(str(catalog.food(food_id).get("picture", "")))
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_constant_override("icon_max_width", int(PICTURE_BUTTON_SIZE.x * 0.7))
		button.set_meta("food_id", food_id)
		button.pressed.connect(pick_picture.bind(food_id), CONNECT_DEFERRED)
		row.add_child(button)
		picture_buttons.append(button)


func _build_note() -> void:
	var note_text: Label = _label(str(visit.note.get("text", "")), TITLE_FONT_SIZE)
	note_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_text.custom_minimum_size = Vector2(1100, 0)
	content.add_child(note_text)
	content.add_child(_label(visit.note_choice.prompt, TEXT_FONT_SIZE))
	var row: HBoxContainer = _row(36)
	row.name = "Choices"
	content.add_child(row)
	for option: String in visit.note_choice.choices:
		var button: Button = _button(option, CHOICE_BUTTON_SIZE, BUTTON_FONT_SIZE)
		button.pressed.connect(pick_note.bind(option), CONNECT_DEFERRED)
		row.add_child(button)
		choice_buttons.append(button)


func _build_fact_card() -> void:
	var card: PanelContainer = PanelContainer.new()
	card.name = "FactCard"
	card.custom_minimum_size = Vector2(1000, 0)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style: StyleBoxFlat = _box_style(PAPER, 20)
	style.set_content_margin_all(24)
	card.add_theme_stylebox_override("panel", style)
	content.add_child(card)
	var lines: VBoxContainer = VBoxContainer.new()
	lines.add_theme_constant_override("separation", 14)
	card.add_child(lines)
	var facts: Array[String] = visit.facts_to_show()
	var new_index: int = visit.new_fact_index()
	for i: int in facts.size():
		var fact: Label = _label((NEW_FACT_TAG if i == new_index else "") + facts[i], FACT_FONT_SIZE)
		fact.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		fact.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if i == new_index:
			fact.add_theme_color_override("font_color", NEW_FACT_COLOR)
		lines.add_child(fact)
		fact_labels.append(fact)
	if GameState.read_aloud:
		var read: Button = _button(READ_ALOUD, Vector2(240, 64), BUTTON_FONT_SIZE - 8)
		read.name = "ReadAloud"
		read.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		read.pressed.connect(func() -> void: Speech.say(" ".join(facts)), CONNECT_DEFERRED)
		lines.add_child(read)


func _clear_content() -> void:
	_stop_glow()
	tile_buttons.clear()
	letter_labels.clear()
	picture_buttons.clear()
	choice_buttons.clear()
	fact_labels.clear()
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()


## "{animal}" in a sidekick line → the animal's name.
func _fill(text: String) -> String:
	return text.replace("{animal}", animal_name().to_lower())


func _wiggle(control: Control) -> void:
	control.pivot_offset = control.size / 2.0
	var tween: Tween = create_tween()
	tween.tween_property(control, "rotation_degrees", WIGGLE_DEGREES, WIGGLE_SECONDS)
	tween.tween_property(control, "rotation_degrees", -WIGGLE_DEGREES, WIGGLE_SECONDS)
	tween.tween_property(control, "rotation_degrees", 0.0, WIGGLE_SECONDS)


func _play(stream: AudioStream) -> void:
	_sfx.stream = stream
	_sfx.play()


func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var header: HBoxContainer = HBoxContainer.new()
	header.position = Vector2(24, 16)
	header.add_theme_constant_override("separation", 18)
	add_child(header)
	portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	header.add_child(portrait)
	title_label = _label("", TITLE_FONT_SIZE)
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(title_label)

	later_button = _button(LATER, LATER_BUTTON_SIZE, BUTTON_FONT_SIZE - 8)
	later_button.name = "Later"
	later_button.position = Vector2(1280 - LATER_BUTTON_SIZE.x - 24, 24)
	later_button.pressed.connect(finish.bind(false), CONNECT_DEFERRED)
	add_child(later_button)

	_build_bubble()

	# The step's widgets go in `content`; the feedback line sits right under them.
	var column: VBoxContainer = VBoxContainer.new()
	column.position = Vector2(0, CONTENT_TOP)
	column.size = Vector2(1280, CONTENT_BOTTOM - CONTENT_TOP)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 10)
	add_child(column)
	content = VBoxContainer.new()
	content.name = "Content"
	content.add_theme_constant_override("separation", 14)
	column.add_child(content)
	feedback = _label("", FEEDBACK_FONT_SIZE)
	feedback.name = "Feedback"
	feedback.custom_minimum_size = Vector2(0, FEEDBACK_FONT_SIZE + 10)
	column.add_child(feedback)

	next_button = _button(NEXT, NEXT_BUTTON_SIZE, BUTTON_FONT_SIZE)
	next_button.name = "Next"
	next_button.position = Vector2(1280 - NEXT_BUTTON_SIZE.x - 24, 720 - NEXT_BUTTON_SIZE.y - 16)
	next_button.visible = false
	next_button.pressed.connect(next_step, CONNECT_DEFERRED)
	add_child(next_button)

	_sfx = AudioStreamPlayer.new()
	add_child(_sfx)


## Sidekick portrait + speech bubble, bottom left.
func _build_bubble() -> void:
	bubble = PanelContainer.new()
	bubble.name = "SidekickBubble"
	bubble.position = Vector2(16, 720 - SIDEKICK_FACE_SIZE - 40)
	var style: StyleBoxFlat = _box_style(PAPER, 16)
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
	bubble_label.add_theme_color_override("font_color", INK)
	row.add_child(bubble_label)


func _food_picture(food_id: String, edge: float) -> TextureRect:
	var picture: TextureRect = TextureRect.new()
	picture.name = "FoodPicture"
	picture.texture = load(str(catalog.food(food_id).get("picture", "")))
	picture.custom_minimum_size = Vector2(edge, edge)
	picture.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return picture


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	return label


func _row(separation: int) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", separation)
	return row


func _button(text: String, min_size: Vector2, font_size: int) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", font_size)
	button.focus_mode = Control.FOCUS_NONE
	return button


## A wooden letter tile (light, so the hint glow shows).
func _letter_tile(letter: String) -> Button:
	var tile: Button = _button(letter, TILE_SIZE, TILE_FONT_SIZE)
	tile.add_theme_stylebox_override("normal", _box_style(TILE_COLOR, 12))
	tile.add_theme_stylebox_override("hover", _box_style(TILE_HOVER_COLOR, 12))
	tile.add_theme_stylebox_override("pressed", _box_style(TILE_HOVER_COLOR, 12))
	tile.add_theme_stylebox_override("disabled", _box_style(TILE_COLOR, 12))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		tile.add_theme_color_override(state, INK)
	return tile


func _box_style(color: Color, radius: int) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = BORDER
	style.set_border_width_all(3)
	style.set_corner_radius_all(radius)
	return style
