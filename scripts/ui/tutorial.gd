extends CanvasLayer
class_name Tutorial

## Guía por objetivos de la Jornada 1. Muestra el paso actual en una franja sobre el HUD,
## lo marca en cuanto el jugador lo cumple y pasa al siguiente. [T] omite los tutoriales.
## Cada paso es {"texto": String, "detalle": String, "hecho": Callable -> bool}.

signal terminado

var clave := ""
var pasos: Array[Dictionary] = []
var indice := 0
var _espera := 0.0          # pausa breve para que se vea el "¡Bien!" antes del siguiente paso
var _cerrando := false

# Nodos de la escena scenes/ui/tutorial.tscn
@onready var _titulo: Label = $Panel/Fila/Titulo
@onready var _texto: Label = $Panel/Fila/Columna/Texto
@onready var _detalle: Label = $Panel/Fila/Columna/Detalle

## Crea el tutorial (escena tutorial.tscn) con sus pasos.
static func crear(nueva_clave: String, nuevos_pasos: Array[Dictionary]) -> Tutorial:
	var tutorial: Tutorial = load("res://scenes/ui/tutorial.tscn").instantiate()
	tutorial.clave = nueva_clave
	tutorial.pasos = nuevos_pasos
	return tutorial

func _ready() -> void:
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
