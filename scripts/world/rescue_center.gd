class_name RescueCenter
extends HabitatMap
## The Wildlife Rescue Center hub (PLAN.md 3.1, 3.9). Everything from HabitatMap (ground, gates,
## ranger), plus:
## - One pen per habitat (from data/maps/rescue_center.json). Its fence sections start knocked
##   over by the storm; each animal rescued from that habitat fixes one section. Sections fixed
##   since the last visit stand back up while you watch.
## - Rescued animals live in their habitat's pen and wander around inside it.
## - The sidekick stands in the plaza and says something helpful when you walk up.
## - Walk up to a pen with animals in it and a care button appears for each kind of animal
##   there ("Care for the Raccoon", or "Deer" / "Bear" / "Owl" with faces when there are several).
##   Space/Enter cares for the kind cared for least. It opens the CareScreen (feed, care note,
##   fact card) while the world waits.

const MAX_RESIDENTS_PER_PEN: int = 8
## How close (pixels) to a pen's fence the ranger must be to care for its animals.
const CARE_DISTANCE: float = 24.0
const CARE_BUTTON_SIZE: Vector2 = Vector2(420, 84)
## Width of each button when a pen has several kinds of animals.
const CARE_KIND_BUTTON_WIDTH: float = 230.0
const CARE_ICON_SIZE: int = 64
## Space between the care and Decorate buttons.
const CARE_ROW_GAP: int = 24
const CARE_BUTTON_FONT_SIZE: int = 34
const CARE_BUTTON_TEXT: String = "Care for the %s"
const CARED_TEXT: String = "The %s is happy and full!"
const LEVEL_UP_TEXT: String = " Level %d!"
const PEN_LEVEL_TEXT: String = "%s level %d"
const DECORATE_TEXT: String = "Decorate"
const DECORATE_BUTTON_WIDTH: float = 240.0
const BOOK_TEXT: String = "Book (B)"
const HUD_BUTTON_SIZE: Vector2 = Vector2(280, 64)
const HUD_GAP: float = 8.0
## Same decoration variety every visit.
const DECORATION_SEED: int = 7
const HAPPY_EMOTE: Texture2D = preload("res://assets/ui/emotes/happy.png")
const HAPPY_EMOTE_SECONDS: float = 2.5
## How close (pixels) the ranger must be for the sidekick to talk.
const TALK_DISTANCE: float = 30.0
## Knocked-over fence look: tilt (alternating) and how far it slumps down.
const BROKEN_TILT: Array[float] = [-24.0, 31.0, -17.0, 27.0]
const BROKEN_DROP: float = 4.0
const REPAIR_SECONDS: float = 0.45
const REPAIR_STAGGER: float = 0.4
const FENCE_COLLISION: Vector2 = Vector2(46, 6)
const PEN_LABEL_FONT_SIZE: int = 10
const PEN_LABEL_TEXT: String = "%s pen"
const SPECIAL_LABEL: String = "Special"
const SPECIAL_LEVEL_TEXT: String = "Level %d"
const SPECIAL_LABEL_COLOR: Color = Color(1, 0.85, 0.3)
const TALK_FONT_SIZE: int = 30
const TALK_FACE_SIZE: float = 96.0
const REPAIRED_TEXT: String = "You fixed %d fence%s! %s pen: %d of %d"

## One entry per pen: {habitat, label, cell, pieces, depth, fences: Array[StaticBody2D], residents: Array[Critter]}.
var pens: Array[Dictionary] = []
var sidekick: Sidekick
var sidekick_sprite: AnimatedSprite2D
var talk_bubble: PanelContainer
var talk_label: Label
## How many fence sections stood back up on this visit (for the banner and tests).
var newly_repaired: int = 0
## Bottom-center row: one care button per kind of animal in the nearby pen, then Decorate.
var care_row: HBoxContainer
var care_buttons: Array[Button] = []
## The kinds of animals the care buttons are offering (in order).
var care_kinds: Array[String] = []
var care_screen: CareScreen
## The animal id Space/Enter cares for (the kind cared for least), or "".
var care_target: String = ""
var decorate_button: Button
var book_button: Button
var shop_screen: ShopScreen
var book_screen: BookScreen
var finale_screen: FinaleScreen
## The pen the Decorate button is offering (its habitat), or "".
var decorate_target: String = ""
var rest_button: Button


