extends FaseManana

## Interior del Mercado o la Cervecería, construido con tiles de Kenney (Roguelike RPG + Indoors).
## Cada producto está en su propio mueble: Dani camina hasta él y compra ahí.

const ANCHO := 17
const ALTO := 12
const PUERTA_DESDE := 7
const PUERTA_HASTA := 9
const ORIGEN := Vector2(232, 100)

const R := Interior.RPG
const I := Interior.INDOOR

## Estantes: insumo, título, rect de tiles del mueble (sólido) y tile donde se compra.
const ESTANTES := {
	Catalogo.MERCADO: [
		{"insumo": "carne", "titulo": "CARNICERÍA", "rect": [2, 3, 4, 1], "compra": [3.5, 4.2]},
		{"insumo": "pollo", "titulo": "POLLERÍA", "rect": [7, 3, 3, 1], "compra": [8.0, 4.2]},
		{"insumo": "pan", "titulo": "PANADERÍA", "rect": [11, 3, 4, 1], "compra": [12.5, 4.2]},
		{"insumo": "papas", "titulo": "PAPAS", "rect": [1, 6, 2, 3], "compra": [3.3, 7.0]},
		{"insumo": "verdura", "titulo": "VERDURAS", "rect": [6, 6, 5, 3], "compra": [8.0, 9.2]},
	],
	Catalogo.CERVECERIA: [
		{"insumo": "cerveza", "titulo": "CERVEZAS", "rect": [1, 3, 6, 2], "compra": [4.0, 5.2]},
		{"insumo": "refresco", "titulo": "REFRESCOS", "rect": [11, 3, 5, 2], "compra": [13.0, 5.2]},
		{"insumo": "hielo", "titulo": "HIELO", "rect": [1, 8, 3, 1], "compra": [2.0, 9.2]},
		{"insumo": "monster", "titulo": "MONSTER ENERGY", "rect": [7, 6, 3, 2], "compra": [8.0, 8.2]},
	],
}
const CAJA := [12, 9, 3, 1]

var tienda := Catalogo.MERCADO
var interior: Interior
var _exhibidor: Sprite2D
var _rotacion := 0.0
var _estante: PanelTienda

func nombre_lugar() -> String:
	return "MERCADO CENTRAL" if tienda == Catalogo.MERCADO else "CERVECERÍA LA ESQUINA"

func _ready() -> void:
	tienda = GameState.tienda_actual if GameState.tienda_actual != "" else Catalogo.MERCADO
	var fondo := ColorRect.new()
	fondo.color = Color("15171f")
	fondo.size = Vector2(1280, 720)
	fondo.z_index = -20
	add_child(fondo)

	interior = Interior.new()
	interior.position = ORIGEN
	interior.z_index = -10
	add_child(interior)
	var piso := Interior.PISO_PIEDRA if tienda == Catalogo.MERCADO else Interior.PISO_MADERA
	interior.cuarto(ANCHO, ALTO, piso, PUERTA_DESDE, PUERTA_HASTA)
	if tienda == Catalogo.MERCADO:
		_amueblar_mercado()
	else:
		_amueblar_cerveceria()
	_amueblar_caja()

	for estante in ESTANTES[tienda]:
		_crear_estante(estante)
	etiqueta_mapa(nombre_lugar(), ORIGEN + Vector2(0, -2), ANCHO * Interior.LADO, UIKit.ACENTO, 20)
	add_child(PuntoInteraccion.crear("Salir al pueblo", interior.a_mundo(8, ALTO - 1.6), _salir, 36))

	crear_dani(interior.a_mundo(8, ALTO - 2.6), false)
	preparar_fase()
	# Ventana compacta para comprar un solo producto desde su estante.
	_estante = PanelTienda.new()
	_estante._producto = "compacto"
	add_child(_estante)
	GameState.aviso.emit("Acércate a cada estante y presiona Espacio para comprar.")

func _process(delta: float) -> void:
	super._process(delta)
	# La lata del refrigerador de Monster cambia de diseño cada momento.
	if _exhibidor:
		_rotacion += delta
		if _rotacion >= 1.2:
			_rotacion = 0.0
			_exhibidor.texture = AssetPaths.siguiente_diseno("monster")
			_ajustar_exhibidor()

# ---------------------------------------------------------------- Mobiliario

