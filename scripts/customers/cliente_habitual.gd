extends Cliente
class_name ClienteHabitual

## Llega sin reservación, pide del menú y tiene paciencia normal.

var _variante := "cliente_1"

func _init() -> void:
	_variante = ["cliente_1", "cliente_2", "cliente_3"].pick_random()

func clave_sprite() -> String:
	return _variante

func nombre_tipo() -> String:
	return "Aficionado"

func elegir_pedido() -> String:
	# En el medio tiempo y tras los goles se piden más bebidas.
	var prob_bebida: float = restaurante.probabilidad_bebida() if restaurante else GameState.probabilidad_bebida()
	if randf() < prob_bebida:
		return Catalogo.BEBIDAS.pick_random()
	return [Catalogo.HAMBURGUESA, Catalogo.ALITAS, Catalogo.PAPAS].pick_random()