func build() -> void:
	super.build()
	sidekick = Sidekick.load_by_id(GameState.sidekick_id, GameState.rng)
	_build_pens()
	_place_sidekick()
	_build_talk_bubble()
	_build_care_row()
	_show_repairs()
	_build_rest_button()
	_build_book_button()
	show_finale_if_ready.call_deferred()


## Fence sections in a pen: one rail piece per column, top and bottom rows.
static func pen_sections(pen: Dictionary) -> int:
	return int(pen["pieces"]) * 2


## Is this animal one of the hidden snakes (they live in the special pens)?
static func is_special_animal(animal_id: String) -> bool:
	return bool(GameState.catalog.get_animal(animal_id).get("hides_under_rocks", false))


## Rescues that live in this pen: the habitat's regular animals, or its snake for a special pen.
static func pen_rescues(pen: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	for id: String in GameState.rescued_from(str(pen["habitat"])):
		if is_special_animal(id) == bool(pen.get("special", false)):
			ids.append(id)
	return ids


## How many of a pen's sections are fixed: one per regular rescue; catching the habitat's
## snake fixes its whole special pen.
static func repaired_sections(pen: Dictionary) -> int:
	var rescued: int = pen_rescues(pen).size()
	if bool(pen.get("special", false)):
		return pen_sections(pen) if rescued > 0 else 0
	return mini(rescued, pen_sections(pen))


func pen_for(habitat_id: String) -> Dictionary:
	for pen: Dictionary in pens:
		if pen["habitat"] == habitat_id:
			return pen
	return {}


## Is this fence section standing (fixed)?
static func is_fixed(fence: StaticBody2D) -> bool:
	return not (fence.get_child(0) as CollisionShape2D).disabled


## A care, shop, or book screen is open (the world waits).
func screen_open() -> bool:
	return care_screen != null or shop_screen != null or book_screen != null or finale_screen != null


func _process(_delta: float) -> void:
	if ranger == null or screen_open():
		return
	_update_care_buttons()
	if sidekick_sprite == null:
		return
	var near: bool = ranger.global_position.distance_to(sidekick_sprite.global_position) <= TALK_DISTANCE
	if near and not talk_bubble.visible:
		talk_label.text = sidekick_line()
		talk_bubble.visible = true
	elif not near and talk_bubble.visible:
		talk_bubble.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if screen_open():
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_B:
		get_viewport().set_input_as_handled()
		open_book()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F10:
		get_viewport().set_input_as_handled()
		_rest()
		return
	if care_target != "" and care_screen == null and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		open_care(care_target)


## The pen's area in pixels (fences included).
static func pen_rect(pen: Dictionary) -> Rect2:
	var cell: Vector2i = Vector2i(int(pen["cell"][0]), int(pen["cell"][1]))
	return Rect2(Vector2(cell.x * TILE, cell.y * TILE), Vector2(int(pen["pieces"]) * 3 * TILE, int(pen["depth"]) * TILE))


## The kinds of animals (with care data) in the pen within CARE_DISTANCE of a spot, each once,
## in the order they moved in; [] if none.
func care_kinds_near(point: Vector2) -> Array[String]:
	var kinds: Array[String] = []
	for resident: Critter in pen_near(point).get("residents", []):
		var id: String = str(resident.animal.get("id", ""))
		if GameState.care_catalog.has_animal(id) and not kinds.has(id):
			kinds.append(id)
	return kinds


## The kind with the fewest care visits (the first one on a tie), or "".
static func least_cared(kinds: Array[String]) -> String:
	var best: String = ""
	for id: String in kinds:
		if best == "" or GameState.care_visits_for(id) < GameState.care_visits_for(best):
			best = id
	return best


## The closest pen within CARE_DISTANCE of a spot, or {}. (A habitat pen and its special pen
## touch, so the nearer one wins.)
func pen_near(point: Vector2) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = INF
	for pen: Dictionary in pens:
		var rect: Rect2 = pen_rect(pen)
		if not rect.grow(CARE_DISTANCE).has_point(point):
			continue
		var distance: float = point.distance_to(point.clamp(rect.position, rect.end))
		if distance < best_distance:
			best = pen
			best_distance = distance
	return best


func _update_care_buttons() -> void:
	var kinds: Array[String] = care_kinds_near(ranger.global_position)
	var near: Dictionary = pen_near(ranger.global_position)
	# Regular pens can be decorated once someone lives there.
	decorate_target = str(near.get("habitat", "")) if not kinds.is_empty() and not bool(near.get("special", false)) else ""
	decorate_button.visible = decorate_target != ""
	if kinds == care_kinds:
		return
	_show_care_kinds(kinds)


## Replaces the care buttons with one per kind (none for []).
func _show_care_kinds(kinds: Array[String]) -> void:
	care_kinds = kinds
	care_target = least_cared(kinds)
	for button: Button in care_buttons:
		button.queue_free()
	care_buttons.clear()
	for id: String in kinds:
		var animal: Dictionary = catalog.get_animal(id)
		var name_text: String = str(animal.get("name", id))
		var button: Button = Button.new()
		button.name = "Care_" + id
		button.text = CARE_BUTTON_TEXT % name_text if kinds.size() == 1 else name_text
		button.custom_minimum_size = Vector2(CARE_BUTTON_SIZE.x if kinds.size() == 1 else CARE_KIND_BUTTON_WIDTH, CARE_BUTTON_SIZE.y)
		if animal.has("faceset"):
			button.icon = load(str(animal["faceset"]))
			button.expand_icon = true
			button.add_theme_constant_override("icon_max_width", CARE_ICON_SIZE)
		button.add_theme_font_size_override("font_size", CARE_BUTTON_FONT_SIZE)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(open_care.bind(id), CONNECT_DEFERRED)
		care_row.add_child(button)
		care_row.move_child(button, care_buttons.size())
		care_buttons.append(button)


## Freezes the world and hides the hub buttons while a screen is open (or brings them back).
func _set_world_waiting(waiting: bool) -> void:
	objects.process_mode = Node.PROCESS_MODE_DISABLED if waiting else Node.PROCESS_MODE_INHERIT
	_show_care_kinds([])
	decorate_button.visible = false
	rest_button.visible = not waiting
	book_button.visible = not waiting
	decorate_target = ""
	if waiting:
		talk_bubble.visible = false
		mode_button.visible = false
	else:
		refresh_mode_button()


## Opens the pen shop for a habitat's pen.
func open_shop(habitat_id: String) -> void:
	if screen_open() or pen_for(habitat_id).is_empty():
		return
	_set_world_waiting(true)
	shop_screen = ShopScreen.new()
	add_child(shop_screen)
	shop_screen.closed.connect(_on_shop_closed.bind(habitat_id))
	shop_screen.start(habitat_id, str(pen_for(habitat_id).get("label", habitat_id)), map.objects)


func _on_shop_closed(habitat_id: String) -> void:
	shop_screen.queue_free()
	shop_screen = null
	_set_world_waiting(false)
	_place_decorations(pen_for(habitat_id))


func open_book() -> void:
	if screen_open():
		return
	_set_world_waiting(true)
	book_screen = BookScreen.new()
	add_child(book_screen)
	book_screen.closed.connect(_on_book_closed)


## Plays the finale once, the first time the player is at the hub with everyone home.
func show_finale_if_ready() -> void:
	if screen_open() or GameState.finale_seen or not GameState.finale_ready():
		return
	_set_world_waiting(true)
	GameState.log_event("finale", {"rescued": GameState.rescued_count()})
	finale_screen = FinaleScreen.new()
	add_child(finale_screen)
	finale_screen.closed.connect(_on_finale_closed)


func _on_finale_closed() -> void:
	GameState.finale_seen = true
	GameState.save_progress()
	finale_screen.queue_free()
	finale_screen = null
	_set_world_waiting(false)


func _on_book_closed() -> void:
	book_screen.queue_free()
	book_screen = null
	_set_world_waiting(false)


## Opens the care screen for `animal_id` (one of the residents). The world waits meanwhile.
func open_care(animal_id: String) -> void:
	if screen_open() or not catalog.has_animal(animal_id):
		return
	_set_world_waiting(true)
	# Snakes are cared for one grade up (a little harder to read and spell).
	var grade: String = CareCatalog.harder_grade(GameState.grade) if is_special_animal(animal_id) else GameState.grade
	var visit: CareVisit = CareVisit.make(GameState.care_catalog, animal_id, grade,
		GameState.care_visits_for(animal_id), GameState.rng)
	care_screen = CareScreen.new()
	add_child(care_screen)
	care_screen.finished.connect(_on_care_finished.bind(animal_id))
	care_screen.start(catalog.get_animal(animal_id), visit)


func _on_care_finished(completed: bool, animal_id: String) -> void:
	care_screen.queue_free()
	care_screen = null
	_set_world_waiting(false)
	if not completed:
		return
	var stars_before: int = GameState.stars
	var leveled_up: bool = GameState.record_care(animal_id)
	var text: String = CARED_TEXT % catalog.get_animal(animal_id).get("name", animal_id)
	if leveled_up:
		text += LEVEL_UP_TEXT % GameState.animal_level(animal_id)
	show_banner(text + STARS_EARNED_TEXT % (GameState.stars - stars_before))
	_refresh_pen_levels()
	for pen: Dictionary in pens:
		for resident: Critter in pen["residents"]:
			if resident.animal.get("id", "") == animal_id:
				_show_happy(resident)


## A happy face over a resident for a moment.
func _show_happy(resident: Critter) -> void:
	resident.emote.texture = HAPPY_EMOTE
	resident.emote.visible = true
	# A tween owned by the resident, so it goes away with it (a scene-tree timer could outlive it).
	var tween: Tween = resident.create_tween()
	tween.tween_interval(HAPPY_EMOTE_SECONDS)
	tween.tween_callback(resident.emote.hide)


## The bottom-center row: care buttons (filled in by _show_care_kinds), then Decorate, centered together.
func _build_care_row() -> void:
	care_row = HBoxContainer.new()
	care_row.name = "CareRow"
	care_row.add_theme_constant_override("separation", CARE_ROW_GAP)
	care_row.anchor_left = 0.5
	care_row.anchor_right = 0.5
	care_row.anchor_top = 1.0
	care_row.anchor_bottom = 1.0
	care_row.offset_bottom = -30
	care_row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	care_row.grow_vertical = Control.GROW_DIRECTION_BEGIN
	get_node("Hud").add_child(care_row)
	decorate_button = Button.new()
	decorate_button.name = "DecorateButton"
	decorate_button.text = DECORATE_TEXT
	decorate_button.custom_minimum_size = Vector2(DECORATE_BUTTON_WIDTH, CARE_BUTTON_SIZE.y)
	decorate_button.add_theme_font_size_override("font_size", CARE_BUTTON_FONT_SIZE)
	decorate_button.focus_mode = Control.FOCUS_NONE
	decorate_button.visible = false
	decorate_button.pressed.connect(func() -> void:
		if decorate_target != "":
			open_shop(decorate_target), CONNECT_DEFERRED)
	care_row.add_child(decorate_button)


func _build_book_button() -> void:
	book_button = Button.new()
	book_button.name = "BookButton"
	book_button.text = BOOK_TEXT
	book_button.position = Vector2(16, 16 + HUD_BUTTON_SIZE.y + HUD_GAP)
	book_button.custom_minimum_size = HUD_BUTTON_SIZE
	book_button.add_theme_font_size_override("font_size", 28)
	# World arrows move the ranger; B is the keyboard shortcut.
	book_button.focus_mode = Control.FOCUS_NONE
	book_button.pressed.connect(open_book, CONNECT_DEFERRED)
	get_node("Hud").add_child(book_button)


## Shows the pen's bought decorations (each once).
func _place_decorations(pen: Dictionary) -> void:
	if pen.is_empty() or bool(pen.get("special", false)):
		return
	var cell: Vector2i = Vector2i(int(pen["cell"][0]), int(pen["cell"][1]))
	var placed: Dictionary = pen.get("decorations", {})
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = DECORATION_SEED
	for id: Variant in GameState.decorations.get(str(pen["habitat"]), []):
		var item: Dictionary = GameState.rewards.decoration(str(id))
		if item.is_empty() or placed.has(id) or not map.objects.has(str(item["object"])):
			continue
		var def: Dictionary = (map.objects[str(item["object"])] as Dictionary).duplicate()
		def["blocks"] = false  # residents wander through and never get stuck
		var node: Node2D = _make_object(def, cell + Vector2i(int(item["spot"][0]), int(item["spot"][1])), rng)
		node.name = "Decoration_%s_%s" % [pen["habitat"], id]
		objects.add_child(node)
		placed[id] = node
	pen["decorations"] = placed


## "Raccoon level 2" under each pen with animals in it.
func _refresh_pen_levels() -> void:
	for pen: Dictionary in pens:
		var label: Label = pen["level_label"]
		# Levels come from care, so name the first resident that can be cared for.
		var id: String = ""
		for resident: Critter in pen["residents"]:
			if GameState.care_catalog.has_animal(str(resident.animal["id"])):
				id = str(resident.animal["id"])
				break
		label.visible = id != ""
		if label.visible:
			label.text = (SPECIAL_LEVEL_TEXT % GameState.animal_level(id)) if bool(pen.get("special", false)) 				else PEN_LEVEL_TEXT % [catalog.get_animal(id).get("name", id), GameState.animal_level(id)]


## What the sidekick says when you walk up: where to go at first, then how it's going.
func sidekick_line() -> String:
	var count: int = GameState.rescued_count()
	var event: String = "hub_start" if count == 0 else "hub_progress"
	return sidekick.line(event).replace("{count}", str(count))


func _build_pens() -> void:
	for def: Variant in map.meta.get("pens", []):
		var habitat_pen: Dictionary = (def as Dictionary).duplicate()
		habitat_pen["repair_key"] = habitat_pen["habitat"]
		_build_pen(habitat_pen)
		if int(def.get("special_pieces", 0)) > 0:
			# The snake's pen sits right beside its habitat's pen, in the same fence line.
			_build_pen({"habitat": def["habitat"], "label": SPECIAL_LABEL, "special": true,
				"cell": [int(def["cell"][0]) + int(def["pieces"]) * 3, int(def["cell"][1])],
				"pieces": int(def["special_pieces"]), "depth": def["depth"],
				"repair_key": "%s_special" % def["habitat"]})
	_refresh_pen_levels()


func _build_pen(pen: Dictionary) -> void:
	var cell: Vector2i = Vector2i(int(pen["cell"][0]), int(pen["cell"][1]))
	var pieces: int = int(pen["pieces"])
	var depth: int = int(pen["depth"])
	var fences: Array[StaticBody2D] = []
	for row_y: int in [cell.y, cell.y + depth]:
		for i: int in pieces:
			var fence: StaticBody2D = _make_fence(Vector2i(cell.x + i * 3 + 1, row_y), fences.size())
			objects.add_child(fence)
			fences.append(fence)
	pen["fences"] = fences
	# Special pens are narrow, so their labels stay short.
	var title: String = SPECIAL_LABEL if bool(pen.get("special", false)) else PEN_LABEL_TEXT % str(pen.get("label", ""))
	var name_label: Label = _add_pen_label(title, cell, pieces)
	if bool(pen.get("special", false)):
		name_label.add_theme_color_override("font_color", SPECIAL_LABEL_COLOR)
	pen["level_label"] = _add_pen_label("", cell, pieces)
	(pen["level_label"] as Label).position.y += PEN_LABEL_FONT_SIZE + 2
	pen["residents"] = _add_residents(pen, cell, pieces, depth)
	pens.append(pen)
	_place_decorations(pen)


## One rail section, starting knocked over (no collision).
func _make_fence(center_cell: Vector2i, index: int) -> StaticBody2D:
	var body: StaticBody2D = StaticBody2D.new()
	body.name = "Fence_%d_%d" % [center_cell.x, center_cell.y]
	body.position = map.cell_to_feet(center_cell)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = FENCE_COLLISION
	shape.shape = box
	shape.position = Vector2(0, -FENCE_COLLISION.y / 2.0)
	shape.disabled = true
	body.add_child(shape)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.name = "Sprite"
	sprite.texture = ELEMENT_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = FENCE_REGION
	sprite.offset = Vector2(0, -FENCE_REGION.size.y / 2.0)
	sprite.rotation_degrees = BROKEN_TILT[index % BROKEN_TILT.size()]
	sprite.position.y = BROKEN_DROP
	sprite.modulate = Color(0.85, 0.8, 0.75)
	body.add_child(sprite)
	return body


## Stands a fence section back up (animated unless `instant`).
func _fix_fence(fence: StaticBody2D, instant: bool, delay: float = 0.0) -> void:
	(fence.get_child(0) as CollisionShape2D).set_deferred("disabled", false)
	var sprite: Sprite2D = fence.get_node("Sprite")
	if instant:
		sprite.rotation_degrees = 0.0
		sprite.position.y = 0.0
		sprite.modulate = Color.WHITE
		return
	var tween: Tween = create_tween().set_parallel()
	tween.tween_property(sprite, "rotation_degrees", 0.0, REPAIR_SECONDS).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "position:y", 0.0, REPAIR_SECONDS).set_delay(delay)
	tween.tween_property(sprite, "modulate", Color.WHITE, REPAIR_SECONDS).set_delay(delay)


