extends PanelModal
class_name PanelUrgente

## Pedido urgente por teléfono al proveedor (tecla Q o el teléfono de la barra).
## Es más caro que el mercado y tarda en llegar según la dificultad.

const PAQUETES := [3, 6]

var restaurante: Node
var _refresco := 0.0

func tamano() -> Vector2:
	return Vector2(700, 520)

func _unhandled_input(evento: InputEvent) -> void:
	if esta_abierto() and evento.is_action_pressed("pedido_urgente"):
		get_viewport().set_input_as_handled()
		cerrar()
		return
	super._unhandled_input(evento)

func _process(delta: float) -> void:
	if not esta_abierto():
		return
	_refresco += delta
	if _refresco >= 0.5:
		_refresco = 0.0
		construir()

func construir() -> void:
	UIKit.limpiar(contenido)
	var config := GameState.config
	var info := UIKit.etiqueta("Proveedor de emergencia: cobra ×%.1f y tarda %d s en llegar. Dinero: %s" % [config.urgente_multiplicador_costo, int(config.urgente_demora), UIKit.dinero(GameState.dinero)], 15, UIKit.ACENTO)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.custom_minimum_size.x = 640
	contenido.add_child(info)
	contenido.add_child(HSeparator.new())
	for insumo in Catalogo.INSUMOS:
		var fila := UIKit.hbox(8)
		fila.add_child(UIKit.icono(Catalogo.INSUMOS[insumo]["icono"], 26))
		var cantidad := GameState.inventario.total(insumo)
		var nombre := UIKit.etiqueta("%s (tienes %d)" % [Catalogo.nombre_insumo(insumo), cantidad], 15, UIKit.ROJO if cantidad <= 2 else UIKit.TEXTO)
		nombre.custom_minimum_size.x = 230
		fila.add_child(nombre)
		for paquete in PAQUETES:
			var costo := GameState.costo_urgente(insumo, paquete)
			var boton := UIKit.boton("+%d por %s" % [paquete, UIKit.dinero(costo)], _pedir.bind(insumo, paquete), 14, 150)
			boton.disabled = costo > GameState.dinero
			fila.add_child(boton)
		contenido.add_child(fila)
	if restaurante and not restaurante.entregas.is_empty():
		contenido.add_child(HSeparator.new())
		contenido.add_child(UIKit.etiqueta("En camino:", 15, UIKit.AZUL))
		for entrega in restaurante.entregas:
			contenido.add_child(UIKit.etiqueta("· %d %s — llega en %d s" % [entrega["cantidad"], Catalogo.nombre_insumo(entrega["insumo"]), int(ceil(entrega["restante"]))], 14))

func _pedir(insumo: String, cantidad: int) -> void:
	if restaurante and restaurante.pedir_urgente(insumo, cantidad):
		construir()
