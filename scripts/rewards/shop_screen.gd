class_name ShopScreen
extends CanvasLayer
## The pen shop (PLAN.md 3.10): spend stars on decorations for one habitat's pen.
## Each decoration can be bought once per pen. Emits `closed` when the player is done.

signal closed

const NATURE_TEXTURE: Texture2D = preload("res://assets/tilesets/nature.png")
const SFX_BUY: AudioStream = preload("res://assets/audio/sfx/correct.wav")
const TILE: int = 16
const BACKGROUND: Color = Color(0.93, 0.87, 0.72)
const INK: Color = Color(0.2, 0.18, 0.12)
const TITLE_FONT_SIZE: int = 48
const TEXT_FONT_SIZE: int = 32
const ITEM_FONT_SIZE: int = 28
const ITEM_SIZE: Vector2 = Vector2(250, 250)
const DONE_SIZE: Vector2 = Vector2(220, 80)

const TITLE: String = "Decorate the %s pen"
const STARS_TEXT: String = "You have ★ %d"
const PRICE_TEXT: String = "%s\n★ %d"
const OWNED_TEXT: String = "%s\nIn the pen!"
const BOUGHT_TEXT: String = "The %s is in the pen now!"
const SAVE_UP_TEXT: String = "Keep rescuing and caring to earn more stars."
const DONE: String = "Done"

var habitat_id: String = ""
## Legend object definitions (MapData.objects), for each decoration's picture.
var object_defs: Dictionary = {}
var stars_label: Label
var feedback: Label
var item_buttons: Array[Button] = []
var done_button: Button
var _sfx: AudioStreamPlayer


## Opens the shop for one pen. `label` is the habitat's name ("Meadow").
func start(pen_habitat: String, label: String, defs: Dictionary) -> void:
	habitat_id = pen_habitat
	object_defs = defs
	layer = 10
	_build(TITLE % label)
	refresh()


## Buys decoration `id` for this pen (the item buttons call this).
func buy(id: String) -> void:
	if not GameState.buy_decoration(habitat_id, id):
		feedback.text = SAVE_UP_TEXT
		return
	_sfx.play()
	feedback.text = BOUGHT_TEXT % str(GameState.rewards.decoration(id)["name"]).to_lower()
	refresh()


## Updates the star count and which items can be bought.
func refresh() -> void:
	stars_label.text = STARS_TEXT % GameState.stars
	for button: Button in item_buttons:
		var item: Dictionary = GameState.rewards.decoration(button.get_meta("id"))
		var owned: bool = GameState.has_decoration(habitat_id, item["id"])
		button.text = (OWNED_TEXT % item["name"]) if owned else (PRICE_TEXT % [item["name"], int(item["price"])])
		button.disabled = owned or GameState.stars < int(item["price"])
	if done_button.has_focus() or not item_buttons.any(func(b: Button) -> bool: return b.has_focus() and not b.disabled):
		done_button.grab_focus()


func close() -> void:
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()


## The decoration's picture: its tile(s) from nature.png.
func icon_for(item: Dictionary) -> Texture2D:
	var def: Dictionary = object_defs.get(str(item["object"]), {})
	if def.is_empty():
		return null
	var atlas_value: Variant = def["atlas"]
	var first: Array = atlas_value[0] if atlas_value[0] is Array else atlas_value
	var icon: AtlasTexture = AtlasTexture.new()
	icon.atlas = NATURE_TEXTURE
	icon.region = Rect2(Vector2(int(first[0]), int(first[1])) * TILE, Vector2(int(def["size"][0]), int(def["size"][1])) * TILE)
	return icon


func _build(title: String) -> void:
	var background: ColorRect = ColorRect.new()
	background.color = BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 24)
	add_child(column)
	column.add_child(_label(title, TITLE_FONT_SIZE))
	stars_label = _label("", TEXT_FONT_SIZE)
	column.add_child(stars_label)
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	for item: Dictionary in GameState.rewards.decorations():
		var button: Button = Button.new()
		button.name = "Item_%s" % item["id"]
		button.set_meta("id", item["id"])
		button.custom_minimum_size = ITEM_SIZE
		button.icon = icon_for(item)
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		button.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		button.add_theme_constant_override("icon_max_width", int(ITEM_SIZE.x * 0.5))
		button.add_theme_font_size_override("font_size", ITEM_FONT_SIZE)
		button.pressed.connect(buy.bind(str(item["id"])), CONNECT_DEFERRED)
		row.add_child(button)
		item_buttons.append(button)
	feedback = _label("", TEXT_FONT_SIZE)
	column.add_child(feedback)
	done_button = Button.new()
	done_button.name = "Done"
	done_button.text = DONE
	done_button.custom_minimum_size = DONE_SIZE
	done_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	done_button.add_theme_font_size_override("font_size", TEXT_FONT_SIZE)
	done_button.pressed.connect(close, CONNECT_DEFERRED)
	column.add_child(done_button)
	_sfx = AudioStreamPlayer.new()
	_sfx.stream = SFX_BUY
	add_child(_sfx)


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	return label
