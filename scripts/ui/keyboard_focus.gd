class_name KeyboardFocus
extends RefCounted
## Shared visible focus and a predictable keyboard loop for changing button groups.

static func style(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	var outline: StyleBoxFlat = StyleBoxFlat.new()
	outline.bg_color = Color.TRANSPARENT
	outline.border_color = Color(0.15, 0.35, 0.85)
	outline.set_border_width_all(4)
	outline.set_corner_radius_all(8)
	button.add_theme_stylebox_override("focus", outline)


static func connect_group(buttons: Array[Button], preferred: Button = null) -> void:
	var active: Array[Button] = []
	for button: Button in buttons:
		if is_instance_valid(button) and button.is_visible_in_tree() and not button.disabled:
			active.append(button)
	if active.is_empty():
		return
	for i: int in active.size():
		var button: Button = active[i]
		var previous: NodePath = button.get_path_to(active[posmod(i - 1, active.size())])
		var next: NodePath = button.get_path_to(active[(i + 1) % active.size()])
		button.focus_previous = previous
		button.focus_next = next
		button.focus_neighbor_left = previous
		button.focus_neighbor_top = previous
		button.focus_neighbor_right = next
		button.focus_neighbor_bottom = next
	if preferred != null and active.has(preferred):
		preferred.grab_focus()
	elif not active.has(active[0].get_viewport().gui_get_focus_owner()):
		active[0].grab_focus()
