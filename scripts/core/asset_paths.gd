extends RefCounted
class_name AssetPaths

const TILES := "res://Assets/sprites/rpg_urban/Tiles/tile_%04d.png"

const ALTURA_PERSONAJE := -14.0
const COMIDA := "res://Assets/sprites/food_kit/Previews/%s.png"

const TEXTURAS := {
	"insumo_carne": COMIDA % "meat-raw",
	"insumo_pollo": COMIDA % "meat-cooked",
	"insumo_papas": COMIDA % "bag",
	"insumo_verdura": COMIDA % "cabbage",
	"insumo_pan": COMIDA % "bread",
	"insumo_cerveza": COMIDA % "can",
	"insumo_refresco": COMIDA % "soda-can",
	"insumo_hielo": COMIDA % "glass",
	"platillo_hamburguesa": COMIDA % "burger-cheese",
	"platillo_alitas": COMIDA % "turkey",
	"platillo_papas": COMIDA % "fries",
	"platillo_refresco": COMIDA % "soda-glass",
	"platillo_cerveza": COMIDA % "mug",
	"platillo_combo": COMIDA % "burger-double",
	"plato_sucio": COMIDA % "plate",
	"arbol": "res://Assets/sprites/rpg_urban/Tiles/tile_0260.png",
	"arbol_2": "res://Assets/sprites/rpg_urban/Tiles/tile_0292.png",
	"arbol_otono": "res://Assets/sprites/rpg_urban/Tiles/tile_0319.png",
	"banca": "res://Assets/sprites/rpg_urban/Tiles/tile_0270.png",
	"farol": "res://Assets/sprites/rpg_urban/Tiles/tile_0169.png",
	"caja_frutas": "res://Assets/sprites/rpg_urban/Tiles/tile_0276.png",
	"caja_verduras": "res://Assets/sprites/rpg_urban/Tiles/tile_0277.png",
	"barril": "res://Assets/sprites/rpg_urban/Tiles/tile_0280.png",
	"bote_basura": "res://Assets/sprites/rpg_urban/Tiles/tile_0278.png",
	"puerta": "res://Assets/sprites/rpg_urban/Tiles/tile_0283.png",
	"puerta_doble": "res://Assets/sprites/rpg_urban/Tiles/tile_0284.png",
	"refrigerador": "res://Assets/sprites/rpg_urban/Tiles/tile_0282.png",
	"planta": "res://Assets/sprites/rpg_urban/Tiles/tile_0265.png",
	"tv_1": "res://Assets/sprites/restaurante/tv_1.png",
	"tv_2": "res://Assets/sprites/restaurante/tv_2.png",
	"tv_gol": "res://Assets/sprites/restaurante/tv_gol.png",
	"neon_on": "res://Assets/sprites/restaurante/neon_on.png",
	"neon_off": "res://Assets/sprites/restaurante/neon_off.png",
}

const PERSONAJES := {
	"dani": 429,
	"chef": 267,
	"cliente_1": 24,
	"cliente_2": 105,
	"cliente_3": 186,
	"cliente_vip": 348,
	"critico": 186,
	"vendedor_mercado": 186,
	"encargado_cerveceria": 105,
	"dona_mari": 105,
	"profe_juve": 24,
	"capitan": 348,
}

const CODIGOS := {
	"dani": "player",
	"chef": "npc1",
	"vendedor_mercado": "npc2",
	"encargado_cerveceria": "npc3",
	"cliente_vip": "npc4",
	"critico": "npc5",
	"dona_mari": "npc6",
	"profe_juve": "npc7",
	"capitan": "npc8",
	"cliente_1": "npc9",
	"cliente_2": "npc10",
	"cliente_3": "npc11",
}

const HOJAS_PROPIAS := "res://Assets/sprites/personajes/%s.png"
const RETRATOS_PROPIOS := "res://Assets/sprites/personajes/retrato_%s.png"
const COLUMNAS_HOJA := 4
const FILAS_HOJA := 3

const AUDIO := {
	"musica_manana": "res://Assets/audio/musica_manana.ogg",
	"musica_jornada": "res://Assets/audio/musica_jornada.ogg",
	"pedido_listo": "res://Assets/audio/pedido_listo.ogg",
	"caja": "res://Assets/audio/caja.ogg",
	"gol": "res://Assets/audio/gol.ogg",
	"telefono": "res://Assets/audio/telefono.ogg",
	"stock_bajo": "res://Assets/audio/stock_bajo.ogg",
	"silbato": "res://Assets/audio/silbato.ogg",
}

const ROTATIVAS := {
	"monster": {"ruta": "res://Assets/sprites/monster/monster_%d.png", "cantidad": 7},
}
const COLORES_MONSTER := [
	[Color("2b2b2b"), Color("66e01f")],
	[Color("f4f4f4"), Color("c9c9c9")],
	[Color("3a3a3a"), Color("8cc8f0")],
	[Color("f28a1e"), Color("f7b36b")],
	[Color("2b2b2b"), Color("9e1414")],
	[Color("f6a8d8"), Color("fde0f2")],
	[Color("7ee62e"), Color("c8c8c8")],
]

static var _cache := {}
static var _indices_rotativos := {}

