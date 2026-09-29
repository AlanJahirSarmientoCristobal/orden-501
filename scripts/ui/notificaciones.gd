extends CanvasLayer
class_name Notificaciones

## Avisos breves en la parte superior de la pantalla. Escucha GameState.aviso.

const MAXIMO := 4
const DURACION := 3.5

var historial: Array[String] = []
var _caja: VBoxContainer

func _ready() -> void:
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	_caja = UIKit.vbox(6)
	_caja.position = Vector2(390, 64)
	_caja.custom_minimum_size = Vector2(500, 0)
	_caja.size = Vector2(500, 0)
	_caja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_caja)
	GameState.aviso.connect(mostrar)

func mostrar(mensaje: String) -> void:
	historial.push_front(mensaje)
	if historial.size() > 12:
		historial.resize(12)
	var panel := UIKit.panel(UIKit.FONDO, UIKit.BORDE, 8)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var texto := UIKit.etiqueta(mensaje, 15, UIKit.TEXTO, true)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size.x = 470
	panel.add_child(texto)
	_caja.add_child(panel)
	while _caja.get_child_count() > MAXIMO:
		_caja.get_child(0).queue_free()
		_caja.remove_child(_caja.get_child(0))
	var tween := panel.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(DURACION)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)
