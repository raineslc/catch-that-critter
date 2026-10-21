class_name HintPicture
extends Control
## The sidekick's visual hint for a problem (PLAN.md 3.6): dots, a number line with hops,
## base-ten blocks, a clock with minute labels, coins with their values, or groups.

const DOT_RADIUS: float = 11.0
const DOT_STEP: float = 28.0
const DOT_A: Color = Color(0.9, 0.4, 0.2)
const DOT_B: Color = Color(0.25, 0.5, 0.9)
const CROSS: Color = Color(0.2, 0.2, 0.2)
const TEXT: Color = Color.WHITE
const LINE: Color = Color(1, 1, 1)
const MARK_A: Color = Color(1, 0.8, 0.2)
const MARK_B: Color = Color(0.4, 0.85, 1)
const HOP: Color = Color(1, 0.6, 0.3)
const LINE_MARGIN: float = 60.0
const MAX_LABELED_TICKS: int = 26
const BLOCK_UNIT: float = 6.0
const BLOCK_GAP: float = 6.0
const HUNDRED_COLOR: Color = Color(0.95, 0.75, 0.3)
const TEN_COLOR: Color = Color(0.4, 0.75, 0.95)
const ONE_COLOR: Color = Color(0.95, 0.5, 0.5)

var problem: MathProblem


## What the hint draws: "count_dots", "dots", "number_line", "blocks", "clock", "coins", "groups", or "".
static func kind_for(p: MathProblem) -> String:
	if p == null:
		return ""
	match p.hint:
		"dots":
			return "count_dots" if p.type == "count_objects" else "dots"
		"number_line":
			return "number_line"
		"base_ten_blocks":
			return "blocks"
		"clock":
			return "clock"
		"coins":
			return "coins"
		"groups":
			return "groups"
	return ""


## Number line plan for a problem: {lo, hi, step, marks: {value: Color}, hops: [[from, to]], question: value or null}.
static func number_line_plan(p: MathProblem) -> Dictionary:
	var d: Dictionary = p.data
	var plan: Dictionary = {"step": 1, "marks": {}, "hops": [], "question": null}
	match p.type:
		"next_number":
			var n: int = int(d["n"])
			plan.merge({"lo": maxi(0, n - 4), "hi": n + 4, "marks": {n: MARK_A}, "hops": [[n, n + 1]], "question": n + 1}, true)
		"compare_more":
			var a: int = int(d["a"])
			var b: int = int(d["b"])
			plan.merge({"lo": maxi(0, mini(a, b) - 1), "hi": maxi(a, b) + 1, "marks": {a: MARK_A, b: MARK_B}}, true)
		"add":
			var a: int = int(d["a"])
			var b: int = int(d["b"])
			var hops: Array = []
			for i: int in b:
				hops.append([a + i, a + i + 1])
			plan.merge({"lo": maxi(0, a - 2), "hi": a + b + 2, "marks": {a: MARK_A}, "hops": hops}, true)
		"subtract":
			var a: int = int(d["a"])
			var b: int = int(d["b"])
			var hops: Array = []
			for i: int in b:
				hops.append([a - i, a - i - 1])
			plan.merge({"lo": maxi(0, a - b - 2), "hi": a + 2, "marks": {a: MARK_A}, "hops": hops}, true)
		"missing_addend":
			var a: int = int(d["a"])
			var total: int = int(d["total"])
			plan.merge({"lo": maxi(0, a - 2), "hi": total + 2, "marks": {a: MARK_A, total: MARK_B}}, true)
		"skip_count":
			var sequence: Array = d["sequence"]
			var step: int = int(d["step"])
			var last: int = int(sequence[sequence.size() - 1])
			var hops: Array = []
			for i: int in sequence.size() - 1:
				hops.append([int(sequence[i]), int(sequence[i + 1])])
			hops.append([last, last + step])
			plan.merge({"lo": int(sequence[0]), "hi": last + 2 * step, "step": step, "hops": hops, "question": last + step}, true)
	return plan


