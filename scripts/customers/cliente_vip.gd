extends Cliente
class_name ClienteVIP

func nombre_tipo() -> String:
	return "★ VIP"

func color_insignia() -> Color:
	return UIKit.ACENTO

func multiplicador_paciencia() -> float:
	return GameState.config.paciencia_vip

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
