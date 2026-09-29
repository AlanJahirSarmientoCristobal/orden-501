extends FaseManana

## Fase de mañana: el pueblo. Dani lo recorre y entra al Mercado y a la Cervecería
## para comprar insumos. Al entrar a La 501 comienza la jornada.

const TAMANO := Vector2(2560, 1440)

# Calles
const AVENIDA := Rect2(0, 600, 2560, 120)
const AVENIDA_VERTICAL := Rect2(1200, 0, 120, 1440)
const CALLE_SUR := Rect2(1320, 1150, 1240, 90)

# Edificios con puerta
const RESTAURANTE := Rect2(180, 250, 520, 290)
const MERCADO := Rect2(1560, 230, 560, 310)
const CERVECERIA := Rect2(1600, 830, 480, 300)

# Zonas abiertas
const PLAZA := Rect2(760, 230, 380, 330)
const PARQUE := Rect2(60, 790, 1080, 590)
const CANCHA := Rect2(1980, 1270, 520, 150)

const CASAS := [
	Rect2(1380, 290, 130, 250), Rect2(2180, 300, 150, 240), Rect2(2380, 300, 140, 240),
	Rect2(1380, 860, 160, 250), Rect2(2140, 860, 170, 250), Rect2(2350, 860, 170, 250),
	Rect2(1400, 1270, 150, 150), Rect2(1600, 1270, 150, 150), Rect2(1800, 1270, 150, 150),
	Rect2(20, 290, 130, 250),
]
const COLORES_CASA := [Color("b86e52"), Color("c9a26b"), Color("7f9fb5"), Color("a86f8f"), Color("8fae6b")]

const CONSEJOS := [
	{"nombre": "Doña Mari", "pos": Vector2(930, 520), "sprite": "cliente_3",
		"texto": "\"Dicen que en el medio tiempo todos piden bebidas. ¡Que no te falte hielo!\""},
	{"nombre": "Profe Juve", "pos": Vector2(760, 1040), "sprite": "cliente_2",
		"texto": "\"La carne, el pollo, la verdura, el pan y el hielo caducan. Compra lo que vayas a usar.\""},
	{"nombre": "Capitán del equipo", "pos": Vector2(2240, 1230), "sprite": "cliente_1",
		"texto": "\"Cuando metemos gol, la banda pide otra ronda. ¡Ten cerveza, refresco y Monster!\""},
]

func nombre_lugar() -> String:
	return "PUEBLO · %s" % GameState.info_nivel()["nombre"].to_upper()

func _ready() -> void:
	_crear_limites()
	for rect in [RESTAURANTE, MERCADO, CERVECERIA]:
		pared(Rect2(rect.position, Vector2(rect.size.x, rect.size.y - 10)))
	for casa in CASAS:
		pared(casa)
	pared(Rect2(PARQUE.get_center() - Vector2(55, 55), Vector2(110, 110)))   # Estanque
	_decorar()
	_crear_personajes()
	_crear_interacciones()

	var inicio := GameState.posicion_pueblo if GameState.posicion_pueblo != Vector2.ZERO else Vector2(RESTAURANTE.get_center().x, RESTAURANTE.end.y + 50)
	crear_dani(inicio, true, Rect2(Vector2.ZERO, TAMANO))
	preparar_fase()
	queue_redraw()

	if not GameState.intro_vista:
		_mostrar_intro.call_deferred()
	elif GameState.posicion_pueblo == Vector2.ZERO:
		GameState.aviso.emit("Día %d · Mañana. Recorre el pueblo y compra para: %s" % [GameState.dia, GameState.info_nivel()["nombre"]])

