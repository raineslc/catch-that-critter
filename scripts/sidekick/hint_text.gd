class_name HintText
extends RefCounted
## One calm sentence the sidekick says to help with a problem (PLAN.md 3.3, 3.6).
## Hints point to a strategy; they never just say the answer.


static func for_problem(p: MathProblem) -> String:
	var d: Dictionary = p.data
	match p.type:
		"count_objects":
			return "Let's touch each one and count together."
		"next_number":
			return "Find %d on the number line and hop one step forward." % int(d["n"])
		"compare_more":
			return "The number further along the number line is more."
		"add":
			if p.hint == "base_ten_blocks":
				return "Add the tens first, then add the ones."
			return "Start at %d and count up %d more." % [int(d["a"]), int(d["b"])]
		"subtract":
			if p.hint == "base_ten_blocks":
				return "Take away the tens first, then the ones."
			return "Start at %d and count back %d." % [int(d["a"]), int(d["b"])]
		"missing_addend":
			return "Start at %d and count up until you reach %d." % [int(d["a"]), int(d["total"])]
		"tens_ones":
			return "The long rods are tens and the little cubes are ones."
		"digit_value":
			return "Is the %d in the hundreds, tens, or ones place?" % int(d["digit"])
		"compare":
			return "Look at the biggest place first. The open side faces the bigger number."
		"skip_count":
			return "Each hop is %d. Hop one more time!" % int(d["step"])
		"clock":
			return "The short hand shows the hour. Count by fives for the long hand."
		"coins":
			return "Start with the biggest coin and count on."
		"equal_groups", "multiply":
			return "Count all the dots in all the groups."
		"divide":
			return "Share %d into %d equal groups. How many are in each?" % [int(d["dividend"]), int(d["divisor"])]
		"missing_factor":
			return "How many in each of %d groups makes %d?" % [int(d["a"]), int(d["product"])]
	return "Let's think about it together."