func _amueblar_mercado() -> void:
	# Ventanas en la pared
	for x in [4, 12]:
		interior.columna(x, 1, R, [158, 215], 0)
	# Carnicería: mostrador con carne
	interior.fila(2, 3, I, [324, 325, 325, 326])
	interior.fila(3, 3, R, [795, 795], 2)
	# Pollería: mostrador con pollo asado
	interior.fila(7, 3, I, [324, 325, 326])
	interior.fila(7, 3, R, [909, 909, 909], 2)
	# Panadería: mostrador de madera con pan
	interior.fila(11, 3, R, [295, 238, 238, 352])
	interior.fila(12, 3, R, [796, 796], 2)
	# Papas: cajas apiladas junto a barriles
	interior.columna(1, 6, R, [413, 413, 413])
	interior.columna(2, 6, R, [413, 23, 413])
	# Puesto de verduras con toldo a rayas
	interior.fila(6, 6, R, [10, 11, 10, 11, 10], 2)
	interior.fila(6, 7, R, [67, 68, 67, 68, 67], 1)
	interior.fila(6, 8, R, [356, 358, 356, 358, 356])
	# Plantas y barriles de adorno
	interior.poner(15, 3, I, 16)
	interior.poner(15, 6, R, 23)
	interior.poner(15, 7, R, 24)
	interior.solido(15, 3, 1, 1)
	interior.solido(15, 6, 1, 2)

func _amueblar_cerveceria() -> void:
	# Repisas con botellas en la pared
	interior.fila(8, 1, R, [784, 785], 0)
	interior.fila(8, 1, R, [738, 739], 2)
	interior.columna(12, 1, R, [158, 215], 0)
	# Cerveza: refrigeradores verdes y barriles
	for x in range(1, 5):
		interior.columna(x, 3, R, [207, 264])
	interior.columna(5, 3, R, [23, 24])
	interior.columna(6, 3, R, [24, 23])
	# Refresco: refrigeradores blancos de dos puertas
	interior.fila(11, 3, R, [378, 379, 378, 379], 1)
	interior.fila(11, 4, R, [435, 436, 435, 436], 1)
	interior.poner(15, 3, I, 16)
	interior.solido(15, 3, 1, 1)
	# Hielo: congeladores
	interior.fila(1, 8, R, [146, 147, 146])
	# Monster: refrigeradores negros con la lata rotando al frente
	interior.columna(7, 6, R, [208, 265])
	interior.columna(8, 6, R, [208, 265])
	interior.columna(9, 6, R, [208, 265])
	_exhibidor = Sprite2D.new()
	_exhibidor.texture = AssetPaths.siguiente_diseno("monster")
	_exhibidor.position = interior.a_mundo(8, 6.5)
	_exhibidor.z_index = 3
	add_child(_exhibidor)
	_ajustar_exhibidor()
	interior.poner(15, 8, I, 17)
	interior.solido(15, 8, 1, 1)

func _amueblar_caja() -> void:
	var x: int = CAJA[0]
	var y: int = CAJA[1]
	interior.fila(x, y, I, [405, 406, 407])
	interior.poner(x + 2, y, R, 1017, 2)
	interior.solido(x, y, CAJA[2], CAJA[3])
	var vendedor := "vendedor_mercado" if tienda == Catalogo.MERCADO else "encargado_cerveceria"
	var nombre_vendedor := "Don Chema" if tienda == Catalogo.MERCADO else "Lupita"
	npc(vendedor, interior.a_mundo(x + 1, y - 0.8), nombre_vendedor, &"down")
	add_child(PuntoInteraccion.crear("Platicar con %s" % nombre_vendedor, interior.a_mundo(x + 1, y + 1.1), _platicar, 34))

func _ajustar_exhibidor() -> void:
	if _exhibidor and _exhibidor.texture:
		var escala := 56.0 / float(_exhibidor.texture.get_height())
		_exhibidor.scale = Vector2(escala, escala)

func _crear_estante(estante: Dictionary) -> void:
	var r: Array = estante["rect"]
	interior.solido(r[0], r[1], r[2], r[3])
	var insumo: String = estante["insumo"]
	var datos: Dictionary = Catalogo.INSUMOS[insumo]
	var zona := interior.rect_mundo(r[0], r[1], r[2], r[3])
	var etiqueta := etiqueta_mapa("%s · %s" % [estante["titulo"], UIKit.dinero(datos["precio"])], Vector2(zona.position.x - 40, zona.position.y - 22), zona.size.x + 80, Color("fff0a6"), 12)
	etiqueta.z_index = 20
	var compra: Array = estante["compra"]
	var titulo := "%s · %s" % [estante["titulo"], nombre_lugar()]
	add_child(PuntoInteraccion.crear("Comprar %s" % datos["nombre"], interior.a_mundo(compra[0] - 0.5, compra[1] - 0.5), _comprar.bind(insumo, titulo), 34))

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
