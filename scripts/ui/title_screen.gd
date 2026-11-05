extends Control
## Title screen. Normal play: two big profile buttons (PLAN 3.2), one per boy, each showing his
## ranger, his sidekick, and his name. A new profile (or an old save with no name yet) first
## makes its ranger. Playtests skip the buttons: any key starts the playtest's own save.

const START_SCENE: String = "res://scenes/story/storm_intro.tscn"
const HUB_SCENE: String = "res://scenes/world/rescue_center.tscn"
const CARD_SIZE: Vector2 = Vector2(400, 320)
const FACE_SIZE: Vector2 = Vector2(120, 120)
const NAME_FONT_SIZE: int = 40
const SMALL_FONT_SIZE: int = 26
const NEW_RANGER: String = "New ranger"
const WITH_TEXT: String = "with %s"
const TITLE_RAISE: float = 230.0
const PLAYTEST_HINT: String = "Playtest 3: pick your ranger"

## Tests point this at their own slots so they never read the real saves.
var slots: Array = []
var cards: Array[Button] = []
var setup_screen: RangerSetup
## Off in tests: then nothing changes scene by itself.
var auto_change_scene: bool = true


func _ready() -> void:
	if GameState.is_playtest() and not GameState.playtest_uses_profiles():
		$StartHint.text = "Press any key to continue" if GameState.intro_seen else "Press any key to start"
		$StartHint.text += "\nPlaytest 2: rescue and care" if GameState.playtest.get("version", "").begins_with("playtest-2") else "\nChase playtest"
		return
	$StartHint.visible = GameState.is_playtest()
	$StartHint.text = PLAYTEST_HINT
	$Title.position.y -= TITLE_RAISE
	if slots.is_empty() and GameState.profile_access:
		slots = GameState.profile_slots()
	var row: HBoxContainer = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 48)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	row.position.y += 60
	add_child(row)
	for profile_slot: Variant in slots:
		var card: Button = _card(profile_slot as Dictionary)
		row.add_child(card)
		cards.append(card)
	if not cards.is_empty():
		cards[0].grab_focus.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if not GameState.is_playtest() or GameState.playtest_uses_profiles():
		return
	var is_start: bool = (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) \
		and event.is_pressed() and not event.is_echo()
	if is_start:
		get_viewport().set_input_as_handled()
		if GameState.can_start():
			_go()


## Plays a profile slot: loads (or makes) its save, then asks for a name and look if it has none.
func choose(profile_slot: Dictionary) -> void:
	if setup_screen != null or not GameState.start_slot(profile_slot):
		return
	if GameState.player_name == "":
		_open_setup()
	else:
		_go()


func _open_setup() -> void:
	$Title.visible = false
	for card: Button in cards:
		card.visible = false
	setup_screen = RangerSetup.new()
	add_child(setup_screen)
	setup_screen.setup(GameState.player_name, GameState.look)
	setup_screen.done.connect(_on_setup_done)
	setup_screen.cancelled.connect(_close_setup)


func _on_setup_done(player_name: String, look: Dictionary) -> void:
	GameState.player_name = player_name
	GameState.look = look
	GameState.save_progress()
	_close_setup()
	_go()


func _close_setup() -> void:
	setup_screen.queue_free()
	setup_screen = null
	$Title.visible = true
	for card: Button in cards:
		card.visible = true


func _go() -> void:
	if auto_change_scene:
		get_tree().change_scene_to_file(HUB_SCENE if GameState.intro_seen else START_SCENE)


func _card(profile_slot: Dictionary) -> Button:
	var saved: Dictionary = GameState.peek_slot(profile_slot)
	var card: Button = Button.new()
	card.name = "Card_%s" % profile_slot["id"]
	card.custom_minimum_size = CARD_SIZE
	card.pressed.connect(choose.bind(profile_slot), CONNECT_DEFERRED)
	var column: VBoxContainer = VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(column)
	var faces: HBoxContainer = HBoxContainer.new()
	faces.alignment = BoxContainer.ALIGNMENT_CENTER
	faces.add_theme_constant_override("separation", 16)
	faces.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(faces)
	var sidekick_id: String = str(saved.get("sidekick_id", profile_slot.get("sidekick_id", "henrito")))
	var sidekick: Sidekick = Sidekick.load_by_id(sidekick_id, GameState.rng)
	faces.add_child(_face(RangerLook.faceset(saved.get("look", {}))))
	faces.add_child(_face(sidekick.faceset()))
	var name_text: String = str(saved.get("name", ""))
	column.add_child(_label(name_text if name_text != "" else NEW_RANGER, NAME_FONT_SIZE))
	column.add_child(_label(WITH_TEXT % sidekick.display_name(), SMALL_FONT_SIZE))
	return card


func _face(texture: Texture2D) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.texture = texture
	rect.custom_minimum_size = FACE_SIZE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return rect


func _label(text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label
