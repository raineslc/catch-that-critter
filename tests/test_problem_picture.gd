extends GutTest


func _problem(type: String, data: Dictionary) -> MathProblem:
	return MathProblem.create(type, "", "", "1", ["1"] as Array[String], data)


func test_picture_kind_per_problem_type() -> void:
	assert_eq(ProblemPicture.kind_for(_problem("count_objects", {"count": 3})), "critters")
	assert_eq(ProblemPicture.kind_for(_problem("clock", {"hour": 3, "minute": 0})), "clock")
	assert_eq(ProblemPicture.kind_for(_problem("coins", {"coins": {}})), "coins")
	assert_eq(ProblemPicture.kind_for(_problem("equal_groups", {"groups": 2, "size": 5})), "groups")
	assert_eq(ProblemPicture.kind_for(_problem("add", {})), "")
	assert_eq(ProblemPicture.kind_for(null), "")


func test_clock_hands_point_the_right_way() -> void:
	var three: Vector2 = ProblemPicture.hand_angles(3, 0)
	assert_almost_eq(three.x, TAU / 4.0, 0.001, "hour hand on 3")
	assert_almost_eq(three.y, 0.0, 0.001, "minute hand on 12")
	var half_past_six: Vector2 = ProblemPicture.hand_angles(6, 30)
	assert_almost_eq(half_past_six.y, PI, 0.001, "minute hand on 6")
	assert_almost_eq(half_past_six.x, TAU * 6.5 / 12.0, 0.001, "hour hand halfway between 6 and 7")
	assert_almost_eq(ProblemPicture.hand_angles(12, 0).x, 0.0, 0.001)


func test_coins_are_listed_biggest_value_first() -> void:
	var rows: Array = ProblemPicture.coin_rows({"penny": 2, "quarter": 1, "dime": 3})
	assert_eq(rows, [["quarter", 1], ["dime", 3], ["penny", 2]])


func test_every_coin_type_can_be_drawn() -> void:
	for coin: String in TimeMoneyGenerator.COIN_VALUES:
		assert_true(ProblemPicture.COINS.has(coin), coin)
