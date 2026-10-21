extends Control
## Title screen: any key, click, or tap starts the storm intro (which then goes to the Meadow).

const START_SCENE: String = "res://scenes/story/storm_intro.tscn"


func _unhandled_input(event: InputEvent) -> void:
	var is_start: bool = (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) \
		and event.is_pressed() and not event.is_echo()
	if is_start:
		get_viewport().set_input_as_handled()
		get_tree().change_scene_to_file(START_SCENE)
