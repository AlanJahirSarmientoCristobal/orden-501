extends FaseManana

## Interior del Mercado o la Cervecería. Cada producto está en su propio estante:
## Dani camina hasta él y compra ahí. La tienda es pequeña (una sola pantalla).

const CUARTO := Rect2(240, 110, 800, 560)
const PUERTA := Vector2(640, 670)

## Estantes por tienda: insumo, mueble (rect), tipo de mueble y punto de compra.
const ESTANTES := {
	Catalogo.MERCADO: [
		{"insumo": "carne", "rect": Rect2(280, 150, 200, 70), "tipo": "vitrina", "titulo": "CARNICERÍA", "compra": Vector2(380, 250)},
		{"insumo": "pollo", "rect": Rect2(540, 150, 200, 70), "tipo": "vitrina", "titulo": "POLLERÍA", "compra": Vector2(640, 250)},
		{"insumo": "pan", "rect": Rect2(800, 150, 200, 70), "tipo": "repisa", "titulo": "PANADERÍA", "compra": Vector2(900, 250)},
		{"insumo": "papas", "rect": Rect2(280, 350, 90, 170), "tipo": "costales", "titulo": "PAPAS", "compra": Vector2(410, 435)},
		{"insumo": "verdura", "rect": Rect2(540, 360, 200, 90), "tipo": "puesto", "titulo": "VERDURAS", "compra": Vector2(640, 485)},
	],
	Catalogo.CERVECERIA: [
		{"insumo": "cerveza", "rect": Rect2(280, 150, 300, 70), "tipo": "refri", "titulo": "CERVEZAS", "compra": Vector2(430, 250)},
		{"insumo": "refresco", "rect": Rect2(960, 180, 60, 240), "tipo": "refri_lateral", "titulo": "REFRESCOS", "compra": Vector2(910, 300)},
		{"insumo": "hielo", "rect": Rect2(280, 470, 150, 70), "tipo": "congelador", "titulo": "HIELO", "compra": Vector2(355, 580)},
		{"insumo": "monster", "rect": Rect2(590, 330, 100, 90), "tipo": "exhibidor", "titulo": "MONSTER ENERGY", "compra": Vector2(640, 460)},
	],
}

const CAJA := Rect2(840, 550, 140, 50)

var tienda := Catalogo.MERCADO
var _exhibidor: Sprite2D
var _estante: PanelTienda
var _rotacion := 0.0

func nombre_lugar() -> String:
	return "MERCADO CENTRAL" if tienda == Catalogo.MERCADO else "CERVECERÍA LA ESQUINA"

func _ready() -> void:
	tienda = GameState.tienda_actual if GameState.tienda_actual != "" else Catalogo.MERCADO
	_crear_paredes()
	for estante in ESTANTES[tienda]:
		_crear_estante(estante)
	pared(CAJA)
	var vendedor := "vendedor_mercado" if tienda == Catalogo.MERCADO else "encargado_cerveceria"
	var nombre_vendedor := "Don Chema" if tienda == Catalogo.MERCADO else "Lupita"
	npc(vendedor, Vector2(CAJA.get_center().x, CAJA.position.y - 22), nombre_vendedor, &"down")
	etiqueta_mapa("CAJA", Vector2(CAJA.position.x, CAJA.position.y + 12), CAJA.size.x, UIKit.TEXTO, 12)
	add_child(PuntoInteraccion.crear("Platicar con %s" % nombre_vendedor, Vector2(CAJA.get_center().x, CAJA.end.y + 22), _platicar, 36))
	add_child(PuntoInteraccion.crear("Salir al pueblo", PUERTA + Vector2(0, -24), _salir, 36))
	etiqueta_mapa(nombre_lugar(), Vector2(CUARTO.position.x, CUARTO.position.y - 44), CUARTO.size.x, UIKit.ACENTO, 20)

	crear_dani(PUERTA + Vector2(0, -60), false)
	preparar_fase()
	# Ventana compacta para comprar un solo producto desde su estante.
	_estante = PanelTienda.new()
	_estante._producto = "compacto"
	add_child(_estante)
	queue_redraw()
	GameState.aviso.emit("Acércate a cada estante y presiona Espacio para comprar.")