func show_problem(p: MathProblem) -> void:
	problem = p
	queue_redraw()


func _draw() -> void:
	if problem == null:
		return
	var d: Dictionary = problem.data
	match kind_for(problem):
		"count_dots":
			_draw_counted_dots(int(d["count"]))
		"dots":
			_draw_dot_sum(int(d["a"]), int(d["b"]), str(d.get("op", "+")) == "-")
		"number_line":
			_draw_number_line(number_line_plan(problem))
		"blocks":
			_draw_blocks_for(problem)
		"clock":
			ProblemPicture.draw_clock(self, size / 2.0, int(d["hour"]), int(d["minute"]), true)
		"coins":
			ProblemPicture.draw_coins(self, size, d["coins"], true)
		"groups":
			_draw_groups_for(problem)


## Dots with their counting numbers inside, five to a row.
func _draw_counted_dots(count: int) -> void:
	var font: Font = ThemeDB.fallback_font
	var per_row: int = 5
	var rows: int = ceili(count / float(per_row))
	var origin: Vector2 = Vector2((size.x - (mini(count, per_row) - 1) * DOT_STEP * 1.4) / 2.0, (size.y - (rows - 1) * DOT_STEP * 1.4) / 2.0)
	for i: int in count:
		var spot: Vector2 = origin + Vector2(i % per_row, i / per_row) * DOT_STEP * 1.4
		draw_circle(spot, DOT_RADIUS * 1.2, DOT_A)
		ProblemPicture._draw_centered_text(self, font, spot, str(i + 1), 16, TEXT)


## Addition: a orange dots then b blue dots. Subtraction: a dots with the last b crossed out.
func _draw_dot_sum(a: int, b: int, take_away: bool) -> void:
	var total: int = a if take_away else a + b
	var width: float = (total - 1) * DOT_STEP + (0.0 if take_away else DOT_STEP)
	var x: float = (size.x - width) / 2.0
	var y: float = size.y / 2.0
	for i: int in total:
		var gap: float = DOT_STEP if not take_away and i >= a else 0.0
		var spot: Vector2 = Vector2(x + i * DOT_STEP + gap, y)
		var crossed: bool = take_away and i >= a - b
		draw_circle(spot, DOT_RADIUS, DOT_B if (not take_away and i >= a) else DOT_A)
		if crossed:
			draw_line(spot + Vector2(-DOT_RADIUS, -DOT_RADIUS), spot + Vector2(DOT_RADIUS, DOT_RADIUS), CROSS, 3.0)
			draw_line(spot + Vector2(-DOT_RADIUS, DOT_RADIUS), spot + Vector2(DOT_RADIUS, -DOT_RADIUS), CROSS, 3.0)


func _draw_number_line(plan: Dictionary) -> void:
	var font: Font = ThemeDB.fallback_font
	var lo: int = int(plan["lo"])
	var hi: int = int(plan["hi"])
	var step: int = int(plan["step"])
	var y: float = size.y * 0.62
	var left: float = LINE_MARGIN
	var right: float = size.x - LINE_MARGIN
	var to_x: Callable = func(v: float) -> float: return left + (v - lo) / maxf(hi - lo, 1) * (right - left)
	draw_line(Vector2(left - 20, y), Vector2(right + 20, y), LINE, 3.0)
	var ticks: int = (hi - lo) / step
	for i: int in ticks + 1:
		var value: int = lo + i * step
		var x: float = to_x.call(value)
		draw_line(Vector2(x, y - 8), Vector2(x, y + 8), LINE, 2.0)
		if ticks <= MAX_LABELED_TICKS:
			var label: String = "?" if plan["question"] != null and value == int(plan["question"]) else str(value)
			ProblemPicture._draw_centered_text(self, font, Vector2(x, y + 26), label, 18, TEXT)
	var marks: Dictionary = plan["marks"]
	for value: Variant in marks:
		draw_circle(Vector2(to_x.call(float(value)), y), 10.0, marks[value])
	for hop: Variant in plan["hops"]:
		var from_x: float = to_x.call(float(hop[0]))
		var end_x: float = to_x.call(float(hop[1]))
		var mid: Vector2 = Vector2((from_x + end_x) / 2.0, y)
		var radius: float = absf(end_x - from_x) / 2.0
		draw_arc(mid, radius, PI, TAU, 16, HOP, 3.0)
		draw_circle(Vector2(end_x, y - 2), 4.0, HOP)


