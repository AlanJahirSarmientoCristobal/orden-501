extends RefCounted
class_name ConfiguracionDificultad

const FACIL := "facil"
const NORMAL := "normal"
const DIFICIL := "dificil"
const IMPOSIBLE := "imposible"
const TODAS := [FACIL, NORMAL, DIFICIL]

var id: String
var nombre: String
var paciencia_cliente: float
var multiplicador_cocina: float
var intervalo_llegada: float
var probabilidad_vip: float
var tiempo_limpieza: float
var etiqueta_suciedad: String
var dinero_inicial: int
var urgente_multiplicador_costo: float
var urgente_demora: float
var dias_caducidad: int
var tiempo_pueblo: float
var reputacion_minima: float
var probabilidad_pareja: float
var probabilidad_familia: float
var familias_desde_nivel: int
var precio_insumos: float
var paciencia_vip: float
var paciencia_fila: float
var duracion_extra: float
var piso_reputacion: bool

const _TABLA := {
	FACIL: {
		"nombre": "Fácil", "paciencia": 60.0, "cocina": 0.8, "llegada": 12.0, "vip": 0.10,
		"limpieza": 0.8, "suciedad": "Lento", "dinero": 1500, "urg_costo": 1.5, "urg_demora": 15.0,
		"caducidad": 3, "pueblo": 0.0, "reputacion": 50.0,
		"pareja": 0.0, "familia": 0.0
	},
	NORMAL: {
		"nombre": "Normal", "paciencia": 40.0, "cocina": 1.0, "llegada": 8.0, "vip": 0.25,
		"limpieza": 1.5, "suciedad": "Normal", "dinero": 1000, "urg_costo": 2.0, "urg_demora": 25.0,
		"caducidad": 2, "pueblo": 180.0, "reputacion": 70.0,
		"pareja": 0.20, "familia": 0.10
	},
	DIFICIL: {
		"nombre": "Difícil", "paciencia": 25.0, "cocina": 1.3, "llegada": 5.0, "vip": 0.40,
		"limpieza": 2.5, "suciedad": "Rápido", "dinero": 700, "urg_costo": 3.0, "urg_demora": 40.0,
		"caducidad": 1, "pueblo": 120.0, "reputacion": 85.0,
		"pareja": 0.30, "familia": 0.15
	},
	IMPOSIBLE: {
		"nombre": "Imposible", "paciencia": 25.0, "cocina": 1.3, "llegada": 5.0, "vip": 0.40,
		"limpieza": 2.5, "suciedad": "Rápido", "dinero": 700, "urg_costo": 3.0, "urg_demora": 40.0,
		"caducidad": 1, "pueblo": 120.0, "reputacion": 85.0,
		"pareja": 0.35, "familia": 0.30, "familias_desde": 1, "precio_insumos": 1.67,
		"paciencia_vip": 0.6, "paciencia_fila": 0.5, "duracion_extra": 30.0, "piso_reputacion": false
	}
}

static func obtener(dificultad: String) -> ConfiguracionDificultad:
	var clave := dificultad if _TABLA.has(dificultad) else NORMAL
	var datos: Dictionary = _TABLA[clave]
	var config := ConfiguracionDificultad.new()
	config.id = clave
	config.nombre = datos["nombre"]
	config.paciencia_cliente = datos["paciencia"]
	config.multiplicador_cocina = datos["cocina"]
	config.intervalo_llegada = datos["llegada"]
	config.probabilidad_vip = datos["vip"]
	config.tiempo_limpieza = datos["limpieza"]
	config.etiqueta_suciedad = datos["suciedad"]
	config.dinero_inicial = datos["dinero"]
	config.urgente_multiplicador_costo = datos["urg_costo"]
	config.urgente_demora = datos["urg_demora"]
	config.dias_caducidad = datos["caducidad"]
	config.tiempo_pueblo = datos["pueblo"]
	config.reputacion_minima = datos["reputacion"]
	config.probabilidad_pareja = datos["pareja"]
	config.probabilidad_familia = datos["familia"]
	config.familias_desde_nivel = int(datos.get("familias_desde", 2))
	config.precio_insumos = float(datos.get("precio_insumos", 1.0))
	config.paciencia_vip = float(datos.get("paciencia_vip", 0.7))
	config.paciencia_fila = float(datos.get("paciencia_fila", 0.35))
	config.duracion_extra = float(datos.get("duracion_extra", 0.0))
	config.piso_reputacion = bool(datos.get("piso_reputacion", true))
	return config

func describir() -> String:
	var pueblo := "Sin límite" if tiempo_pueblo <= 0.0 else "%d min" % int(tiempo_pueblo / 60.0)
	var grupos := "Solo clientes individuales" if probabilidad_pareja + probabilidad_familia <= 0.0 else "Parejas %d%% · Familias de 4: %d%%" % [int(probabilidad_pareja * 100.0), int(probabilidad_familia * 100.0)]
	return "Paciencia %d s · Cocina ×%.1f · Cliente cada %d s · VIP %d%%\n%s\nMesas se ensucian: %s · Dinero inicial $%s\nPedido urgente ×%.1f / %d s · Caducidad %d día(s)\nTiempo en el pueblo: %s · Reputación mínima %d%%" % [
		int(paciencia_cliente), multiplicador_cocina, int(intervalo_llegada), int(probabilidad_vip * 100.0), grupos,
		etiqueta_suciedad, _miles(dinero_inicial), urgente_multiplicador_costo, int(urgente_demora),
		dias_caducidad, pueblo, int(reputacion_minima)
	]

static func _miles(valor: int) -> String:
	var texto := str(valor)
	if texto.length() > 3:
		texto = texto.substr(0, texto.length() - 3) + "," + texto.substr(texto.length() - 3)
	return texto
