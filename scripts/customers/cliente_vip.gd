extends Cliente
class_name ClienteVIP

## Pide el Combo VIP (más caro), deja más propina y tiene muy poca paciencia.

func clave_sprite() -> String:
	return "cliente_vip"

func nombre_tipo() -> String:
	return "★ VIP"

func color_insignia() -> Color:
	return UIKit.ACENTO

func multiplicador_paciencia() -> float:
	return 0.6

func propina_base() -> float:
	return 0.35

func penalizacion_reputacion() -> float:
	return 12.0

func bonificacion_reputacion() -> float:
	return 3.0

func es_vip() -> bool:
	return true

func elegir_pedido() -> String:
	return Catalogo.COMBO

func _ready() -> void:
	super._ready()
	_sprite.modulate = Color(1.0, 0.92, 0.6)