func _process(delta: float) -> void:
	super._process(delta)
	# La lata del exhibidor cambia de diseño cada momento.
	if _exhibidor:
		_rotacion += delta
		if _rotacion >= 1.2:
			_rotacion = 0.0
			_exhibidor.texture = AssetPaths.siguiente_diseno("monster")
			_ajustar_exhibidor()

func _ajustar_exhibidor() -> void:
	if _exhibidor.texture:
		var escala := 70.0 / float(_exhibidor.texture.get_height())
		_exhibidor.scale = Vector2(escala, escala)

func _crear_paredes() -> void:
	var grosor := 30.0
	pared(Rect2(CUARTO.position.x - grosor, CUARTO.position.y - grosor, CUARTO.size.x + grosor * 2, grosor))
	pared(Rect2(CUARTO.position.x - grosor, CUARTO.position.y, grosor, CUARTO.size.y + grosor))
	pared(Rect2(CUARTO.end.x, CUARTO.position.y, grosor, CUARTO.size.y + grosor))
	pared(Rect2(CUARTO.position.x, CUARTO.end.y, PUERTA.x - 50 - CUARTO.position.x, grosor))
	pared(Rect2(PUERTA.x + 50, CUARTO.end.y, CUARTO.end.x - PUERTA.x - 50, grosor))
	pared(Rect2(PUERTA.x - 50, CUARTO.end.y + 20, 100, grosor))

func _crear_estante(estante: Dictionary) -> void:
	var rect: Rect2 = estante["rect"]
	var insumo: String = estante["insumo"]
	pared(rect)
	var datos: Dictionary = Catalogo.INSUMOS[insumo]
	# Productos exhibidos en el mueble.
	if estante["tipo"] == "exhibidor":
		_exhibidor = Sprite2D.new()
		_exhibidor.texture = AssetPaths.siguiente_diseno("monster")
		_exhibidor.position = rect.get_center() + Vector2(0, -6)
		_exhibidor.z_index = 3
		add_child(_exhibidor)
		_ajustar_exhibidor()
	else:
		var vertical: bool = rect.size.y > rect.size.x
		var cantidad := 3 if vertical else int(rect.size.x / 44.0)
		for i in range(cantidad):
			var icono := Sprite2D.new()
			icono.texture = AssetPaths.textura(datos["icono"])
			if icono.texture:
				var escala := 30.0 / float(icono.texture.get_width())
				icono.scale = Vector2(escala, escala)
			icono.position = rect.position + (Vector2(rect.size.x * 0.5, 40 + i * 55) if vertical else Vector2(26 + i * 44, rect.size.y * 0.5))
			icono.z_index = 3
			add_child(icono)
	var etiqueta_pos := Vector2(rect.position.x - 30, rect.end.y + 2)
	var etiqueta := etiqueta_mapa("%s · %s" % [estante["titulo"], UIKit.dinero(datos["precio"])], etiqueta_pos, rect.size.x + 60, Color("fff0a6"), 12)
	if rect.size.y > rect.size.x:
		etiqueta.position = Vector2(rect.position.x - 100, rect.position.y - 26)
		etiqueta.size.x = 200
	var titulo := "%s · %s" % [estante["titulo"], nombre_lugar()]
	add_child(PuntoInteraccion.crear("Comprar %s" % datos["nombre"], estante["compra"], _comprar.bind(insumo, titulo), 34))

func _comprar(insumo: String, titulo: String) -> void:
	_estante.abrir_producto(insumo, titulo)

func _platicar() -> void:
	GameState.aviso.emit(PanelTienda.SALUDOS.get(tienda, ""))

