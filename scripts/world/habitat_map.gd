class_name HabitatMap
extends Node2D
## Builds an area from a text map: ground tiles (grass, paths, water), nature objects
## (trees, bushes, rocks, flowers), invisible walls at the edges, gates to other areas,
## critters (skipping ones already rescued), and the ranger at the spawn point
## (or at the gate they came in through).

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
const MODE_BUTTON_SIZE: Vector2 = Vector2(300, 64)
const MODE_BUTTON_FONT_SIZE: int = 28
## A critter won't reappear while the ranger is this close to its spot (pixels).
const RESPAWN_CLEARANCE: float = 80.0
const RESPAWN_RETRY_SECONDS: float = 3.0
## How close (pixels) the ranger must be to a rock to look under it.
const LOOK_DISTANCE: float = 24.0
const LOOK_BUTTON_SIZE: Vector2 = Vector2(420, 84)
const LOOK_TEXT: String = "Look under the rock"
const FOUND_SNAKE_TEXT: String = "Something wiggled!"
const EMPTY_ROCK_TEXT: String = "Just %s! Try another rock."
const SNAKE_CLUE_TEXT: String = "%s: I saw something wiggle to the %s!"
const SNAKE_CAUGHT_TEXT: String = "The %s is safe at the Rescue Center!"
const SNAKE_MOVED_TEXT: String = "It's hiding under another rock. Keep looking!"
## Little things under the empty rocks: [what the banner says, picture].
const ROCK_FINDS: Array = [["a worm", "res://assets/ui/food/worms.png"], ["some bugs", "res://assets/ui/food/bugs.png"],
	["a beetle", "res://assets/ui/food/bugs.png"]]
const FIND_SHOW_SECONDS: float = 1.2
const SNAKE_REVEAL_SECONDS: float = 0.8
const ELEMENT_TEXTURE: Texture2D = preload("res://assets/tilesets/element.png")
## Rail fence piece in element.png (3 tiles wide, 2 tall): closes locked gates, builds pens.
const FENCE_REGION: Rect2 = Rect2(11 * 16, 2 * 16, 48, 32)
const SIGN_FONT_SIZE: int = 10
const SIGN_TEXT: String = "To the %s"
const BANNER_SECONDS: float = 2.5
## Room at the top for the Explore/Race button, so banners sit below it.
const BANNER_TOP: float = 100.0
## The gate you arrive through works again once you are this far (pixels) from it, so holding
## the arrow key that brought you here doesn't walk you straight back out.
const GATE_REARM_DISTANCE: float = TILE * 3.0
const CAUGHT_TEXT: String = "The %s is safe at the Rescue Center!"
const STARS_EARNED_TEXT: String = " +%d stars"
const STARS_TEXT: String = "★ %d"
const STARS_FONT_SIZE: int = 36
const LOCKED_TEXT: String = "The %s opens soon!"
const SNAKE_LOCKED_TEXT: String = "Find the %s's hidden snake to open the %s!"
const SNAKE_LOCKED_SIGN: String = "\n(find the %s snake)"
const AREA_OPENED_TEXT: String = " The %s is open now!"

## A critter got startled: a chase is about to start.
signal chase_requested(critter: Critter)
## A chase ended (caught or not).
signal chase_ended(critter_id: String, caught: bool)
## The ranger walked through an open gate (tests turn off auto_travel and watch this).
signal gate_used(to_map: String, scene: String)

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
## Star count, top left.
var stars_label: Label
## Explore / Race switch (hidden when a parent locks Explore).
var mode_button: Button
var _rng: RandomNumberGenerator
var _chase_started_msec: int = 0
## Turn off in tests: the chase screen then opens only when open_chase() is called.
var auto_open_chase: bool = true
## Turn off in tests: walking through a gate then only emits gate_used.
var auto_travel: bool = true
## This area's id and habitat (from data/maps/<name>.json).
var map_id: String = ""
var habitat: String = ""
## gate char -> Area2D (open gates) or StaticBody2D (locked gates).
var gates: Dictionary = {}
var _traveling: bool = false
## The gate just arrived through (ignored until the ranger walks away from it), or "".
var arrived_gate: String = ""
var _banner_token: int = 0
## Rock cells in this habitat (where a snake can hide).
var rock_cells: Array[Vector2i] = []
## The habitat's hidden snake (animal data), or {} when there is none left to find.
var hidden_snake: Dictionary = {}
var snake_hunt: SnakeHunt
var snake_screen: SnakeScreen
var look_button: Button
## The rock the Look button is offering, or (-1, -1).
var look_target: Vector2i = Vector2i(-1, -1)
var _snake_popup: AnimatedSprite2D


