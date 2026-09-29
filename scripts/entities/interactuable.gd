extends Area2D
class_name Interactuable

## Base para todo lo que Dani puede usar con Espacio: tiendas, mesas, cocina, barra, teléfono...
## Las subclases sobrescriben obtener_texto(), interactuar() y, si hace falta mantener
## pulsado Espacio, tiempo_mantener().

const CAPA_INTERACTUABLES := 8

signal usado(dani: Node)

@export var texto := "Interactuar"
@export var radio := 56.0

func _ready() -> void:
	collision_layer = CAPA_INTERACTUABLES
	collision_mask = 0
	monitoring = false
	monitorable = true
	add_to_group("interactuables")
	if get_child_count() == 0 or not _tiene_forma():
		var forma := CollisionShape2D.new()
		var circulo := CircleShape2D.new()
		circulo.radius = radio
		forma.shape = circulo
		add_child(forma)

func _tiene_forma() -> bool:
	for hijo in get_children():
		if hijo is CollisionShape2D:
			return true
	return false

func obtener_texto(_dani: Node) -> String:
	return texto

func disponible(_dani: Node) -> bool:
	return true

## Segundos que hay que mantener Espacio (0 = acción instantánea).
func tiempo_mantener(_dani: Node) -> float:
	return 0.0

func interactuar(dani: Node) -> void:
	usado.emit(dani)
