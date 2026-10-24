extends Node
## Autoload "GameState": shared state for this play session.
## One local profile now persists progress. Multiple profiles and parent settings remain Phase 5.
##
## Playtest mode: starting the game with `-- --playtest` (the desktop shortcut does this)
## loads data/playtest.json: a playtest-only math skill for every chase, critters that come
## back after being caught, and a local log of every answer (see PlaytestLog).

const PLAYTEST_PATH: String = "res://data/playtest.json"
const PLAYTEST_FLAG: String = "--playtest"
const SPEECH_POLL_SECONDS: float = 0.1
const READ_ALOUD_DEFAULT: bool = false
const WORLD_PATH: String = "res://data/maps/world.json"
const FULL_PLAYTEST_PATH: String = "res://data/playtest_2.json"
const PROFILE_PATH: String = "user://profiles/default.json"
const PLAYTEST_PROFILE_PATH: String = "user://profiles/playtest_2.json"

signal save_status_changed(message: String)

var persistence_enabled: bool = false
var profile_path: String = ""
var profile_id: String = "default"
var intro_seen: bool = false
var save_message: String = ""
var _save_blocked: bool = false

var factory: ProblemFactory
var engine: AdaptiveEngine
var catalog: AnimalCatalog
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Animal ids rescued this session, in order.
var rescued: Array[String] = []
## Every rescue: {"animal", "habitat", "map", "cell": [x, y]} (cell is where it was caught from).
var rescues: Array[Dictionary] = []
## habitat -> how many of its pen's fence repairs the player has already seen fixed.
var pen_repairs_shown: Dictionary = {}
## Reading/spelling grade for care tasks: "K", "1", "2", "3" (per profile in Phase 5).
var grade: String = CareCatalog.DEFAULT_GRADE
## animal id -> finished care visits (each one adds a fact to its card).
var care_visits: Dictionary = {}
var care_catalog: CareCatalog
## Set by travel_to(): the area being entered and the gate to appear at.
var arrival_map: String = ""
var arrival_gate: String = ""
## data/maps/world.json: which areas exist and their scenes.
var world: Dictionary = {}
## Read questions and Henrito's lines aloud with text-to-speech. Off since 2026-10-21:
## Chris found the Windows voices sounded weird and some lines off (see DECISIONS.md).
var read_aloud: bool = READ_ALOUD_DEFAULT
## "explore" (no timer) or "race" (timed chases). See ChaseState.
var mode: String = ChaseState.EXPLORE
## Parent setting: keep the game in Explore mode (Phase 5 parent area sets this).
var explore_locked: bool = false
## Which sidekick gives hints (per profile in Phase 5).
var sidekick_id: String = "henrito"
## Playtest settings (empty when not playtesting).
var playtest: Dictionary = {}
## Playtest answer log, or null.
var playtest_log: PlaytestLog
## Playtest freeze detector, or null (see FreezeWatch).
var freeze_watch: FreezeWatch
var _speech_poll_left: float = 0.0


func _ready() -> void:
	reset()
	# Script runners (GUT and utilities) must never load or write the player's profile.
	var args: PackedStringArray = OS.get_cmdline_args()
	if Engine.is_editor_hint() or args.has("-s") or args.has("--script"):
		return
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if user_args.has("--playtest-full"):
		enable_playtest(load_playtest_config(FULL_PLAYTEST_PATH))
		if not user_args.has("--no-save"):
			start_profile(PLAYTEST_PROFILE_PATH, "playtest-2")
	elif user_args.has(PLAYTEST_FLAG):
		enable_playtest()
	elif not user_args.has("--no-save"):
		start_profile(PROFILE_PATH)
	get_tree().auto_accept_quit = false
	add_child(SaveNotice.new())


## Speaks a waiting text-to-speech line once the voice is free (see Speech).
func _process(delta: float) -> void:
	_speech_poll_left -= delta
	if _speech_poll_left <= 0.0:
		_speech_poll_left = SPEECH_POLL_SECONDS
		Speech.poll()


