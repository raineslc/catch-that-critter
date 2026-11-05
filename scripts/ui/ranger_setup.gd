class_name RangerSetup
extends PanelContainer
## "Make your ranger" (PLAN 3.2): type a name (a grown-up can help) and tap swatches for
## hair, skin, and outfit, with a live preview. Emits `done(name, look)` or `cancelled`.

signal done(player_name: String, look: Dictionary)
signal cancelled

const TITLE_TEXT: String = "Make your ranger"
const NAME_HINT: String = "Name (a grown-up can type it)"
const PART_LABELS: Dictionary = {"hair": "Hair", "skin": "Skin", "outfit": "Outfit"}
const START_TEXT: String = "Start!"
const BACK_TEXT: String = "Back"
const FONT_SIZE: int = 30
const TITLE_FONT_SIZE: int = 44
const SWATCH_SIZE: Vector2 = Vector2(64, 64)
const PREVIEW_SIZE: Vector2 = Vector2(152, 152)
const BUTTON_SIZE: Vector2 = Vector2(200, 72)
const PICKED_BORDER: Color = Color.WHITE
const PAPER: Color = Color(0.16, 0.3, 0.16, 0.96)

var look: Dictionary = {}
var name_edit: LineEdit
var start_button: Button
var face_preview: TextureRect
var body_preview: TextureRect
## part -> {option -> Button}
var swatches: Dictionary = {}


## Fill in the name and look to start from (an existing save keeps its own).
func setup(start_name: String, start_look: Dictionary) -> void:
	look = RangerLook.complete(start_look)
	_build()
	name_edit.text = start_name
	_refresh()


func pick(part: String, option: String) -> void:
	look[part] = option
	_refresh()


func confirm() -> void:
	if not start_button.disabled:
		done.emit(name_edit.text.strip_edges(), look.duplicate())


func _refresh() -> void:
	start_button.disabled = name_edit.text.strip_edges() == ""
	face_preview.texture = RangerLook.faceset(look)
	var front: AtlasTexture = AtlasTexture.new()
	front.atlas = RangerLook.sheet(look)
	front.region = Rect2(0, 0, Ranger.FRAME_SIZE, Ranger.FRAME_SIZE)
	body_preview.texture = front
	for part: String in swatches:
		for option: String in swatches[part]:
			var picked: bool = look[part] == option
			var style: StyleBoxFlat = StyleBoxFlat.new()
			style.bg_color = RangerLook.swatch(part, option)
			style.set_corner_radius_all(12)
			style.border_color = PICKED_BORDER
			style.set_border_width_all(6 if picked else 0)
			for state: String in ["normal", "hover", "pressed", "focus"]:
				(swatches[part][option] as Button).add_theme_stylebox_override(state, style)


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BOTH
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PAPER
	style.set_corner_radius_all(20)
	style.set_content_margin_all(28)
	add_theme_stylebox_override("panel", style)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	add_child(column)
	column.add_child(_label(TITLE_TEXT, TITLE_FONT_SIZE))
	name_edit = LineEdit.new()
	name_edit.placeholder_text = NAME_HINT
	name_edit.max_length = ProfileStore.MAX_NAME_LENGTH
	name_edit.custom_minimum_size = Vector2(520, 64)
	name_edit.add_theme_font_size_override("font_size", FONT_SIZE)
	name_edit.text_changed.connect(func(_text: String) -> void: _refresh())
	name_edit.text_submitted.connect(func(_text: String) -> void: confirm())
	column.add_child(name_edit)
	var middle: HBoxContainer = HBoxContainer.new()
	middle.add_theme_constant_override("separation", 24)
	column.add_child(middle)
	var previews: VBoxContainer = VBoxContainer.new()
	middle.add_child(previews)
	face_preview = _preview()
	previews.add_child(face_preview)
	body_preview = _preview()
	body_preview.custom_minimum_size = PREVIEW_SIZE / 2.0
	body_preview.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	previews.add_child(body_preview)
	var rows: VBoxContainer = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	middle.add_child(rows)
	for part: String in RangerLook.PARTS:
		var row: HBoxContainer = HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		var label: Label = _label(PART_LABELS[part], FONT_SIZE)
		label.custom_minimum_size.x = 110
		row.add_child(label)
		swatches[part] = {}
		for option: String in RangerLook.options(part):
			var swatch: Button = Button.new()
			swatch.name = "%s_%s" % [part, option]
			swatch.custom_minimum_size = SWATCH_SIZE
			swatch.tooltip_text = option.capitalize()
			swatch.pressed.connect(pick.bind(part, option))
			row.add_child(swatch)
			swatches[part][option] = swatch
		rows.add_child(row)
	var buttons: HBoxContainer = HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 24)
	column.add_child(buttons)
	var back: Button = _button(BACK_TEXT)
	back.pressed.connect(func() -> void: cancelled.emit())
	buttons.add_child(back)
	start_button = _button(START_TEXT)
	start_button.pressed.connect(confirm)
	buttons.add_child(start_button)
	name_edit.grab_focus.call_deferred()


func _preview() -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.custom_minimum_size = PREVIEW_SIZE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return rect


func _button(text: String) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.custom_minimum_size = BUTTON_SIZE
	button.add_theme_font_size_override("font_size", FONT_SIZE)
	return button


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	return label
