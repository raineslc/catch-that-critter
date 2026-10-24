class_name SaveNotice
extends CanvasLayer
## Visible only when saving needs attention; failures must not look like successful saves.

var panel: PanelContainer
var label: Label

func _ready() -> void:
	layer = 30
	panel = PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 160
	panel.offset_right = -160
	panel.offset_top = 2
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(panel)
	label = Label.new()
	label.add_theme_font_size_override("font_size", 24)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(label)
	GameState.save_status_changed.connect(_show_message)
	_show_message(GameState.save_message)


func _show_message(message: String) -> void:
	label.text = message
	panel.visible = message != ""
