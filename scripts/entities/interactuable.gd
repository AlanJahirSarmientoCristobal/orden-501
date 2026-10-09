extends Area2D
class_name Interactuable

## Base para todo lo que Dani puede usar con Espacio: tiendas, mesas, cocina, barra, teléfono...
## Es un Area2D en la capa 8 (CAPA_INTERACTUABLES) con un CollisionShape2D que marca su alcance;
## al usarse emite la señal "usado", que cada escena conecta a su acción.
## Las subclases sobrescriben obtener_texto(), interactuar() y, si hace falta mantener
## pulsado Espacio, tiempo_mantener().

const CAPA_INTERACTUABLES := 8

signal usado(dani: Node)

## Texto que aparece sobre Dani al acercarse ("[Espacio] ...").
@export var texto := "Interactuar"

func obtener_texto(_dani: Node) -> String:
	return texto

func disponible(_dani: Node) -> bool:
	return true

## Segundos que hay que mantener Espacio (0 = acción instantánea).
func tiempo_mantener(_dani: Node) -> float:
	return 0.0

func interactuar(dani: Node) -> void:
	usado.emit(dani)