func _ready() -> void:
	build()


func build() -> void:
	map = MapData.load_map(map_path)
	map_id = map.id()
	habitat = map.habitat()
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = decoration_seed
	ground = TileMapLayer.new()
	ground.name = "Ground"
	ground.tile_set = _make_tile_set()
	# Optional "ground_tint": [r, g, b] in the map's info file, e.g. sandy grass for the Desert.
	var tint: Array = map.meta.get("ground_tint", [1.0, 1.0, 1.0])
	ground.modulate = Color(float(tint[0]), float(tint[1]), float(tint[2]))
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
				if def.get("name", "") == "rock":
					rock_cells.append(cell)
	_add_edge_walls()
	ranger = RANGER_SCENE.instantiate()
	var arrive: String = GameState.take_arrival(map_id)
	var start_cell: Vector2i = map.arrival_cell(arrive) if arrive != "" and map.gate_cells().has(arrive) else map.spawn_cell()
	ranger.position = map.cell_to_feet(start_cell)
	if start_cell != map.spawn_cell():
		arrived_gate = arrive
	objects.add_child(ranger)
	var size: Vector2i = map.pixel_size()
	ranger.camera.limit_left = 0
	ranger.camera.limit_top = 0
	ranger.camera.limit_right = size.x
	ranger.camera.limit_bottom = size.y
	_spawn_critters(rng)
	_make_banner()
	_build_gates()
	_setup_snake()


func _spawn_critters(rng: RandomNumberGenerator) -> void:
	catalog = AnimalCatalog.new()
	_rng = rng
	# In playtests caught critters come back, so every spot is used again.
	var keep_rescued_away: bool = GameState.respawn_seconds() <= 0.0
	for y: int in map.height:
		for x: int in map.width:
			var cell: Vector2i = Vector2i(x, y)
			var id: String = map.critter_at(cell)
			if id == "" or (keep_rescued_away and GameState.is_spot_rescued(map_id, cell)):
				continue
			add_critter(id, map.cell_to_feet(cell), cell)


## Puts a critter in the habitat with its feet at `feet`. `cell` is its map spot (to remember
## the rescue); (-1, -1) for critters that aren't from a map spot. Returns null for unknown animals.
func add_critter(id: String, feet: Vector2, cell: Vector2i = Vector2i(-1, -1)) -> Critter:
	if not catalog.has_animal(id):
		push_error("HabitatMap: unknown animal '%s' in %s" % [id, map_path])
		return null
	var is_open: Callable = func(point: Vector2) -> bool: return map.is_walkable(map.pixel_to_cell(point))
	var critter: Critter = Critter.new()
	critter.setup(catalog.get_animal(id), feet, is_open, _rng)
	critter.set_meta("spawn_cell", cell)
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
	var misses: int = chase_screen.chase.misses if chase_screen.chase != null else 0
	chase_screen.queue_free()
	chase_screen = null
	chase_target = null
	GameState.log_event("chase_end", {"animal": id, "caught": caught,
		"seconds": snappedf((Time.get_ticks_msec() - _chase_started_msec) / 1000.0, 0.1)})
	if caught:
		GameState.record_rescue(id, habitat, map_id, critter.get_meta("spawn_cell", Vector2i(-1, -1)))
		var earned: int = GameState.rewards.catch_stars(misses)
		GameState.add_stars(earned, "catch")
		show_banner(CAUGHT_TEXT % critter.animal.get("name", "critter") + STARS_EARNED_TEXT % earned)
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
	banner.offset_top = BANNER_TOP
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	banner.add_theme_font_size_override("font_size", BANNER_FONT_SIZE)
	banner.add_theme_color_override("font_outline_color", Color(0.2, 0.3, 0.1))
	banner.add_theme_constant_override("outline_size", 10)
	banner.visible = false
	layer.add_child(banner)
	stars_label = Label.new()
	stars_label.name = "Stars"
	# Under the mode button, on a dark backing so it reads over any ground.
	stars_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	stars_label.offset_left = -MODE_BUTTON_SIZE.x - 16
	stars_label.offset_right = -16
	stars_label.offset_top = 16 + MODE_BUTTON_SIZE.y + 8
	stars_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var backing: StyleBoxFlat = StyleBoxFlat.new()
	backing.bg_color = Color(0.1, 0.08, 0.05, 0.6)
	backing.set_corner_radius_all(6)
	backing.set_content_margin_all(6)
	stars_label.add_theme_stylebox_override("normal", backing)
	stars_label.add_theme_font_size_override("font_size", STARS_FONT_SIZE)
	stars_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	stars_label.add_theme_color_override("font_outline_color", Color(0.25, 0.18, 0.08))
	stars_label.add_theme_constant_override("outline_size", 10)
	layer.add_child(stars_label)
	GameState.stars_changed.connect(_refresh_stars)
	_refresh_stars(GameState.stars)
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