## Fixes one section per rescue; the ones fixed since last time stand up while you watch.
func _show_repairs() -> void:
	newly_repaired = 0
	var messages: Array[String] = []
	for pen: Dictionary in pens:
		var key: String = str(pen["repair_key"])
		var fixed: int = repaired_sections(pen)
		var seen: int = mini(int(GameState.pen_repairs_shown.get(key, 0)), fixed)
		var fences: Array[StaticBody2D] = pen["fences"]
		for k: int in fixed:
			_fix_fence(fences[k], k < seen, (k - seen) * REPAIR_STAGGER + 0.5)
		var new_now: int = fixed - seen
		if new_now > 0:
			newly_repaired += new_now
			messages.append(REPAIRED_TEXT % [new_now, "" if new_now == 1 else "s", str(pen["label"]), fixed, pen_sections(pen)])
		GameState.pen_repairs_shown[key] = fixed
	GameState.save_progress()
	if not messages.is_empty():
		show_banner(" ".join(messages), BANNER_SECONDS + newly_repaired * REPAIR_STAGGER)


func _build_rest_button() -> void:
	rest_button = Button.new()
	rest_button.text = "Save & rest (F10)"
	rest_button.position = Vector2(16, 16)
	rest_button.custom_minimum_size = Vector2(280, 64)
	rest_button.add_theme_font_size_override("font_size", 28)
	# World arrows move the ranger; F10 supplies the keyboard shortcut here.
	rest_button.focus_mode = Control.FOCUS_NONE
	rest_button.pressed.connect(_rest, CONNECT_DEFERRED)
	get_node("Hud").add_child(rest_button)


