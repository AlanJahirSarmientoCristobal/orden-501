extends CanvasLayer
class_name Notificaciones

## Avisos breves en la parte superior de la pantalla (cada uno es una escena aviso.tscn).
## Escucha GameState.aviso.

const MAXIMO := 4
const DURACION := 3.5

var historial: Array[String] = []

const AVISO := preload("res://scenes/ui/aviso.tscn")

@onready var _caja: VBoxContainer = $Caja

func _ready() -> void:
	GameState.aviso.connect(mostrar)

func mostrar(mensaje: String) -> void:
	historial.push_front(mensaje)
	if historial.size() > 12:
		historial.resize(12)
	var panel: PanelContainer = AVISO.instantiate()
	panel.get_node("Texto").text = mensaje
	_caja.add_child(panel)
	while _caja.get_child_count() > MAXIMO:
		_caja.get_child(0).queue_free()
		_caja.remove_child(_caja.get_child(0))
	var tween := panel.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_interval(DURACION)
	tween.tween_property(panel, "modulate:a", 0.0, 0.4)
	tween.tween_callback(panel.queue_free)