func _refresh_stars(total: int) -> void:
	stars_label.text = STARS_TEXT % total


## Shows a message at the top for a few seconds.
func show_banner(text: String, seconds: float = BANNER_SECONDS) -> void:
	_banner_token += 1
	var token: int = _banner_token
	banner.text = text
	banner.visible = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if token == _banner_token and chase_target == null:
			banner.visible = false)


## Open gates become triggers; gates to areas that aren't built (or are marked locked) get a
## fence across them and a "coming soon" sign.
func _build_gates() -> void:
	var cells: Dictionary = map.gate_cells()
	for gate: String in cells:
		var cell: Vector2i = cells[gate]
		var info: Dictionary = map.gate_info(gate)
		var label: String = str(info.get("label", "?"))
		var feet: Vector2 = map.cell_to_feet(cell)
		var to: String = str(info.get("to", ""))
		var locked: bool = bool(info.get("locked", false)) or GameState.scene_for(to) == ""
		var snake_locked: bool = not locked and not GameState.is_area_open(to)
		var after: String = GameState.opens_after(to).capitalize()
		var locked_text: String = (SNAKE_LOCKED_TEXT % [after, label]) if snake_locked else (LOCKED_TEXT % label)
		var note: String = "\n(coming soon)" if locked else (SNAKE_LOCKED_SIGN % after if snake_locked else "")
		_add_sign(SIGN_TEXT % label + note, cell)
		locked = locked or snake_locked
		if locked:
			var body: StaticBody2D = StaticBody2D.new()
			body.name = "LockedGate_%s" % gate
			body.position = feet
			var shape: CollisionShape2D = CollisionShape2D.new()
			var box: RectangleShape2D = RectangleShape2D.new()
			box.size = Vector2(TILE, TILE)
			shape.shape = box
			shape.position = Vector2(0, -TILE / 2.0)
			body.add_child(shape)
			var fence: Sprite2D = Sprite2D.new()
			fence.texture = ELEMENT_TEXTURE
			fence.region_enabled = true
			fence.region_rect = FENCE_REGION
			fence.offset = Vector2(0, -FENCE_REGION.size.y / 2.0)
			if cell.x == 0 or cell.x == map.width - 1:
				fence.rotation_degrees = 90.0
				fence.offset = Vector2(-FENCE_REGION.size.y / 2.0 + TILE / 2.0, 0)
			body.add_child(fence)
			objects.add_child(body)
			gates[gate] = body
			_add_gate_area(gate, cell, func() -> void: show_banner(locked_text), TILE * 2.5)
		else:
			gates[gate] = _add_gate_area(gate, cell, use_gate.bind(gate), TILE * 0.6)


## An invisible area over a gate that calls `action` when the ranger walks into it.
func _add_gate_area(gate: String, cell: Vector2i, action: Callable, size: float) -> Area2D:
	var area: Area2D = Area2D.new()
	area.name = "GateArea_%s" % gate
	area.collision_layer = 0
	area.collision_mask = PhysicsLayers.RANGER
	area.position = map.cell_to_feet(cell) + Vector2(0, -TILE / 2.0)
	var shape: CollisionShape2D = CollisionShape2D.new()
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = Vector2(size, size)
	shape.shape = box
	area.add_child(shape)
	area.body_entered.connect(func(body: Node2D) -> void:
		if body == ranger:
			action.call())
	add_child(area)
	return area


