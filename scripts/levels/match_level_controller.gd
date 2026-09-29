extends Node

const MANAGEMENT_PANEL = preload("res://scenes/ui/management_panel.tscn")

@export var level_number: int = 1

var pause_overlay: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_pause_overlay()
	if BusinessManager.management_mode:
		BusinessManager.begin_turn(level_number)
		add_child(MANAGEMENT_PANEL.instantiate())
	GameManager.start_level(level_number)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and GameManager.is_game_active:
		get_tree().paused = not get_tree().paused
		pause_overlay.visible = get_tree().paused
		get_viewport().set_input_as_handled()

func _create_pause_overlay() -> void:
	var layer = CanvasLayer.new()
	layer.layer = 40
	layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(layer)

	pause_overlay = Control.new()
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	layer.add_child(pause_overlay)

	var dim = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.01, 0.03, 0.06, 0.86)
	pause_overlay.add_child(dim)

	var title = Label.new()
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.position = Vector2(-180, -55)
	title.size = Vector2(360, 110)
	title.text = "⏸ PARTIDO EN PAUSA\n\nPresiona [Esc] para continuar"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.3))
	pause_overlay.add_child(title)
