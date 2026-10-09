extends CharacterBody2D
class_name Dani

## Dani, el gerente de La 501. El mismo personaje se usa en el pueblo y en el restaurante.
## Sus nodos (sprite, colisión, detector, barras y cámara) están en scenes/entities/dani.tscn.

signal bandeja_cambiada(platillos: Array[String])

const VELOCIDAD_BASE := 240.0

# Sprint (Shift): corre más rápido gastando estamina. Si se agota, hay que esperar
# a recuperar un mínimo antes de volver a correr.
const MULTIPLICADOR_SPRINT := 1.6
const ESTAMINA_MAX := 100.0
const GASTO_ESTAMINA := 35.0          # por segundo corriendo
const RECUPERACION_ESTAMINA := 22.0   # por segundo sin correr
const MINIMO_PARA_CORRER := 25.0

var bloqueado := false
var bandeja: Array[String] = []
var estamina := ESTAMINA_MAX
var agotado := false
var corriendo := false

# Nodos de la escena scenes/entities/dani.tscn
@onready var _sprite: AnimatedSprite2D = $Sprite
@onready var _etiqueta: Label = $Indicacion
@onready var _barra_mantener: ProgressBar = $BarraMantener
@onready var _barra_estamina: ColorRect = $BarraEstamina
@onready var _relleno_estamina: ColorRect = $BarraEstamina/Relleno
@onready var _vista_bandeja: HBoxContainer = $Bandeja
@onready var camara: Camera2D = $Camara

const ANCHO_BARRA_ESTAMINA := 40.0
const COLOR_ESTAMINA := Color("7fe0ff")

var _cercanos: Array[Interactuable] = []
var _objetivo_mantener: Interactuable
var _progreso_mantener := 0.0

func _physics_process(delta: float) -> void:
	if bloqueado:
		velocity = Vector2.ZERO
		_sprite.stop()
		_cancelar_mantener()
		actualizar_estamina(delta, false, false)
		_actualizar_prompt()
		return
	var direccion := Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")
	var corre := actualizar_estamina(delta, Input.is_action_pressed("correr"), direccion != Vector2.ZERO)
	velocity = direccion * VELOCIDAD_BASE * GameState.multiplicador_velocidad() * (MULTIPLICADOR_SPRINT if corre else 1.0)
	_sprite.speed_scale = 1.6 if corre else 1.0
	if direccion != Vector2.ZERO:
		_animar(direccion)
		_cancelar_mantener()
	else:
		_sprite.stop()
		_sprite.frame = 0
	move_and_slide()
	_procesar_mantener(delta)
	_actualizar_prompt()

## Actualiza la estamina y devuelve si Dani está corriendo en este cuadro.
func actualizar_estamina(delta: float, quiere_correr: bool, moviendose: bool) -> bool:
	corriendo = quiere_correr and moviendose and not agotado and estamina > 0.0
	if corriendo:
		estamina = maxf(0.0, estamina - GASTO_ESTAMINA * delta)
		if estamina <= 0.0:
			agotado = true
	else:
		estamina = minf(ESTAMINA_MAX, estamina + RECUPERACION_ESTAMINA * delta)
		if agotado and estamina >= MINIMO_PARA_CORRER:
			agotado = false
	if _barra_estamina:
		_barra_estamina.visible = estamina < ESTAMINA_MAX
		_relleno_estamina.size.x = ANCHO_BARRA_ESTAMINA * estamina / ESTAMINA_MAX
		_relleno_estamina.color = UIKit.ROJO if agotado else COLOR_ESTAMINA
	return corriendo

func _animar(direccion: Vector2) -> void:
	if absf(direccion.x) > absf(direccion.y):
		_sprite.animation = &"side"
		_sprite.flip_h = direccion.x < 0
	elif direccion.y < 0:
		_sprite.animation = &"up"
		_sprite.flip_h = false
	else:
		_sprite.animation = &"down"
		_sprite.flip_h = false
	_sprite.play()

func _unhandled_input(evento: InputEvent) -> void:
	if bloqueado or not evento.is_action_pressed("interactuar") or evento.is_echo():
		return
	var objetivo := objetivo_cercano()
	if objetivo == null:
		return
	get_viewport().set_input_as_handled()
	if objetivo.tiempo_mantener(self) > 0.0:
		_objetivo_mantener = objetivo
		_progreso_mantener = 0.0
	else:
		objetivo.interactuar(self)

func _procesar_mantener(delta: float) -> void:
	if _objetivo_mantener == null:
		return
	if not is_instance_valid(_objetivo_mantener) or not Input.is_action_pressed("interactuar") or not _cercanos.has(_objetivo_mantener):
		_cancelar_mantener()
		return
	var total := _objetivo_mantener.tiempo_mantener(self)
	if total <= 0.0:
		_cancelar_mantener()
		return
	_progreso_mantener += delta
	_barra_mantener.visible = true
	_barra_mantener.value = _progreso_mantener / total
	if _progreso_mantener >= total:
		var objetivo := _objetivo_mantener
		_cancelar_mantener()
		objetivo.interactuar(self)

func _cancelar_mantener() -> void:
	_objetivo_mantener = null
	_progreso_mantener = 0.0
	if _barra_mantener:
		_barra_mantener.visible = false

func objetivo_cercano() -> Interactuable:
	var mejor: Interactuable = null
	var mejor_distancia := INF
	for area in _cercanos:
		if not is_instance_valid(area) or not area.visible or not area.disponible(self):
			continue
		var distancia := global_position.distance_squared_to(area.global_position)
		if distancia < mejor_distancia:
			mejor = area
			mejor_distancia = distancia
	return mejor

func _actualizar_prompt() -> void:
	var objetivo := objetivo_cercano() if not bloqueado else null
	if objetivo:
		var accion := "Mantén [Espacio]" if objetivo.tiempo_mantener(self) > 0.0 else "[Espacio]"
		_etiqueta.text = "%s %s" % [accion, objetivo.obtener_texto(self)]
		_etiqueta.visible = true
	else:
		_etiqueta.visible = false

func _al_entrar(area: Area2D) -> void:
	if area is Interactuable and not _cercanos.has(area):
		_cercanos.append(area)

func _al_salir(area: Area2D) -> void:
	_cercanos.erase(area)

# ---------------------------------------------------------------- Bandeja

func puede_cargar() -> bool:
	return bandeja.size() < GameState.capacidad_bandeja()

func agregar_platillo(platillo: String) -> bool:
	if not puede_cargar():
		return false
	bandeja.append(platillo)
	_actualizar_bandeja()
	return true

func tiene_platillo(platillo: String) -> bool:
	return bandeja.has(platillo)

func quitar_platillo(platillo: String) -> bool:
	var indice := bandeja.find(platillo)
	if indice == -1:
		return false
	bandeja.remove_at(indice)
	_actualizar_bandeja()
	return true

func vaciar_bandeja() -> Array[String]:
	var retirados: Array[String] = bandeja.duplicate()
	bandeja.clear()
	_actualizar_bandeja()
	return retirados

func _actualizar_bandeja() -> void:
	UIKit.limpiar(_vista_bandeja)
	for platillo in bandeja:
		_vista_bandeja.add_child(UIKit.icono(Catalogo.icono_platillo(platillo), 20.0))
	bandeja_cambiada.emit(bandeja)
