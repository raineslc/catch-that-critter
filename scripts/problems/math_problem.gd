class_name MathProblem
extends RefCounted
## One math question shown during a chase.

## Skill id from data/skills.json (e.g. "add_subtract"); set by ProblemFactory.
var skill_id: String = ""
## 1-based level within the skill; set by ProblemFactory.
var level: int = 0
## Problem type within the skill (e.g. "missing_addend").
var type: String = ""
## Text shown on screen, e.g. "7 + 5 = ?".
var prompt: String = ""
## Text read aloud by text-to-speech, e.g. "What is 7 plus 5?".
var spoken: String = ""
## The correct choice, exactly as it appears in `choices`.
var answer: String = ""
## Shuffled answer buttons; always contains `answer`.
var choices: Array[String] = []
## Common Core codes for the parent report; set by ProblemFactory.
var standards: Array[String] = []
## Which visual hint the sidekick shows (dots, number_line, clock, coins...); set by ProblemFactory.
var hint: String = ""
## Numbers behind the problem (operands, clock time, coins) for drawing visuals and hints.
var data: Dictionary = {}


static func create(problem_type: String, prompt_text: String, spoken_text: String, correct: String, answer_choices: Array[String], problem_data: Dictionary = {}) -> MathProblem:
	var problem: MathProblem = MathProblem.new()
	problem.type = problem_type
	problem.prompt = prompt_text
	problem.spoken = spoken_text
	problem.answer = correct
	problem.choices = answer_choices
	problem.data = problem_data
	return problem


func is_correct(choice: String) -> bool:
	return choice == answer