func _rest() -> void:
	if not screen_open() and GameState.finish_session():
		Speech.stop()
		get_tree().change_scene_to_file("res://scenes/main.tscn")


## Rescued animals from this habitat, wandering inside the pen (they never get startled).
func _add_residents(pen: Dictionary, cell: Vector2i, pieces: int, depth: int) -> Array[Critter]:
	var residents: Array[Critter] = []
	var inside: Rect2 = Rect2(
		Vector2(cell.x * TILE + 6, (cell.y + 1) * TILE + 4),
		Vector2(pieces * 3 * TILE - 12, (depth - 1) * TILE - 18))
	var is_open: Callable = func(point: Vector2) -> bool: return inside.has_point(point)
	var ids: Array[String] = pen_rescues(pen)
	for i: int in mini(ids.size(), MAX_RESIDENTS_PER_PEN):
		if not catalog.has_animal(ids[i]):
			continue
		var resident: Critter = Critter.new()
		var home: Vector2 = inside.position + Vector2(_rng.randf() * inside.size.x, _rng.randf() * inside.size.y)
		resident.setup(catalog.get_animal(ids[i]), home, is_open, _rng)
		resident.name = "Resident_%s_%d" % [ids[i], i]
		objects.add_child(resident)
		residents.append(resident)
	return residents


