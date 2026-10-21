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
const BANNER_FONT_SIZE: int = 48
const MODE_BUTTON_SIZE: Vector2 = Vector2(220, 64)
const MODE_BUTTON_FONT_SIZE: int = 28
## A critter won't reappear while the ranger is this close to its spot (pixels).
const RESPAWN_CLEARANCE: float = 80.0
const RESPAWN_RETRY_SECONDS: float = 3.0

## A critter got startled: a chase is about to start.
signal chase_requested(critter: Critter)
## A chase ended (caught or not).
signal chase_ended(critter_id: String, caught: bool)

@export_file("*.txt") var map_path: String = "res://data/maps/meadow.txt"
## Same seed = same grass/flower variety every time the map loads.
@export var decoration_seed: int = 1

var map: MapData
var ground: TileMapLayer
var objects: Node2D
var ranger: Ranger
var catalog: AnimalCatalog
var critters: Array[Critter] = []
## The critter being chased, or null.
var chase_target: Critter
var chase_screen: ChaseScreen
var banner: Label
## Explore / Race switch (hidden when a parent locks Explore).
var mode_button: Button
var _rng: RandomNumberGenerator
var _chase_started_msec: int = 0
## Turn off in tests: the chase screen then opens only when open_chase() is called.
var auto_open_chase: bool = true


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
	_spawn_critters(rng)
	_make_banner()


func _spawn_critters(rng: RandomNumberGenerator) -> void:
	catalog = AnimalCatalog.new()
	_rng = rng
	for y: int in map.height:
		for x: int in map.width:
			var id: String = map.critter_at(Vector2i(x, y))
			if id != "":
				add_critter(id, map.cell_to_feet(Vector2i(x, y)))


## Puts a critter in the habitat with its feet at `feet`. Returns null for unknown animals.
func add_critter(id: String, feet: Vector2) -> Critter:
	if not catalog.has_animal(id):
		push_error("HabitatMap: unknown animal '%s' in %s" % [id, map_path])
		return null
	var is_open: Callable = func(point: Vector2) -> bool: return map.is_walkable(map.pixel_to_cell(point))
	var critter: Critter = Critter.new()
	critter.setup(catalog.get_animal(id), feet, is_open, _rng)
	critter.ranger = ranger
	critter.startled.connect(_on_critter_startled)
	objects.add_child(critter)
	critters.append(critter)
	return critter


## Brings a caught critter back after a while (playtests). Waits longer if the ranger is standing there.
func _schedule_respawn(id: String, feet: Vector2, seconds: float) -> void:
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if not is_inside_tree():
			return
		if ranger.global_position.distance_to(feet) < RESPAWN_CLEARANCE:
			_schedule_respawn(id, feet, RESPAWN_RETRY_SECONDS)
			return
		GameState.breadcrumb("map: %s comes back (chase on: %s)" % [id, chase_target != null])
		var back: Critter = add_critter(id, feet)
		GameState.log_event("respawn", {"animal": id, "during_chase": chase_target != null,
			"spot": [int(feet.x), int(feet.y)], "ok": back != null}))


func _on_critter_startled(critter: Critter) -> void:
	if chase_target != null:
		return
	GameState.breadcrumb("map: startled %s" % critter.name)
	chase_target = critter
	# Freeze the world (ranger and critters) while the chase is on.
	objects.process_mode = Node.PROCESS_MODE_DISABLED
	banner.text = "Chase the %s!" % critter.animal.get("name", "critter")
	banner.visible = true
	chase_requested.emit(critter)
	if auto_open_chase:
		get_tree().create_timer(float(ChaseState.load_config().get("start_delay", 0.8))).timeout.connect(open_chase)


## Shows the chase screen for the current chase target.
func open_chase() -> void:
	if chase_target == null or chase_screen != null:
		return
	banner.visible = false
	chase_screen = ChaseScreen.new()
	chase_screen.auto_advance = auto_open_chase
	add_child(chase_screen)
	chase_screen.finished.connect(_on_chase_finished)
	var skill: String = GameState.chase_skill_for(chase_target.animal)
	_chase_started_msec = Time.get_ticks_msec()
	GameState.log_event("chase_start", {"animal": chase_target.animal["id"], "mode": GameState.chase_mode(),
		"skill": skill, "level": GameState.engine.level(skill)})
	chase_screen.start(chase_target.animal, skill)


func _on_chase_finished(caught: bool) -> void:
	var critter: Critter = chase_target
	var id: String = str(critter.animal["id"])
	chase_screen.queue_free()
	chase_screen = null
	chase_target = null
	GameState.log_event("chase_end", {"animal": id, "caught": caught,
		"seconds": snappedf((Time.get_ticks_msec() - _chase_started_msec) / 1000.0, 0.1)})
	if caught:
		GameState.record_rescue(id)
		critters.erase(critter)
		if GameState.respawn_seconds() > 0.0:
			_schedule_respawn(id, critter.spawn_point, GameState.respawn_seconds())
		critter.queue_free()
	else:
		critter.emote.visible = false
		critter.state = Critter.State.IDLE
		critter.cooldown_left = float(critter.animal["cooldown_seconds"])
	objects.process_mode = Node.PROCESS_MODE_INHERIT
	chase_ended.emit(id, caught)


func _make_banner() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.name = "Hud"
	add_child(layer)
	banner = Label.new()
	banner.name = "Banner"
	banner.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	banner.offset_top = 40
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", BANNER_FONT_SIZE)
	banner.add_theme_color_override("font_outline_color", Color(0.2, 0.3, 0.1))
	banner.add_theme_constant_override("outline_size", 10)
	banner.visible = false
	layer.add_child(banner)
	mode_button = Button.new()
	mode_button.name = "ModeButton"
	mode_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	mode_button.offset_left = -MODE_BUTTON_SIZE.x - 16
	mode_button.offset_top = 16
	mode_button.offset_right = -16
	mode_button.offset_bottom = 16 + MODE_BUTTON_SIZE.y
	mode_button.add_theme_font_size_override("font_size", MODE_BUTTON_FONT_SIZE)
	mode_button.focus_mode = Control.FOCUS_NONE
	mode_button.pressed.connect(func() -> void:
		GameState.toggle_mode()
		refresh_mode_button())
	layer.add_child(mode_button)
	refresh_mode_button()


func refresh_mode_button() -> void:
	mode_button.visible = not GameState.explore_locked
	mode_button.text = "Race mode" if GameState.chase_mode() == ChaseState.RACE else "Explore mode"


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
