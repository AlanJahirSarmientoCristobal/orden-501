extends Node2D
class_name NPC

## Personaje fijo con nombre: vendedores, vecinos del pueblo y el Chef.
## Su aspecto, nombre y pose se configuran en el Inspector.

@export var frames: SpriteFrames
@export var nombre := ""
@export var animacion: StringName = &"down"
@export var mirar_izquierda := false
@export var animado := false

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var etiqueta: Label = $Nombre

func _ready() -> void:
	if frames:
		sprite.sprite_frames = frames
	sprite.animation = animacion
	sprite.flip_h = mirar_izquierda
	if animado:
		sprite.play()
	etiqueta.text = nombre
	etiqueta.visible = nombre != ""
