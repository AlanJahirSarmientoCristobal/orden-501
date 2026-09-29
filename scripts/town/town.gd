extends FaseManana

## Fase de mañana: el pueblo, construido con TileMap (Kenney RPG Urban, mismo estilo que su Sample).
## El mapa está en scenes/town/mapa_pueblo.tscn y se puede editar en el editor de Godot;
## la ubicación de puertas y zonas se lee de scenes/town/mapa_pueblo.json.

const ESCENA_MAPA := "res://scenes/town/mapa_pueblo.tscn"
const DATOS_MAPA := "res://scenes/town/mapa_pueblo.json"

var tile := 48.0                        # Tamaño de un tile en pantalla (16 px × escala 3)
var tamano := Vector2(2592, 1440)
var datos := {}

const CONSEJOS := [
	{"nombre": "Doña Mari", "lugar": "plaza", "desfase": Vector2(0, 2.5), "sprite": "cliente_2",
		"texto": "\"Dicen que en el medio tiempo todos piden bebidas. ¡Que no te falte hielo!\""},
	{"nombre": "Profe Juve", "lugar": "parque", "desfase": Vector2(0, 4.0), "sprite": "cliente_1",
		"texto": "\"La carne, el pollo, la verdura, el pan y el hielo caducan. Compra lo que vayas a usar.\""},
	{"nombre": "Capitán del equipo", "lugar": "cancha", "desfase": Vector2(0, 0.5), "sprite": "cliente_vip",
		"texto": "\"Cuando metemos gol, la banda pide otra ronda. ¡Ten cerveza, refresco y Monster!\""},
]

func nombre_lugar() -> String:
	return "PUEBLO · %s" % GameState.info_nivel()["nombre"].to_upper()

func _ready() -> void:
	datos = JSON.parse_string(FileAccess.get_file_as_string(DATOS_MAPA))
	tile = float(datos["tile"]) * float(datos["escala"])
	tamano = Vector2(float(datos["columnas"]), float(datos["filas"])) * tile
	var mapa: Node2D = load(ESCENA_MAPA).instantiate()
	mapa.z_index = -10
	add_child(mapa)
	_crear_limites()
	_crear_letreros()
	_crear_personajes()
	_crear_interacciones()

	var inicio := GameState.posicion_pueblo if GameState.posicion_pueblo != Vector2.ZERO else _a_mundo(datos["inicio"])
	crear_dani(inicio, true, Rect2(Vector2.ZERO, tamano))
	preparar_fase()
	queue_redraw()

	if not GameState.intro_vista:
		_mostrar_intro.call_deferred()
	elif GameState.posicion_pueblo == Vector2.ZERO:
		GameState.aviso.emit("Día %d · Mañana. Recorre el pueblo y compra para: %s" % [GameState.dia, GameState.info_nivel()["nombre"]])

## Convierte coordenadas en tiles (del JSON) a píxeles del mundo.
func _a_mundo(p: Array) -> Vector2:
	return Vector2(float(p[0]), float(p[1])) * tile

func _rect(clave: String) -> Rect2:
	var r: Array = datos["lugares"][clave]["rect"]
	return Rect2(float(r[0]) * tile, float(r[1]) * tile, float(r[2]) * tile, float(r[3]) * tile)

func _rect_calle(clave: String) -> Rect2:
	var r: Array = datos["calles"][clave]
	return Rect2(float(r[0]) * tile, float(r[1]) * tile, float(r[2]) * tile, float(r[3]) * tile)

func puerta(lugar: String) -> Vector2:
	return _a_mundo(datos["lugares"][lugar]["puerta"])

func extender_hud(capa: CanvasLayer) -> void:
	var mapa := Minimapa.new()
	mapa.position = Vector2(1058, 60)
	mapa.size = Vector2(208, 116)
	mapa.tamano_mundo = tamano
	mapa.calles = [_rect_calle("avenida"), _rect_calle("avenida_vertical"), _rect_calle("calle_sur")]
	mapa.lugares = [
		{"rect": _rect("restaurante"), "color": Color("c0503f"), "nombre": "La 501"},
		{"rect": _rect("mercado"), "color": Color("3f9a80"), "nombre": "Mercado"},
		{"rect": _rect("cerveceria"), "color": Color("5a6fb0"), "nombre": "Cervecería"},
		{"rect": _rect("parque"), "color": Color("4f8f43"), "nombre": ""},
		{"rect": _rect("cancha"), "color": Color("4f8f43"), "nombre": ""},
	]
	mapa.objetivo = dani
	capa.add_child(mapa)

func _mostrar_intro() -> void:
	var texto := "Dani acaba de ser contratado como nuevo gerente de La 501, un restaurante que funcionaba con libretas, mensajes de WhatsApp y la memoria del personal.\n\nSe acerca la liguilla: los insumos se acaban a media jornada, hay reservaciones duplicadas y se tira comida caducada. Tu misión es poner orden hasta la Gran Final.\n\nCada mañana recorre el pueblo y compra en el Mercado y la Cervecería; cada noche atiende el restaurante durante el partido."
	_dialogo.mostrar("ORDEN 501", texto, [["¡A poner orden!", _cerrar_intro]], false)

func _cerrar_intro() -> void:
	GameState.intro_vista = true
	GameState.guardar()

# ---------------------------------------------------------------- Construcción

