extends GutTest

const SAMPLES: int = 300

var rng: RandomNumberGenerator
var time_pattern: RegEx


func before_each() -> void:
	rng = RandomNumberGenerator.new()
	rng.seed = 4
	time_pattern = RegEx.new()
	time_pattern.compile("^(1[0-2]|[1-9]):[0-5]\\d$")


func test_shift_time_wraps_around_twelve() -> void:
	assert_eq(TimeMoneyGenerator.shift_time(12, 0, 60), "1:00")
	assert_eq(TimeMoneyGenerator.shift_time(1, 0, -60), "12:00")
	assert_eq(TimeMoneyGenerator.shift_time(11, 55, 5), "12:00")
	assert_eq(TimeMoneyGenerator.shift_time(3, 0, -5), "2:55")


func test_clock_times_match_their_step() -> void:
	for step: int in [60, 30, 5, 1]:
		for i: int in SAMPLES:
			var p: MathProblem = TimeMoneyGenerator.generate("clock", {"minute_step": step}, 4, rng)
			var hour: int = p.data["hour"]
			var minute: int = p.data["minute"]
			assert_between(hour, 1, 12)
			assert_eq(minute % step, 0)
			assert_eq(p.answer, TimeMoneyGenerator.format_time(hour, minute))
			for choice: String in p.choices:
				assert_not_null(time_pattern.search(choice), "bad time choice " + choice)


func test_coins_total_is_correct_and_capped() -> void:
	var params: Dictionary = {"types": ["penny", "nickel", "dime", "quarter"], "min_coins": 2, "max_coins": 6, "max_total": 99}
	for i: int in SAMPLES:
		var p: MathProblem = TimeMoneyGenerator.generate("coins", params, 4, rng)
		var coins: Dictionary = p.data["coins"]
		var total: int = 0
		var count: int = 0
		for coin: Variant in coins:
			total += int(TimeMoneyGenerator.COIN_VALUES[coin]) * int(coins[coin])
			count += int(coins[coin])
		assert_eq(total, int(p.data["total"]))
		assert_lte(total, 99)
		assert_between(count, 2, 6)
		assert_eq(p.answer, "%d¢" % total)
		for choice: String in p.choices:
			assert_true(choice.ends_with("¢"), "money choice needs ¢: " + choice)


func test_coins_only_use_allowed_types() -> void:
	var params: Dictionary = {"types": ["penny", "nickel"], "min_coins": 2, "max_coins": 5, "max_total": 50}
	for i: int in SAMPLES:
		var p: MathProblem = TimeMoneyGenerator.generate("coins", params, 4, rng)
		for coin: Variant in p.data["coins"]:
			assert_has(["penny", "nickel"], coin)
