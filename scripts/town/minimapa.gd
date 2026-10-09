extends Control
class_name Minimapa

## Minimapa del pueblo: calles, edificios importantes y la posición de Dani.

var tamano_mundo := Vector2(2560, 1440)
var calles: Array[Rect2] = []
var lugares: Array[Dictionary] = []    # {"rect": Rect2, "color": Color, "nombre": String}
var objetivo: Node2D

var _espera := 0.0

func _process(delta: float) -> void:
	_espera -= delta
	if _espera <= 0.0:
		_espera = 0.1
		queue_redraw()

func _escala() -> Vector2:
	return size / tamano_mundo

func _draw() -> void:
	var e := _escala()
	draw_rect(Rect2(Vector2.ZERO, size), Color("2f5f2a"))
	for calle in calles:
		draw_rect(Rect2(calle.position * e, calle.size * e), Color("4a4f5c"))
	var fuente := ThemeDB.fallback_font
	for lugar in lugares:
		var r: Rect2 = lugar["rect"]
		draw_rect(Rect2(r.position * e, r.size * e), lugar["color"])
		draw_string(fuente, r.position * e + Vector2(1, -2), lugar["nombre"], HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
	if is_instance_valid(objetivo):
		var p := objetivo.position * e
		draw_circle(p, 4.0, Color("ffd84a"))
		draw_arc(p, 5.5, 0, TAU, 16, Color.BLACK, 1.5)
	draw_rect(Rect2(Vector2.ZERO, size), UIKit.BORDE, false, 2.0)