func _add_pen_label(text: String, cell: Vector2i, pieces: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", PEN_LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.25, 0.18, 0.08))
	label.add_theme_constant_override("outline_size", 4)
	label.size = Vector2(pieces * 3 * TILE, 14)
	label.position = Vector2(cell.x * TILE, (cell.y - 2) * TILE - 4)
	label.z_index = 10
	add_child(label)
	return label


func _place_sidekick() -> void:
	var spot: Vector2i = map.find_char(map.sidekick_char)
	if spot.x < 0:
		return
	sidekick_sprite = AnimatedSprite2D.new()
	sidekick_sprite.name = "Sidekick"
	sidekick_sprite.sprite_frames = Ranger.build_frames(load(str(sidekick.data["sprite"])))
	sidekick_sprite.offset = Vector2(0, -TILE / 2.0)
	sidekick_sprite.position = map.cell_to_feet(spot)
	sidekick_sprite.play("idle_down")
	objects.add_child(sidekick_sprite)


func _build_talk_bubble() -> void:
	talk_bubble = PanelContainer.new()
	talk_bubble.name = "TalkBubble"
	talk_bubble.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	talk_bubble.offset_left = 40
	talk_bubble.offset_right = -40
	talk_bubble.offset_top = -170
	talk_bubble.offset_bottom = -30
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 0.97)
	style.border_color = Color(0.3, 0.25, 0.15)
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(14)
	talk_bubble.add_theme_stylebox_override("panel", style)
	talk_bubble.visible = false
	get_node("Hud").add_child(talk_bubble)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	talk_bubble.add_child(row)
	var face: TextureRect = TextureRect.new()
	face.texture = sidekick.faceset()
	face.custom_minimum_size = Vector2(TALK_FACE_SIZE, TALK_FACE_SIZE)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(face)
	talk_label = Label.new()
	talk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	talk_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	talk_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	talk_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	talk_label.add_theme_font_size_override("font_size", TALK_FONT_SIZE)
	talk_label.add_theme_color_override("font_color", Color(0.2, 0.18, 0.12))
	row.add_child(talk_label)
