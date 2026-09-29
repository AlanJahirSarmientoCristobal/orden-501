extends Interactuable
class_name PuntoInteraccion

## Interactuable simple que ejecuta una acción (entrar a una tienda, abrir el restaurante...).

var accion: Callable

static func crear(texto_prompt: String, posicion: Vector2, al_usar: Callable, radio_area: float = 56.0) -> PuntoInteraccion:
	var punto := PuntoInteraccion.new()
	punto.texto = texto_prompt
	punto.position = posicion
	punto.accion = al_usar
	punto.radio = radio_area
	return punto

func interactuar(dani: Node) -> void:
	super.interactuar(dani)
	if accion.is_valid():
		accion.call()
