extends PanelModal
class_name DialogoOpciones

var _mensaje := ""
var _opciones: Array = []
var permitir_cerrar := true

func mostrar(titulo: String, mensaje: String, opciones: Array, se_puede_cerrar: bool = true) -> void:
	_mensaje = mensaje
	_opciones = opciones
	permitir_cerrar = se_puede_cerrar
	abrir(titulo)

func construir() -> void:
	UIKit.limpiar(contenido)
	var texto := UIKit.etiqueta(_mensaje, 16)
	texto.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texto.custom_minimum_size.x = 620
	contenido.add_child(texto)
	contenido.add_child(HSeparator.new())
	for opcion in _opciones:
		var accion: Callable = opcion[1]
		contenido.add_child(UIKit.boton(str(opcion[0]), _elegir.bind(accion), 16, 620))

func _elegir(accion: Callable) -> void:
	cerrar()
	if accion.is_valid():
		accion.call()

func _unhandled_input(evento: InputEvent) -> void:
	if permitir_cerrar:
		super._unhandled_input(evento)
	elif esta_abierto() and evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
