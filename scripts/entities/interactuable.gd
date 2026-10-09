extends Area2D
class_name Interactuable

const CAPA_INTERACTUABLES := 8

signal usado(dani: Node)

@export var texto := "Interactuar"

func obtener_texto(_dani: Node) -> String:
	return texto

func disponible(_dani: Node) -> bool:
	return true

func tiempo_mantener(_dani: Node) -> float:
	return 0.0

func interactuar(dani: Node) -> void:
	usado.emit(dani)
