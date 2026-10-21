class_name Ranger
extends CharacterBody2D
## The player: walks with arrow keys / WASD, or walks to where you click.
## Node origin is at the feet so y-sorting puts the ranger behind or in front of trees correctly.

const WALK_SPEED: float = 70.0
const ARRIVE_DISTANCE: float = 2.0
## Stop click-walking after this many physics frames without moving (blocked by a tree or water).
const STUCK_FRAMES: int = 12
const FRAME_SIZE: int = 16
const WALK_FPS: float = 8.0
const WALK_FRAME_COUNT: int = 4
## Sprite sheet columns, left to right.
const DIRECTIONS: Array[String] = ["down", "up", "left", "right"]
const DEFAULT_SHEET: Texture2D = preload("res://assets/sprites/ranger/sprite_sheet.png")
const CAMERA_ZOOM: float = 3.0

## Arrow keys and WASD for each movement action.
const MOVE_KEYS: Dictionary = {
	"move_up": [KEY_UP, KEY_W],
	"move_down": [KEY_DOWN, KEY_S],
	"move_left": [KEY_LEFT, KEY_A],
	"move_right": [KEY_RIGHT, KEY_D],
}

## Tests set this instead of pressing keys.
var input_override: Vector2 = Vector2.ZERO
var facing: String = "down"
var has_target: bool = false
var target: Vector2 = Vector2.ZERO

var sprite: AnimatedSprite2D
var camera: Camera2D
var _stuck_frames: int = 0


func _ready() -> void:
	ensure_input_actions()
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = build_frames(DEFAULT_SHEET)
	sprite.offset = Vector2(0, -FRAME_SIZE / 2.0)
	add_child(sprite)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(10, 6)
	shape.shape = rect
	shape.position = Vector2(0, -3)
	add_child(shape)
	camera = Camera2D.new()
	camera.name = "Camera"
	camera.zoom = Vector2(CAMERA_ZOOM, CAMERA_ZOOM)
	camera.position_smoothing_enabled = true
	add_child(camera)
	sprite.play("idle_down")


## Adds the move_* actions if the project doesn't define them yet.
static func ensure_input_actions() -> void:
	for action: String in MOVE_KEYS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for keycode: int in MOVE_KEYS[action]:
			var event: InputEventKey = InputEventKey.new()
			event.physical_keycode = keycode
			InputMap.action_add_event(action, event)


## Walk + idle animations for each direction from a Ninja Adventure character sheet.
static func build_frames(sheet: Texture2D) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.remove_animation("default")
	for column: int in DIRECTIONS.size():
		var direction: String = DIRECTIONS[column]
		var walk: String = "walk_" + direction
		var idle: String = "idle_" + direction
		frames.add_animation(walk)
		frames.set_animation_speed(walk, WALK_FPS)
		frames.add_animation(idle)
		for row: int in WALK_FRAME_COUNT:
			var frame: AtlasTexture = AtlasTexture.new()
			frame.atlas = sheet
			frame.region = Rect2(column * FRAME_SIZE, row * FRAME_SIZE, FRAME_SIZE, FRAME_SIZE)
			frames.add_frame(walk, frame)
			if row == 0:
				frames.add_frame(idle, frame)
	return frames


## Start walking toward a point (click-to-move).
func walk_to(point: Vector2) -> void:
	target = point
	has_target = true
	_stuck_frames = 0


func _unhandled_input(event: InputEvent) -> void:
	var click: InputEventMouseButton = event as InputEventMouseButton
	if click and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		walk_to(get_global_mouse_position())


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = _input_direction()
	if direction != Vector2.ZERO:
		has_target = false
	elif has_target:
		var to_target: Vector2 = target - global_position
		if to_target.length() <= ARRIVE_DISTANCE:
			has_target = false
		else:
			direction = to_target.normalized()
	velocity = direction * WALK_SPEED
	var before: Vector2 = global_position
	move_and_slide()
	if has_target:
		_stuck_frames = _stuck_frames + 1 if global_position.distance_to(before) < 0.1 else 0
		if _stuck_frames >= STUCK_FRAMES:
			has_target = false
	_animate(direction)


func _input_direction() -> Vector2:
	if input_override != Vector2.ZERO:
		return input_override.normalized()
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func _animate(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		sprite.play("idle_" + facing)
		return
	if absf(direction.x) > absf(direction.y):
		facing = "right" if direction.x > 0 else "left"
	else:
		facing = "down" if direction.y > 0 else "up"
	sprite.play("walk_" + facing)
