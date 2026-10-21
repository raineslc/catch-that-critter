class_name HabitatMap
extends Node2D
## Builds a habitat from a text map: ground tiles (grass, paths, water), nature objects
## (trees, bushes, rocks, flowers), invisible walls at the edges, and the ranger at the spawn point.

const TILE: int = 16
const FLOOR_TEXTURE: Texture2D = preload("res://assets/tilesets/floor.png")
const WATER_TEXTURE: Texture2D = preload("res://assets/tilesets/water.png")
const NATURE_TEXTURE: Texture2D = preload("res://assets/tilesets/nature.png")
const RANGER_SCENE: PackedScene = preload("res://scenes/world/ranger.tscn")

const FLOOR_SOURCE: int = 0
const WATER_SOURCE: int = 1
## Plain grass and its decorated variants in floor.png (first one used most).
## This is the lighter yellow-green set: the only grass that matches the pond shore in water.png.
const GRASS_TILES: Array[Vector2i] = [Vector2i(0, 12), Vector2i(1, 12), Vector2i(2, 12), Vector2i(3, 12), Vector2i(2, 11), Vector2i(3, 11)]
const GRASS_VARIANT_CHANCE: float = 0.08
## Top-left of the grass-edged dirt path set in floor.png.
const PATH_SET: Vector2i = Vector2i(0, 7)
## Top-left of the grass-edged pond set in water.png. Ponds must be convex
## (no inside corners): this simple set has no inside-corner pieces.
const WATER_SET: Vector2i = Vector2i(0, 6)
const PHYSICS_LAYER: int = 0
## Collision box size (pixels) at the base of blocking objects, by object footprint width.
const SMALL_BLOCKER: Vector2 = Vector2(12, 8)
const TREE_BLOCKER: Vector2 = Vector2(16, 10)
const WALL_THICKNESS: float = 16.0

@export_file("*.txt") var map_path: String = "res://data/maps/meadow.txt"
## Same seed = same grass/flower variety every time the map loads.
@export var decoration_seed: int = 1

var map: MapData
var ground: TileMapLayer
var objects: Node2D
var ranger: Ranger


func _ready() -> void:
	build()


func build() -> void:
	map = MapData.load_map(map_path)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = decoration_seed
	ground = TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = _make_tile_set()
	add_child(ground)
	objects = Node2D.new()
	objects.name = "Objects"
	objects.y_sort_enabled = true
	add_child(objects)
	for y: int in map.height:
		for x: int in map.width:
			var cell: Vector2i = Vector2i(x, y)
			_place_ground(cell, rng)
			var def: Dictionary = map.object_at(cell)
			if not def.is_empty():
				objects.add_child(_make_object(def, cell, rng))
	_add_edge_walls()
	ranger = RANGER_SCENE.instantiate()
	ranger.position = map.cell_to_feet(map.spawn_cell())
	objects.add_child(ranger)
	var size: Vector2i = map.pixel_size()
	ranger.camera.limit_left = 0
	ranger.camera.limit_top = 0
	ranger.camera.limit_right = size.x
	ranger.camera.limit_bottom = size.y


func _place_ground(cell: Vector2i, rng: RandomNumberGenerator) -> void:
	match map.ground_at(cell):
		"path":
			var mask: int = EdgeTiles.neighbor_mask(func(c: Vector2i) -> bool: return map.ground_at(c) == "path", cell)
			ground.set_cell(cell, FLOOR_SOURCE, EdgeTiles.atlas_coords(PATH_SET, mask))
		"water":
			# Map edges count as water so ponds touching the edge don't draw a shore there.
			var mask: int = EdgeTiles.neighbor_mask(func(c: Vector2i) -> bool: return not map.in_bounds(c) or map.ground_at(c) == "water", cell)
			ground.set_cell(cell, WATER_SOURCE, EdgeTiles.atlas_coords(WATER_SET, mask))
		_:
			var grass: Vector2i = GRASS_TILES[0]
			if rng.randf() < GRASS_VARIANT_CHANCE:
				grass = GRASS_TILES[rng.randi_range(1, GRASS_TILES.size() - 1)]
			ground.set_cell(cell, FLOOR_SOURCE, grass)


