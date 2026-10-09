extends Node2D
class_name Peaton

const VELOCIDAD := 70.0

@export var ruta: Array[Vector2] = []
@export var frames: SpriteFrames

var _indice := 0

@onready var _sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	if frames:
		_sprite.sprite_frames = frames
	_indice = randi_range(0, ruta.size() - 1)
	position = ruta[_indice]
	_siguiente()

func _siguiente() -> void:
	if ruta.size() < 2:
		return
	_indice = (_indice + 1) % ruta.size()
	var destino := ruta[_indice]
	var direccion := destino - position
	if absf(direccion.x) > absf(direccion.y):
		_sprite.animation = &"side"
		_sprite.flip_h = direccion.x < 0
	else:
		_sprite.animation = &"up" if direccion.y < 0 else &"down"
	_sprite.play()
	var tween := create_tween()
	tween.tween_property(self, "position", destino, direccion.length() / VELOCIDAD)
	tween.tween_callback(_detenerse)
	tween.tween_interval(randf_range(0.5, 2.5))
	tween.tween_callback(_siguiente)

func _detenerse() -> void:
	_sprite.stop()
	_sprite.frame = 0
