extends Node2D

## Fase de mañana: Dani recorre el pueblo y compra insumos en el Mercado y la Cervecería.
## Al entrar a La 501 comienza la jornada.

const TAMANO := Vector2(2560, 720)

const RESTAURANTE := Rect2(140, 70, 440, 230)
const MERCADO := Rect2(1000, 70, 420, 230)
const CERVECERIA := Rect2(1880, 70, 420, 230)

var dani: Dani
var tiempo_restante := 0.0
var _terminando := false
var _aviso_30s := false

var _hud_dinero: Label
var _hud_reputacion: Label
var _hud_almacen: Label
var _hud_tiempo: Label
var _tablet: Tablet
var _tienda: PanelTienda
var _inventario: PanelInventario
var _dialogo: DialogoOpciones
var _notificaciones: Notificaciones
var _pausa: MenuPausa

func _ready() -> void:
	AudioManager.musica("manana")
	_crear_limites()
	_crear_edificio(RESTAURANTE)
	_crear_edificio(MERCADO)
	_crear_edificio(CERVECERIA)
	_decorar()
	_crear_personajes()
	_crear_interacciones()

	dani = Dani.new()
	dani.usar_camara = true
	dani.limites_camara = Rect2(Vector2.ZERO, TAMANO)
	dani.position = Vector2(360, 380)
	add_child(dani)

	_notificaciones = Notificaciones.new()
	add_child(_notificaciones)
	_tablet = Tablet.new()
	_tablet.notificaciones = _notificaciones
	add_child(_tablet)
	_tienda = PanelTienda.new()
	add_child(_tienda)
	_inventario = PanelInventario.new()
	add_child(_inventario)
	_dialogo = DialogoOpciones.new()
	add_child(_dialogo)
	_pausa = MenuPausa.new()
	add_child(_pausa)
	_crear_hud()

	tiempo_restante = GameState.config.tiempo_pueblo
	GameState.dinero_cambiado.connect(_al_cambiar_dinero)
	GameState.inventario_cambiado.connect(_actualizar_hud)
	_actualizar_hud()
	queue_redraw()

	if not GameState.intro_vista:
		_mostrar_intro.call_deferred()
	else:
		GameState.aviso.emit("Día %d · Mañana. Compra lo necesario para: %s" % [GameState.dia, GameState.info_nivel()["nombre"]])

func _process(delta: float) -> void:
	if _terminando or get_tree().paused:
		return
	# El reloj corre también dentro de las tiendas; solo se detiene en la pausa y en los diálogos.
	if GameState.config.tiempo_pueblo > 0.0 and not _dialogo.esta_abierto():
		tiempo_restante -= delta
		if tiempo_restante <= 30.0 and not _aviso_30s:
			_aviso_30s = true
			AudioManager.sfx("stock_bajo")
			GameState.aviso.emit("¡Quedan 30 segundos de mañana! Regresa a La 501.")
		if tiempo_restante <= 0.0:
			tiempo_restante = 0.0
			GameState.aviso.emit("Se acabó la mañana: es hora de abrir el restaurante.")
			_ir_al_restaurante()
	_actualizar_tiempo()

func _unhandled_input(evento: InputEvent) -> void:
	if PanelModal.abiertos > 0 or _pausa.esta_abierto():
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

func _al_cambiar_dinero(_valor: int) -> void:
	_actualizar_hud()

func _mostrar_intro() -> void:
	var texto := "Dani acaba de ser contratado como nuevo gerente de La 501, un restaurante que funcionaba con libretas, mensajes de WhatsApp y la memoria del personal.\n\nSe acerca la liguilla: los insumos se acaban a media jornada, hay reservaciones duplicadas y se tira comida caducada. Tu misión es poner orden hasta la Gran Final.\n\nCada mañana compra en el Mercado y la Cervecería; cada noche atiende el restaurante durante el partido."
	_dialogo.mostrar("ORDEN 501", texto, [["¡A poner orden!", _cerrar_intro]], false)

func _cerrar_intro() -> void:
	GameState.intro_vista = true
	GameState.guardar()

# ---------------------------------------------------------------- Construcción del mapa

func _crear_limites() -> void:
	_pared(Rect2(-40, -40, TAMANO.x + 80, 40))
	_pared(Rect2(-40, TAMANO.y, TAMANO.x + 80, 40))
	_pared(Rect2(-40, 0, 40, TAMANO.y))
	_pared(Rect2(TAMANO.x, 0, 40, TAMANO.y))

func _crear_edificio(rect: Rect2) -> void:
	_pared(Rect2(rect.position, Vector2(rect.size.x, rect.size.y - 10)))

func _pared(rect: Rect2) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.collision_layer = 1
	cuerpo.position = rect.get_center()
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = rect.size
	forma.shape = caja
	cuerpo.add_child(forma)
	add_child(cuerpo)

