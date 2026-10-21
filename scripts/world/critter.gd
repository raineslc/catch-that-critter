class_name Critter
extends CharacterBody2D
## A runaway animal in its habitat. It strolls around near home; when the ranger
## gets close it startles ("!"), emits `startled` (which starts a chase), then darts away
## and won't startle again until its cooldown ends.
## Node origin is at the feet for y-sorting. Tuning comes from data/animals.json.

signal startled(critter: Critter)

enum State { IDLE, WANDER, STARTLED, FLEE }

const STARTLED_EMOTE: Texture2D = preload("res://assets/ui/emotes/startled.png")
const EMOTE_HEIGHT: float = 26.0
const ARRIVE_DISTANCE: float = 2.0
const STUCK_FRAMES: int = 10

## Animal data from AnimalCatalog (id, name, sprite, speeds...).
var animal: Dictionary = {}
var state: State = State.IDLE
## Who to watch for. Set by the habitat.
var ranger: Node2D
## Seconds left in the current idle / startle / flee.
var time_left: float = 0.0
var cooldown_left: float = 0.0
var target: Vector2 = Vector2.ZERO

var brain: WanderBrain
var sprite: AnimatedSprite2D
var emote: Sprite2D
var _is_open: Callable
var _rng: RandomNumberGenerator
var _stuck_frames: int = 0


## Call before adding to the tree. `is_open(point)` says whether a spot is walkable.
func setup(animal_data: Dictionary, home: Vector2, is_open: Callable, rng: RandomNumberGenerator) -> void:
	animal = animal_data
	position = home
	_is_open = is_open
	_rng = rng
	brain = WanderBrain.new(home, float(animal["wander_radius_tiles"]) * 16.0, rng)
	name = "%s_%d_%d" % [animal["id"], int(home.x), int(home.y)]


func _ready() -> void:
	collision_layer = PhysicsLayers.CRITTERS
	collision_mask = PhysicsLayers.WORLD
	motion_mode = MOTION_MODE_FLOATING
	var shape: CollisionShape2D = CollisionShape2D.new()
	var rect: RectangleShape2D = RectangleShape2D.new()
	rect.size = Vector2(10, 6)
	shape.shape = rect
	shape.position = Vector2(0, -3)
	add_child(shape)
	sprite = AnimatedSprite2D.new()
	sprite.name = "Sprite"
	sprite.sprite_frames = build_frames(animal)
	var frame_size: Vector2 = _frame_size()
	sprite.offset = Vector2(0, -frame_size.y / 2.0)
	add_child(sprite)
	emote = Sprite2D.new()
	emote.name = "Emote"
	emote.texture = STARTLED_EMOTE
	emote.position = Vector2(0, -EMOTE_HEIGHT)
	emote.visible = false
	add_child(emote)
	_go_idle()


## "walk" animation from a horizontal strip of frames.
static func build_frames(animal_data: Dictionary) -> SpriteFrames:
	var frames: SpriteFrames = SpriteFrames.new()
	frames.rename_animation("default", "walk")
	frames.set_animation_speed("walk", float(animal_data["animation_fps"]))
	var sheet: Texture2D = load(str(animal_data["sprite"]))
	var size: Array = animal_data["frame_size"]
	for i: int in int(animal_data["frames"]):
		var frame: AtlasTexture = AtlasTexture.new()
		frame.atlas = sheet
		frame.region = Rect2(i * int(size[0]), 0, int(size[0]), int(size[1]))
		frames.add_frame("walk", frame)
	return frames


func can_startle() -> bool:
	return (state == State.IDLE or state == State.WANDER) and cooldown_left <= 0.0


func _physics_process(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if can_startle() and ranger != null and global_position.distance_to(ranger.global_position) <= float(animal["startle_radius"]):
		_startle()
		# A chase may have just frozen the world (and taken us out of physics): stop here.
		if not can_process():
			return
	match state:
		State.IDLE:
			time_left -= delta
			velocity = Vector2.ZERO
			if time_left <= 0.0:
				target = brain.pick_target(_is_open)
				_stuck_frames = 0
				state = State.WANDER
		State.WANDER:
			var to_target: Vector2 = target - global_position
			if to_target.length() <= ARRIVE_DISTANCE or _stuck_frames >= STUCK_FRAMES:
				_go_idle()
			else:
				velocity = to_target.normalized() * float(animal["wander_speed"])
		State.STARTLED:
			velocity = Vector2.ZERO
			time_left -= delta
			if time_left <= 0.0:
				emote.visible = false
				state = State.FLEE
				time_left = float(animal["flee_seconds"])
		State.FLEE:
			time_left -= delta
			var away: Vector2 = global_position - ranger.global_position if ranger != null else Vector2.RIGHT
			velocity = away.normalized() * float(animal["flee_speed"])
			if time_left <= 0.0:
				cooldown_left = float(animal["cooldown_seconds"])
				brain.home = global_position
				_go_idle()
	var before: Vector2 = global_position
	move_and_slide()
	_stuck_frames = _stuck_frames + 1 if state == State.WANDER and global_position.distance_to(before) < 0.05 else 0
	_animate()


func _startle() -> void:
	state = State.STARTLED
	time_left = float(animal["startle_seconds"])
	emote.visible = true
	if ranger != null:
		sprite.flip_h = _faces_right() != (ranger.global_position.x > global_position.x)
	startled.emit(self)


func _go_idle() -> void:
	state = State.IDLE
	var range_seconds: Array = animal["idle_seconds"]
	time_left = _rng.randf_range(float(range_seconds[0]), float(range_seconds[1]))
	velocity = Vector2.ZERO


func _animate() -> void:
	if velocity.length() > 0.1:
		sprite.flip_h = _faces_right() != (velocity.x >= 0.0)
		sprite.play("walk")
	else:
		sprite.stop()
		sprite.frame = 0


func _faces_right() -> bool:
	return str(animal.get("faces", "right")) == "right"


func _frame_size() -> Vector2:
	var size: Array = animal["frame_size"]
	return Vector2(float(size[0]), float(size[1]))
