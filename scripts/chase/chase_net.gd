class_name ChaseNet
extends Node2D
## A simple catching net drawn in code (the art pack has none): a hoop with crossing strings.

const RADIUS: float = 34.0
const HOOP: Color = Color(0.55, 0.35, 0.15)
const MESH: Color = Color(1, 1, 1, 0.8)
const STRINGS: int = 5


func _draw() -> void:
	draw_circle(Vector2.ZERO, RADIUS, Color(1, 1, 1, 0.15))
	for i: int in range(1, STRINGS + 1):
		var t: float = -RADIUS + i * (2.0 * RADIUS / (STRINGS + 1))
		var half: float = sqrt(RADIUS * RADIUS - t * t)
		draw_line(Vector2(t, -half), Vector2(t, half), MESH, 2.0)
		draw_line(Vector2(-half, t), Vector2(half, t), MESH, 2.0)
	draw_arc(Vector2.ZERO, RADIUS, 0.0, TAU, 40, HOOP, 5.0)
	draw_line(Vector2(RADIUS * 0.7, RADIUS * 0.7), Vector2(RADIUS * 1.6, RADIUS * 1.6), HOOP, 6.0)
