extends Node
## Autoload "GameState": shared state for this play session.
## (Profiles and saving come in Phase 5; for now everything resets when the game closes.)

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


func _ready() -> void:
	reset()


func reset() -> void:
	factory = ProblemFactory.new()
	engine = AdaptiveEngine.new(AdaptiveEngine.level_counts_from(factory))
	catalog = AnimalCatalog.new()
	rescued.clear()
	rng.randomize()
	mode = ChaseState.EXPLORE
	explore_locked = false
	sidekick_id = "henrito"


## The mode chases actually use (Explore whenever a parent has locked it).
func chase_mode() -> String:
	return ChaseState.EXPLORE if explore_locked else mode


func toggle_mode() -> void:
	if not explore_locked:
		mode = ChaseState.RACE if mode == ChaseState.EXPLORE else ChaseState.EXPLORE


func record_rescue(animal_id: String) -> void:
	rescued.append(animal_id)
