class_name SpellingTask
extends RefCounted
## Spell a food's name with letter tiles (PLAN.md 3.9). The player taps tiles to fill the blanks
## from left to right; a tile with the next letter fills it, any other tile is a gentle miss and
## stays put. Only the first `to_place` letters are blanks (1 = "first letter" mode for K); the
## rest of the word is shown already filled in. Tiles can include extra letters to make it harder.

enum Result { RIGHT, DONE, MISS, IGNORED }

const ALPHABET: String = "abcdefghijklmnopqrstuvwxyz"
## Reshuffle this many times if the tiles come out already in order.
const SHUFFLE_TRIES: int = 5

var word: String = ""
## How many letters from the start the player places.
var to_place: int = 0
## Letters on the tiles, in the order shown.
var tiles: Array[String] = []
## Tile indexes already placed.
var used: Array[int] = []
## Letters placed so far.
var placed: int = 0
var misses: int = 0
## Misses since the last right letter (for when the sidekick helps).
var misses_here: int = 0


## `to_place` 0 = the whole word. `extra_letters` = decoy tiles with letters not in the word.
static func make(spell_word: String, place_count: int, extra_letters: int, rng: RandomNumberGenerator) -> SpellingTask:
	var task: SpellingTask = SpellingTask.new()
	task.word = spell_word.to_lower()
	task.to_place = task.word.length() if place_count <= 0 else mini(place_count, task.word.length())
	var letters: Array[String] = []
	for i: int in task.to_place:
		letters.append(task.word[i])
	for letter: String in decoys(task.word, extra_letters, rng):
		letters.append(letter)
	var in_order: Array[String] = letters.duplicate()
	for attempt: int in SHUFFLE_TRIES:
		shuffle(letters, rng)
		if letters != in_order or letters.size() < 2:
			break
	task.tiles = letters
	return task


## `count` different letters that aren't in `avoid`.
static func decoys(avoid: String, count: int, rng: RandomNumberGenerator) -> Array[String]:
	var pool: Array[String] = []
	for letter: String in ALPHABET:
		if not avoid.contains(letter):
			pool.append(letter)
	shuffle(pool, rng)
	return pool.slice(0, mini(count, pool.size()))


## Fisher–Yates with our own RNG (Array.shuffle() ignores seeds).
static func shuffle(items: Array, rng: RandomNumberGenerator) -> void:
	for i: int in range(items.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var swap: Variant = items[i]
		items[i] = items[j]
		items[j] = swap


## The player tapped tile `index`.
func press(index: int) -> Result:
	if is_done() or index < 0 or index >= tiles.size() or used.has(index):
		return Result.IGNORED
	if tiles[index] != next_letter():
		misses += 1
		misses_here += 1
		return Result.MISS
	used.append(index)
	placed += 1
	misses_here = 0
	return Result.DONE if is_done() else Result.RIGHT


func is_done() -> bool:
	return placed >= to_place


## The letter that goes in the next blank, or "" when done.
func next_letter() -> String:
	return "" if is_done() else word[placed]


## An unused tile with the next letter (for the hint glow), or -1.
func hint_tile() -> int:
	for i: int in tiles.size():
		if not used.has(i) and tiles[i] == next_letter():
			return i
	return -1


## What each letter box shows: the letter once placed (or given), "" for a blank.
func shown() -> Array[String]:
	var out: Array[String] = []
	for i: int in word.length():
		out.append(word[i] if i < placed or i >= to_place else "")
	return out
