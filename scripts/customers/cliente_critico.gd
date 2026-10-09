extends ClienteHabitual
class_name ClienteCritico

## Evento del partido: un crítico gastronómico. Tiene poca paciencia, pero una buena
## reseña sube mucho la reputación; si se va molesto, la baja mucho.

## Su sprite está fijo en la escena cliente_critico.tscn.
func _elegir_aspecto() -> void:
	pass

func nombre_tipo() -> String:
	return "Crítico"

func texto_grupo() -> String:
	return "Crítico gastronómico"

func color_insignia() -> Color:
	return Color("c9a0ff")

func multiplicador_paciencia() -> float:
	return 0.8

func propina_base() -> float:
	return 0.3

func penalizacion_reputacion() -> float:
	return 15.0

func bonificacion_reputacion() -> float:
	return 10.0
