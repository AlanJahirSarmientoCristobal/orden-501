extends CanvasLayer
class_name Tutorial

## Guía por objetivos de la Jornada 1. Muestra el paso actual en una franja sobre el HUD,
## lo marca en cuanto el jugador lo cumple y pasa al siguiente. [T] omite los tutoriales.
## Cada paso es {"texto": String, "detalle": String, "hecho": Callable -> bool}.

signal terminado

var clave := ""
var pasos: Array[Dictionary] = []
var indice := 0
var _titulo: Label
var _texto: Label
var _detalle: Label
var _espera := 0.0          # pausa breve para que se vea el "¡Bien!" antes del siguiente paso
var _cerrando := false

func _init(nueva_clave: String = "", nuevos_pasos: Array[Dictionary] = []) -> void:
	clave = nueva_clave
	pasos = nuevos_pasos
	layer = 60

func _ready() -> void:
	var panel := UIKit.panel(Color("1b2a1f"), UIKit.VERDE, 8)
	panel.position = Vector2(6, 4)
	panel.size = Vector2(1268, 62)
	var fila := UIKit.hbox(14)
	_titulo = UIKit.etiqueta("", 15, UIKit.VERDE)
	_titulo.custom_minimum_size.x = 150
	fila.add_child(_titulo)
	var columna := UIKit.vbox(0)
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_texto = UIKit.etiqueta("", 17, UIKit.TEXTO)
	_detalle = UIKit.etiqueta("", 12, UIKit.TEXTO_TENUE)
	_detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	columna.add_child(_texto)
	columna.add_child(_detalle)
	fila.add_child(columna)
	fila.add_child(UIKit.etiqueta("[T] Saltar tutorial", 12, UIKit.TEXTO_TENUE))
	panel.add_child(fila)
	add_child(panel)
	_mostrar()

func _mostrar() -> void:
	if indice >= pasos.size():
		return
	_titulo.text = "TUTORIAL %d/%d" % [indice + 1, pasos.size()]
	_texto.text = str(pasos[indice]["texto"])
	_detalle.text = str(pasos[indice].get("detalle", ""))

func _process(delta: float) -> void:
	if _cerrando or indice >= pasos.size():
		return
	if _espera > 0.0:
		_espera -= delta
		if _espera <= 0.0:
			_mostrar()
		return
	var hecho: Callable = pasos[indice]["hecho"]
	if hecho.call():
		indice += 1
		AudioManager.sfx("pedido_listo")
		if indice >= pasos.size():
			_finalizar(true)
		else:
			_texto.text = "¡Bien!"
			_detalle.text = ""
			_espera = 0.9

func _input(evento: InputEvent) -> void:
	if _cerrando or not (evento is InputEventKey) or not evento.pressed or evento.echo:
		return
	if evento.keycode == KEY_T:
		get_viewport().set_input_as_handled()
		GameState.omitir_tutoriales()
		_finalizar(false)

func _finalizar(completo: bool) -> void:
	_cerrando = true
	GameState.completar_tutorial(clave)
	_titulo.text = "TUTORIAL"
	_texto.text = "¡Tutorial completado!" if completo else "Tutorial omitido."
	_detalle.text = ""
	terminado.emit()
	await get_tree().create_timer(2.0).timeout
	queue_free()