func extender_hud(capa: CanvasLayer) -> void:
	var mapa := Minimapa.new()
	mapa.position = Vector2(1058, 60)
	mapa.size = Vector2(208, 117)
	mapa.tamano_mundo = TAMANO
	mapa.calles = [AVENIDA, AVENIDA_VERTICAL, CALLE_SUR]
	mapa.lugares = [
		{"rect": RESTAURANTE, "color": Color("c0503f"), "nombre": "La 501"},
		{"rect": MERCADO, "color": Color("3f9a80"), "nombre": "Mercado"},
		{"rect": CERVECERIA, "color": Color("5a6fb0"), "nombre": "Cervecería"},
		{"rect": PARQUE, "color": Color("4f8f43"), "nombre": ""},
	]
	mapa.objetivo = dani
	capa.add_child(mapa)

func _mostrar_intro() -> void:
	var texto := "Dani acaba de ser contratado como nuevo gerente de La 501, un restaurante que funcionaba con libretas, mensajes de WhatsApp y la memoria del personal.\n\nSe acerca la liguilla: los insumos se acaban a media jornada, hay reservaciones duplicadas y se tira comida caducada. Tu misión es poner orden hasta la Gran Final.\n\nCada mañana recorre el pueblo y compra en el Mercado y la Cervecería; cada noche atiende el restaurante durante el partido."
	_dialogo.mostrar("ORDEN 501", texto, [["¡A poner orden!", _cerrar_intro]], false)

func _cerrar_intro() -> void:
	GameState.intro_vista = true
	GameState.guardar()

# ---------------------------------------------------------------- Mapa

func _crear_limites() -> void:
	pared(Rect2(-40, -40, TAMANO.x + 80, 40))
	pared(Rect2(-40, TAMANO.y, TAMANO.x + 80, 40))
	pared(Rect2(-40, 0, 40, TAMANO.y))
	pared(Rect2(TAMANO.x, 0, 40, TAMANO.y))

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, TAMANO), Color("5b9e4d"))
	_dibujar_calles()
	# Plaza con fuente
	draw_rect(PLAZA, Color("c2b59b"))
	for x in range(int(PLAZA.position.x), int(PLAZA.end.x), 40):
		draw_line(Vector2(x, PLAZA.position.y), Vector2(x, PLAZA.end.y), Color(0, 0, 0, 0.06), 2.0)
	draw_circle(PLAZA.get_center(), 60, Color("8f8575"))
	draw_circle(PLAZA.get_center(), 44, Color("5aa9e6"))
	# Parque con caminos y estanque
	draw_rect(PARQUE, Color("4f8f43"))
	draw_rect(PARQUE, Color("6bb35a"), false, 6.0)
	var c := PARQUE.get_center()
	draw_line(Vector2(PARQUE.position.x, c.y), Vector2(PARQUE.end.x, c.y), Color("d9c38f"), 26.0)
	draw_line(Vector2(c.x, PARQUE.position.y), Vector2(c.x, PARQUE.end.y), Color("d9c38f"), 26.0)
	draw_circle(c, 78, Color("d9c38f"))
	draw_circle(c, 60, Color("5aa9e6"))
	# Cancha de fútbol
	draw_rect(CANCHA, Color("3f8f3a"))
	draw_rect(CANCHA.grow(-8), Color(1, 1, 1, 0.8), false, 3.0)
	draw_line(Vector2(CANCHA.get_center().x, CANCHA.position.y + 8), Vector2(CANCHA.get_center().x, CANCHA.end.y - 8), Color(1, 1, 1, 0.8), 3.0)
	draw_arc(CANCHA.get_center(), 30, 0, TAU, 32, Color(1, 1, 1, 0.8), 3.0)
	# Casas
	for i in range(CASAS.size()):
		_dibujar_casa(CASAS[i], COLORES_CASA[i % COLORES_CASA.size()])
	# Edificios principales
	_dibujar_edificio(RESTAURANTE, Color("8f3e32"), Color("f2b544"))
	_dibujar_edificio(MERCADO, Color("2f6f5e"), Color("e49d45"))
	_dibujar_edificio(CERVECERIA, Color("3b4a7a"), Color("f2d16b"))
	# Toldos del mercado
	for i in range(4):
		var x := MERCADO.position.x + 20 + i * 135
		for j in range(6):
			draw_rect(Rect2(x + j * 18, MERCADO.end.y - 90, 18, 14), Color("f5f0e1") if j % 2 == 0 else Color("d9534f"))
	# Autos estacionados
	for pos in [Vector2(120, 606), Vector2(880, 690), Vector2(1450, 606), Vector2(2300, 690), Vector2(1206, 300), Vector2(1290, 1000), Vector2(2100, 1156)]:
		_dibujar_auto(pos)