func _make_tile_set() -> TileSet:
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	tile_set.add_physics_layer()
	var floor_source: TileSetAtlasSource = _atlas(FLOOR_TEXTURE)
	tile_set.add_source(floor_source, FLOOR_SOURCE)
	for coords: Vector2i in GRASS_TILES:
		floor_source.create_tile(coords)
	for offset: Vector2i in EdgeTiles.OFFSETS.values():
		floor_source.create_tile(PATH_SET + offset)
	var water_source: TileSetAtlasSource = _atlas(WATER_TEXTURE)
	tile_set.add_source(water_source, WATER_SOURCE)
	var half: float = TILE / 2.0
	var square: PackedVector2Array = [Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)]
	for offset: Vector2i in EdgeTiles.OFFSETS.values():
		var coords: Vector2i = WATER_SET + offset
		water_source.create_tile(coords)
		var data: TileData = water_source.get_tile_data(coords, 0)
		data.add_collision_polygon(PHYSICS_LAYER)
		data.set_collision_polygon_points(PHYSICS_LAYER, 0, square)
	return tile_set


func _atlas(texture: Texture2D) -> TileSetAtlasSource:
	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(TILE, TILE)
	return source


## A nature object whose origin is at the bottom-center of its cell (for y-sorting).
func _make_object(def: Dictionary, cell: Vector2i, rng: RandomNumberGenerator) -> Node2D:
	var size: Vector2i = Vector2i(int(def["size"][0]), int(def["size"][1]))
	var atlas: Vector2i = _pick_atlas(def["atlas"], rng)
	var node: Node2D
	if bool(def.get("blocks", false)):
		var body: StaticBody2D = StaticBody2D.new()
		var shape: CollisionShape2D = CollisionShape2D.new()
		var rect: RectangleShape2D = RectangleShape2D.new()
		rect.size = TREE_BLOCKER if size.x > 1 else SMALL_BLOCKER
		shape.shape = rect
		shape.position = Vector2(0, -rect.size.y / 2.0)
		body.add_child(shape)
		node = body
	else:
		node = Node2D.new()
	node.name = "%s_%d_%d" % [def.get("name", "object"), cell.x, cell.y]
	node.position = map.cell_to_feet(cell)
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = NATURE_TEXTURE
	sprite.region_enabled = true
	sprite.region_rect = Rect2(atlas * TILE, size * TILE)
	sprite.centered = false
	sprite.offset = Vector2(-size.x * TILE / 2.0, -size.y * TILE)
	node.add_child(sprite)
	return node


## "atlas" is one [x, y] pair or a list of pairs to pick from.
static func _pick_atlas(value: Variant, rng: RandomNumberGenerator) -> Vector2i:
	var choices: Array = value
	if not choices.is_empty() and choices[0] is Array:
		var pick: Array = choices[rng.randi_range(0, choices.size() - 1)]
		return Vector2i(int(pick[0]), int(pick[1]))
	return Vector2i(int(choices[0]), int(choices[1]))


func _add_edge_walls() -> void:
	var size: Vector2 = Vector2(map.pixel_size())
	var walls: StaticBody2D = StaticBody2D.new()
	walls.name = "EdgeWalls"
	var t: float = WALL_THICKNESS
	for rect: Rect2 in [Rect2(-t, -t, size.x + 2 * t, t), Rect2(-t, size.y, size.x + 2 * t, t), Rect2(-t, 0, t, size.y), Rect2(size.x, 0, t, size.y)]:
		var shape: CollisionShape2D = CollisionShape2D.new()
		var box: RectangleShape2D = RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.position = rect.get_center()
		walls.add_child(shape)
	add_child(walls)