static func textura(clave: String) -> Texture2D:
	if ROTATIVAS.has(clave):
		return siguiente_diseno(clave)
	if _cache.has(clave):
		return _cache[clave]
	var ruta: String = TEXTURAS.get(clave, "")
	var tex: Texture2D = null
	if ruta != "" and ResourceLoader.exists(ruta):
		tex = load(ruta)
	_cache[clave] = tex
	return tex

static func siguiente_diseno(clave: String) -> Texture2D:
	var disenos := disenos_de(clave)
	if disenos.is_empty():
		return null
	var indice: int = _indices_rotativos.get(clave, 0)
	_indices_rotativos[clave] = (indice + 1) % disenos.size()
	return disenos[indice]

static func disenos_de(clave: String) -> Array[Texture2D]:
	var cache_clave := "disenos_" + clave
	if _cache.has(cache_clave):
		return _cache[cache_clave]
	var disenos: Array[Texture2D] = []
	var datos: Dictionary = ROTATIVAS.get(clave, {})
	for i in range(int(datos.get("cantidad", 0))):
		var ruta := str(datos["ruta"]) % (i + 1)
		if ResourceLoader.exists(ruta):
			disenos.append(load(ruta))
	if disenos.is_empty() and clave == "monster":
		for colores in COLORES_MONSTER:
			disenos.append(_lata_provisional(colores[0], colores[1]))
	_cache[cache_clave] = disenos
	return disenos

static func _lata_provisional(lata: Color, garra: Color) -> Texture2D:
	var img := Image.create(12, 20, false, Image.FORMAT_RGBA8)
	var contorno := Color("111111")
	var metal := Color("c8ccd4")
	for y in range(20):
		for x in range(12):
			var c := Color.TRANSPARENT
			if x == 0 or x == 11 or y == 0 or y == 19:
				c = contorno if (x > 0 and x < 11) or (y > 0 and y < 19) else Color.TRANSPARENT
			elif y <= 2:
				c = metal
			else:
				c = lata
				if x == 1:
					c = lata.lightened(0.25)
				var trazo := (x == 3 or x == 6 or x == 9) and y >= 5 and y <= 13
				var union := y == 5 and x >= 3 and x <= 9
				if trazo or union:
					c = garra
				if y >= 15 and y <= 16 and x >= 3 and x <= 8:
					c = lata.darkened(0.3)
			img.set_pixel(x, y, c)
	return ImageTexture.create_from_image(img)

static func limpiar_cache() -> void:
	_cache.clear()
	_indices_rotativos.clear()

static func tile(indice: int) -> Texture2D:
	var ruta := TILES % indice
	return load(ruta) if ResourceLoader.exists(ruta) else null

static func frames(clave: String) -> SpriteFrames:
	return load("res://Assets/sprites/personajes/frames/%s.tres" % clave)

static func hoja_propia(clave: String) -> Texture2D:
	var ruta := HOJAS_PROPIAS % codigo(clave)
	return load(ruta) if ResourceLoader.exists(ruta) else null

static func codigo(clave: String) -> String:
	return CODIGOS.get(clave, clave)

static func frames_personaje(clave: String) -> SpriteFrames:
	var cache_clave := "frames_" + clave
	if _cache.has(cache_clave):
		return _cache[cache_clave]
	var hoja := hoja_propia(clave)
	if hoja:
		_cache[cache_clave] = _frames_de_hoja(hoja)
		return _cache[cache_clave]
	var base: int = PERSONAJES.get(clave, PERSONAJES["cliente_1"])
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var direcciones := {&"down": 0, &"up": 1, &"side": 2}
	for anim in direcciones:
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 8.0)
		frames.set_animation_loop(anim, true)
		var columna: int = direcciones[anim]
		for fila in [0, 1, 0, 2]:
			var tex := tile(base + columna + fila * 27)
			if tex:
				frames.add_frame(anim, tex)
	_cache[cache_clave] = frames
	return frames

static func _frames_de_hoja(hoja: Texture2D) -> SpriteFrames:
	var ancho := hoja.get_width() / COLUMNAS_HOJA
	var alto := hoja.get_height() / FILAS_HOJA
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	var filas := [&"down", &"up", &"side"]
	for fila in range(FILAS_HOJA):
		var anim: StringName = filas[fila]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, 8.0)
		frames.set_animation_loop(anim, true)
		for columna in range(COLUMNAS_HOJA):
			var cuadro := AtlasTexture.new()
			cuadro.atlas = hoja
			cuadro.region = Rect2(columna * ancho, fila * alto, ancho, alto)
			frames.add_frame(anim, cuadro)
	return frames

static func retrato(clave: String) -> Texture2D:
	var propio := textura("retrato_" + clave)
	if propio:
		return propio
	var ruta_retrato := RETRATOS_PROPIOS % codigo(clave)
	if ResourceLoader.exists(ruta_retrato):
		return load(ruta_retrato)
	var hoja := hoja_propia(clave)
	if hoja:
		var cuadro := AtlasTexture.new()
		cuadro.atlas = hoja
		cuadro.region = Rect2(0, 0, hoja.get_width() / COLUMNAS_HOJA, hoja.get_height() / FILAS_HOJA)
		return cuadro
	return tile(int(PERSONAJES.get(clave, PERSONAJES["cliente_1"])))

static func audio(clave: String) -> AudioStream:
	var ruta: String = AUDIO.get(clave, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		return load(ruta)
	return null
