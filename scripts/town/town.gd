extends FaseManana

## Fase de mañana: el pueblo (scenes/town/town.tscn). El mapa es un TileMap (Kenney RPG Urban);
## letreros, vecinos, peatones, puertas y la cámara de Dani son nodos de la escena.
## scenes/town/mapa_pueblo.json guarda las zonas que usa el minimapa.

const DATOS_MAPA := "res://scenes/town/mapa_pueblo.json"

var tile := 48.0                        # Tamaño de un tile en pantalla (16 px × escala 3)
var tamano := Vector2(2592, 1440)
var datos := {}

## Lo que dicen los vecinos (en el mismo orden que los nodos Interacciones/Platicar...).
const CONSEJOS := [
	{"nombre": "Doña Mari", "texto": "\"Dicen que en el medio tiempo todos piden bebidas. ¡Que no te falte hielo!\""},
	{"nombre": "Profe Juve", "texto": "\"La carne, el pollo, la verdura, el pan y el hielo caducan. Compra lo que vayas a usar.\""},
	{"nombre": "Capitán del equipo", "texto": "\"Cuando metemos gol, la banda pide otra ronda. ¡Ten cerveza, refresco y Monster!\""},
]

func nombre_lugar() -> String:
	return "PUEBLO · %s" % GameState.info_nivel()["nombre"].to_upper()

func _ready() -> void:
	datos = JSON.parse_string(FileAccess.get_file_as_string(DATOS_MAPA))
	tile = float(datos["tile"]) * float(datos["escala"])
	tamano = Vector2(float(datos["columnas"]), float(datos["filas"])) * tile
	# Al volver de una tienda, Dani aparece frente a su puerta.
	if GameState.posicion_pueblo != Vector2.ZERO:
		dani.position = GameState.posicion_pueblo
	preparar_fase()
	_preparar_minimapa()

	if not GameState.intro_vista:
		_mostrar_intro.call_deferred()
	else:
		_iniciar_tutorial.call_deferred()
		if GameState.posicion_pueblo == Vector2.ZERO:
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

## El minimapa (nodo HUD/Minimapa) se llena con las zonas del JSON del mapa.
func _preparar_minimapa() -> void:
	var mapa: Minimapa = $HUD/Minimapa
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

func _mostrar_intro() -> void:
	var texto := "Dani acaba de ser contratado como nuevo gerente de La 501, un restaurante que funcionaba con libretas, mensajes de WhatsApp y la memoria del personal.\n\nSe acerca la liguilla: los insumos se acaban a media jornada, hay reservaciones duplicadas y se tira comida caducada. Tu misión es poner orden hasta la Gran Final.\n\nCada mañana recorre el pueblo y compra en el Mercado y la Cervecería; cada noche atiende el restaurante durante el partido."
	_dialogo.mostrar("ORDEN 501", texto, [["¡A poner orden!", _cerrar_intro]], false)

func _cerrar_intro() -> void:
	GameState.intro_vista = true
	GameState.guardar()
	_iniciar_tutorial()

## Jornada 1: primero los controles básicos; al volver de la tienda, cómo abrir el restaurante.
func _iniciar_tutorial() -> void:
	if GameState.tutorial_pendiente("pueblo"):
		var inicio := dani.global_position
		var pasos: Array[Dictionary] = [
			{"texto": "Muévete con W A S D o las flechas.",
				"detalle": "El minimapa (arriba a la derecha) marca La 501, el Mercado y la Cervecería. Durante el tutorial el reloj de la mañana no avanza.",
				"hecho": func() -> bool: return dani.global_position.distance_to(inicio) > 150.0},
			{"texto": "Mantén Shift mientras caminas para correr.",
				"detalle": "Correr gasta estamina (la barra azul debajo de Dani). Si se vacía se pone roja y hay que esperar a que se recupere.",
				"hecho": func() -> bool: return dani.estamina < Dani.ESTAMINA_MAX - 15.0},
			{"texto": "Presiona E para abrir la tablet.",
				"detalle": "Ahí están el aviso del partido de hoy, las reservaciones y tu stock. Se cierra con Esc.",
				"hecho": func() -> bool: return _tablet.esta_abierto()},
			{"texto": "Presiona I para ver el inventario del almacén.",
				"detalle": "La carne, el pollo, la verdura, el pan y el hielo caducan: compra solo lo que vayas a usar.",
				"hecho": func() -> bool: return _inventario.esta_abierto()},
			{"texto": "Entra al Mercado o a la Cervecería: camina hasta su puerta.",
				"detalle": "El Mercado vende lo de la cocina (carne, pollo, papas, verdura y pan); la Cervecería, las bebidas y el hielo.",
				"hecho": func() -> bool: return false},
		]
		add_child(Tutorial.crear("pueblo", pasos))
	elif GameState.tutorial_pendiente("restaurante") and GameState.tutoriales.get("tienda", false):
		var pasos: Array[Dictionary] = [
			{"texto": "Cuando termines de comprar, entra a La 501 (está marcada en el minimapa).",
				"detalle": "Revisa que tengas comida y bebidas. Objetivo de hoy: no quedarte sin stock y perder máximo 3 clientes.",
				"hecho": func() -> bool: return false},
		]
		add_child(Tutorial.crear("regreso", pasos))

# ---------------------------------------------------------------- Interacciones (señal "usado")

func _al_entrar_tienda(_dani: Node, tienda: String) -> void:
	_entrar_tienda(tienda, puerta(tienda) + Vector2(0, tile * 0.6))

func _al_entrar_restaurante(_dani: Node) -> void:
	_confirmar_restaurante()

func _al_platicar(_dani: Node, indice: int) -> void:
	_platicar(CONSEJOS[indice])

func _platicar(consejo: Dictionary) -> void:
	GameState.aviso.emit("%s: %s" % [consejo["nombre"], consejo["texto"]])

func _entrar_tienda(tienda: String, regreso: Vector2) -> void:
	if terminando:
		return
	terminando = true
	GameState.tienda_actual = tienda
	GameState.posicion_pueblo = regreso
	AudioManager.sfx("click")
	GameState.cambiar_escena(GameState.escena_tienda(tienda))

func _confirmar_restaurante() -> void:
	var mensaje := "Durante la jornada no podrás volver al pueblo; si algo se acaba tendrás que pedirlo por teléfono (más caro y tarda en llegar).\n\nAlmacén: %d unidades. ¿Abrir el restaurante?" % GameState.inventario.total_unidades()
	_dialogo.mostrar("¿Listo para el partido?", mensaje, [["Sí, abrir La 501", ir_al_restaurante], ["Todavía no", Callable()]])