func _crear_limites() -> void:
	pared(Rect2(-40, -40, tamano.x + 80, 40))
	pared(Rect2(-40, tamano.y, tamano.x + 80, 40))
	pared(Rect2(-40, 0, 40, tamano.y))
	pared(Rect2(tamano.x, 0, 40, tamano.y))

func _draw() -> void:
	# Líneas de la cancha sobre el pasto del tilemap.
	var cancha := _rect("cancha").grow(-tile * 0.5)
	cancha.position.y += tile * 0.5
	cancha.size.y -= tile * 0.5
	var blanco := Color(1, 1, 1, 0.85)
	draw_rect(cancha, blanco, false, 4.0)
	draw_line(Vector2(cancha.get_center().x, cancha.position.y), Vector2(cancha.get_center().x, cancha.end.y), blanco, 4.0)
	draw_arc(cancha.get_center(), tile * 0.9, 0, TAU, 32, blanco, 4.0)
	for lado in [cancha.position.x, cancha.end.x - tile * 1.2]:
		draw_rect(Rect2(lado, cancha.get_center().y - tile * 0.8, tile * 1.2, tile * 1.6), blanco, false, 3.0)

func _crear_letreros() -> void:
	_letrero("LA 501 · SPORTS BAR", "restaurante", UIKit.ACENTO)
	_letrero("MERCADO CENTRAL", "mercado", Color("f7c686"))
	_letrero("CERVECERÍA LA ESQUINA", "cerveceria", Color("f2d16b"))
	var plaza := _rect("plaza")
	etiqueta_mapa("PLAZA 501", Vector2(plaza.position.x, plaza.position.y + tile * 0.2), plaza.size.x, Color("fff0a6"), 16)
	var parque := _rect("parque")
	etiqueta_mapa("PARQUE DE LA RIBERA", Vector2(parque.position.x, parque.position.y + parque.size.y * 0.5 - 70), parque.size.x, Color("e6f5c9"), 16)
	var cancha := _rect("cancha")
	etiqueta_mapa("CANCHA DEL BARRIO", Vector2(cancha.position.x, cancha.position.y + tile * 1.2), cancha.size.x, Color("e6f5c9"), 14)

func _letrero(texto: String, lugar: String, color: Color) -> void:
	var r := _rect(lugar)
	var l := etiqueta_mapa(texto, Vector2(r.position.x + tile * 0.5, r.position.y + tile * 0.9), r.size.x - tile, color, 18)
	l.add_theme_stylebox_override("normal", UIKit.estilo(Color("1b1f2a", 0.9), 4, color, 2, 4))

func _crear_personajes() -> void:
	npc("vendedor_mercado", puerta("mercado") + Vector2(tile * 2, 0), "")
	for consejo in CONSEJOS:
		npc(consejo["sprite"], _posicion_consejo(consejo), consejo["nombre"])
	# Vecinos que caminan por las banquetas.
	var av: Rect2 = _rect_calle("avenida")
	var avv: Rect2 = _rect_calle("avenida_vertical")
	var sur: Rect2 = _rect_calle("calle_sur")
	var arriba := av.position.y - tile * 0.5
	var abajo := av.end.y + tile * 0.5
	var izq := avv.position.x - tile * 0.5
	var der := avv.end.x + tile * 0.5
	var rutas: Array = [
		["cliente_1", [Vector2(tile, arriba), Vector2(izq - tile, arriba)]],
		["cliente_2", [Vector2(der + tile, abajo), Vector2(tamano.x - tile, abajo)]],
		["cliente_3", [Vector2(izq, tile), Vector2(izq, tamano.y - tile)]],
		["cliente_vip", [Vector2(der, tamano.y - tile), Vector2(der, tile)]],
		["cliente_1", [Vector2(der + tile, sur.position.y - tile * 0.5), Vector2(tamano.x - tile, sur.position.y - tile * 0.5)]],
		["cliente_2", [Vector2(tile, abajo), Vector2(izq - tile, abajo)]],
	]
	for ruta in rutas:
		var puntos: Array[Vector2] = []
		puntos.assign(ruta[1])
		add_child(Peaton.crear(ruta[0], puntos))

func _posicion_consejo(consejo: Dictionary) -> Vector2:
	var lugar: Dictionary = datos["lugares"][consejo["lugar"]]
	var centro := _rect(consejo["lugar"]).get_center()
	for clave in ["fuente", "estanque"]:
		if lugar.has(clave):
			centro = _a_mundo(lugar[clave])
	return centro + consejo["desfase"] * tile

func _crear_interacciones() -> void:
	var p_mercado := puerta("mercado")
	var p_cerveceria := puerta("cerveceria")
	add_child(PuntoInteraccion.crear("Entrar al Mercado", p_mercado, _entrar_tienda.bind(Catalogo.MERCADO, p_mercado + Vector2(0, tile * 0.6)), 44))
	add_child(PuntoInteraccion.crear("Entrar a la Cervecería", p_cerveceria, _entrar_tienda.bind(Catalogo.CERVECERIA, p_cerveceria + Vector2(0, tile * 0.6)), 44))
	add_child(PuntoInteraccion.crear("Abrir La 501 (empezar la jornada)", puerta("restaurante"), _confirmar_restaurante, 44))
	for consejo in CONSEJOS:
		add_child(PuntoInteraccion.crear("Platicar con %s" % consejo["nombre"], _posicion_consejo(consejo), _platicar.bind(consejo), 40))

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
