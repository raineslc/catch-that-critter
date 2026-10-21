extends GutTest
## Smoke tests: prove the project and test runner are wired up.

const MAIN_SCENE_PATH: String = "res://scenes/main.tscn"


func test_project_name_is_set() -> void:
	assert_eq(ProjectSettings.get_setting("application/config/name"), "Catch That Critter")


func test_main_scene_setting_points_to_main() -> void:
	assert_eq(ProjectSettings.get_setting("application/run/main_scene"), MAIN_SCENE_PATH)


func test_main_scene_loads_and_has_title() -> void:
	var packed: PackedScene = load(MAIN_SCENE_PATH)
	assert_not_null(packed, "main scene should load")
	var main: Node = packed.instantiate()
	add_child_autofree(main)
	var title: Label = main.get_node("Title")
	assert_eq(title.text, "Catch That Critter")