func _physics_process(_delta: float) -> void:
	if arrived_gate != "" and ranger != null:
		var gate_feet: Vector2 = map.cell_to_feet(map.gate_cells()[arrived_gate])
		if ranger.global_position.distance_to(gate_feet) >= GATE_REARM_DISTANCE:
			arrived_gate = ""
	_update_look_button()


func _unhandled_input(event: InputEvent) -> void:
	if look_target.x >= 0 and event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		peek_rock(look_target)


## Hides this habitat's special snake under one of its rocks, until it has been caught.
func _setup_snake() -> void:
	for id: String in catalog.ids():
		var animal: Dictionary = catalog.get_animal(id)
		if bool(animal.get("hides_under_rocks", false)) and str(animal["habitat"]) == habitat and habitat != "":
			if not GameState.rescued.has(id) and not rock_cells.is_empty():
				hidden_snake = animal
				snake_hunt = SnakeHunt.new(rock_cells, _rng)
	look_button = Button.new()
	look_button.name = "LookButton"
	look_button.text = LOOK_TEXT
	look_button.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	look_button.offset_left = -LOOK_BUTTON_SIZE.x / 2.0
	look_button.offset_right = LOOK_BUTTON_SIZE.x / 2.0
	look_button.offset_top = -LOOK_BUTTON_SIZE.y - 30
	look_button.offset_bottom = -30
	look_button.add_theme_font_size_override("font_size", MODE_BUTTON_FONT_SIZE + 6)
	look_button.focus_mode = Control.FOCUS_NONE
	look_button.visible = false
	look_button.pressed.connect(func() -> void:
		if look_target.x >= 0:
			peek_rock(look_target), CONNECT_DEFERRED)
	get_node("Hud").add_child(look_button)


func _update_look_button() -> void:
	look_target = Vector2i(-1, -1)
	if snake_hunt != null and snake_screen == null and chase_target == null and ranger != null:
		for cell: Vector2i in rock_cells:
			if ranger.global_position.distance_to(map.cell_to_feet(cell)) <= LOOK_DISTANCE:
				look_target = cell
				break
	if look_button != null:
		look_button.visible = look_target.x >= 0


## Looks under the rock at `cell`: the snake, or a little find (and maybe a clue).
func peek_rock(cell: Vector2i) -> void:
	if snake_hunt == null or snake_screen != null or chase_target != null:
		return
	if snake_hunt.peek(cell) == SnakeHunt.Peek.FOUND:
		GameState.log_event("snake_found", {"animal": hidden_snake["id"], "empty_peeks": snake_hunt.peeked.size()})
		objects.process_mode = Node.PROCESS_MODE_DISABLED
		show_banner(FOUND_SNAKE_TEXT, SNAKE_REVEAL_SECONDS + 0.5)
		_snake_popup = AnimatedSprite2D.new()
		_snake_popup.sprite_frames = Critter.build_frames(hidden_snake)
		_snake_popup.position = map.cell_to_feet(cell) + Vector2(0, -TILE)
		_snake_popup.play("walk")
		add_child(_snake_popup)
		if auto_open_chase:
			get_tree().create_timer(SNAKE_REVEAL_SECONDS).timeout.connect(open_snake)
		else:
			open_snake()
		return
	var find: Array = ROCK_FINDS[_rng.randi_range(0, ROCK_FINDS.size() - 1)]
	_show_find(cell, load(str(find[1])))
	GameState.log_event("rock_empty", {"animal": hidden_snake["id"], "empty_peeks": snake_hunt.peeked.size()})
	if snake_hunt.wants_clue():
		var direction: String = snake_hunt.direction_from(map.pixel_to_cell(ranger.global_position))
		var helper: String = Sidekick.load_by_id(GameState.sidekick_id, GameState.rng).display_name()
		show_banner(SNAKE_CLUE_TEXT % [helper, direction])
	else:
		show_banner(EMPTY_ROCK_TEXT % find[0])


## A little picture pops up over the rock for a moment.
func _show_find(cell: Vector2i, texture: Texture2D) -> void:
	var sprite: Sprite2D = Sprite2D.new()
	sprite.texture = texture
	sprite.position = map.cell_to_feet(cell) + Vector2(0, -TILE * 1.5)
	sprite.z_index = 5
	add_child(sprite)
	var tween: Tween = sprite.create_tween()
	tween.tween_property(sprite, "position:y", sprite.position.y - TILE / 2.0, FIND_SHOW_SECONDS)
	tween.tween_callback(sprite.queue_free)