func _dibujar_calles() -> void:
	var banqueta := Color("c9c1ae")
	var asfalto := Color("4a4f5c")
	for calle in [AVENIDA, AVENIDA_VERTICAL, CALLE_SUR]:
		draw_rect(calle.grow(20), banqueta)
	for calle in [AVENIDA, AVENIDA_VERTICAL, CALLE_SUR]:
		draw_rect(calle, asfalto)
	var amarillo := Color("f2d16b")
	for x in range(20, int(TAMANO.x), 110):
		if x < AVENIDA_VERTICAL.position.x - 40 or x > AVENIDA_VERTICAL.end.x + 20:
			draw_rect(Rect2(x, AVENIDA.get_center().y - 4, 60, 8), amarillo)
	for y in range(20, int(TAMANO.y), 110):
		if y < AVENIDA.position.y - 40 or y > AVENIDA.end.y + 20:
			draw_rect(Rect2(AVENIDA_VERTICAL.get_center().x - 4, y, 8, 60), amarillo)
	for x in range(int(CALLE_SUR.position.x) + 40, int(TAMANO.x), 110):
		draw_rect(Rect2(x, CALLE_SUR.get_center().y - 3, 50, 6), amarillo)
	# Pasos peatonales frente a cada puerta
	for puerta_x in [RESTAURANTE.get_center().x, MERCADO.get_center().x]:
		for i in range(6):
			draw_rect(Rect2(puerta_x - 50 + i * 18, AVENIDA.position.y + 4, 10, AVENIDA.size.y - 8), Color(1, 1, 1, 0.75))
	for i in range(5):
		draw_rect(Rect2(CERVECERIA.get_center().x - 45 + i * 18, CALLE_SUR.position.y + 4, 10, CALLE_SUR.size.y - 8), Color(1, 1, 1, 0.75))

func _dibujar_edificio(rect: Rect2, pared_color: Color, acento: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(6, 8), rect.size), Color(0, 0, 0, 0.25))
	draw_rect(rect, pared_color)
	draw_rect(Rect2(rect.position.x - 10, rect.position.y - 16, rect.size.x + 20, 30), pared_color.darkened(0.35))
	draw_rect(Rect2(rect.position.x + 20, rect.position.y + 40, rect.size.x - 40, 36), Color("1b1f2a"))
	draw_rect(Rect2(rect.position.x + 20, rect.position.y + 40, rect.size.x - 40, 36), acento, false, 3.0)
	var ancho := (rect.size.x - 60) / 3.0
	for i in range(3):
		draw_rect(Rect2(rect.position.x + 30 + i * ancho, rect.position.y + 100, ancho - 16, 60), Color("9ad1e8"))
	var puerta := Rect2(rect.get_center().x - 30, rect.end.y - 70, 60, 70)
	draw_rect(puerta, Color("3b2c2a"))
	draw_rect(puerta, acento, false, 3.0)

func _dibujar_casa(rect: Rect2, color: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(5, 6), rect.size), Color(0, 0, 0, 0.2))
	draw_rect(rect, color)
	draw_rect(Rect2(rect.position.x - 6, rect.position.y - 14, rect.size.x + 12, 26), color.darkened(0.4))
	draw_rect(Rect2(rect.get_center().x - 15, rect.end.y - 50, 30, 50), Color("3b2c2a"))
	if rect.size.y > 180:
		draw_rect(Rect2(rect.position.x + 16, rect.position.y + 40, 34, 30), Color("9ad1e8"))
		draw_rect(Rect2(rect.end.x - 50, rect.position.y + 40, 34, 30), Color("9ad1e8"))

