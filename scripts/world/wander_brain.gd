class_name WanderBrain
extends RefCounted
## Picks places for a critter to stroll to: random spots near home that it can stand on.

## Random spots tried before giving up and going home.
const MAX_TRIES: int = 20

var home: Vector2
var radius: float
var rng: RandomNumberGenerator


func _init(home_point: Vector2, wander_radius: float, random: RandomNumberGenerator) -> void:
	home = home_point
	radius = wander_radius
	rng = random


## A point within `radius` of home where `is_open.call(point)` is true; home if none found.
func pick_target(is_open: Callable) -> Vector2:
	for attempt: int in MAX_TRIES:
		var angle: float = rng.randf_range(0.0, TAU)
		var distance: float = radius * sqrt(rng.randf())
		var point: Vector2 = home + Vector2.from_angle(angle) * distance
		if is_open.call(point):
			return point
	return home
