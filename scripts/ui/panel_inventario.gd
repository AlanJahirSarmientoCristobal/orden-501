extends PanelModal
class_name PanelInventario

## Inventario del almacén (tecla I en el mapa del pueblo).

func tamano() -> Vector2:
	return Vector2(640, 500)

func _unhandled_input(evento: InputEvent) -> void:
	if esta_abierto() and evento.is_action_pressed("inventario"):
		get_viewport().set_input_as_handled()
		cerrar()
		return
	super._unhandled_input(evento)

func construir() -> void:
	UIKit.limpiar(contenido)
	Tablet.llenar_stock(contenido)