func _dibujar_auto(pos: Vector2) -> void:
	var vertical := pos.x > AVENIDA_VERTICAL.position.x - 10 and pos.x < AVENIDA_VERTICAL.end.x and (pos.y < AVENIDA.position.y or pos.y > AVENIDA.end.y)
	var tam := Vector2(24, 44) if vertical else Vector2(44, 24)
	var colores := [Color("d9534f"), Color("3fa9f5"), Color("f2d16b"), Color("5fd38d")]
	var color: Color = colores[int(pos.x + pos.y) % colores.size()]
	draw_rect(Rect2(pos, tam), color)
	draw_rect(Rect2(pos + tam * 0.25, tam * 0.5), Color("1b1f2a"))

func _decorar() -> void:
	etiqueta_mapa("LA 501 · SPORTS BAR", Vector2(RESTAURANTE.position.x + 20, RESTAURANTE.position.y + 44), RESTAURANTE.size.x - 40, UIKit.ACENTO)
	etiqueta_mapa("MERCADO CENTRAL", Vector2(MERCADO.position.x + 20, MERCADO.position.y + 44), MERCADO.size.x - 40, Color("f7c686"))
	etiqueta_mapa("CERVECERÍA LA ESQUINA", Vector2(CERVECERIA.position.x + 20, CERVECERIA.position.y + 44), CERVECERIA.size.x - 40, Color("f2d16b"))
	etiqueta_mapa("PLAZA 501", Vector2(PLAZA.position.x, PLAZA.position.y + 10), PLAZA.size.x, Color("fff0a6"))
	etiqueta_mapa("PARQUE DE LA RIBERA", Vector2(PARQUE.position.x, PARQUE.position.y + 12), PARQUE.size.x, Color("e6f5c9"))
	etiqueta_mapa("CANCHA DEL BARRIO", Vector2(CANCHA.position.x, CANCHA.position.y - 30), CANCHA.size.x, Color("e6f5c9"), 14)
	# Letrero en el cruce principal
	var letrero := etiqueta_mapa("← La 501      Mercado →\nCervecería ↘", Vector2(1330, 740), 240, UIKit.TEXTO, 13)
	letrero.add_theme_stylebox_override("normal", UIKit.estilo(Color("1b1f2a", 0.85), 6, UIKit.BORDE, 2, 6))
	# Árboles
	for x in range(80, int(TAMANO.x), 180):
		if absf(x - AVENIDA_VERTICAL.get_center().x) > 120:
			sprite("arbol" if x % 360 == 80 else "arbol_2", Vector2(x, 150), 4.0)
	var arboles_parque := [Vector2(140, 880), Vector2(320, 1000), Vector2(160, 1280), Vector2(420, 1320), Vector2(820, 880), Vector2(1020, 1000), Vector2(900, 1300), Vector2(1080, 1320), Vector2(300, 1180), Vector2(760, 1200)]
	for i in range(arboles_parque.size()):
		sprite("arbol_otono" if i % 3 == 0 else "arbol", arboles_parque[i], 4.0)
	for pos in [Vector2(2300, 1340), Vector2(1960, 1260), Vector2(2520, 800)]:
		sprite("arbol_2", pos, 3.5)
	# Bancas y faroles
	for pos in [Vector2(470, 1000), Vector2(650, 1000), Vector2(470, 1170), Vector2(650, 1170), Vector2(820, 500), Vector2(1060, 500)]:
		sprite("banca", pos, 3.0)
	for x in range(100, int(TAMANO.x), 300):
		sprite("farol", Vector2(x, AVENIDA.position.y - 22), 3.0)
	for y in range(100, int(TAMANO.y), 300):
		sprite("farol", Vector2(AVENIDA_VERTICAL.position.x - 22, y), 3.0)
	# Frente de las tiendas
	for pos in [Vector2(MERCADO.position.x - 28, 520), Vector2(MERCADO.end.x + 28, 520), Vector2(MERCADO.end.x + 28, 470)]:
		sprite("caja_frutas", pos, 3.0)
	sprite("caja_verduras", Vector2(MERCADO.position.x - 28, 470), 3.0)
	for pos in [Vector2(CERVECERIA.position.x - 28, 1100), Vector2(CERVECERIA.end.x + 28, 1100)]:
		sprite("barril", pos, 3.0)
	sprite("planta", Vector2(RESTAURANTE.position.x - 26, 520), 3.0)
	sprite("planta", Vector2(RESTAURANTE.end.x + 26, 520), 3.0)
	sprite("bote_basura", Vector2(1150, 580), 2.5)