func _draw_blocks_for(p: MathProblem) -> void:
	var d: Dictionary = p.data
	var numbers: Array[int] = []
	match p.type:
		"compare", "add", "subtract":
			numbers = [int(d["a"]), int(d["b"])]
		_:
			numbers = [int(d["n"])]
	var gap: float = 60.0
	var total: float = (numbers.size() - 1) * gap
	for n: int in numbers:
		total += blocks_width(n, BLOCK_UNIT)
	# Shrink the blocks if two big numbers wouldn't fit side by side.
	var unit: float = BLOCK_UNIT * minf(1.0, (size.x - 40.0) / total)
	total = (numbers.size() - 1) * gap
	for n: int in numbers:
		total += blocks_width(n, unit)
	var x: float = (size.x - total) / 2.0
	var font: Font = ThemeDB.fallback_font
	for n: int in numbers:
		var w: float = blocks_width(n, unit)
		_draw_blocks(n, Vector2(x, 8), unit)
		ProblemPicture._draw_centered_text(self, font, Vector2(x + w / 2.0, 8 + unit * 10 + 22), str(n), 20, TEXT)
		x += w + gap


static func blocks_width(n: int, unit: float) -> float:
	var hundreds: int = n / 100
	var tens: int = (n / 10) % 10
	var ones: int = n % 10
	var width: float = hundreds * (unit * 10 + BLOCK_GAP) + tens * (unit + BLOCK_GAP)
	if ones > 0:
		width += ceili(ones / 5.0) * (unit + 2) + BLOCK_GAP
	return maxf(width - BLOCK_GAP, unit)


## Hundreds as flats, tens as rods, ones as little cubes (stacked in columns of 5).
func _draw_blocks(n: int, top_left: Vector2, unit: float) -> void:
	var x: float = top_left.x
	for h: int in n / 100:
		draw_rect(Rect2(x, top_left.y, unit * 10, unit * 10), HUNDRED_COLOR)
		for k: int in range(1, 10):
			draw_line(Vector2(x + k * unit, top_left.y), Vector2(x + k * unit, top_left.y + unit * 10), CROSS, 1.0)
			draw_line(Vector2(x, top_left.y + k * unit), Vector2(x + unit * 10, top_left.y + k * unit), CROSS, 1.0)
		x += unit * 10 + BLOCK_GAP
	for t: int in (n / 10) % 10:
		draw_rect(Rect2(x, top_left.y, unit, unit * 10), TEN_COLOR)
		for k: int in range(1, 10):
			draw_line(Vector2(x, top_left.y + k * unit), Vector2(x + unit, top_left.y + k * unit), CROSS, 1.0)
		x += unit + BLOCK_GAP
	for o: int in n % 10:
		draw_rect(Rect2(x + (o / 5) * (unit + 2), top_left.y + (o % 5) * (unit + 2), unit, unit), ONE_COLOR)


func _draw_groups_for(p: MathProblem) -> void:
	var d: Dictionary = p.data
	match p.type:
		"equal_groups":
			ProblemPicture.draw_groups(self, size, int(d["groups"]), int(d["size"]))
		"multiply":
			ProblemPicture.draw_groups(self, size, maxi(int(d["a"]), 0), int(d["b"]))
		"divide":
			# The dividend's dots, shared into `divisor` groups.
			ProblemPicture.draw_groups(self, size, int(d["divisor"]), int(d["dividend"]) / int(d["divisor"]))
		"missing_factor":
			ProblemPicture.draw_groups(self, size, int(d["a"]), 0, true)
