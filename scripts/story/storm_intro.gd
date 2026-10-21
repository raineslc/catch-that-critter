class_name StormIntro
extends Control
## The storm intro (PLAN.md 3.1): a few panels with big captions. A sunny rescue center,
## a thunderstorm, fences crashing down, animals running off, then the sidekick explains the mission.
## Panels and captions come from data/story/intro.json. Next / click / Space / Enter goes on;
## Skip jumps to the game. Emits `finished` and (by default) goes to the Rescue Center.

signal finished

const STORY_PATH: String = "res://data/story/intro.json"
const NEXT_SCENE: String = "res://scenes/world/rescue_center.tscn"
const SCALE: float = 4.0
const TILE: int = 16
const FLOOR_TEXTURE: Texture2D = preload("res://assets/tilesets/floor.png")
const ELEMENT_TEXTURE: Texture2D = preload("res://assets/tilesets/element.png")
const GRASS_ATLAS: Vector2i = Vector2i(0, 12)
## Rail fence piece in element.png: 3 tiles wide, 2 tall.
const FENCE_REGION: Rect2 = Rect2(11 * 16, 2 * 16, 48, 32)
const FENCE_PIECES: int = 4
## Where the pen's fence rows appear on screen (top-left corner of each row).
const PEN_LEFT: float = 256.0
const PEN_TOP_Y: float = 90.0
const PEN_BOTTOM_Y: float = 400.0
const ANIMAL_ROW_Y: float = 330.0
const HENRITO_STOP_X: float = 150.0
const HENRITO_Y: float = 500.0
## Fallen fences: tipped this many degrees (alternating left/right) and dropped this far.
const FALLEN_TILT: Array[float] = [-24.0, 31.0, -17.0, 27.0]
const FALLEN_DROP: float = 36.0
const STORM_MUSIC_FADE: float = 1.0
const MUSIC: AudioStream = preload("res://assets/audio/music/calm_village.ogg")
const STORM_SOUND: AudioStream = preload("res://assets/audio/ambient/storm.wav")
const NIGHT_COLOR: Color = Color(0.04, 0.06, 0.2, 0.62)
const FLASH_COLOR: Color = Color(1, 1, 0.9, 0.6)
const BOLT_COLOR: Color = Color(1, 0.97, 0.6)
const LIGHTNING_EVERY: Vector2 = Vector2(1.6, 3.2)
const CAPTION_FONT_SIZE: int = 40
const BUBBLE_FONT_SIZE: int = 34
const BUTTON_SIZE: Vector2 = Vector2(240, 96)
const NEXT_TEXT: String = "Next"
const LAST_TEXT: String = "Let's go!"

## Off in tests: then nothing changes scene by itself.
var auto_change_scene: bool = true

var story: Dictionary = {}
var panels: Array = []
var panel_index: int = -1
var state: String = ""
var sidekick: Sidekick

var stage: Control
var fences: Array[TextureRect] = []
var animals: Array[AnimatedSprite2D] = []
var henrito: AnimatedSprite2D
var night: ColorRect
var flash: ColorRect
var bolt: Line2D
var rain: CPUParticles2D
var caption_panel: PanelContainer
var caption: Label
var bubble: PanelContainer
var bubble_label: Label
var next_button: Button
var skip_button: Button
var music: AudioStreamPlayer
var storm_sound: AudioStreamPlayer

var _lightning_left: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _done: bool = false


func _ready() -> void:
	_rng.randomize()
	story = load_story()
	panels = story.get("panels", [])
	sidekick = Sidekick.load_by_id(GameState.sidekick_id, GameState.rng)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	show_panel(0)


static func load_story(path: String = STORY_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## Caption text with {sidekick} filled in.
func caption_text(panel: Dictionary) -> String:
	return str(panel.get("caption", "")).replace("{sidekick}", sidekick.display_name())


func show_panel(index: int) -> void:
	panel_index = index
	var panel: Dictionary = panels[index]
	_enter_state(str(panel.get("state", "sunny")))
	var text: String = caption_text(panel)
	var by_sidekick: bool = str(panel.get("speaker", "")) == "sidekick"
	caption_panel.visible = not by_sidekick
	bubble.visible = by_sidekick
	caption.text = text
	bubble_label.text = text
	next_button.text = LAST_TEXT if index == panels.size() - 1 else NEXT_TEXT


## Next panel, or finish after the last one.
func advance() -> void:
	if _done:
		return
	if panel_index >= panels.size() - 1:
		finish()
	else:
		show_panel(panel_index + 1)


func finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	if auto_change_scene:
		get_tree().change_scene_to_file(NEXT_SCENE)


func _unhandled_input(event: InputEvent) -> void:
	var key: InputEventKey = event as InputEventKey
	var click: InputEventMouseButton = event as InputEventMouseButton
	var touch: InputEventScreenTouch = event as InputEventScreenTouch
	var go: bool = (key != null and key.pressed and not key.echo and key.keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_RIGHT]) \
		or (click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT) \
		or (touch != null and touch.pressed)
	if go:
		get_viewport().set_input_as_handled()
		advance()


