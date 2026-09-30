extends ClienteHabitual
class_name ClientePractica

## Cliente del tutorial de la Jornada 1: nunca se desespera, pide un refresco que no gasta
## inventario y no cuenta en las ventas ni en la reputación.

func nombre_tipo() -> String:
	return "Cliente de práctica"

func texto_grupo() -> String:
	return "Práctica"

func multiplicador_paciencia() -> float:
	return 1000.0

func elegir_pedido() -> String:
	return Catalogo.REFRESCO

func servir(dani: Dani) -> bool:
	if estado != Estado.ESPERANDO_COMIDA or not dani.quitar_platillo(pedido):
		return false
	AudioManager.sfx("caja")
	estado = Estado.COMIENDO
	tiempo_comiendo = 3.0
	pedido_enviado = false
	_barra.visible = false
	_mostrar_burbuja(Catalogo.icono_platillo(pedido), "¡Gracias!")
	return true
