extends Node2D
class_name Interior

## Construye interiores con tiles de Kenney (Roguelike RPG Pack + Roguelike Indoors):
## paredes color crema, pisos, muebles y colisiones. Cada tile mide 16 px y se dibuja a escala 3.
##
## Uso típico:
##   var interior := Interior.new()
##   interior.position = origen
##   add_child(interior)
##   interior.cuarto(17, 12, Interior.PISO_MADERA, 7, 9)
##   interior.poner(4, 5, Interior.INDOOR, 324)
##   interior.solido(4, 5, 3, 1)

const RPG := "rpg"
const INDOOR := "indoor"

const FUENTES := {
	RPG: {"ruta": "res://Assets/sprites/interiores/roguelike_rpg.png", "columnas": 57, "id": 0},
	INDOOR: {"ruta": "res://Assets/sprites/interiores/roguelike_indoor.png", "columnas": 27, "id": 1},
}

const ESCALA := 3.0
const TAM := 16
const LADO := TAM * ESCALA        # 48 px en pantalla

# Piezas del RPG Pack (mismas que usa su mapa de ejemplo "sample_indoor")
const PISO_MADERA := 119
const PISO_PIEDRA := 120
const PISO_CLARO := 121
const BORDE_SUP := [700, 698, 701]         # esquina izq, tramo, esquina der
const BORDE_LADO := 756
const BORDE_INF := [757, 698, 758]
const BORDE_INF_CORTE := [699, 697]        # remates junto a la puerta (fin izq, inicio der)
const PARED_ALTA := 873
const PARED_BAJA := 868

static var _tileset: TileSet
static var _texturas := {}

var suelo: TileMapLayer
var objetos: TileMapLayer
var encima: TileMapLayer

func _init() -> void:
	suelo = _capa("Suelo", 0)
	objetos = _capa("Objetos", 1)
	encima = _capa("Encima", 2)

func _capa(nombre: String, z: int) -> TileMapLayer:
	var capa := TileMapLayer.new()
	capa.name = nombre
	capa.tile_set = tileset()
	capa.scale = Vector2(ESCALA, ESCALA)
	capa.z_index = z
	add_child(capa)
	return capa

## TileSet compartido con las dos hojas (se crea una sola vez).
static func tileset() -> TileSet:
	if _tileset:
		return _tileset
	_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(TAM, TAM)
	for clave in FUENTES:
		var datos: Dictionary = FUENTES[clave]
		var fuente := TileSetAtlasSource.new()
		fuente.texture = load(datos["ruta"])
		fuente.texture_region_size = Vector2i(TAM, TAM)
		fuente.separation = Vector2i(1, 1)
		var columnas: int = datos["columnas"]
		var filas := int((fuente.texture.get_height() + 1) / (TAM + 1))
		for fila in range(filas):
			for col in range(columnas):
				fuente.create_tile(Vector2i(col, fila))
		_tileset.add_source(fuente, datos["id"])
	return _tileset

## Textura de un solo tile (para sprites sueltos, por ejemplo las mesas del restaurante).
static func textura(fuente: String, id: int) -> AtlasTexture:
	var clave := "%s_%d" % [fuente, id]
	if _texturas.has(clave):
		return _texturas[clave]
	var datos: Dictionary = FUENTES[fuente]
	var columnas: int = datos["columnas"]
	var tex := AtlasTexture.new()
	tex.atlas = load(datos["ruta"])
	tex.region = Rect2((id % columnas) * (TAM + 1), (id / columnas) * (TAM + 1), TAM, TAM)
	_texturas[clave] = tex
	return tex

static func limpiar_cache() -> void:
	_texturas.clear()
	_tileset = null

func _coords(fuente: String, id: int) -> Vector2i:
	var columnas: int = FUENTES[fuente]["columnas"]
	return Vector2i(id % columnas, id / columnas)

