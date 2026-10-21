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


func _ready() -> void:
	reset()


func reset() -> void:
	factory = ProblemFactory.new()
	engine = AdaptiveEngine.new(AdaptiveEngine.level_counts_from(factory))
	catalog = AnimalCatalog.new()
	rescued.clear()
	rng.randomize()


func record_rescue(animal_id: String) -> void:
	rescued.append(animal_id)
