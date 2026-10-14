extends RefCounted
class_name AssetPaths

const ALTURA_PERSONAJE := -14.0
const COMIDA := "res://Assets/sprites/comida/%s.png"

const TEXTURAS := {
	"insumo_carne": COMIDA % "insumo_carne",
	"insumo_pollo": COMIDA % "insumo_pollo",
	"insumo_papas": COMIDA % "insumo_papas",
	"insumo_verdura": COMIDA % "insumo_verdura",
	"insumo_pan": COMIDA % "insumo_pan",
	"insumo_cerveza": COMIDA % "insumo_cerveza",
	"insumo_refresco": COMIDA % "insumo_refresco",
	"insumo_hielo": COMIDA % "insumo_hielo",
	"platillo_hamburguesa": COMIDA % "platillo_hamburguesa",
	"platillo_alitas": COMIDA % "platillo_alitas",
	"platillo_papas": COMIDA % "platillo_papas",
	"platillo_refresco": COMIDA % "platillo_refresco",
	"platillo_cerveza": COMIDA % "platillo_cerveza",
	"platillo_combo": COMIDA % "platillo_combo",
	"plato_sucio": COMIDA % "plato_sucio",
	"tv_1": "res://Assets/sprites/restaurante/tv_1.png",
	"tv_2": "res://Assets/sprites/restaurante/tv_2.png",
	"tv_gol": "res://Assets/sprites/restaurante/tv_gol.png",
	"neon_on": "res://Assets/sprites/restaurante/neon_on.png",
	"neon_off": "res://Assets/sprites/restaurante/neon_off.png",
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
	_cache[cache_clave] = disenos
	return disenos

static func limpiar_cache() -> void:
	_cache.clear()
	_indices_rotativos.clear()

static func frames(clave: String) -> SpriteFrames:
	return load("res://Assets/sprites/personajes/frames/%s.tres" % clave)

static func hoja_propia(clave: String) -> Texture2D:
	var ruta := HOJAS_PROPIAS % codigo(clave)
	return load(ruta) if ResourceLoader.exists(ruta) else null

static func codigo(clave: String) -> String:
	return CODIGOS.get(clave, clave)

static func frames_personaje(clave: String) -> SpriteFrames:
	var hoja := hoja_propia(clave)
	return _frames_de_hoja(hoja) if hoja else null

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
	var ruta_retrato := RETRATOS_PROPIOS % codigo(clave)
	if ResourceLoader.exists(ruta_retrato):
		return load(ruta_retrato)
	var hoja := hoja_propia(clave)
	if hoja:
		var cuadro := AtlasTexture.new()
		cuadro.atlas = hoja
		cuadro.region = Rect2(0, 0, hoja.get_width() / COLUMNAS_HOJA, hoja.get_height() / FILAS_HOJA)
		return cuadro
	return null

static func audio(clave: String) -> AudioStream:
	var ruta: String = AUDIO.get(clave, "")
	if ruta != "" and ResourceLoader.exists(ruta):
		return load(ruta)
	return null
