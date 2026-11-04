class_name BookScreen
extends CanvasLayer
## The Rescue Book (PLAN.md 3.10): one page per habitat with its three animals and a gold
## "special" slot. Animals not rescued yet show "???". Picking a rescued animal shows its level,
## how many are home, and the facts learned so far from caring for it. Emits `closed`.

signal closed

const BACKGROUND: Color = Color(0.93, 0.87, 0.72)
const INK: Color = Color(0.2, 0.18, 0.12)
const PAPER: Color = Color(1, 1, 0.97)
const SPECIAL_GOLD: Color = Color(0.95, 0.75, 0.2)
const UNKNOWN_SHADE: Color = Color(0.45, 0.42, 0.38)
const TITLE_FONT_SIZE: int = 48
const TEXT_FONT_SIZE: int = 28
const FACT_FONT_SIZE: int = 26
const SLOT_SIZE: Vector2 = Vector2(240, 230)
const NAV_SIZE: Vector2 = Vector2(150, 64)

const TITLE: String = "Rescue Book: %s"
const PAGE_TEXT: String = "Page %d of %d"
const UNKNOWN: String = "???"
const SPECIAL_UNKNOWN: String = "???\nSpecial"
const SLOT_TEXT: String = "%s\nLevel %d · %d home"
const NO_FACTS: String = "Care for the %s to learn a fact!"
const PICK_TEXT: String = "Pick an animal you rescued to read about it."
const PREVIOUS: String = "< Back"
const NEXT: String = "Next >"
const CLOSE: String = "Close (B)"

var page: int = 0
var title_label: Label
var page_label: Label
var slot_buttons: Array[Button] = []
var facts_label: Label
var previous_button: Button
var next_button: Button
var close_button: Button
var _slots_row: HBoxContainer


func _ready() -> void:
	layer = 10
	_build()
	show_page(0)


func pages() -> Array:
	return GameState.rewards.book_pages()


func show_page(index: int) -> void:
	page = clampi(index, 0, pages().size() - 1)
	var entry: Dictionary = pages()[page]
	title_label.text = TITLE % str(entry["habitat"]).capitalize()
	page_label.text = PAGE_TEXT % [page + 1, pages().size()]
	previous_button.disabled = page == 0
	next_button.disabled = page == pages().size() - 1
	facts_label.text = PICK_TEXT
	for button: Button in slot_buttons:
		_slots_row.remove_child(button)
		button.queue_free()
	slot_buttons.clear()
	for id: Variant in entry["animals"]:
		_add_slot(str(id), false)
	_add_slot(str(entry["special"]), true)
	close_button.grab_focus()


## How many of this animal are home at the Rescue Center.
static func home_count(animal_id: String) -> int:
	return GameState.rescues.filter(func(r: Dictionary) -> bool: return r["animal"] == animal_id).size()


## Shows the facts learned so far for a rescued animal.
func show_animal(animal_id: String) -> void:
	var facts: Array[String] = GameState.care_catalog.facts_for(animal_id)
	var known: Array[String] = facts.slice(0, mini(GameState.care_visits_for(animal_id), facts.size()))
	var name: String = str(GameState.catalog.get_animal(animal_id).get("name", animal_id))
	facts_label.text = (NO_FACTS % name.to_lower()) if known.is_empty() else "\n".join(known)


func close() -> void:
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B):
		get_viewport().set_input_as_handled()
		close()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_PAGEDOWN:
		get_viewport().set_input_as_handled()
		show_page(page + 1)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_PAGEUP:
		get_viewport().set_input_as_handled()
		show_page(page - 1)


func _add_slot(animal_id: String, special: bool) -> void:
	var button: Button = Button.new()
	button.name = "Slot_%s" % animal_id
	button.custom_minimum_size = SLOT_SIZE
	button.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	button.add_theme_constant_override("icon_max_width", int(SLOT_SIZE.x * 0.45))
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAPER if home_count(animal_id) > 0 else UNKNOWN_SHADE
	style.border_color = SPECIAL_GOLD if special else INK
	style.set_border_width_all(6 if special else 3)
	style.set_corner_radius_all(14)
	for state: String in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state, style)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK if home_count(animal_id) > 0 else PAPER)
	if home_count(animal_id) > 0:
		var animal: Dictionary = GameState.catalog.get_animal(animal_id)
		button.icon = load(str(animal["faceset"])) if animal.has("faceset") else null
		button.text = SLOT_TEXT % [animal.get("name", animal_id), GameState.animal_level(animal_id), home_count(animal_id)]
		button.pressed.connect(show_animal.bind(animal_id), CONNECT_DEFERRED)
	else:
		button.text = SPECIAL_UNKNOWN if special else UNKNOWN
		button.disabled = true
	_slots_row.add_child(button)
	slot_buttons.append(button)


func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_top = 24
	column.offset_bottom = -24
	column.add_theme_constant_override("separation", 18)
	add_child(column)
	title_label = _label("", TITLE_FONT_SIZE)
	column.add_child(title_label)
	_slots_row = HBoxContainer.new()
	_slots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_slots_row.add_theme_constant_override("separation", 22)
	column.add_child(_slots_row)
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(1040, 170)
	card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = INK
	style.set_border_width_all(3)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(18)
	card.add_theme_stylebox_override("panel", style)
	column.add_child(card)
	facts_label = _label("", FACT_FONT_SIZE)
	facts_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	facts_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(facts_label)
	var nav: HBoxContainer = HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 24)
	column.add_child(nav)
	previous_button = _nav_button(PREVIOUS, func() -> void: show_page(page - 1))
	nav.add_child(previous_button)
	page_label = _label("", TEXT_FONT_SIZE)
	nav.add_child(page_label)
	next_button = _nav_button(NEXT, func() -> void: show_page(page + 1))
	nav.add_child(next_button)
	close_button = _nav_button(CLOSE, close)
	close_button.custom_minimum_size.x = 200
	nav.add_child(close_button)


func _nav_button(text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = NAV_SIZE
	button.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	button.pressed.connect(action, CONNECT_DEFERRED)
	return button


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	return label