func _process(delta: float) -> void:
	if state != "storm" and state != "fences_fall" and state != "scatter":
		return
	_lightning_left -= delta
	if _lightning_left <= 0.0:
		_lightning_left = _rng.randf_range(LIGHTNING_EVERY.x, LIGHTNING_EVERY.y)
		_strike()


## Each state changes the scene once (several panels can share a state).
func _enter_state(new_state: String) -> void:
	if new_state == state:
		return
	state = new_state
	match state:
		"sunny":
			night.color.a = 0.0
			rain.emitting = false
			_play_music()
		"storm":
			_tween_night(NIGHT_COLOR.a)
			rain.emitting = true
			_fade_out(music)
			storm_sound.play()
			_lightning_left = 0.3
		"fences_fall":
			night.color.a = NIGHT_COLOR.a
			rain.emitting = true
			_knock_down_fences()
			_shake()
		"scatter":
			night.color.a = NIGHT_COLOR.a
			rain.emitting = true
			_knock_down_fences()
			_scatter_animals()
		"morning":
			_knock_down_fences()
			_scatter_animals(true)
			rain.emitting = false
			_tween_night(0.0)
			_fade_out(storm_sound)
			_play_music()
			_walk_in_henrito()


func _play_music() -> void:
	music.volume_db = -8.0
	if not music.playing:
		music.play()


func _fade_out(player: AudioStreamPlayer) -> void:
	if not player.playing:
		return
	var tween: Tween = create_tween()
	tween.tween_property(player, "volume_db", -40.0, STORM_MUSIC_FADE)
	tween.tween_callback(func() -> void:
		player.stop()
		player.volume_db = 0.0)


func _tween_night(alpha: float) -> void:
	create_tween().tween_property(night, "color:a", alpha, 1.2)


## A lightning bolt and a white flash.
func _strike() -> void:
	var x: float = _rng.randf_range(150.0, 1130.0)
	var points: PackedVector2Array = [Vector2(x, 0)]
	var y: float = 0.0
	while y < 280.0:
		y += _rng.randf_range(30.0, 55.0)
		x += _rng.randf_range(-35.0, 35.0)
		points.append(Vector2(x, y))
	bolt.points = points
	bolt.visible = true
	flash.color = FLASH_COLOR
	var tween: Tween = create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.35)
	tween.parallel().tween_callback(func() -> void: bolt.visible = false).set_delay(0.15)


func _knock_down_fences() -> void:
	for i: int in fences.size():
		var fence: TextureRect = fences[i]
		if fence.has_meta("down"):
			continue
		fence.set_meta("down", true)
		var tween: Tween = create_tween().set_parallel()
		var delay: float = i * 0.08
		tween.tween_property(fence, "rotation_degrees", FALLEN_TILT[i % FALLEN_TILT.size()], 0.35).set_delay(delay).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tween.tween_property(fence, "position:y", fence.position.y + FALLEN_DROP, 0.35).set_delay(delay).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _shake() -> void:
	var tween: Tween = create_tween()
	for i: int in 8:
		tween.tween_property(stage, "position", Vector2(_rng.randf_range(-12, 12), _rng.randf_range(-8, 8)), 0.05)
	tween.tween_property(stage, "position", Vector2.ZERO, 0.05)


## Animals run off screen in different directions. `instant` = already gone (later panels).
func _scatter_animals(instant: bool = false) -> void:
	var exits: Array[Vector2] = [Vector2(-200, 300), Vector2(1500, 260), Vector2(1500, 520), Vector2(-200, 560), Vector2(640, -220)]
	for i: int in animals.size():
		var animal: AnimatedSprite2D = animals[i]
		if animal.has_meta("gone"):
			continue
		animal.set_meta("gone", true)
		var exit: Vector2 = exits[i % exits.size()]
		var to_right: bool = exit.x > animal.position.x
		if animal.sprite_frames.has_animation("run_right"):
			animal.play("run_right" if to_right else "run_left")
		else:
			animal.flip_h = not to_right if animal.get_meta("faces_right", true) else to_right
			animal.play("walk")
		if instant:
			animal.position = exit
			continue
		create_tween().tween_property(animal, "position", exit, 1.4).set_delay(i * 0.15)


