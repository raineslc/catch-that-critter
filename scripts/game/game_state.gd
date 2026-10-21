extends Node
## Autoload "GameState": shared state for this play session.
## (Profiles and saving come in Phase 5; for now everything resets when the game closes.)
##
## Playtest mode: starting the game with `-- --playtest` (the desktop shortcut does this)
## loads data/playtest.json: a playtest-only math skill for every chase, critters that come
## back after being caught, and a local log of every answer (see PlaytestLog).

const PLAYTEST_PATH: String = "res://data/playtest.json"
const PLAYTEST_FLAG: String = "--playtest"

var factory: ProblemFactory
var engine: AdaptiveEngine
var catalog: AnimalCatalog
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Animal ids rescued this session, in order.
var rescued: Array[String] = []
## Read each chase question aloud with text-to-speech.
var read_aloud: bool = true
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


func _ready() -> void:
	reset()
	if OS.get_cmdline_user_args().has(PLAYTEST_FLAG):
		enable_playtest()


func reset() -> void:
	if playtest_log != null:
		playtest_log.close()
	playtest_log = null
	playtest = {}
	factory = ProblemFactory.new()
	engine = AdaptiveEngine.new(AdaptiveEngine.level_counts_from(factory))
	catalog = AnimalCatalog.new()
	rescued.clear()
	rng.randomize()
	mode = ChaseState.EXPLORE
	explore_locked = false
	sidekick_id = "henrito"


## Turns on playtest mode. `log_dir` "" = the default user://playtest folder.
func enable_playtest(config: Dictionary = {}, log_dir: String = "") -> void:
	playtest = config if not config.is_empty() else load_playtest_config()
	if playtest.has("skill"):
		factory.add_skill(playtest["skill"])
		engine = AdaptiveEngine.new(AdaptiveEngine.level_counts_from(factory))
	if bool(playtest.get("log", false)):
		playtest_log = PlaytestLog.new()
		if playtest_log.open(log_dir if log_dir != "" else PlaytestLog.DIR):
			log_event("session_start", {"skill": playtest_skill(), "date": Time.get_datetime_string_from_system()})
			print("Playtest log: ", playtest_log.global_path())
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


## The mode chases actually use (Explore whenever a parent has locked it).
func chase_mode() -> String:
	return ChaseState.EXPLORE if explore_locked else mode


func toggle_mode() -> void:
	if not explore_locked:
		mode = ChaseState.RACE if mode == ChaseState.EXPLORE else ChaseState.EXPLORE
		log_event("mode", {"mode": mode})


func record_rescue(animal_id: String) -> void:
	rescued.append(animal_id)


## Writes a summary to the playtest log when the window closes.
func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		end_playtest_log()


func end_playtest_log() -> void:
	if playtest_log == null:
		return
	var skill: String = playtest_skill()
	log_event("session_end", {"rescued": rescued.size(), "stats": engine.stats(skill) if skill != "" else {}})
	playtest_log.close()
	playtest_log = null