func _salir() -> void:
	if terminando:
		return
	terminando = true
	GameState.tienda_actual = ""
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("15171f"))
	# Piso
	var claro := Color("d8cfb8") if tienda == Catalogo.MERCADO else Color("6b4a2b")
	var oscuro := Color("c4b99d") if tienda == Catalogo.MERCADO else Color("5e4025")
	for x in range(int(CUARTO.position.x), int(CUARTO.end.x), 40):
		for y in range(int(CUARTO.position.y), int(CUARTO.end.y), 40):
			var par := (int((x - CUARTO.position.x) / 40) + int((y - CUARTO.position.y) / 40)) % 2 == 0
			draw_rect(Rect2(x, y, 40, 40), claro if par else oscuro)
	# Paredes
	var pared_color := Color("2f6f5e") if tienda == Catalogo.MERCADO else Color("3b4a7a")
	draw_rect(Rect2(CUARTO.position.x - 30, CUARTO.position.y - 30, CUARTO.size.x + 60, 30), pared_color)
	draw_rect(Rect2(CUARTO.position.x - 30, CUARTO.position.y, 30, CUARTO.size.y + 30), pared_color.darkened(0.2))
	draw_rect(Rect2(CUARTO.end.x, CUARTO.position.y, 30, CUARTO.size.y + 30), pared_color.darkened(0.2))
	draw_rect(Rect2(CUARTO.position.x, CUARTO.end.y, PUERTA.x - 50 - CUARTO.position.x, 20), pared_color.darkened(0.2))
	draw_rect(Rect2(PUERTA.x + 50, CUARTO.end.y, CUARTO.end.x - PUERTA.x - 50, 20), pared_color.darkened(0.2))
	# Tapete de la entrada
	draw_rect(Rect2(PUERTA.x - 45, CUARTO.end.y - 30, 90, 30), Color("a33b3b"))
	# Caja registradora
	draw_rect(CAJA, Color("8a5a34"))
	draw_rect(CAJA, Color("5a3a20"), false, 3.0)
	draw_rect(Rect2(CAJA.position.x + 90, CAJA.position.y + 8, 36, 22), Color("2b2b33"))
	for estante in ESTANTES[tienda]:
		_dibujar_mueble(estante["rect"], estante["tipo"])

func _dibujar_mueble(rect: Rect2, tipo: String) -> void:
	draw_rect(Rect2(rect.position + Vector2(4, 6), rect.size), Color(0, 0, 0, 0.25))
	match tipo:
		"vitrina":
			draw_rect(rect, Color("dfe6ee"))
			draw_rect(rect.grow(-6), Color("a9d6f0"))
			draw_rect(rect, Color("6c7a8c"), false, 3.0)
		"repisa":
			draw_rect(rect, Color("a0652f"))
			for i in range(3):
				draw_line(Vector2(rect.position.x, rect.position.y + 18 + i * 18), Vector2(rect.end.x, rect.position.y + 18 + i * 18), Color("5a3a20"), 3.0)
		"costales":
			draw_rect(rect, Color("8a6a3a"))
			for i in range(3):
				draw_circle(rect.position + Vector2(rect.size.x * 0.5, 40 + i * 55), 30, Color("c9a26b"))
		"puesto":
			draw_rect(rect, Color("7a4f2e"))
			for j in range(int(rect.size.x / 20.0)):
				draw_rect(Rect2(rect.position.x + j * 20, rect.position.y - 14, 20, 14), Color("f5f0e1") if j % 2 == 0 else Color("5fd38d"))
		"refri", "refri_lateral":
			draw_rect(rect, Color("d9dde3"))
			draw_rect(rect.grow(-5), Color("7fc4e8"))
			draw_rect(rect, Color("5a6470"), false, 3.0)
		"congelador":
			draw_rect(rect, Color("f4f7fa"))
			draw_rect(rect.grow(-6), Color("cdeeff"))
			draw_rect(rect, Color("8fa3b5"), false, 3.0)
		"exhibidor":
			draw_rect(rect, Color("111111"))
			draw_rect(rect.grow(-4), Color("1d1d1d"))
			draw_rect(rect, Color("66e01f"), false, 3.0)
