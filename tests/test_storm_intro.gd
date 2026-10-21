extends GutTest
## The storm intro: story data, panels, storm effects, and finishing into the game.

const SCENE: PackedScene = preload("res://scenes/story/storm_intro.tscn")
const STATES: Array[String] = ["sunny", "storm", "fences_fall", "scatter", "morning"]
const UNKIND_WORDS: Array[String] = ["wrong", "bad", "fail", "stupid", "dead", "die"]
const MAX_CAPTION_LENGTH: int = 90

var intro: StormIntro


func before_each() -> void:
	GameState.reset()
	intro = SCENE.instantiate()
	intro.auto_change_scene = false
	add_child_autofree(intro)


func test_story_data_is_kid_friendly_and_complete() -> void:
	var story: Dictionary = StormIntro.load_story()
	var panels: Array = story["panels"]
	assert_between(panels.size(), 3, 10, "a few panels, not a movie")
	var seen: Dictionary = {}
	for panel: Variant in panels:
		var state: String = str(panel["state"])
		assert_has(STATES, state)
		seen[state] = true
		var text: String = str(panel["caption"])
		assert_lte(text.length(), MAX_CAPTION_LENGTH, "short caption: " + text)
		for word: String in UNKIND_WORDS:
			assert_false(text.to_lower().contains(word), "'%s' in: %s" % [word, text])
	assert_eq(seen.size(), STATES.size(), "every part of the story is shown")
	for member: Variant in story["cast"]:
		assert_true(ResourceLoader.exists(str(member["sheet"])), str(member["id"]))


func test_starts_sunny_with_animals_in_the_pen() -> void:
	assert_eq(intro.panel_index, 0)
	assert_eq(intro.state, "sunny")
	assert_true(intro.caption_panel.visible)
	assert_string_contains(intro.caption.text, "Rescue Center")
	assert_gte(intro.animals.size(), 3)
	assert_eq(intro.fences.size(), StormIntro.FENCE_PIECES * 2)
	assert_false(intro.rain.emitting)


func test_storm_brings_rain_dark_sky_and_lightning() -> void:
	intro.advance()
	assert_eq(intro.state, "storm")
	assert_true(intro.rain.emitting)
	await wait_seconds(1.4)
	assert_gt(intro.night.color.a, 0.4, "sky gets dark")


func test_fences_fall_and_animals_run_off() -> void:
	intro.advance()
	intro.advance()
	assert_eq(intro.state, "fences_fall")
	await wait_seconds(0.9)
	for fence: TextureRect in intro.fences:
		assert_gt(absf(fence.rotation_degrees), 10.0, "fence knocked over")
	intro.advance()
	assert_eq(intro.state, "scatter")
	await wait_seconds(2.4)
	var view: Rect2 = Rect2(Vector2.ZERO, Vector2(1280, 720))
	for animal: AnimatedSprite2D in intro.animals:
		assert_false(view.has_point(animal.position), animal.name + " ran off screen")


func test_morning_the_sidekick_explains_the_mission() -> void:
	while intro.state != "morning":
		intro.advance()
	assert_false(intro.rain.emitting)
	assert_true(intro.bubble.visible, "sidekick speaks in a bubble")
	assert_false(intro.caption_panel.visible)
	assert_true(intro.henrito.visible)
	await wait_seconds(1.5)
	assert_lt(intro.night.color.a, 0.1, "sky is bright again")
	assert_almost_eq(intro.henrito.position.x, StormIntro.HENRITO_STOP_X, 1.0)


func test_last_panel_says_lets_go_and_finishes() -> void:
	watch_signals(intro)
	while intro.panel_index < intro.panels.size() - 1:
		intro.advance()
	assert_eq(intro.next_button.text, StormIntro.LAST_TEXT)
	assert_string_contains(intro.bubble_label.text, "chase", "last line explains how to play")
	intro.advance()
	assert_signal_emitted(intro, "finished")
	intro.advance()
	assert_signal_emit_count(intro, "finished", 1, "only finishes once")


func test_skip_finishes_right_away() -> void:
	watch_signals(intro)
	intro.skip_button.pressed.emit()
	await wait_frames(2)
	assert_signal_emitted(intro, "finished")


func test_space_and_click_go_to_the_next_panel() -> void:
	var key: InputEventKey = InputEventKey.new()
	key.keycode = KEY_SPACE
	key.pressed = true
	intro._unhandled_input(key)
	assert_eq(intro.panel_index, 1)
	var click: InputEventMouseButton = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	intro._unhandled_input(click)
	assert_eq(intro.panel_index, 2)


func test_sidekick_name_is_filled_in() -> void:
	var panel: Dictionary = {"caption": "Hi, I'm {sidekick}!"}
	assert_eq(intro.caption_text(panel), "Hi, I'm Henrito!")


func test_title_screen_starts_the_intro() -> void:
	var title: GDScript = load("res://scripts/ui/title_screen.gd")
	assert_eq(title.get_script_constant_map()["START_SCENE"], "res://scenes/story/storm_intro.tscn")
	assert_eq(StormIntro.NEXT_SCENE, "res://scenes/world/rescue_center.tscn", "new games start at the Rescue Center")
