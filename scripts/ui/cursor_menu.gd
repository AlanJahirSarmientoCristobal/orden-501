extends Control
class_name CursorMenu

const TINTA := Color("303040")
const SOMBRA := Color("c8c8c0")

func _draw() -> void:
	var puntos := PackedVector2Array([Vector2(6, 8), Vector2(22, 18), Vector2(6, 28)])
	draw_colored_polygon(puntos + PackedVector2Array([Vector2(2, 2), Vector2(2, 2), Vector2(2, 2)]), SOMBRA)
	draw_colored_polygon(puntos, TINTA)
