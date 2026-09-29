extends Node2D
class_name FaseManana

## Base de la fase de mañana, compartida por el pueblo y el interior de las tiendas:
## HUD, reloj de la mañana, tablet (E), inventario (I), reservaciones (R) y pausa.

var dani: Dani
var terminando := false

var _hud_dinero: Label
var _hud_reputacion: Label
var _hud_almacen: Label
var _hud_tiempo: Label
var _tablet: Tablet
var _inventario: PanelInventario
var _dialogo: DialogoOpciones
var _notificaciones: Notificaciones
var _pausa: MenuPausa
var _aviso_30s := false

## Nombre del lugar para la barra superior (lo define cada escena).
func nombre_lugar() -> String:
	return "PUEBLO"

func crear_dani(posicion: Vector2, camara: bool, limites: Rect2 = Rect2(0, 0, 1280, 720)) -> void:
	dani = Dani.new()
	dani.usar_camara = camara
	dani.limites_camara = limites
	dani.position = posicion
	add_child(dani)

func preparar_fase() -> void:
	AudioManager.musica("manana")
	_notificaciones = Notificaciones.new()
	add_child(_notificaciones)
	_tablet = Tablet.new()
	_tablet.notificaciones = _notificaciones
	add_child(_tablet)
	_inventario = PanelInventario.new()
	add_child(_inventario)
	_dialogo = DialogoOpciones.new()
	add_child(_dialogo)
	_pausa = MenuPausa.new()
	add_child(_pausa)
	_crear_hud()
	_aviso_30s = GameState.config.tiempo_pueblo > 0.0 and GameState.tiempo_manana <= 30.0
	GameState.dinero_cambiado.connect(_al_cambiar_dinero)
	GameState.inventario_cambiado.connect(_actualizar_hud)
	_actualizar_hud()

func _al_cambiar_dinero(_valor: int) -> void:
	_actualizar_hud()

func _process(delta: float) -> void:
	if terminando or get_tree().paused:
		return
	# El reloj corre en el pueblo y dentro de las tiendas; se detiene en pausa y en los diálogos.
	if GameState.config.tiempo_pueblo > 0.0 and not _dialogo.esta_abierto():
		GameState.tiempo_manana -= delta
		if GameState.tiempo_manana <= 30.0 and not _aviso_30s:
			_aviso_30s = true
			AudioManager.sfx("stock_bajo")
			GameState.aviso.emit("¡Quedan 30 segundos de mañana! Regresa a La 501.")
		if GameState.tiempo_manana <= 0.0:
			GameState.tiempo_manana = 0.0
			GameState.aviso.emit("Se acabó la mañana: es hora de abrir el restaurante.")
			ir_al_restaurante()
	_actualizar_tiempo()

func _unhandled_input(evento: InputEvent) -> void:
	if terminando or PanelModal.abiertos > 0 or _pausa.esta_abierto():
		return
	if evento.is_action_pressed("tablet"):
		get_viewport().set_input_as_handled()
		_tablet.abrir_seccion("avisos")
	elif evento.is_action_pressed("inventario"):
		get_viewport().set_input_as_handled()
		_inventario.abrir("INVENTARIO DEL ALMACÉN")
	elif evento.is_action_pressed("reservaciones"):
		get_viewport().set_input_as_handled()
		_tablet.abrir_seccion("reservaciones")

func ir_al_restaurante() -> void:
	if terminando:
		return
	terminando = true
	GameState.iniciar_jornada()
	GameState.cambiar_escena(GameState.ESCENA_RESTAURANTE)

# ---------------------------------------------------------------- Utilidades de construcción

func pared(rect: Rect2) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.collision_layer = 1
	cuerpo.position = rect.get_center()
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = rect.size
	forma.shape = caja
	cuerpo.add_child(forma)
	add_child(cuerpo)

func sprite(clave: String, pos: Vector2, escala: float) -> Sprite2D:
	var tex := AssetPaths.textura(clave)
	if tex == null:
		return null
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.scale = Vector2(escala, escala)
	add_child(s)
	return s

func etiqueta_mapa(texto: String, pos: Vector2, ancho: float, color: Color, tam: int = 18) -> Label:
	var l := UIKit.etiqueta(texto, tam, color, true)
	l.position = pos
	l.size = Vector2(ancho, tam + 12)
	add_child(l)
	return l

func npc(clave: String, pos: Vector2, nombre: String, animacion: StringName = &"down") -> AnimatedSprite2D:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = AssetPaths.frames_personaje(clave)
	s.animation = animacion
	s.frame = 1
	s.scale = Vector2(AssetPaths.ESCALA_PERSONAJE, AssetPaths.ESCALA_PERSONAJE)
	s.position = pos
	s.z_index = 5
	add_child(s)
	if nombre != "":
		var l := UIKit.etiqueta(nombre, 11, UIKit.TEXTO, true)
		l.position = pos + Vector2(-60, 26)
		l.size = Vector2(120, 16)
		l.z_index = 5
		add_child(l)
	return s

# ---------------------------------------------------------------- HUD

func _crear_hud() -> void:
	var capa := UIKit.capa(20)
	add_child(capa)
	var barra := UIKit.panel(UIKit.FONDO, UIKit.BORDE, 8)
	barra.position = Vector2(10, 8)
	barra.size = Vector2(1260, 44)
	var fila := UIKit.hbox(24)
	barra.add_child(fila)
	fila.add_child(UIKit.etiqueta("DÍA %d · MAÑANA · %s" % [GameState.dia, nombre_lugar()], 16, UIKit.ACENTO))
	_hud_dinero = UIKit.etiqueta("", 16)
	_hud_reputacion = UIKit.etiqueta("", 16)
	_hud_almacen = UIKit.etiqueta("", 16)
	_hud_tiempo = UIKit.etiqueta("", 16, UIKit.VERDE)
	for l in [_hud_dinero, _hud_reputacion, _hud_almacen, _hud_tiempo]:
		fila.add_child(l)
	capa.add_child(barra)
	var ayuda := UIKit.etiqueta("WASD Moverse · Shift Correr · Espacio Interactuar · E Tablet · I Inventario · R Reservaciones · Esc Pausa", 13, UIKit.TEXTO_TENUE, true)
	ayuda.position = Vector2(0, 694)
	ayuda.size = Vector2(1280, 20)
	capa.add_child(ayuda)
	extender_hud(capa)

## Las escenas pueden agregar elementos al HUD (por ejemplo, el minimapa del pueblo).
func extender_hud(_capa: CanvasLayer) -> void:
	pass

func _actualizar_hud() -> void:
	if _hud_dinero == null:
		return
	_hud_dinero.text = "Dinero %s" % UIKit.dinero(GameState.dinero)
	_hud_reputacion.text = "%s %d%%" % [UIKit.estrellas(GameState.reputacion), int(GameState.reputacion)]
	_hud_almacen.text = "Almacén %d/%d" % [GameState.inventario.total_unidades(), GameState.capacidad_almacen()]
	_actualizar_tiempo()

func _actualizar_tiempo() -> void:
	if _hud_tiempo == null:
		return
	if GameState.config.tiempo_pueblo <= 0.0:
		_hud_tiempo.text = "Tiempo: sin límite"
		return
	var segundos := int(ceil(GameState.tiempo_manana))
	_hud_tiempo.text = "Tiempo %d:%02d" % [segundos / 60, segundos % 60]
	_hud_tiempo.add_theme_color_override("font_color", UIKit.ROJO if GameState.tiempo_manana <= 30.0 else UIKit.VERDE)