func _crear_personajes() -> void:
	npc("vendedor_mercado", Vector2(MERCADO.get_center().x + 80, MERCADO.end.y + 18), "")
	for consejo in CONSEJOS:
		npc(consejo["sprite"], consejo["pos"], consejo["nombre"])
	var rutas: Array = [
		["cliente_1", [Vector2(60, 750), Vector2(1100, 750), Vector2(1100, 580), Vector2(60, 580)]],
		["cliente_2", [Vector2(1360, 580), Vector2(2500, 580), Vector2(2500, 750), Vector2(1360, 750)]],
		["cliente_3", [Vector2(1180, 60), Vector2(1180, 1400), Vector2(1340, 1400), Vector2(1340, 60)]],
		["cliente_vip", [Vector2(470, 960), Vector2(730, 960), Vector2(730, 1210), Vector2(470, 1210)]],
		["cliente_1", [Vector2(1360, 1130), Vector2(2520, 1130), Vector2(2520, 1260), Vector2(1360, 1260)]],
		["cliente_2", [Vector2(780, 540), Vector2(1120, 540), Vector2(1120, 250), Vector2(780, 250)]],
	]
	for ruta in rutas:
		var puntos: Array[Vector2] = []
		puntos.assign(ruta[1])
		add_child(Peaton.crear(ruta[0], puntos))

func _crear_interacciones() -> void:
	var puerta_mercado := Vector2(MERCADO.get_center().x, MERCADO.end.y + 12)
	var puerta_cerveceria := Vector2(CERVECERIA.get_center().x, CERVECERIA.end.y + 12)
	add_child(PuntoInteraccion.crear("Entrar al Mercado", puerta_mercado, _entrar_tienda.bind(Catalogo.MERCADO, puerta_mercado + Vector2(0, 30)), 50))
	add_child(PuntoInteraccion.crear("Entrar a la Cervecería", puerta_cerveceria, _entrar_tienda.bind(Catalogo.CERVECERIA, puerta_cerveceria + Vector2(0, 30)), 50))
	add_child(PuntoInteraccion.crear("Abrir La 501 (empezar la jornada)", Vector2(RESTAURANTE.get_center().x, RESTAURANTE.end.y + 12), _confirmar_restaurante, 50))
	for consejo in CONSEJOS:
		add_child(PuntoInteraccion.crear("Platicar con %s" % consejo["nombre"], consejo["pos"], _platicar.bind(consejo), 40))

func _platicar(consejo: Dictionary) -> void:
	GameState.aviso.emit("%s: %s" % [consejo["nombre"], consejo["texto"]])

func _entrar_tienda(tienda: String, regreso: Vector2) -> void:
	if terminando:
		return
	terminando = true
	GameState.tienda_actual = tienda
	GameState.posicion_pueblo = regreso
	AudioManager.sfx("click")
	GameState.cambiar_escena(GameState.ESCENA_TIENDA)

func _confirmar_restaurante() -> void:
	var mensaje := "Durante la jornada no podrás volver al pueblo; si algo se acaba tendrás que pedirlo por teléfono (más caro y tarda en llegar).\n\nAlmacén: %d unidades. ¿Abrir el restaurante?" % GameState.inventario.total_unidades()
	_dialogo.mostrar("¿Listo para el partido?", mensaje, [["Sí, abrir La 501", ir_al_restaurante], ["Todavía no", Callable()]])
