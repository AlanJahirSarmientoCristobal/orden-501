extends ClienteHabitual
class_name ClienteCritico

## Evento del partido: un crítico gastronómico. Tiene poca paciencia, pero una buena
## reseña sube mucho la reputación; si se va molesto, la baja mucho.

func clave_sprite() -> String:
	return "cliente_3"

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

func _ready() -> void:
	super._ready()
	_sprite.modulate = Color(0.85, 0.8, 1.1)
