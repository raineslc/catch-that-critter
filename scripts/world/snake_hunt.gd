class_name SnakeHunt
extends RefCounted
## The rules for finding a habitat's hidden snake, with no visuals: one of the habitat's rocks
## hides it (a different one each visit). Peeking under the others finds little things instead;
## after a few empty rocks the sidekick gives a direction clue. If the word problem is missed,
## the snake slides under a different rock.

enum Peek { FOUND, EMPTY }

## Empty peeks (since the snake last moved) before the sidekick gives a clue.
const CLUE_AFTER_EMPTY: int = 3

## Rock cells in the habitat.
var rocks: Array[Vector2i] = []
## Index into `rocks` of the rock hiding the snake.
var hiding: int = 0
## Rocks already peeked under (and empty) since the snake last moved.
var peeked: Array[Vector2i] = []


func _init(rock_cells: Array[Vector2i], rng: RandomNumberGenerator) -> void:
	rocks = rock_cells
	hiding = rng.randi_range(0, rocks.size() - 1) if not rocks.is_empty() else -1


func hiding_cell() -> Vector2i:
	return rocks[hiding] if hiding >= 0 else Vector2i(-1, -1)


func peek(cell: Vector2i) -> Peek:
	if cell == hiding_cell():
		return Peek.FOUND
	if not peeked.has(cell):
		peeked.append(cell)
	return Peek.EMPTY


## Time for the sidekick's clue (shown once per CLUE_AFTER_EMPTY empty rocks).
func wants_clue() -> bool:
	return not peeked.is_empty() and peeked.size() % CLUE_AFTER_EMPTY == 0


## The missed snake slides under a different rock; peeking starts fresh.
func move(rng: RandomNumberGenerator) -> void:
	peeked.clear()
	if rocks.size() < 2:
		return
	var next: int = rng.randi_range(0, rocks.size() - 2)
	hiding = next if next < hiding else next + 1


## Which way the snake is from a cell: "up", "down", "left", or "right".
func direction_from(cell: Vector2i) -> String:
	var offset: Vector2i = hiding_cell() - cell
	if absi(offset.x) >= absi(offset.y):
		return "right" if offset.x > 0 else "left"
	return "down" if offset.y > 0 else "up"
