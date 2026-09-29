extends RefCounted
class_name Catalogo

## Insumos, platillos, recetas y tiendas del juego.

const MERCADO := "mercado"
const CERVECERIA := "cerveceria"

const COCINA := "cocina"
const BARRA := "barra"

## Insumos: tienda donde se compran, precio por unidad y si caducan.
const INSUMOS := {
	"carne":    {"nombre": "Carne",    "tienda": MERCADO,    "precio": 20, "perecedero": true,  "icono": "insumo_carne"},
	"pollo":    {"nombre": "Pollo",    "tienda": MERCADO,    "precio": 18, "perecedero": true,  "icono": "insumo_pollo"},
	"papas":    {"nombre": "Papas",    "tienda": MERCADO,    "precio": 8,  "perecedero": false, "icono": "insumo_papas"},
	"verdura":  {"nombre": "Verdura",  "tienda": MERCADO,    "precio": 6,  "perecedero": true,  "icono": "insumo_verdura"},
	"pan":      {"nombre": "Pan",      "tienda": MERCADO,    "precio": 5,  "perecedero": true,  "icono": "insumo_pan"},
	"cerveza":  {"nombre": "Cerveza",  "tienda": CERVECERIA, "precio": 15, "perecedero": false, "icono": "insumo_cerveza"},
	"refresco": {"nombre": "Refresco", "tienda": CERVECERIA, "precio": 8,  "perecedero": false, "icono": "insumo_refresco"},
	"hielo":    {"nombre": "Hielo",    "tienda": CERVECERIA, "precio": 3,  "perecedero": true,  "icono": "insumo_hielo"},
}

const HAMBURGUESA := "Hamburguesa 501"
const ALITAS := "Alitas del Estadio"
const PAPAS := "Papas MVP"
const REFRESCO := "Refresco"
const CERVEZA := "Cerveza"
const COMBO := "Combo VIP"

## Platillos: receta, precio, estación donde se prepara/recoge y tiempo de preparación base.
const PLATILLOS := {
	HAMBURGUESA: {"receta": {"carne": 1, "pan": 1, "verdura": 1}, "precio": 90,  "estacion": COCINA, "tiempo": 5.0, "icono": "platillo_hamburguesa", "bebida": false},
	ALITAS:      {"receta": {"pollo": 2},                          "precio": 110, "estacion": COCINA, "tiempo": 6.0, "icono": "platillo_alitas",      "bebida": false},
	PAPAS:       {"receta": {"papas": 2},                          "precio": 50,  "estacion": COCINA, "tiempo": 3.5, "icono": "platillo_papas",       "bebida": false},
	REFRESCO:    {"receta": {"refresco": 1, "hielo": 1},           "precio": 30,  "estacion": BARRA,  "tiempo": 1.0, "icono": "platillo_refresco",    "bebida": true},
	CERVEZA:     {"receta": {"cerveza": 1, "hielo": 1},            "precio": 50,  "estacion": BARRA,  "tiempo": 1.0, "icono": "platillo_cerveza",     "bebida": true},
	COMBO:       {"receta": {"carne": 1, "pan": 1, "verdura": 1, "papas": 2, "cerveza": 1, "hielo": 1}, "precio": 220, "estacion": COCINA, "tiempo": 7.0, "icono": "platillo_combo", "bebida": false},
}

## Menú que piden los clientes habituales (el Combo es exclusivo de VIP).
const MENU_HABITUAL := [HAMBURGUESA, ALITAS, PAPAS, REFRESCO, CERVEZA]
const BEBIDAS := [REFRESCO, CERVEZA]

## Sustitutos que Dani puede ofrecer cuando falta un insumo (en orden de preferencia).
const SUSTITUTOS := {
	HAMBURGUESA: [ALITAS, PAPAS],
	ALITAS: [HAMBURGUESA, PAPAS],
	PAPAS: [HAMBURGUESA, ALITAS],
	REFRESCO: [CERVEZA],
	CERVEZA: [REFRESCO],
	COMBO: [HAMBURGUESA, ALITAS],
}

static func insumos_de_tienda(tienda: String) -> Array[String]:
	var lista: Array[String] = []
	for clave in INSUMOS:
		if INSUMOS[clave]["tienda"] == tienda:
			lista.append(clave)
	return lista

static func nombre_insumo(clave: String) -> String:
	return INSUMOS.get(clave, {}).get("nombre", clave)

static func receta(platillo: String) -> Dictionary:
	return PLATILLOS.get(platillo, {}).get("receta", {})

static func precio(platillo: String) -> int:
	return int(PLATILLOS.get(platillo, {}).get("precio", 0))

static func estacion(platillo: String) -> String:
	return PLATILLOS.get(platillo, {}).get("estacion", COCINA)

static func es_bebida(platillo: String) -> bool:
	return bool(PLATILLOS.get(platillo, {}).get("bebida", false))

static func icono_platillo(platillo: String) -> String:
	return PLATILLOS.get(platillo, {}).get("icono", "")