func _draw() -> void:
	# Pasto
	draw_rect(Rect2(Vector2.ZERO, TAMANO), Color("5b9e4d"))
	# Banqueta y calle principal
	draw_rect(Rect2(0, 300, TAMANO.x, 40), Color("c9c1ae"))
	draw_rect(Rect2(0, 340, TAMANO.x, 120), Color("4a4f5c"))
	draw_rect(Rect2(0, 460, TAMANO.x, 30), Color("c9c1ae"))
	for x in range(20, int(TAMANO.x), 110):
		draw_rect(Rect2(x, 396, 60, 8), Color("f2d16b"))
	# Paso peatonal hacia cada edificio
	for centro in [RESTAURANTE.get_center().x, MERCADO.get_center().x, CERVECERIA.get_center().x]:
		for i in range(6):
			draw_rect(Rect2(centro - 50 + i * 18, 344, 10, 112), Color(1, 1, 1, 0.75))
	# Parque
	draw_rect(Rect2(60, 520, 900, 180), Color("4f8f43"))
	draw_rect(Rect2(70, 530, 880, 160), Color("6bb35a"), false, 4.0)
	draw_circle(Vector2(510, 610), 60, Color("5aa9e6"))
	draw_arc(Vector2(510, 610), 60, 0, TAU, 48, Color("c9c1ae"), 8.0)
	# Plaza
	draw_rect(Rect2(1100, 520, 700, 180), Color("b9ad98"))
	draw_circle(Vector2(1450, 610), 55, Color("8f8575"))
	draw_circle(Vector2(1450, 610), 38, Color("5aa9e6"))
	# Casas del fondo
	for x in [640, 780, 1500, 1640, 2360]:
		draw_rect(Rect2(x, 150, 110, 150), Color("b86e52"))
		draw_rect(Rect2(x - 6, 130, 122, 26), Color("7c3f33"))
		draw_rect(Rect2(x + 40, 240, 30, 60), Color("3b2c2a"))
	# Edificios principales
	_dibujar_edificio(RESTAURANTE, Color("8f3e32"), Color("f2b544"), "LA 501 · SPORTS BAR")
	_dibujar_edificio(MERCADO, Color("2f6f5e"), Color("e49d45"), "MERCADO CENTRAL")
	_dibujar_edificio(CERVECERIA, Color("3b4a7a"), Color("f2d16b"), "CERVECERÍA LA ESQUINA")
	# Puestos del mercado
	for i in range(3):
		draw_rect(Rect2(MERCADO.position.x + 30 + i * 130, MERCADO.end.y - 70, 100, 44), Color("e49d45"))
		for j in range(5):
			draw_rect(Rect2(MERCADO.position.x + 30 + i * 130 + j * 20, MERCADO.end.y - 78, 20, 10), Color("f5f0e1") if j % 2 == 0 else Color("d9534f"))

func _dibujar_edificio(rect: Rect2, pared: Color, acento: Color, _nombre: String) -> void:
	draw_rect(rect, pared)
	draw_rect(Rect2(rect.position.x - 10, rect.position.y - 16, rect.size.x + 20, 30), pared.darkened(0.35))
	draw_rect(Rect2(rect.position.x + 20, rect.position.y + 40, rect.size.x - 40, 36), Color("1b1f2a"))
	draw_rect(Rect2(rect.position.x + 20, rect.position.y + 40, rect.size.x - 40, 36), acento, false, 3.0)
	for i in range(3):
		draw_rect(Rect2(rect.position.x + 30 + i * (rect.size.x - 60) / 3.0, rect.position.y + 100, (rect.size.x - 60) / 3.0 - 16, 60), Color("9ad1e8"))
	var puerta := Rect2(rect.get_center().x - 30, rect.end.y - 70, 60, 70)
	draw_rect(puerta, Color("3b2c2a"))
	draw_rect(puerta, acento, false, 3.0)

func _decorar() -> void:
	_etiqueta_mapa("LA 501 · SPORTS BAR", Vector2(RESTAURANTE.position.x + 20, RESTAURANTE.position.y + 44), RESTAURANTE.size.x - 40, UIKit.ACENTO)
	_etiqueta_mapa("MERCADO CENTRAL", Vector2(MERCADO.position.x + 20, MERCADO.position.y + 44), MERCADO.size.x - 40, Color("f7c686"))
	_etiqueta_mapa("CERVECERÍA LA ESQUINA", Vector2(CERVECERIA.position.x + 20, CERVECERIA.position.y + 44), CERVECERIA.size.x - 40, Color("f2d16b"))
	for pos in [Vector2(100, 560), Vector2(240, 660), Vector2(820, 560), Vector2(930, 650), Vector2(620, 40), Vector2(900, 40), Vector2(1760, 40), Vector2(2460, 60), Vector2(1080, 650), Vector2(1830, 560)]:
		_sprite("arbol", pos, 4.0)
	for pos in [Vector2(380, 560), Vector2(640, 560), Vector2(1300, 560), Vector2(1600, 560)]:
		_sprite("banca", pos, 3.0)
	for x in range(80, int(TAMANO.x), 320):
		_sprite("farol", Vector2(x, 300), 3.0)
	for pos in [Vector2(MERCADO.position.x - 30, 280), Vector2(MERCADO.end.x + 30, 280)]:
		_sprite("caja_frutas", pos, 3.0)
	for pos in [Vector2(CERVECERIA.position.x - 30, 280), Vector2(CERVECERIA.end.x + 30, 280)]:
		_sprite("barril", pos, 3.0)
	_sprite("planta", Vector2(RESTAURANTE.position.x - 26, 280), 3.0)
	_sprite("planta", Vector2(RESTAURANTE.end.x + 26, 280), 3.0)
	_etiqueta_mapa("PARQUE", Vector2(420, 670), 180, Color("e6f5c9"))
	_etiqueta_mapa("PLAZA", Vector2(1360, 670), 180, Color("fff0a6"))

