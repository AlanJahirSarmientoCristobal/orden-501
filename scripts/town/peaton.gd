extends Node2D
class_name Peaton

## Vecino que camina por el pueblo siguiendo una ruta (solo ambientación, no choca).

const VELOCIDAD := 70.0

var ruta: Array[Vector2] = []
var _indice := 0
var _sprite: AnimatedSprite2D

static func crear(clave: String, puntos: Array[Vector2]) -> Peaton:
	var p := Peaton.new()
	p.ruta = puntos
	p.position = puntos[0]
	p._clave = clave
	return p

var _clave := "cliente_1"

func _ready() -> void:
	z_index = 4
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = AssetPaths.frames_personaje(_clave)
	_sprite.scale = AssetPaths.escala(_clave)
	_sprite.position = Vector2(0, AssetPaths.ALTURA_PERSONAJE)
	add_child(_sprite)
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
	# Pausa breve en cada punto, como si platicara o viera un aparador.
	tween.tween_callback(_detenerse)
	tween.tween_interval(randf_range(0.5, 2.5))
	tween.tween_callback(_siguiente)

func _detenerse() -> void:
	_sprite.stop()
	_sprite.frame = 0
