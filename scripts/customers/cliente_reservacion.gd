extends ClienteHabitual
class_name ClienteReservacion

## Llega a una hora fija y espera su mesa lista. Pone a prueba la asignación de mesas.

var reserva: Dictionary = {}

func nombre_tipo() -> String:
	return "Reserva %s" % reserva.get("id", "")

func color_insignia() -> Color:
	return UIKit.AZUL

func multiplicador_paciencia() -> float:
	return 1.2

func propina_base() -> float:
	return 0.2

func mesa_reservada() -> int:
	return int(reserva.get("mesa", 0))

func terminar() -> void:
	reserva["estado"] = "atendida"
	GameState.registrar_estadistica("reservas_atendidas")
	GameState.reservaciones_cambiadas.emit()
	super.terminar()