func _sprite(clave: String, pos: Vector2, escala: float) -> void:
	var tex := AssetPaths.textura(clave)
	if tex == null:
		return
	var s := Sprite2D.new()
	s.texture = tex
	s.position = pos
	s.scale = Vector2(escala, escala)
	add_child(s)

func _etiqueta_mapa(texto: String, pos: Vector2, ancho: float, color: Color) -> void:
	var l := UIKit.etiqueta(texto, 18, color, true)
	l.position = pos
	l.size = Vector2(ancho, 30)
	add_child(l)

func _crear_personajes() -> void:
	_npc("vendedor_mercado", Vector2(MERCADO.get_center().x + 70, MERCADO.end.y + 16), "Don Chema")
	_npc("encargado_cerveceria", Vector2(CERVECERIA.get_center().x + 70, CERVECERIA.end.y + 16), "Lupita")

func _npc(clave: String, pos: Vector2, nombre: String) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = AssetPaths.frames_personaje(clave)
	s.animation = &"down"
	s.frame = 1
	s.scale = Vector2(3, 3)
	s.position = pos
	add_child(s)
	var l := UIKit.etiqueta(nombre, 11, UIKit.TEXTO, true)
	l.position = pos + Vector2(-50, 22)
	l.size = Vector2(100, 16)
	add_child(l)

func _crear_interacciones() -> void:
	add_child(PuntoInteraccion.crear("Entrar al Mercado (comprar comida)", Vector2(MERCADO.get_center().x, MERCADO.end.y + 10), func(): _tienda.abrir_tienda(Catalogo.MERCADO), 60))
	add_child(PuntoInteraccion.crear("Entrar a la Cervecería (bebidas y hielo)", Vector2(CERVECERIA.get_center().x, CERVECERIA.end.y + 10), func(): _tienda.abrir_tienda(Catalogo.CERVECERIA), 60))
	add_child(PuntoInteraccion.crear("Abrir La 501 (empezar la jornada)", Vector2(RESTAURANTE.get_center().x, RESTAURANTE.end.y + 10), _confirmar_restaurante, 60))

func _confirmar_restaurante() -> void:
	var mensaje := "Durante la jornada no podrás volver al pueblo; si algo se acaba tendrás que pedirlo por teléfono (más caro y tarda en llegar).\n\nAlmacén: %d unidades. ¿Abrir el restaurante?" % GameState.inventario.total_unidades()
	_dialogo.mostrar("¿Listo para el partido?", mensaje, [["Sí, abrir La 501", _ir_al_restaurante], ["Todavía no", Callable()]])

func _ir_al_restaurante() -> void:
	if _terminando:
		return
	_terminando = true
	GameState.iniciar_jornada()
	GameState.cambiar_escena(GameState.ESCENA_RESTAURANTE)

# ---------------------------------------------------------------- HUD

func _crear_hud() -> void:
	var capa := UIKit.capa(20)
	add_child(capa)
	var barra := UIKit.panel(UIKit.FONDO, UIKit.BORDE, 8)
	barra.position = Vector2(10, 8)
	barra.size = Vector2(1260, 44)
	var fila := UIKit.hbox(26)
	barra.add_child(fila)
	fila.add_child(UIKit.etiqueta("DÍA %d · MAÑANA · %s" % [GameState.dia, GameState.info_nivel()["nombre"].to_upper()], 16, UIKit.ACENTO))
	_hud_dinero = UIKit.etiqueta("", 16)
	_hud_reputacion = UIKit.etiqueta("", 16)
	_hud_almacen = UIKit.etiqueta("", 16)
	_hud_tiempo = UIKit.etiqueta("", 16, UIKit.VERDE)
	for l in [_hud_dinero, _hud_reputacion, _hud_almacen, _hud_tiempo]:
		fila.add_child(l)
	capa.add_child(barra)
	var ayuda := UIKit.etiqueta("WASD Moverse · Espacio Interactuar · E Tablet · I Inventario · R Reservaciones · Esc Pausa", 13, UIKit.TEXTO_TENUE, true)
	ayuda.position = Vector2(0, 694)
	ayuda.size = Vector2(1280, 20)
	capa.add_child(ayuda)

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
	var segundos := int(ceil(tiempo_restante))
	_hud_tiempo.text = "Tiempo %d:%02d" % [segundos / 60, segundos % 60]
	_hud_tiempo.add_theme_color_override("font_color", UIKit.ROJO if tiempo_restante <= 30.0 else UIKit.VERDE)
