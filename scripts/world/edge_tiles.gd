class_name EdgeTiles
extends RefCounted
## Picks the right edge piece for blob-style ground (paths, ponds) from which
## of the 4 neighbors are the same kind.
##
## Ninja Adventure lays out every blob set the same way, relative to its top-left tile:
##   (0..2, 0..2) 3x3 block: corners, edges, center
##   column 3, rows 0..2: 1-wide vertical strip (top cap, middle, bottom cap)
##   row 3, columns 0..2: 1-wide horizontal strip (left cap, middle, right cap)
##   (3, 3): single round piece

const N: int = 1
const E: int = 2
const S: int = 4
const W: int = 8

## neighbor mask -> offset from the set's top-left tile.
const OFFSETS: Dictionary = {
	0: Vector2i(3, 3),
	N: Vector2i(3, 2),
	S: Vector2i(3, 0),
	E: Vector2i(0, 3),
	W: Vector2i(2, 3),
	N | S: Vector2i(3, 1),
	E | W: Vector2i(1, 3),
	S | E: Vector2i(0, 0),
	S | W: Vector2i(2, 0),
	N | E: Vector2i(0, 2),
	N | W: Vector2i(2, 2),
	N | E | S: Vector2i(0, 1),
	N | S | W: Vector2i(2, 1),
	E | S | W: Vector2i(1, 0),
	N | E | W: Vector2i(1, 2),
	N | E | S | W: Vector2i(1, 1),
}


## Bit mask of which neighbors match. `is_same` takes a Vector2i cell and returns bool.
static func neighbor_mask(is_same: Callable, cell: Vector2i) -> int:
	var mask: int = 0
	if is_same.call(cell + Vector2i.UP):
		mask |= N
	if is_same.call(cell + Vector2i.RIGHT):
		mask |= E
	if is_same.call(cell + Vector2i.DOWN):
		mask |= S
	if is_same.call(cell + Vector2i.LEFT):
		mask |= W
	return mask


static func atlas_coords(set_origin: Vector2i, mask: int) -> Vector2i:
	return set_origin + OFFSETS[mask]
