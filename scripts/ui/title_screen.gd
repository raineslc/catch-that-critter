extends Control
## Resume an existing rescue center or introduce a new player's mission.

const START_SCENE: String = "res://scenes/story/storm_intro.tscn"

func _ready() -> void:
	$StartHint.text = "Press any key to continue" if GameState.intro_seen else "Press any key to start"
	if GameState.is_playtest():
		$StartHint.text += "\nPlaytest 2: rescue and care" if GameState.playtest.get("version", "").begins_with("playtest-2") else "\nChase playtest"


func _unhandled_input(event: InputEvent) -> void:
	var is_start: bool = (event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch) \
		and event.is_pressed() and not event.is_echo()
	if is_start:
		get_viewport().set_input_as_handled()
		if GameState.can_start():
			get_tree().change_scene_to_file("res://scenes/world/rescue_center.tscn" if GameState.intro_seen else START_SCENE)
