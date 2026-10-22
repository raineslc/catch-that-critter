class_name CareChoice
extends RefCounted
## A question with one good answer among a few choices: care notes ("What will help?") and the
## Kindergarten picture match ("Find the fish"). Picking another choice is a gentle miss.

var prompt: String = ""
## Choices in the order shown.
var choices: Array[String] = []
var answer: String = ""
var misses: int = 0
var solved: bool = false


static func make(question: String, good: String, others: Array, rng: RandomNumberGenerator) -> CareChoice:
	var choice: CareChoice = CareChoice.new()
	choice.prompt = question
	choice.answer = good
	choice.choices.append(good)
	for other: Variant in others:
		choice.choices.append(str(other))
	SpellingTask.shuffle(choice.choices, rng)
	return choice


## Returns true for the good answer.
func pick(option: String) -> bool:
	if option == answer:
		solved = true
		return true
	misses += 1
	return false
