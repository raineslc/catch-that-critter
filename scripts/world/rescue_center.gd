class_name RescueCenter
extends HabitatMap
## The Wildlife Rescue Center hub (PLAN.md 3.1, 3.9). Everything from HabitatMap (ground, gates,
## ranger), plus:
## - One pen per habitat (from data/maps/rescue_center.json). Its fence sections start knocked
##   over by the storm; each animal rescued from that habitat fixes one section. Sections fixed
##   since the last visit stand back up while you watch.
## - Rescued animals live in their habitat's pen and wander around inside it.
## - The sidekick stands in the plaza and says something helpful when you walk up.

const MAX_RESIDENTS_PER_PEN: int = 8
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


func build() -> void:
	super.build()
	sidekick = Sidekick.load_by_id(GameState.sidekick_id, GameState.rng)
	_build_pens()
	_place_sidekick()
	_build_talk_bubble()
	_show_repairs()


## Fence sections in a pen: one rail piece per column, top and bottom rows.
static func pen_sections(pen: Dictionary) -> int:
	return int(pen["pieces"]) * 2


## How many of a pen's sections are fixed (one per rescue from its habitat).
static func repaired_sections(pen: Dictionary) -> int:
	return mini(GameState.rescued_count(str(pen["habitat"])), pen_sections(pen))


func pen_for(habitat_id: String) -> Dictionary:
	for pen: Dictionary in pens:
		if pen["habitat"] == habitat_id:
			return pen
	return {}


## Is this fence section standing (fixed)?
static func is_fixed(fence: StaticBody2D) -> bool:
	return not (fence.get_child(0) as CollisionShape2D).disabled


func _process(_delta: float) -> void:
	if sidekick_sprite == null or ranger == null:
		return
	var near: bool = ranger.global_position.distance_to(sidekick_sprite.global_position) <= TALK_DISTANCE
	if near and not talk_bubble.visible:
		talk_label.text = sidekick_line()
		talk_bubble.visible = true
	elif not near and talk_bubble.visible:
		talk_bubble.visible = false


## What the sidekick says when you walk up: where to go at first, then how it's going.
func sidekick_line() -> String:
	var count: int = GameState.rescued_count()
	var event: String = "hub_start" if count == 0 else "hub_progress"
	return sidekick.line(event).replace("{count}", str(count))


func _build_pens() -> void:
	for def: Variant in map.meta.get("pens", []):
		var pen: Dictionary = (def as Dictionary).duplicate()
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
		_add_pen_label(PEN_LABEL_TEXT % str(pen.get("label", "")), cell, pieces)
		pen["residents"] = _add_residents(str(pen["habitat"]), cell, pieces, depth)
		pens.append(pen)


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
		var habitat_id: String = str(pen["habitat"])
		var fixed: int = repaired_sections(pen)
		var seen: int = mini(int(GameState.pen_repairs_shown.get(habitat_id, 0)), fixed)
		var fences: Array[StaticBody2D] = pen["fences"]
		for k: int in fixed:
			_fix_fence(fences[k], k < seen, (k - seen) * REPAIR_STAGGER + 0.5)
		var new_now: int = fixed - seen
		if new_now > 0:
			newly_repaired += new_now
			messages.append(REPAIRED_TEXT % [new_now, "" if new_now == 1 else "s", str(pen["label"]), fixed, pen_sections(pen)])
		GameState.pen_repairs_shown[habitat_id] = fixed
	if not messages.is_empty():
		show_banner(" ".join(messages), BANNER_SECONDS + newly_repaired * REPAIR_STAGGER)


## Rescued animals from this habitat, wandering inside the pen (they never get startled).
func _add_residents(habitat_id: String, cell: Vector2i, pieces: int, depth: int) -> Array[Critter]:
	var residents: Array[Critter] = []
	var inside: Rect2 = Rect2(
		Vector2(cell.x * TILE + 6, (cell.y + 1) * TILE + 4),
		Vector2(pieces * 3 * TILE - 12, (depth - 1) * TILE - 18))
	var is_open: Callable = func(point: Vector2) -> bool: return inside.has_point(point)
	var ids: Array[String] = GameState.rescued_from(habitat_id)
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


func _add_pen_label(text: String, cell: Vector2i, pieces: int) -> void:
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