func _walk_in_henrito() -> void:
	henrito.visible = true
	henrito.play("walk_right")
	var tween: Tween = create_tween()
	tween.tween_property(henrito, "position:x", HENRITO_STOP_X, 1.0)
	tween.tween_callback(func() -> void: henrito.play("idle_down"))


## Frames for a cast member: "strip" sheets are side-on frames in a row; "grid" sheets are
## 4 directions (down, up, left, right) × 4 frames like the characters.
static func cast_frames(member: Dictionary) -> SpriteFrames:
	var sheet: Texture2D = load(str(member["sheet"]))
	if str(member.get("layout", "strip")) == "grid":
		var grid: SpriteFrames = SpriteFrames.new()
		grid.remove_animation("default")
		var columns: Dictionary = {"walk": 0, "run_left": 2, "run_right": 3}
		for anim: String in columns:
			grid.add_animation(anim)
			grid.set_animation_speed(anim, 6.0 if anim == "walk" else 10.0)
			for row: int in int(member.get("frames", 4)):
				var frame: AtlasTexture = AtlasTexture.new()
				frame.atlas = sheet
				frame.region = Rect2(int(columns[anim]) * TILE, row * TILE, TILE, TILE)
				grid.add_frame(anim, frame)
		return grid
	var strip: SpriteFrames = SpriteFrames.new()
	strip.rename_animation("default", "walk")
	strip.set_animation_speed("walk", 6.0)
	for i: int in int(member.get("frames", 2)):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(i * TILE, 0, TILE, TILE)
		strip.add_frame("walk", frame)
	return strip


