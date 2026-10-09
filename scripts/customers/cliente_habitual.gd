extends Cliente
class_name ClienteHabitual

const VARIANTES := ["cliente_1", "cliente_2", "cliente_3"]

func _elegir_aspecto() -> void:
	_sprite.sprite_frames = AssetPaths.frames(VARIANTES.pick_random())

func nombre_tipo() -> String:
	return "Aficionado"

func elegir_pedido() -> String:
	var prob_bebida: float = restaurante.probabilidad_bebida() if restaurante else GameState.probabilidad_bebida()
	if randf() < prob_bebida:
		return Catalogo.BEBIDAS.pick_random()
	return [Catalogo.HAMBURGUESA, Catalogo.ALITAS, Catalogo.PAPAS].pick_random()
