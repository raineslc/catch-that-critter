class_name TimeMoneyGenerator
extends RefCounted
## Desert problems (grades 1–3, 1.MD.3 / 2.MD.7–8 / 3.MD.1): read a clock, count coins.

## Cents per coin (US coins).
const COIN_VALUES: Dictionary = {"penny": 1, "nickel": 5, "dime": 10, "quarter": 25}
const MINUTES_PER_HOUR: int = 60
const MINUTES_PER_HALF_DAY: int = 720
## Random coin piles tried before falling back to pennies only.
const MAX_COIN_TRIES: int = 100


static func generate(type: String, params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	match type:
		"clock":
			return _clock(params, choice_count, rng)
		"coins":
			return _coins(params, choice_count, rng)
	push_error("TimeMoneyGenerator: unknown problem type '%s'" % type)
	return null


## "h:mm" for a 12-hour clock, e.g. "3:05".
static func format_time(hour: int, minute: int) -> String:
	return "%d:%02d" % [hour, minute]


## The clock time `delta_minutes` away from hour:minute, wrapping around 12.
static func shift_time(hour: int, minute: int, delta_minutes: int) -> String:
	var total: int = posmod((hour % 12) * MINUTES_PER_HOUR + minute + delta_minutes, MINUTES_PER_HALF_DAY)
	var new_hour: int = total / MINUTES_PER_HOUR
	if new_hour == 0:
		new_hour = 12
	return format_time(new_hour, total % MINUTES_PER_HOUR)


## minute_step 60 = on the hour, 30 = half hour, 5 = five minutes, 1 = any minute.
static func _clock(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var step: int = int(params.get("minute_step", 60))
	var hour: int = rng.randi_range(1, 12)
	var minute: int = step * rng.randi_range(0, MINUTES_PER_HOUR / step - 1)
	var answer: String = format_time(hour, minute)
	var candidates: Array[String] = [
		shift_time(hour, minute, MINUTES_PER_HOUR),
		shift_time(hour, minute, -MINUTES_PER_HOUR),
		shift_time(hour, minute, 2 * MINUTES_PER_HOUR),
	]
	if step < MINUTES_PER_HOUR:
		candidates.append(shift_time(hour, minute, step))
		candidates.append(shift_time(hour, minute, -step))
	# Mixing up the hands: reading the minute hand as the hour.
	if minute > 0 and minute % 5 == 0:
		candidates.append(format_time(minute / 5, (hour * 5) % MINUTES_PER_HOUR))
	var choices: Array[String] = ChoiceBuilder.from_strings(answer, candidates, choice_count, rng)
	var text: String = "What time does the clock show?"
	return MathProblem.create("clock", text, text, answer, choices, {"hour": hour, "minute": minute})


static func _coins(params: Dictionary, choice_count: int, rng: RandomNumberGenerator) -> MathProblem:
	var types: Array = params.get("types", ["penny", "nickel", "dime"])
	var min_coins: int = int(params.get("min_coins", 2))
	var max_coins: int = int(params.get("max_coins", 5))
	var max_total: int = int(params.get("max_total", 50))
	var counts: Dictionary = {}
	var total: int = 0
	var coin_count: int = 0
	for attempt: int in MAX_COIN_TRIES:
		counts = {}
		total = 0
		coin_count = rng.randi_range(min_coins, max_coins)
		for i: int in coin_count:
			var coin: String = str(types[rng.randi_range(0, types.size() - 1)])
			counts[coin] = int(counts.get(coin, 0)) + 1
			total += int(COIN_VALUES[coin])
		if total <= max_total:
			break
	if total > max_total:
		coin_count = min_coins
		counts = {"penny": min_coins}
		total = min_coins
	# Likely mistakes: counting coins instead of cents, or slipping by one coin.
	var candidates: Array[int] = [coin_count, total + 1, total - 1, total + 5, total - 5, total + 10, total - 10]
	var values: Array[int] = ChoiceBuilder.numeric(total, choice_count, 1, max_total + 10, rng, 5, candidates)
	return MathProblem.create("coins", "How much money is this?", "How many cents is this?",
		"%d¢" % total, ChoiceBuilder.to_strings(values, "¢"), {"coins": counts, "total": total})
