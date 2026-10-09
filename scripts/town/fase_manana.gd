extends Node2D
class_name FaseManana

@onready var dani: Dani = $Dani
var terminando := false

@onready var _hud_lugar: Label = $HUD/Barra/Fila/Lugar
@onready var _hud_dinero: Label = $HUD/Barra/Fila/Dinero
@onready var _hud_reputacion: Label = $HUD/Barra/Fila/Reputacion
@onready var _hud_almacen: Label = $HUD/Barra/Fila/Almacen
@onready var _hud_tiempo: Label = $HUD/Barra/Fila/Tiempo
@onready var _tablet: Tablet = $Tablet
@onready var _inventario: PanelInventario = $Inventario
@onready var _dialogo: DialogoOpciones = $Dialogo
@onready var _notificaciones: Notificaciones = $Notificaciones
@onready var _pausa: MenuPausa = $Pausa
var _aviso_30s := false

func nombre_lugar() -> String:
	return "PUEBLO"

func preparar_fase() -> void:
	AudioManager.musica("manana")
	_tablet.notificaciones = _notificaciones
	_hud_lugar.text = "DÍA %d · MAÑANA · %s" % [GameState.dia, nombre_lugar()]
	_aviso_30s = GameState.config.tiempo_pueblo > 0.0 and GameState.tiempo_manana <= 30.0
	GameState.dinero_cambiado.connect(_al_cambiar_dinero)
	GameState.inventario_cambiado.connect(_actualizar_hud)
	_actualizar_hud()

func _al_cambiar_dinero(_valor: int) -> void:
	_actualizar_hud()

func _process(delta: float) -> void:
	if terminando or get_tree().paused:
		return
	if GameState.config.tiempo_pueblo > 0.0 and not _dialogo.esta_abierto() and not GameState.tutorial_manana_activo():
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

func _actualizar_hud() -> void:
	_hud_dinero.text = "Dinero %s" % UIKit.dinero(GameState.dinero)
	_hud_reputacion.text = "%s %d%%" % [UIKit.estrellas(GameState.reputacion), int(GameState.reputacion)]
	_hud_almacen.text = "Almacén %d/%d" % [GameState.inventario.total_unidades(), GameState.capacidad_almacen()]
	_actualizar_tiempo()

func _actualizar_tiempo() -> void:
	if GameState.config.tiempo_pueblo <= 0.0:
		_hud_tiempo.text = "Tiempo: sin límite"
		return
	var segundos := int(ceil(GameState.tiempo_manana))
	_hud_tiempo.text = "Tiempo %d:%02d" % [segundos / 60, segundos % 60]
	_hud_tiempo.add_theme_color_override("font_color", UIKit.ROJO if GameState.tiempo_manana <= 30.0 else UIKit.VERDE)
