extends Node2D

@export_range(1, 3) var level_number: int = 1

const PLANT_A = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0286.png")
const PLANT_B = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0287.png")
const FOOD_STAND_A = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0276.png")
const FOOD_STAND_B = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0277.png")
const STREET_LIGHT = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0169.png")

var accent_color := Color(0.12, 0.8, 0.62, 0.32)

func _ready() -> void:
	z_index = 1
	accent_color = _get_accent_color()
	_add_sprite(PLANT_A, Vector2(75, 105), 3.6)
	_add_sprite(PLANT_B, Vector2(1205, 105), 3.6, true)
	_add_sprite(PLANT_B, Vector2(75, 650), 3.2)
	_add_sprite(PLANT_A, Vector2(1205, 650), 3.2, true)
	_add_sprite(FOOD_STAND_A, Vector2(115, 235), 3.5)
	_add_sprite(FOOD_STAND_B, Vector2(1165, 235), 3.5)
	_add_sprite(STREET_LIGHT, Vector2(35, 360), 3.2)
	_add_sprite(STREET_LIGHT, Vector2(1245, 360), 3.2, true)
	_add_zone_label()
	queue_redraw()

func _draw() -> void:
	if BusinessManager.management_mode:
		draw_rect(Rect2(18,66,1244,630),Color("#d9c4a3"),false,4.0)
		draw_rect(Rect2(35,80,1210,125),Color(0.2,0.28,0.25,0.32))
		draw_rect(Rect2(55,245,895,420),Color(0.48,0.29,0.16,0.16),false,3.0)
		draw_rect(Rect2(970,245,270,420),Color(0.23,0.3,0.48,0.18),false,3.0)
		for x in range(0,1281,64):
			draw_line(Vector2(x,0),Vector2(x,720),Color(0.35,0.24,0.16,0.12),1.0)
		return
	for x in range(0, 1281, 64):
		draw_line(Vector2(x, 0), Vector2(x, 720), accent_color, 1.0)
	for y in range(0, 721, 64):
		draw_line(Vector2(0, y), Vector2(1280, y), accent_color, 1.0)
	draw_rect(Rect2(18, 66, 1244, 630), Color(accent_color, 0.45), false, 3.0)
	draw_line(Vector2(640, 250), Vector2(640, 675), Color(accent_color, 0.65), 2.0)
	draw_circle(Vector2(640, 465), 92.0, Color(accent_color, 0.12))
	draw_arc(Vector2(640, 465), 92.0, 0.0, TAU, 64, Color(accent_color, 0.65), 2.0)

func _add_sprite(texture: Texture2D, pos: Vector2, sprite_scale: float, flip: bool = false) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.flip_h = flip
	add_child(sprite)

func _add_zone_label() -> void:
	var label = Label.new()
	label.position = Vector2(470, 205)
	label.size = Vector2(340, 36)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(1, 0.9, 0.55))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.08))
	label.add_theme_constant_override("outline_size", 5)
	label.text = (["SALÓN Y PEDIDOS", "RECEPCIÓN Y RESERVAS", "TEMPORADA BAJA Y PROMOCIONES"] if BusinessManager.management_mode else ["ZONA DE AFICIÓN", "LOUNGE DE LIGUILLA", "ARENA DE LA GRAN FINAL"])[level_number - 1]
	add_child(label)

func _get_accent_color() -> Color:
	if BusinessManager.management_mode:
		return Color(0.72,0.48,0.24,0.32)
	match level_number:
		2:
			return Color(0.65, 0.3, 1.0, 0.28)
		3:
			return Color(1.0, 0.68, 0.12, 0.3)
		_:
			return Color(0.12, 0.8, 0.62, 0.28)
