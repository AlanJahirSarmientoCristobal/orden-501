extends CharacterBody2D
class_name Dani

## Dani, el gerente de La 501. El mismo personaje se usa en el pueblo y en el restaurante.

signal bandeja_cambiada(platillos: Array[String])

const VELOCIDAD_BASE := 240.0

# Sprint (Shift): corre más rápido gastando estamina. Si se agota, hay que esperar
# a recuperar un mínimo antes de volver a correr.
const MULTIPLICADOR_SPRINT := 1.6
const ESTAMINA_MAX := 100.0
const GASTO_ESTAMINA := 35.0          # por segundo corriendo
const RECUPERACION_ESTAMINA := 22.0   # por segundo sin correr
const MINIMO_PARA_CORRER := 25.0

@export var usar_camara := false
@export var limites_camara := Rect2(0, 0, 1280, 720)

var bloqueado := false
var bandeja: Array[String] = []
var estamina := ESTAMINA_MAX
var agotado := false
var corriendo := false

var _sprite: AnimatedSprite2D
var _detector: Area2D
var _etiqueta: Label
var _barra_mantener: ProgressBar
var _barra_estamina: ColorRect          # fondo de la barra de estamina
var _relleno_estamina: ColorRect
const ANCHO_BARRA_ESTAMINA := 40.0
const COLOR_ESTAMINA := Color("7fe0ff")
var _vista_bandeja: HBoxContainer
var _cercanos: Array[Interactuable] = []
var _objetivo_mantener: Interactuable
var _progreso_mantener := 0.0

func _ready() -> void:
	add_to_group("dani")
	z_index = 10
	collision_layer = 2
	collision_mask = 1
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_construir()

func _construir() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = AssetPaths.frames_personaje("dani")
	_sprite.animation = &"down"
	_sprite.scale = AssetPaths.escala("dani")
	_sprite.position = Vector2(0, AssetPaths.ALTURA_PERSONAJE)
	add_child(_sprite)

	var cuerpo := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(26, 16)
	cuerpo.shape = rect
	cuerpo.position = Vector2(0, 10)
	add_child(cuerpo)

	_detector = Area2D.new()
	_detector.collision_layer = 0
	_detector.collision_mask = Interactuable.CAPA_INTERACTUABLES
	_detector.monitorable = false
	var alcance := CollisionShape2D.new()
	var circulo := CircleShape2D.new()
	circulo.radius = 30.0
	alcance.shape = circulo
	_detector.add_child(alcance)
	add_child(_detector)
	_detector.area_entered.connect(_al_entrar)
	_detector.area_exited.connect(_al_salir)

	var nombre := UIKit.etiqueta("DANI", 10, UIKit.ACENTO, true)
	nombre.position = Vector2(-40, 20)
	nombre.size = Vector2(80, 14)
	add_child(nombre)

	_etiqueta = UIKit.etiqueta("", 13, Color(1, 0.92, 0.45), true)
	_etiqueta.position = Vector2(-160, -72)
	_etiqueta.size = Vector2(320, 20)
	_etiqueta.z_index = 50
	_etiqueta.visible = false
	add_child(_etiqueta)

	_barra_mantener = ProgressBar.new()
	_barra_mantener.position = Vector2(-30, -48)
	_barra_mantener.size = Vector2(60, 8)
	_barra_mantener.show_percentage = false
	_barra_mantener.max_value = 1.0
	_barra_mantener.visible = false
	_barra_mantener.add_theme_stylebox_override("fill", UIKit.estilo(UIKit.VERDE, 3, Color.TRANSPARENT, 0, 0))
	_barra_mantener.add_theme_stylebox_override("background", UIKit.estilo(Color(0, 0, 0, 0.6), 3, Color.TRANSPARENT, 0, 0))
	add_child(_barra_mantener)

	# Barra delgada (3 px) debajo del nombre; solo se ve mientras la estamina no está llena.
	_barra_estamina = ColorRect.new()
	_barra_estamina.color = Color(0, 0, 0, 0.6)
	_barra_estamina.position = Vector2(-ANCHO_BARRA_ESTAMINA / 2.0 - 1.0, 37)
	_barra_estamina.size = Vector2(ANCHO_BARRA_ESTAMINA + 2.0, 5)
	_barra_estamina.visible = false
	_relleno_estamina = ColorRect.new()
	_relleno_estamina.color = COLOR_ESTAMINA
	_relleno_estamina.position = Vector2(1, 1)
	_relleno_estamina.size = Vector2(ANCHO_BARRA_ESTAMINA, 3)
	_barra_estamina.add_child(_relleno_estamina)
	add_child(_barra_estamina)

	_vista_bandeja = UIKit.hbox(2)
	_vista_bandeja.position = Vector2(-44, -40)
	_vista_bandeja.size = Vector2(88, 22)
	_vista_bandeja.alignment = BoxContainer.ALIGNMENT_CENTER
	_vista_bandeja.z_index = 40
	add_child(_vista_bandeja)

	if usar_camara:
		var camara := Camera2D.new()
		camara.limit_left = int(limites_camara.position.x)
		camara.limit_top = int(limites_camara.position.y)
		camara.limit_right = int(limites_camara.end.x)
		camara.limit_bottom = int(limites_camara.end.y)
		camara.position_smoothing_enabled = true
		camara.position_smoothing_speed = 8.0
		add_child(camara)
		camara.make_current()

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