func _build() -> void:
	stage = Control.new()
	stage.name = "Stage"
	stage.size = Vector2(1280, 720)
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(stage)
	var grass: TextureRect = TextureRect.new()
	var grass_tile: AtlasTexture = AtlasTexture.new()
	grass_tile.atlas = FLOOR_TEXTURE
	grass_tile.region = Rect2(GRASS_ATLAS * TILE, Vector2(TILE, TILE))
	grass.texture = grass_tile
	grass.stretch_mode = TextureRect.STRETCH_TILE
	grass.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	grass.position = Vector2(-48, -48)
	grass.size = Vector2((1280 + 96) / SCALE, (720 + 96) / SCALE)
	grass.scale = Vector2(SCALE, SCALE)
	grass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(grass)

	for row_y: float in [PEN_TOP_Y, PEN_BOTTOM_Y]:
		for i: int in FENCE_PIECES:
			var fence: TextureRect = TextureRect.new()
			var piece: AtlasTexture = AtlasTexture.new()
			piece.atlas = ELEMENT_TEXTURE
			piece.region = FENCE_REGION
			fence.texture = piece
			fence.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			fence.size = FENCE_REGION.size
			fence.scale = Vector2(SCALE, SCALE)
			fence.pivot_offset = Vector2(FENCE_REGION.size.x / 2.0, FENCE_REGION.size.y)
			# Controls scale around their pivot, so shift by pivot * (SCALE - 1) to put the
			# scaled fence's top-left corner exactly at the spot we want.
			var on_screen: Vector2 = Vector2(PEN_LEFT + i * FENCE_REGION.size.x * SCALE, row_y)
			fence.position = on_screen + fence.pivot_offset * (SCALE - 1.0)
			fence.mouse_filter = Control.MOUSE_FILTER_IGNORE
			stage.add_child(fence)
			fences.append(fence)

	var cast: Array = story.get("cast", [])
	for i: int in cast.size():
		var member: Dictionary = cast[i]
		var sprite: AnimatedSprite2D = AnimatedSprite2D.new()
		sprite.name = str(member["id"]).capitalize()
		sprite.sprite_frames = cast_frames(member)
		sprite.set_meta("faces_right", str(member.get("faces", "right")) == "right")
		sprite.scale = Vector2(SCALE, SCALE)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.offset = Vector2(0, -TILE / 2.0)
		sprite.position = Vector2(PEN_LEFT + 96 + i * (FENCE_PIECES * FENCE_REGION.size.x * SCALE - 192) / maxf(cast.size() - 1, 1), ANIMAL_ROW_Y)
		sprite.play("walk")
		sprite.speed_scale = 0.5
		stage.add_child(sprite)
		animals.append(sprite)

	henrito = AnimatedSprite2D.new()
	henrito.name = "Henrito"
	henrito.sprite_frames = Ranger.build_frames(load(str(sidekick.data.get("sprite", ""))))
	henrito.scale = Vector2(SCALE, SCALE)
	henrito.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	henrito.offset = Vector2(0, -TILE / 2.0)
	henrito.position = Vector2(-80, HENRITO_Y)
	henrito.visible = false
	stage.add_child(henrito)

	night = _full_rect(Color(NIGHT_COLOR, 0.0))
	night.name = "Night"
	rain = CPUParticles2D.new()
	rain.name = "Rain"
	var drop: Image = Image.create(2, 12, false, Image.FORMAT_RGBA8)
	drop.fill(Color(0.75, 0.85, 1.0, 0.8))
	rain.texture = ImageTexture.create_from_image(drop)
	rain.amount = 260
	rain.lifetime = 0.9
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(760, 10)
	rain.position = Vector2(640, -20)
	rain.direction = Vector2(0.25, 1)
	rain.spread = 3.0
	rain.gravity = Vector2(0, 600)
	rain.initial_velocity_min = 700.0
	rain.initial_velocity_max = 900.0
	rain.emitting = false
	add_child(rain)
	flash = _full_rect(Color(FLASH_COLOR, 0.0))
	flash.name = "Flash"
	# The bolt goes on top of the flash so it stays bright.
	bolt = Line2D.new()
	bolt.width = 7.0
	bolt.default_color = BOLT_COLOR
	bolt.visible = false
	add_child(bolt)

	caption_panel = PanelContainer.new()
	caption_panel.name = "Caption"
	caption_panel.position = Vector2(40, 560)
	caption_panel.size = Vector2(1200 - BUTTON_SIZE.x - 30, 130)
	caption_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.12, 0.1, 0.82), Color(1, 1, 1, 0.6)))
	add_child(caption_panel)
	caption = Label.new()
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", CAPTION_FONT_SIZE)
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption_panel.add_child(caption)

	bubble = PanelContainer.new()
	bubble.name = "SidekickBubble"
	bubble.position = Vector2(40, 540)
	bubble.size = Vector2(1200 - BUTTON_SIZE.x - 30, 150)
	bubble.add_theme_stylebox_override("panel", _panel_style(Color(1, 1, 0.97), Color(0.3, 0.25, 0.15)))
	bubble.visible = false
	add_child(bubble)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	bubble.add_child(row)
	var face: TextureRect = TextureRect.new()
	face.texture = sidekick.faceset()
	face.custom_minimum_size = Vector2(120, 120)
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	row.add_child(face)
	bubble_label = Label.new()
	bubble_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bubble_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	bubble_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bubble_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bubble_label.add_theme_font_size_override("font_size", BUBBLE_FONT_SIZE)
	bubble_label.add_theme_color_override("font_color", Color(0.2, 0.18, 0.12))
	row.add_child(bubble_label)

	next_button = _button(NEXT_TEXT, Vector2(1280 - 40 - BUTTON_SIZE.x, 720 - 30 - BUTTON_SIZE.y), BUTTON_SIZE, 40)
	next_button.pressed.connect(advance, CONNECT_DEFERRED)
	skip_button = _button("Skip", Vector2(1280 - 24 - 140, 20), Vector2(140, 56), 26)
	skip_button.pressed.connect(finish, CONNECT_DEFERRED)

	music = AudioStreamPlayer.new()
	var song: AudioStream = MUSIC.duplicate()
	if song is AudioStreamOggVorbis:
		(song as AudioStreamOggVorbis).loop = true
	music.stream = song
	add_child(music)
	storm_sound = AudioStreamPlayer.new()
	storm_sound.stream = STORM_SOUND
	storm_sound.finished.connect(func() -> void:
		if state in ["storm", "fences_fall", "scatter"]:
			storm_sound.play())
	add_child(storm_sound)


func _full_rect(color: Color) -> ColorRect:
	var rect: ColorRect = ColorRect.new()
	rect.color = color
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rect)
	return rect


func _button(text: String, at: Vector2, min_size: Vector2, font_size: int) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = at
	button.custom_minimum_size = min_size
	button.add_theme_font_size_override("font_size", font_size)
	button.focus_mode = Control.FOCUS_NONE
	add_child(button)
	return button


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(3)
	style.set_corner_radius_all(18)
	style.set_content_margin_all(18)
	return style