func reset() -> void:
	persistence_enabled = false
	profile_path = ""
	profile_id = "default"
	intro_seen = false
	_save_blocked = false
	_set_save_message("")
	_stop_freeze_watch()
	if playtest_log != null:
		playtest_log.close()
	playtest_log = null
	playtest = {}
	factory = ProblemFactory.new()
	engine = AdaptiveEngine.new(AdaptiveEngine.level_counts_from(factory))
	catalog = AnimalCatalog.new()
	rescued.clear()
	rescues.clear()
	pen_repairs_shown.clear()
	grade = CareCatalog.DEFAULT_GRADE
	care_visits.clear()
	care_catalog = CareCatalog.new()
	arrival_map = ""
	arrival_gate = ""
	world = load_world()
	rng.randomize()
	mode = ChaseState.EXPLORE
	explore_locked = false
	sidekick_id = "henrito"
	read_aloud = READ_ALOUD_DEFAULT


## Turns on playtest mode. `log_dir` "" = the default user://playtest folder.
func enable_playtest(config: Dictionary = {}, log_dir: String = "") -> void:
	playtest = config if not config.is_empty() else load_playtest_config()
	if playtest.has("skill"):
		factory.add_skill(playtest["skill"])
		engine = AdaptiveEngine.new(AdaptiveEngine.level_counts_from(factory))
		engine.set_level(playtest_skill(), int(playtest.get("starting_level", 1)))
	if bool(playtest.get("log", false)):
		playtest_log = PlaytestLog.new()
		if playtest_log.open(log_dir if log_dir != "" else PlaytestLog.DIR):
			log_event("session_start", {"skill": playtest_skill(), "date": Time.get_datetime_string_from_system(),
				"version": str(playtest.get("version", "")), "tts": Speech.is_available()})
			print("Playtest log: ", playtest_log.global_path())
			freeze_watch = FreezeWatch.new()
			freeze_watch.name = "FreezeWatch"
			add_child(freeze_watch)
			freeze_watch.start(playtest_log, int(playtest.get("freeze_after_ms", FreezeWatch.DEFAULT_STALL_MS)))
		else:
			playtest_log = null


