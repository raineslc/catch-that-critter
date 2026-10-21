class_name ProblemPicture
extends Control
## Draws the picture a problem needs: critters to count, an analog clock, coins, or equal groups.
## Problems without a picture draw nothing.

const ICON_SIZE: float = 48.0
const ICONS_PER_ROW: int = 5
const ICON_GAP: float = 8.0
const ROW_GAP_EVERY: int = 5

const CLOCK_RADIUS: float = 62.0
const CLOCK_FACE: Color = Color(1, 0.98, 0.92)
const CLOCK_RIM: Color = Color(0.35, 0.25, 0.15)
const HOUR_HAND: Color = Color(0.2, 0.2, 0.25)
const MINUTE_HAND: Color = Color(0.85, 0.3, 0.2)
const MINUTE_LABEL: Color = Color(0.2, 0.45, 0.85)

## Coin drawing size (px per mm of real diameter) and colors.
const COIN_PX_PER_MM: float = 2.6
const COIN_GAP: float = 14.0
const COINS: Dictionary = {
	"quarter": {"mm": 24.3, "color": Color(0.78, 0.8, 0.82)},
	"nickel": {"mm": 21.2, "color": Color(0.72, 0.74, 0.76)},
	"penny": {"mm": 19.0, "color": Color(0.78, 0.47, 0.25)},
	"dime": {"mm": 17.9, "color": Color(0.82, 0.84, 0.86)},
}
const COIN_ORDER: Array[String] = ["quarter", "dime", "nickel", "penny"]

const DOT_RADIUS: float = 9.0
const GROUP_PAD: float = 10.0
const GROUP_GAP: float = 18.0
const DOT_COLOR: Color = Color(0.85, 0.35, 0.2)
const GROUP_COLOR: Color = Color(1, 1, 1, 0.85)
const OUTLINE: Color = Color(0.2, 0.2, 0.2)

var problem: MathProblem
## Picture used for counting problems (the chased animal's face).
var count_icon: Texture2D


## Which kind of picture a problem gets: "critters", "clock", "coins", "groups", or "".
static func kind_for(p: MathProblem) -> String:
	if p == null:
		return ""
	match p.type:
		"count_objects":
			return "critters"
		"clock":
			return "clock"
		"coins":
			return "coins"
		"equal_groups":
			return "groups"
	return ""


## Clock hand angles in radians, clockwise from 12 o'clock: Vector2(hour hand, minute hand).
static func hand_angles(hour: int, minute: int) -> Vector2:
	var minute_angle: float = minute / 60.0 * TAU
	var hour_angle: float = ((hour % 12) + minute / 60.0) / 12.0 * TAU
	return Vector2(hour_angle, minute_angle)


## Coins listed biggest value first so kids can count on: [["quarter", 2], ["dime", 1], ...].
static func coin_rows(coins: Dictionary) -> Array:
	var rows: Array = []
	for coin: String in COIN_ORDER:
		if int(coins.get(coin, 0)) > 0:
			rows.append([coin, int(coins[coin])])
	return rows


func show_problem(p: MathProblem, icon: Texture2D = null) -> void:
	problem = p
	count_icon = icon
	queue_redraw()


func _draw() -> void:
	match kind_for(problem):
		"critters":
			_draw_critters(int(problem.data["count"]))
		"clock":
			draw_clock(self, size / 2.0, int(problem.data["hour"]), int(problem.data["minute"]), false)
		"coins":
			draw_coins(self, size, problem.data["coins"], false)
		"groups":
			draw_groups(self, size, int(problem.data["groups"]), int(problem.data["size"]))


func _draw_critters(count: int) -> void:
	var rows: int = ceili(count / float(ICONS_PER_ROW))
	var width: float = mini(count, ICONS_PER_ROW) * (ICON_SIZE + ICON_GAP) - ICON_GAP
	var height: float = rows * (ICON_SIZE + ICON_GAP) - ICON_GAP
	var origin: Vector2 = (size - Vector2(width, height)) / 2.0
	for i: int in count:
		var cell: Vector2 = Vector2(i % ICONS_PER_ROW, i / ICONS_PER_ROW)
		var rect: Rect2 = Rect2(origin + cell * (ICON_SIZE + ICON_GAP), Vector2(ICON_SIZE, ICON_SIZE))
		if count_icon != null:
			draw_texture_rect(count_icon, rect, false)
		else:
			draw_circle(rect.get_center(), ICON_SIZE / 2.0, DOT_COLOR)


