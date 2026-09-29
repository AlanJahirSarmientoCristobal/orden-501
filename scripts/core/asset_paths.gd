extends RefCounted
class_name AssetPaths

## Punto único para todas las rutas de gráficos y sonidos.
## Para usar assets propios basta con cambiar la ruta aquí (o dejar el archivo con el
## mismo nombre). Si una ruta no existe, el juego dibuja un reemplazo simple.

const TILES := "res://Assets/sprites/rpg_urban/Tiles/tile_%04d.png"
const COMIDA := "res://Assets/sprites/food_kit/Previews/%s.png"

## Texturas sueltas.
const TEXTURAS := {
	# Íconos de insumos
	"insumo_carne": COMIDA % "meat-raw",
	"insumo_pollo": COMIDA % "meat-cooked",
	"insumo_papas": COMIDA % "bag",
	"insumo_verdura": COMIDA % "cabbage",
	"insumo_pan": COMIDA % "bread",
	"insumo_cerveza": COMIDA % "can",
	"insumo_refresco": COMIDA % "soda-can",
	"insumo_hielo": COMIDA % "glass",
	# Íconos de platillos
	"platillo_hamburguesa": COMIDA % "burger-cheese",
	"platillo_alitas": COMIDA % "turkey",
	"platillo_papas": COMIDA % "fries",
	"platillo_refresco": COMIDA % "soda-glass",
	"platillo_cerveza": COMIDA % "mug",
	"platillo_combo": COMIDA % "burger-double",
	"plato_sucio": COMIDA % "plate",
	# Decoración del pueblo y el restaurante (tiles Kenney RPG Urban)
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
}

## Personajes: índice del primer tile de la columna "abajo" en el tileset RPG Urban.
## Cada personaje usa 3 filas de animación y columnas abajo / arriba / lado.
const PERSONAJES := {
	"dani": 429,
	"chef": 267,
	"cliente_1": 24,
	"cliente_2": 105,
	"cliente_3": 186,
	"cliente_vip": 348,
	"vendedor_mercado": 105,
	"encargado_cerveceria": 186,
}

## Sonidos y música opcionales. Si el archivo existe se usa; si no, AudioManager
## genera un tono procedural equivalente.
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

static var _cache := {}

static func textura(clave: String) -> Texture2D:
	if _cache.has(clave):
		return _cache[clave]
	var ruta: String = TEXTURAS.get(clave, "")
	var tex: Texture2D = null
	if ruta != "" and ResourceLoader.exists(ruta):
		tex = load(ruta)
	_cache[clave] = tex
	return tex

static func tile(indice: int) -> Texture2D:
	var ruta := TILES % indice
	return load(ruta) if ResourceLoader.exists(ruta) else null

## Construye las animaciones "down", "up" y "side" de un personaje.
static func frames_personaje(clave: String) -> SpriteFrames:
	var cache_clave := "frames_" + clave
	if _cache.has(cache_clave):
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
		for fila in [0, 1, 2, 1]:
			var tex := tile(base + columna + fila * 27)
			if tex:
				frames.add_frame(anim, tex)
	_cache[cache_clave] = frames
	return frames

static func audio(clave: String) -> AudioStream:
	var ruta: String = AUDIO.get(clave, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		return load(ruta)
	return null
