class_name CareVisit
extends RefCounted
## One visit to care for an animal at the Rescue Center (PLAN.md 3.9), in three steps:
## FEED (spell the food's name; K: first letter or picture match) → NOTE (read a short care note,
## pick what helps) → FACT (the fact card; each visit adds one new fact until all are known).

enum Step { FEED, NOTE, FACT, DONE }

## Feeding modes (data/care.json "feeding" → "grades" → "modes").
const SPELL: String = "spell"
const FIRST_LETTER: String = "first_letter"
const PICTURE_MATCH: String = "picture_match"
const DEFAULT_PICTURE_CHOICES: int = 3

var animal_id: String = ""
var step: Step = Step.FEED
var food_id: String = ""
var food_word: String = ""
var feed_mode: String = SPELL
## SPELL and FIRST_LETTER modes.
var spelling: SpellingTask
## PICTURE_MATCH mode: the choices are food ids.
var picture_choice: CareChoice
## The care note {"text", "question", "good", "others"} and its question.
var note: Dictionary = {}
var note_choice: CareChoice
var facts: Array[String] = []
## Care visits finished before this one (decides the note and how many facts show).
var visits_before: int = 0
var hint_after: int = 2


static func make(catalog: CareCatalog, id: String, grade: String, visits_done: int, rng: RandomNumberGenerator) -> CareVisit:
	var visit: CareVisit = CareVisit.new()
	visit.animal_id = id
	visit.visits_before = visits_done
	visit.hint_after = catalog.hint_after_misses()
	visit.facts = catalog.facts_for(id)
	var foods: Array[String] = catalog.foods_for(id)
	if not foods.is_empty():
		visit.food_id = foods[rng.randi_range(0, foods.size() - 1)]
		visit.food_word = str(catalog.food(visit.food_id).get("word", visit.food_id))
	var rules: Dictionary = catalog.feeding_rules(grade)
	var modes: Array = rules.get("modes", [SPELL])
	visit.feed_mode = str(modes[rng.randi_range(0, modes.size() - 1)])
	match visit.feed_mode:
		PICTURE_MATCH:
			var others: Array[String] = []
			for other: String in catalog.food_ids():
				if other != visit.food_id:
					others.append(other)
			SpellingTask.shuffle(others, rng)
			var count: int = int(rules.get("choices", DEFAULT_PICTURE_CHOICES)) - 1
			visit.picture_choice = CareChoice.make(visit.food_word, visit.food_id, others.slice(0, count), rng)
		FIRST_LETTER:
			visit.spelling = SpellingTask.make(visit.food_word, 1, int(rules.get("choices", DEFAULT_PICTURE_CHOICES)) - 1, rng)
		_:
			visit.feed_mode = SPELL
			visit.spelling = SpellingTask.make(visit.food_word, 0, int(rules.get("extra_letters", 0)), rng)
	var notes: Array = catalog.notes_for(id)
	if not notes.is_empty():
		visit.note = notes[visits_done % notes.size()]
		visit.note_choice = CareChoice.make(str(visit.note["question"]), str(visit.note["good"]), visit.note.get("others", []), rng)
	if visit.food_id == "":
		visit.step = Step.NOTE if visit.note_choice != null else Step.FACT
	return visit


## Moves to the next step (skipping a missing care note). Returns the new step.
func advance() -> Step:
	match step:
		Step.FEED:
			step = Step.NOTE if note_choice != null else Step.FACT
		Step.NOTE:
			step = Step.FACT
		_:
			step = Step.DONE
	return step


func is_fed() -> bool:
	if spelling != null:
		return spelling.is_done()
	return picture_choice != null and picture_choice.solved


## The facts on the card after this visit (one more than last time, up to all of them).
func facts_to_show() -> Array[String]:
	return facts.slice(0, mini(visits_before + 1, facts.size()))


## Index of the fact this visit unlocks, or -1 if every fact was already known.
func new_fact_index() -> int:
	return visits_before if visits_before < facts.size() else -1