## The snake's story problem (one level harder than the player's current level).
func open_snake() -> void:
	if hidden_snake.is_empty() or snake_screen != null:
		return
	var skill: String = GameState.chase_skill_for(hidden_snake)
	var level: int = WordProblem.snake_level(GameState.engine.level(skill), GameState.factory.level_count(skill))
	var problem: MathProblem = WordProblem.new().make(GameState.factory, skill, level, str(hidden_snake["name"]), GameState.rng)
	if problem == null:
		# shortcut: only add/subtract kinds have stories; other skills fall back to plain add/subtract.
		skill = "add_subtract"
		level = WordProblem.snake_level(GameState.engine.level(skill), GameState.factory.level_count(skill))
		problem = WordProblem.new().make(GameState.factory, skill, level, str(hidden_snake["name"]), GameState.rng)
	banner.visible = false
	snake_screen = SnakeScreen.new()
	add_child(snake_screen)
	snake_screen.finished.connect(_on_snake_finished)
	snake_screen.start(hidden_snake, problem)


func _on_snake_finished(caught: bool) -> void:
	var id: String = str(hidden_snake["id"])
	snake_screen.queue_free()
	snake_screen = null
	if _snake_popup != null:
		_snake_popup.queue_free()
		_snake_popup = null
	objects.process_mode = Node.PROCESS_MODE_INHERIT
	if caught:
		GameState.record_rescue(id, habitat, map_id)
		var earned: int = GameState.rewards.stars_for("snake")
		GameState.add_stars(earned, "snake")
		var opened: String = GameState.area_opened_by(habitat)
		var opened_text: String = (AREA_OPENED_TEXT % opened.capitalize()) if opened != "" else ""
		show_banner(SNAKE_CAUGHT_TEXT % hidden_snake["name"] + STARS_EARNED_TEXT % earned + opened_text)
		hidden_snake = {}
		snake_hunt = null
	else:
		snake_hunt.move(_rng)
		show_banner(SNAKE_MOVED_TEXT)


## Walks through a gate to the area it leads to.
func use_gate(gate: String) -> void:
	if _traveling or chase_target != null or gate == arrived_gate:
		return
	var info: Dictionary = map.gate_info(gate)
	var scene: String = GameState.travel_to(str(info.get("to", "")), str(info.get("arrive", "")))
	if scene == "":
		show_banner(LOCKED_TEXT % str(info.get("label", "area")))
		return
	_traveling = true
	gate_used.emit(str(info.get("to", "")), scene)
	if auto_travel:
		get_tree().change_scene_to_file.call_deferred(scene)


## A small sign label next to a gate, in the world (moves with the map).
func _add_sign(text: String, cell: Vector2i) -> void:
	var label: Label = Label.new()
	label.name = "Sign_%d_%d" % [cell.x, cell.y]
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", SIGN_FONT_SIZE)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_color_override("font_outline_color", Color(0.25, 0.18, 0.08))
	label.add_theme_constant_override("outline_size", 4)
	label.size = Vector2(96, 28)
	var inward: Vector2i = map.arrival_cell(map.char_at(cell)) - cell
	var spot: Vector2 = map.cell_to_feet(cell + inward / 2) - Vector2(48, TILE * 2.4)
	if cell.y == map.height - 1:
		spot.y -= TILE
	# Keep signs fully on the map (the camera never shows past its edges).
	spot.x = clampf(spot.x, 2.0, map.pixel_size().x - label.size.x - 2.0)
	spot.y = clampf(spot.y, 2.0, map.pixel_size().y - label.size.y - 2.0)
	label.position = spot
	label.z_index = 10
	add_child(label)


func refresh_mode_button() -> void:
	mode_button.visible = not GameState.explore_locked
	mode_button.text = "Race mode (M)" if GameState.chase_mode() == ChaseState.RACE else "Explore mode (M)"


func _unhandled_key_input(event: InputEvent) -> void:
	if objects.process_mode != Node.PROCESS_MODE_DISABLED and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_M:
		get_viewport().set_input_as_handled()
		GameState.toggle_mode()
		refresh_mode_button()


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
