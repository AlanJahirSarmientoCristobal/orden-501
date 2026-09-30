extends FaseManana

## Interior del Mercado o la Cervecería, construido con tiles de Kenney (Roguelike RPG + Indoors).
## La tienda está decorada con los productos en sus muebles; para comprar se habla con el
## vendedor de la caja, que abre un menú al estilo de Pokémon Rojo Fuego (MenuCompra).

const ANCHO := 17
const ALTO := 12
const PUERTA_DESDE := 7
const PUERTA_HASTA := 9
const ORIGEN := Vector2(232, 100)

const R := Interior.RPG
const I := Interior.INDOOR

## Muebles con productos (decoración con colisión): rect de tiles.
const ESTANTES := {
	Catalogo.MERCADO: [
		{"insumo": "carne", "titulo": "CARNICERÍA", "rect": [2, 3, 4, 1]},
		{"insumo": "pollo", "titulo": "POLLERÍA", "rect": [7, 3, 3, 1]},
		{"insumo": "pan", "titulo": "PANADERÍA", "rect": [11, 3, 4, 1]},
		{"insumo": "papas", "titulo": "PAPAS", "rect": [1, 6, 2, 3]},
		{"insumo": "verdura", "titulo": "VERDURAS", "rect": [6, 6, 5, 3]},
	],
	Catalogo.CERVECERIA: [
		{"insumo": "cerveza", "titulo": "CERVEZAS", "rect": [1, 3, 6, 2]},
		{"insumo": "refresco", "titulo": "REFRESCOS", "rect": [11, 3, 5, 2]},
		{"insumo": "hielo", "titulo": "HIELO", "rect": [1, 8, 3, 1]},
		{"insumo": "monster", "titulo": "MONSTER ENERGY", "rect": [7, 6, 3, 2]},
	],
}
const CAJA := [12, 9, 3, 1]

var tienda := Catalogo.MERCADO
var interior: Interior
var _exhibidor: Sprite2D
var _rotacion := 0.0
var _menu: MenuCompra
var _nombre_vendedor := ""
var _clave_vendedor := ""

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
		var r: Array = estante["rect"]
		interior.solido(r[0], r[1], r[2], r[3])
	etiqueta_mapa(nombre_lugar(), ORIGEN + Vector2(0, -2), ANCHO * Interior.LADO, UIKit.ACENTO, 20)
	_crear_puerta()

	crear_dani(interior.a_mundo(8, ALTO - 2.6), false)
	preparar_fase()
	_menu = MenuCompra.new()
	add_child(_menu)
	GameState.aviso.emit("Habla con %s en la caja para comprar." % _nombre_vendedor)
	if GameState.tutorial_pendiente("pueblo"):
		GameState.completar_tutorial("pueblo")
	if GameState.tutorial_pendiente("tienda"):
		_iniciar_tutorial()

## Jornada 1: cómo comprar con el menú del vendedor.
func _iniciar_tutorial() -> void:
	var inicial := GameState.inventario.total_unidades()
	var pasos: Array[Dictionary] = [
		{"texto": "Habla con %s en la caja: acércate y presiona Espacio." % _nombre_vendedor,
			"detalle": "Los muebles con productos son decoración: todo se compra en la caja.",
			"hecho": func() -> bool: return _menu.esta_abierto()},
		{"texto": "Elige un producto con W / S (o las flechas) y presiona Espacio.",
			"detalle": "Abajo ves en qué platillos se usa y cuántos días dura antes de caducar.",
			"hecho": func() -> bool: return _menu.estado == MenuCompra.Estado.CANTIDAD},
		{"texto": "Elige la cantidad y confirma con Espacio y luego «Sí».",
			"detalle": "Arriba / abajo cambia de 1 en 1 y los lados de 10 en 10. Cuida tu dinero y el espacio del almacén.",
			"hecho": func() -> bool: return GameState.inventario.total_unidades() > inicial},
		{"texto": "Compra lo que necesites y cierra el menú con SALIR o Esc.",
			"detalle": "Después sal por la puerta de abajo. Si te falta algo, visita la otra tienda.",
			"hecho": func() -> bool: return not _menu.esta_abierto()},
	]
	add_child(Tutorial.new("tienda", pasos))

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
	_clave_vendedor = vendedor
	_nombre_vendedor = "Don Chema" if tienda == Catalogo.MERCADO else "Lupita"
	npc(vendedor, interior.a_mundo(x + 1, y - 0.8), _nombre_vendedor, &"down")
	add_child(PuntoInteraccion.crear("Comprar con %s" % _nombre_vendedor, interior.a_mundo(x + 1, y + 1.1), abrir_menu, 40))

func _ajustar_exhibidor() -> void:
	if _exhibidor and _exhibidor.texture:
		var escala := 56.0 / float(_exhibidor.texture.get_height())
		_exhibidor.scale = Vector2(escala, escala)

func abrir_menu() -> void:
	_menu.abrir(tienda, _nombre_vendedor, _clave_vendedor)

## La puerta: al cruzarla Dani sale al pueblo. Detrás del hueco hay un muro para no salir al vacío.
func _crear_puerta() -> void:
	var ancho_puerta := PUERTA_HASTA - PUERTA_DESDE + 1
	interior.solido(PUERTA_DESDE, ALTO + 0.4, ancho_puerta, 1)
	var salida := Area2D.new()
	salida.collision_layer = 0
	salida.collision_mask = 2
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = Vector2(ancho_puerta, 0.5) * Interior.LADO
	forma.shape = caja
	salida.add_child(forma)
	salida.position = interior.rect_mundo(PUERTA_DESDE, ALTO - 0.2, ancho_puerta, 0.5).get_center()
	add_child(salida)
	salida.body_entered.connect(_al_cruzar_puerta)
	var letrero := etiqueta_mapa("SALIDA", interior.rect_mundo(PUERTA_DESDE, ALTO - 1, ancho_puerta, 1).position + Vector2(0, 10), ancho_puerta * Interior.LADO, UIKit.TEXTO, 12)
	letrero.z_index = 20

func _al_cruzar_puerta(cuerpo: Node) -> void:
	if cuerpo is Dani:
		_salir()

func _salir() -> void:
	if terminando:
		return
	terminando = true
	GameState.tienda_actual = ""
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)