static func load_playtest_config(path: String = PLAYTEST_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func is_playtest() -> bool:
	return not playtest.is_empty()


## The playtest's math skill id, or "".
func playtest_skill() -> String:
	return str(playtest.get("skill", {}).get("id", ""))


## Which skill a chase after this animal uses (the playtest skill overrides the animal's own).
func chase_skill_for(animal: Dictionary) -> String:
	var override: String = playtest_skill()
	return override if override != "" else str(animal.get("skill", ""))


## Seconds until a caught critter comes back (0 = never; only in playtests for now).
func respawn_seconds() -> float:
	return float(playtest.get("respawn_seconds", 0.0))


## Adds a line to the playtest log (does nothing when not logging).
func log_event(event: String, data: Dictionary = {}) -> void:
	if playtest_log != null:
		playtest_log.write(event, data)
	breadcrumb(event)


## A note for the freeze detector about what the game is doing right now (no-op when off).
func breadcrumb(step: String) -> void:
	if freeze_watch != null:
		freeze_watch.mark(step)


func _stop_freeze_watch() -> void:
	if freeze_watch != null:
		freeze_watch.stop()
		freeze_watch.queue_free()
		freeze_watch = null


## The mode chases actually use (Explore whenever a parent has locked it).
func chase_mode() -> String:
	return ChaseState.EXPLORE if explore_locked else mode


func toggle_mode() -> void:
	if not explore_locked:
		mode = ChaseState.RACE if mode == ChaseState.EXPLORE else ChaseState.EXPLORE
		log_event("mode", {"mode": mode})
		save_progress()


## Remembers a rescue. `habitat`/`map_id`/`cell` say where it came from (so it stays rescued
## when you come back, and its habitat's pen gets a fence repair).
func record_rescue(animal_id: String, habitat: String = "", map_id: String = "", cell: Vector2i = Vector2i(-1, -1)) -> void:
	rescued.append(animal_id)
	rescues.append({"animal": animal_id, "habitat": habitat, "map": map_id, "cell": [cell.x, cell.y]})
	save_progress()


func rescued_count(habitat: String = "") -> int:
	if habitat == "":
		return rescues.size()
	return rescues.filter(func(r: Dictionary) -> bool: return r["habitat"] == habitat).size()


## Animal ids rescued from a habitat, oldest first.
func rescued_from(habitat: String) -> Array[String]:
	var ids: Array[String] = []
	for r: Dictionary in rescues:
		if r["habitat"] == habitat:
			ids.append(str(r["animal"]))
	return ids


func care_visits_for(animal_id: String) -> int:
	return int(care_visits.get(animal_id, 0))


## A care visit was finished (fed, care note done, fact card seen).
func record_care(animal_id: String) -> void:
	care_visits[animal_id] = care_visits_for(animal_id) + 1
	log_event("care", {"animal": animal_id, "visits": care_visits[animal_id]})
	save_progress()


## Was the critter that starts at this spot already rescued?
func is_spot_rescued(map_id: String, cell: Vector2i) -> bool:
	for r: Dictionary in rescues:
		if r["map"] == map_id and int(r["cell"][0]) == cell.x and int(r["cell"][1]) == cell.y:
			return true
	return false


static func load_world(path: String = WORLD_PATH) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


## The scene file for an area id, or "" if that area isn't built yet.
func scene_for(map_id: String) -> String:
	return str(world.get("maps", {}).get(map_id, {}).get("scene", ""))


## Get ready to enter `map_id` through `gate`. Returns the scene to change to ("" = not built yet).
func travel_to(map_id: String, gate: String) -> String:
	var scene: String = scene_for(map_id)
	if scene == "":
		return ""
	arrival_map = map_id
	arrival_gate = gate
	log_event("travel", {"to": map_id, "gate": gate})
	save_progress()
	return scene


## If we just traveled into `map_id`, returns the gate to appear at (and forgets it); else "".
func take_arrival(map_id: String) -> String:
	if arrival_map != map_id:
		return ""
	var gate: String = arrival_gate
	arrival_map = ""
	arrival_gate = ""
	return gate


## Finish mastery exactly once on an orderly close, then persist before quitting.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if _save_blocked or finish_session():
			end_playtest_log()
			get_tree().quit()
	elif what == NOTIFICATION_PREDELETE:
		end_playtest_log()


## Explicit paths let tests exercise saves without ever touching the real profile.
func start_profile(path: String, id: String = "default") -> bool:
	profile_path = path
	profile_id = id
	persistence_enabled = true
	var result: Dictionary = ProfileStore.read_profile(path)
	if result.status in ["invalid", "newer"]:
		_save_blocked = true
		_set_save_message("Your saved game needs a grown-up's help. It has been kept safe.")
		return false
	if result.status in ["ok", "recovered"]:
		if result.data.profile_id != id:
			_save_blocked = true
			_set_save_message("This saved game belongs to another profile. It has been kept safe.")
			return false
		_restore(result.data)
		if result.status == "recovered":
			_set_save_message("Your backup saved game was recovered.")
	return true


func snapshot() -> Dictionary:
	return {
		"version": ProfileStore.VERSION, "profile_id": profile_id,
		"intro_seen": intro_seen, "rescues": rescues.duplicate(true),
		"care_visits": care_visits.duplicate(), "pen_repairs_shown": pen_repairs_shown.duplicate(),
		"progress": engine.to_dict(), "grade": grade, "sidekick_id": sidekick_id,
		"mode": mode, "explore_locked": explore_locked,
	}


func _restore(data: Dictionary) -> void:
	intro_seen = data.intro_seen
	rescues.clear()
	rescued.clear()
	for rescue: Dictionary in data.rescues:
		if catalog.has_animal(str(rescue.animal)):
			rescues.append(rescue.duplicate(true))
			rescued.append(str(rescue.animal))
	care_visits = data.care_visits.duplicate()
	pen_repairs_shown = data.pen_repairs_shown.duplicate()
	engine.load_dict(data.progress)
	grade = data.grade
	sidekick_id = data.sidekick_id
	mode = data.mode
	explore_locked = data.explore_locked


func save_progress() -> bool:
	if not persistence_enabled:
		return true
	if _save_blocked:
		return false
	var error: Error = ProfileStore.write_profile(profile_path, snapshot())
	_set_save_message("" if error == OK else "We couldn't save yet. Keep the game open and ask a grown-up to help.")
	return error == OK


func finish_session() -> bool:
	var pending: Dictionary = engine.to_dict()
	# end_session clears its answers, so repeated closes never count twice.
	engine.end_session()
	if save_progress():
		return true
	# A failed save leaves the session open, including any further answers.
	engine.load_dict(pending)
	return false


func finish_intro() -> void:
	intro_seen = true
	save_progress()


func can_start() -> bool:
	return not _save_blocked


func _set_save_message(message: String) -> void:
	save_message = message
	save_status_changed.emit(message)


func end_playtest_log() -> void:
	if playtest_log == null:
		return
	_stop_freeze_watch()
	var skill: String = playtest_skill()
	log_event("session_end", {"rescued": rescued.size(), "stats": engine.stats(skill) if skill != "" else {}})
	playtest_log.close()
	playtest_log = null