## Analog clock. With `minute_labels`, the minutes (5, 10 ... 55) are written around the outside (hint).
static func draw_clock(ci: CanvasItem, center: Vector2, hour: int, minute: int, minute_labels: bool) -> void:
	var font: Font = ThemeDB.fallback_font
	ci.draw_circle(center, CLOCK_RADIUS + 4.0, CLOCK_RIM)
	ci.draw_circle(center, CLOCK_RADIUS, CLOCK_FACE)
	for i: int in 60:
		var angle: float = i / 60.0 * TAU
		var outward: Vector2 = Vector2(sin(angle), -cos(angle))
		var inner: float = CLOCK_RADIUS - (8.0 if i % 5 == 0 else 4.0)
		ci.draw_line(center + outward * inner, center + outward * (CLOCK_RADIUS - 1.0), CLOCK_RIM, 2.0 if i % 5 == 0 else 1.0)
	for n: int in range(1, 13):
		var angle: float = n / 12.0 * TAU
		var outward: Vector2 = Vector2(sin(angle), -cos(angle))
		_draw_centered_text(ci, font, center + outward * (CLOCK_RADIUS - 20.0), str(n), 16, CLOCK_RIM)
		if minute_labels:
			_draw_centered_text(ci, font, center + outward * (CLOCK_RADIUS + 15.0), str((n * 5) % 60), 14, MINUTE_LABEL)
	var angles: Vector2 = hand_angles(hour, minute)
	ci.draw_line(center, center + Vector2(sin(angles.x), -cos(angles.x)) * CLOCK_RADIUS * 0.5, HOUR_HAND, 7.0)
	ci.draw_line(center, center + Vector2(sin(angles.y), -cos(angles.y)) * CLOCK_RADIUS * 0.8, MINUTE_HAND, 4.0)
	ci.draw_circle(center, 5.0, HOUR_HAND)


## Coins biggest value first, centered in `area`. Labels show the name, or the value (hint).
static func draw_coins(ci: CanvasItem, area: Vector2, coins: Dictionary, show_values: bool) -> void:
	var font: Font = ThemeDB.fallback_font
	var pieces: Array[String] = []
	for row: Array in coin_rows(coins):
		for i: int in int(row[1]):
			pieces.append(str(row[0]))
	var widths: float = 0.0
	for coin: String in pieces:
		widths += float(COINS[coin]["mm"]) * COIN_PX_PER_MM + COIN_GAP
	var x: float = (area.x - widths + COIN_GAP) / 2.0
	var y: float = area.y / 2.0 - 8.0
	for coin: String in pieces:
		var radius: float = float(COINS[coin]["mm"]) * COIN_PX_PER_MM / 2.0
		var center: Vector2 = Vector2(x + radius, y)
		ci.draw_circle(center, radius + 2.0, OUTLINE)
		ci.draw_circle(center, radius, COINS[coin]["color"])
		ci.draw_arc(center, radius * 0.8, 0.0, TAU, 32, Color(1, 1, 1, 0.35), 2.0)
		var label: String = "%d¢" % int(TimeMoneyGenerator.COIN_VALUES[coin]) if show_values else coin
		_draw_centered_text(ci, font, Vector2(center.x, y + radius + 16.0), label, 16, Color.WHITE)
		x += radius * 2.0 + COIN_GAP


## `groups` boxes with `group_size` dots each, centered in `area`. Dots shrink to fit big problems.
static func draw_groups(ci: CanvasItem, area: Vector2, groups: int, group_size: int, show_question: bool = false) -> void:
	var font: Font = ThemeDB.fallback_font
	var per_row: int = maxi(mini(group_size, 5), 1)
	var rows: int = maxi(ceili(group_size / float(per_row)), 1)
	var radius: float = DOT_RADIUS
	var box: Vector2
	var total_width: float
	for attempt: int in 4:
		var dot_step: float = radius * 2.0 + 4.0
		box = Vector2(per_row * dot_step + GROUP_PAD * 2.0 - 4.0, rows * dot_step + GROUP_PAD * 2.0 - 4.0)
		total_width = groups * box.x + (groups - 1) * GROUP_GAP
		if total_width <= area.x - 20.0 and box.y <= area.y:
			break
		radius *= 0.7
	var dot_step: float = radius * 2.0 + 4.0
	var origin: Vector2 = Vector2((area.x - total_width) / 2.0, (area.y - box.y) / 2.0)
	for g: int in groups:
		var top_left: Vector2 = origin + Vector2(g * (box.x + GROUP_GAP), 0)
		ci.draw_rect(Rect2(top_left, box), GROUP_COLOR)
		ci.draw_rect(Rect2(top_left, box), OUTLINE, false, 2.0)
		if show_question:
			_draw_centered_text(ci, font, top_left + box / 2.0, "?", 28, OUTLINE)
			continue
		for d: int in group_size:
			var spot: Vector2 = top_left + Vector2(GROUP_PAD + radius + (d % per_row) * dot_step, GROUP_PAD + radius + (d / per_row) * dot_step)
			ci.draw_circle(spot, radius, DOT_COLOR)


static func _draw_centered_text(ci: CanvasItem, font: Font, center: Vector2, text: String, font_size: int, color: Color) -> void:
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	ci.draw_string(font, center + Vector2(-text_size.x / 2.0, text_size.y / 3.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