## Coloca un tile. capa: 0 = suelo, 1 = objetos, 2 = encima (se dibuja sobre los objetos).
func poner(x: int, y: int, fuente: String, id: int, capa: int = 1) -> void:
	var destino: TileMapLayer = [suelo, objetos, encima][capa]
	destino.set_cell(Vector2i(x, y), FUENTES[fuente]["id"], _coords(fuente, id))

func fila(x: int, y: int, fuente: String, ids: Array, capa: int = 1) -> void:
	for i in range(ids.size()):
		if int(ids[i]) >= 0:
			poner(x + i, y, fuente, int(ids[i]), capa)

func columna(x: int, y: int, fuente: String, ids: Array, capa: int = 1) -> void:
	for i in range(ids.size()):
		if int(ids[i]) >= 0:
			poner(x, y + i, fuente, int(ids[i]), capa)

func rellenar(x: int, y: int, ancho: int, alto: int, fuente: String, id: int, capa: int = 0) -> void:
	for fy in range(alto):
		for fx in range(ancho):
			poner(x + fx, y + fy, fuente, id, capa)

## Cuarto rectangular: borde grueso, pared de 2 filas, piso y puerta en el borde inferior
## (columnas puerta_desde..puerta_hasta). Agrega las colisiones de las paredes.
func cuarto(ancho: int, alto: int, piso: int, puerta_desde: int, puerta_hasta: int) -> void:
	# Borde superior y paredes
	poner(0, 0, RPG, BORDE_SUP[0], 0)
	for x in range(1, ancho - 1):
		poner(x, 0, RPG, BORDE_SUP[1], 0)
	poner(ancho - 1, 0, RPG, BORDE_SUP[2], 0)
	for x in range(1, ancho - 1):
		poner(x, 1, RPG, PARED_ALTA, 0)
		poner(x, 2, RPG, PARED_BAJA, 0)
	# Laterales y piso
	for y in range(1, alto - 1):
		poner(0, y, RPG, BORDE_LADO, 0)
		poner(ancho - 1, y, RPG, BORDE_LADO, 0)
	rellenar(1, 3, ancho - 2, alto - 4, RPG, piso)
	# Borde inferior con la puerta
	poner(0, alto - 1, RPG, BORDE_INF[0], 0)
	poner(ancho - 1, alto - 1, RPG, BORDE_INF[2], 0)
	for x in range(1, ancho - 1):
		if x >= puerta_desde and x <= puerta_hasta:
			poner(x, alto - 1, RPG, piso, 0)
		elif x == puerta_desde - 1:
			poner(x, alto - 1, RPG, BORDE_INF_CORTE[0], 0)
		elif x == puerta_hasta + 1:
			poner(x, alto - 1, RPG, BORDE_INF_CORTE[1], 0)
		else:
			poner(x, alto - 1, RPG, BORDE_INF[1], 0)
	# Colisiones: pared superior (bordes + 2 filas de pared), laterales e inferior
	solido(0, 0, ancho, 3)
	solido(0, 0, 1, alto)
	solido(ancho - 1, 0, 1, alto)
	solido(0, alto - 1, puerta_desde, 1)
	solido(puerta_hasta + 1, alto - 1, ancho - puerta_hasta - 1, 1)

## Bloque sólido en coordenadas de tile.
func solido(x: float, y: float, ancho: float, alto: float) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.collision_layer = 1
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = Vector2(ancho, alto) * LADO
	forma.shape = caja
	cuerpo.position = (Vector2(x, y) + Vector2(ancho, alto) * 0.5) * LADO
	cuerpo.add_child(forma)
	add_child(cuerpo)

## Centro de un tile en coordenadas globales.
func a_mundo(x: float, y: float) -> Vector2:
	return global_position + (Vector2(x, y) + Vector2(0.5, 0.5)) * LADO

## Rectángulo de tiles en coordenadas globales.
func rect_mundo(x: float, y: float, ancho: float, alto: float) -> Rect2:
	return Rect2(global_position + Vector2(x, y) * LADO, Vector2(ancho, alto) * LADO)
