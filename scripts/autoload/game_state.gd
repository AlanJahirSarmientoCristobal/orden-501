extends Node

## Estado global de la partida: dificultad, día, dinero, reputación, inventario,
## reservaciones, mejoras, estadísticas de la jornada y guardado.

signal dinero_cambiado(total: int)
signal reputacion_cambiada(valor: float)
signal inventario_cambiado
signal reservaciones_cambiadas
signal aviso(mensaje: String)
signal reputacion_agotada

const SAVE_PATH := "user://orden501_save.json"

const ESCENA_MENU := "res://scenes/menu/main_menu.tscn"
const ESCENA_PUEBLO := "res://scenes/town/town.tscn"
const ESCENA_TIENDA := "res://scenes/town/store.tscn"
const ESCENA_RESTAURANTE := "res://scenes/restaurant/restaurant.tscn"
const ESCENA_REPORTE := "res://scenes/ui/closing_report.tscn"
const ESCENA_VICTORIA := "res://scenes/ui/victory.tscn"

const REPUTACION_INICIAL := 75.0
const CAPACIDAD_ALMACEN_BASE := 100
const CAPACIDAD_ALMACEN_MEJORA := 30

const NIVELES := {
	1: {"nombre": "Jornada Regular", "partido": "La 501 FC vs Deportivo Huasteco", "duracion": 150.0,
		"objetivo": "Terminar el partido sin quedarte sin stock y perdiendo máximo 3 clientes."},
	2: {"nombre": "Liguilla", "partido": "Cuartos de final: Tuzos vs Águilas", "duracion": 180.0,
		"objetivo": "Cero reservaciones duplicadas y alcanzar la meta de ventas."},
	3: {"nombre": "Gran Final", "partido": "Gran Final: La 501 FC vs Rayados de la Sierra", "duracion": 210.0,
		"objetivo": "Terminar con la reputación igual o mayor a la meta de la dificultad."},
}

const META_VENTAS := {"facil": 1000, "normal": 1200, "dificil": 1400}
const MAX_CLIENTES_PERDIDOS_N1 := 3
## Unidades a partir de las cuales se avisa de stock bajo (alcanza para una familia mientras llega el proveedor).
const STOCK_BAJO := 6

## Mejoras del reporte de cierre. "costos" tiene un precio por nivel (el segundo cuesta más).
const MEJORAS := {
	"velocidad": {"nombre": "Tenis nuevos", "descripcion": "Dani camina 15% más rápido por nivel.", "costos": [400, 800]},
	"bandeja": {"nombre": "Bandeja grande", "descripcion": "Cuarto espacio en la bandeja.", "costos": [600]},
	"cocina": {"nombre": "Parrilla industrial", "descripcion": "La cocina prepara 25% más rápido.", "costos": [650]},
	"almacen": {"nombre": "Estantes extra", "descripcion": "+30 espacios de almacén por nivel.", "costos": [350, 700]},
	"limpieza": {"nombre": "Trapeador industrial", "descripcion": "Limpiar una mesa toma 40% menos tiempo.", "costos": [500]},
	"proveedor": {"nombre": "Proveedor preferente", "descripcion": "Pedidos urgentes 30% más baratos y 30% más rápidos.", "costos": [550]},
	"promo": {"nombre": "Promoción 2x1", "descripcion": "Siguiente jornada: ~40% más clientes y cada pedido entregado da +$15 y +1% de reputación.", "costos": [300], "consumible": true},
}
const BONO_PROMO_DINERO := 15
const BONO_PROMO_REPUTACION := 1.0

const NOMBRES_RESERVA := ["Familia Hernández", "Grupo Sarmiento", "Los Cruz", "Peña Tuzos", "Oficina Castelán", "Amigos del barrio", "Familia Bautista", "Club Huasteco"]
const MINUTOS_RESERVA := [10, 20, 30, 45, 55, 65, 75]

var dificultad := ConfiguracionDificultad.NORMAL
var config: ConfiguracionDificultad = ConfiguracionDificultad.obtener(ConfiguracionDificultad.NORMAL)
var partida_activa := false
var dia := 1
var nivel_actual := 1
var nivel_desbloqueado := 1
var dinero := 0
var reputacion := REPUTACION_INICIAL
var inventario := Inventario.new()
var mejoras := {"velocidad": 0, "bandeja": 0, "cocina": 0, "almacen": 0, "limpieza": 0, "proveedor": 0, "promo": 0}
var promo_activa := false
var terraza_desbloqueada := false
var temporada_completada := false
var intro_vista := false
var modo_reto := false       # Reto Imposible: no guarda ni avanza la campaña
var tutoriales := {}         # Tutoriales de la Jornada 1 ya vistos: pueblo, tienda, regreso, restaurante
var tutoriales_habilitados := true   # Las pruebas y el bot los desactivan
var reservaciones: Array[Dictionary] = []
var estadisticas := {}
var historial: Array[Dictionary] = []
var ultimo_informe := {}
var _snapshot := {}

# Estado de la mañana: se conserva al entrar y salir de las tiendas.
var tiempo_manana := 0.0              # Segundos restantes (si la dificultad tiene límite)
var posicion_pueblo := Vector2.ZERO   # Dónde reaparece Dani al volver al pueblo (ZERO = inicio)
var tienda_actual := ""               # Catalogo.MERCADO o Catalogo.CERVECERIA

var _transicion: ColorRect

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_crear_capa_transicion()
	_configurar_controles()
	_reiniciar_estadisticas()

func _exit_tree() -> void:
	AssetPaths.limpiar_cache()

# ---------------------------------------------------------------- Partida

# ---------------------------------------------------------------- Tutoriales

## Los tutoriales solo aparecen en la Jornada 1 de la campaña, una vez cada uno.
func tutorial_pendiente(clave: String) -> bool:
	return tutoriales_habilitados and not modo_reto and nivel_actual == 1 and not tutoriales.get(clave, false)

func completar_tutorial(clave: String) -> void:
	tutoriales[clave] = true

func omitir_tutoriales() -> void:
	for clave in ["pueblo", "tienda", "regreso", "restaurante"]:
		tutoriales[clave] = true

## Mientras se aprende a moverse y a comprar, el reloj de la mañana no avanza.
func tutorial_manana_activo() -> bool:
	return tutorial_pendiente("pueblo") or tutorial_pendiente("tienda")

func nueva_partida(nueva_dificultad: String) -> void:
	modo_reto = false
	dificultad = nueva_dificultad if nueva_dificultad in ConfiguracionDificultad.TODAS else ConfiguracionDificultad.NORMAL
	config = ConfiguracionDificultad.obtener(dificultad)
	partida_activa = true
	dia = 1
	nivel_actual = 1
	nivel_desbloqueado = 1
	dinero = config.dinero_inicial
	reputacion = REPUTACION_INICIAL
	inventario = Inventario.new()
	mejoras = {"velocidad": 0, "bandeja": 0, "cocina": 0, "almacen": 0, "limpieza": 0, "proveedor": 0, "promo": 0}
	promo_activa = false
	terraza_desbloqueada = false
	temporada_completada = false
	intro_vista = false
	tutoriales = {}
	historial = []
	ultimo_informe = {}
	iniciar_manana()

## Prepara la fase de mañana del día actual y toma la "foto" para poder reiniciar la jornada.
func iniciar_manana() -> void:
	# La afición vuelve cada día: la reputación arranca en al menos 75 % (si traes más, se
	# conserva). Evita que un mal día deje la siguiente jornada imposible de ganar.
	if config.piso_reputacion:
		reputacion = maxf(reputacion, REPUTACION_INICIAL)
	_reiniciar_estadisticas()
	_generar_reservaciones()
	promo_activa = false
	tiempo_manana = config.tiempo_pueblo
	posicion_pueblo = Vector2.ZERO
	tienda_actual = ""
	_snapshot = _capturar()
	guardar()
	dinero_cambiado.emit(dinero)
	reputacion_cambiada.emit(reputacion)
	inventario_cambiado.emit()

## Reto Imposible: una Gran Final con el balance original de Difícil. No toca la partida guardada.
func iniciar_reto_imposible() -> void:
	modo_reto = true
	dificultad = ConfiguracionDificultad.IMPOSIBLE
	config = ConfiguracionDificultad.obtener(dificultad)
	partida_activa = true
	dia = 1
	nivel_actual = 3
	dinero = config.dinero_inicial
	reputacion = REPUTACION_INICIAL
	inventario = Inventario.new()
	mejoras = {"velocidad": 0, "bandeja": 0, "cocina": 0, "almacen": 0, "limpieza": 0, "proveedor": 0, "promo": 0}
	promo_activa = false
	intro_vista = true
	ultimo_informe = {}
	iniciar_manana()

## Un nivel se puede repetir desde Selección de nivel cuando ya se superó en la campaña.
func nivel_superado(nivel: int) -> bool:
	return nivel < nivel_desbloqueado or (nivel == 3 and temporada_completada)

func seleccionar_nivel(nivel: int) -> void:
	nivel_actual = clampi(nivel, 1, nivel_desbloqueado)
	iniciar_manana()

## "Reiniciar jornada": vuelve a la mañana con el dinero e inventario que tenía al inicio.
func reiniciar_jornada() -> void:
	if not _snapshot.is_empty():
		_restaurar(_snapshot)
	iniciar_manana()

func iniciar_jornada() -> void:
	promo_activa = mejoras["promo"] > 0
	if promo_activa:
		mejoras["promo"] = 0
	var compras: int = estadisticas.get("compras", 0)
	_reiniciar_estadisticas()
	estadisticas["compras"] = compras
	estadisticas["reputacion_inicial"] = reputacion

func info_nivel(nivel: int = nivel_actual) -> Dictionary:
	return NIVELES.get(nivel, NIVELES[1])

func meta_ventas() -> int:
	return int(META_VENTAS.get(dificultad, 1200))

# ---------------------------------------------------------------- Valores derivados

func duracion_partido() -> float:
	return float(info_nivel()["duracion"]) + config.duracion_extra

func precio_insumo(insumo: String) -> int:
	return int(round(float(Catalogo.INSUMOS[insumo]["precio"]) * config.precio_insumos))

func demora_urgente() -> float:
	return config.urgente_demora * (0.7 if int(mejoras["proveedor"]) > 0 else 1.0)

func costo_mejora(id: String) -> int:
	var costos: Array = MEJORAS[id]["costos"]
	var nivel := int(mejoras[id])
	return int(costos[nivel]) if nivel < costos.size() else -1

func maximo_mejora(id: String) -> int:
	return (MEJORAS[id]["costos"] as Array).size()

func capacidad_almacen() -> int:
	return CAPACIDAD_ALMACEN_BASE + CAPACIDAD_ALMACEN_MEJORA * int(mejoras["almacen"])

func espacio_libre() -> int:
	return capacidad_almacen() - inventario.total_unidades()

func capacidad_bandeja() -> int:
	return 3 + int(mejoras["bandeja"])

func multiplicador_velocidad() -> float:
	return 1.0 + 0.15 * float(mejoras["velocidad"])

func multiplicador_cocina() -> float:
	return config.multiplicador_cocina * (0.75 if int(mejoras["cocina"]) > 0 else 1.0)

func intervalo_llegada() -> float:
	# Promoción 2x1: ~40% más clientes (intervalo ÷ 1.4).
	return config.intervalo_llegada / (1.4 if promo_activa else 1.0)

func paciencia_base() -> float:
	return config.paciencia_cliente * (1.2 if nivel_actual == 1 else 1.0)

func probabilidad_vip() -> float:
	return 0.0 if nivel_actual == 1 else config.probabilidad_vip

func tiempo_limpieza() -> float:
	return config.tiempo_limpieza * (1.3 if nivel_actual == 3 else 1.0) * (0.6 if int(mejoras["limpieza"]) > 0 else 1.0)

## Tamaño del grupo que llega (1, 2 o 4), según la dificultad.
## En la Jornada Regular (nivel 1) llegan parejas, pero las familias empiezan en la Liguilla.
func tamano_grupo() -> int:
	var tirada := randf()
	var familia := config.probabilidad_familia if nivel_actual >= config.familias_desde_nivel else 0.0
	if tirada < familia:
		return 4
	if tirada < familia + config.probabilidad_pareja:
		return 2
	return 1

func probabilidad_bebida() -> float:
	return 0.55 if nivel_actual == 3 else 0.4

func numero_mesas() -> int:
	return 8 if terraza_desbloqueada else 6

## Capacidad de cada mesa (las mesas 1-3 son de 2 personas, el resto de 4).
func capacidad_mesa(numero: int) -> int:
	return 2 if numero <= 3 else 4

# ---------------------------------------------------------------- Dinero, reputación y compras

func cambiar_dinero(cantidad: int) -> void:
	dinero += cantidad
	dinero_cambiado.emit(dinero)

func cambiar_reputacion(delta: float, motivo: String = "") -> void:
	var anterior := reputacion
	reputacion = clampf(reputacion + delta, 0.0, 100.0)
	reputacion_cambiada.emit(reputacion)
	if motivo != "":
		aviso.emit("%s (%+d%% reputación)" % [motivo, int(round(delta))])
	if reputacion <= 0.0 and anterior > 0.0:
		reputacion_agotada.emit()

## Compra en la mañana. Devuelve "" si tuvo éxito o el motivo del rechazo.
func comprar(insumo: String, cantidad: int) -> String:
	if not Catalogo.INSUMOS.has(insumo) or cantidad <= 0:
		return "Producto no válido."
	var costo := precio_insumo(insumo) * cantidad
	if costo > dinero:
		return "No te alcanza el dinero."
	if cantidad > espacio_libre():
		return "No hay espacio en el almacén."
	cambiar_dinero(-costo)
	inventario.agregar(insumo, cantidad, dia)
	estadisticas["compras"] = int(estadisticas.get("compras", 0)) + costo
	inventario_cambiado.emit()
	return ""

func costo_urgente(insumo: String, cantidad: int) -> int:
	var descuento := 0.7 if int(mejoras["proveedor"]) > 0 else 1.0
	return int(ceil(float(precio_insumo(insumo) * cantidad) * config.urgente_multiplicador_costo * descuento))

## Paga un pedido urgente por teléfono. La entrega la programa el restaurante.
func pagar_urgente(insumo: String, cantidad: int) -> bool:
	var costo := costo_urgente(insumo, cantidad)
	if costo > dinero:
		aviso.emit("No hay dinero suficiente para el pedido urgente.")
		return false
	cambiar_dinero(-costo)
	estadisticas["urgentes"] += 1
	estadisticas["gasto_urgente"] += costo
	return true

func recibir_urgente(insumo: String, cantidad: int) -> void:
	inventario.agregar(insumo, cantidad, dia)
	inventario_cambiado.emit()
	aviso.emit("Llegó el proveedor: +%d %s" % [cantidad, Catalogo.nombre_insumo(insumo)])

## Consume los insumos de un platillo. Devuelve false si faltan.
func preparar(platillo: String, porciones: int = 1) -> bool:
	if inventario.consumir_receta(platillo, porciones):
		inventario_cambiado.emit()
		_revisar_stock_bajo(platillo)
		return true
	return false

## Un pedido no se pudo preparar por falta de insumos (cuenta para el Nivel 1).
func registrar_quiebre(platillo: String) -> void:
	estadisticas["quiebres"] += 1
	aviso.emit("Quiebre de stock: no alcanza para %s." % platillo)

func _revisar_stock_bajo(platillo: String) -> void:
	for insumo in Catalogo.receta(platillo):
		var restante := inventario.total(insumo)
		if restante <= STOCK_BAJO and restante + int(Catalogo.receta(platillo)[insumo]) > STOCK_BAJO:
			AudioManager.sfx("stock_bajo")
			aviso.emit("Stock bajo: %s (%d)" % [Catalogo.nombre_insumo(insumo), restante])
			return

func registrar_venta(platillo: String, propina: int, porciones: int = 1) -> void:
	var total := Catalogo.precio(platillo) * porciones + propina
	if promo_activa:
		# Promoción 2x1: los clientes atraídos dejan un bono y una buena reseña.
		total += BONO_PROMO_DINERO
		estadisticas["bono_promo"] = int(estadisticas.get("bono_promo", 0)) + BONO_PROMO_DINERO
		cambiar_reputacion(BONO_PROMO_REPUTACION)
	cambiar_dinero(total)
	estadisticas["ventas"] += total
	estadisticas["propinas"] += propina
	estadisticas["pedidos"] += 1

func registrar_estadistica(clave: String, cantidad: int = 1) -> void:
	estadisticas[clave] = int(estadisticas.get(clave, 0)) + cantidad

# ---------------------------------------------------------------- Reservaciones

func _generar_reservaciones() -> void:
	reservaciones = []
	if nivel_actual < 2:
		reservaciones_cambiadas.emit()
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = dia * 1000 + nivel_actual * 17 + ConfiguracionDificultad.TODAS.find(dificultad)
	var cantidad := 4 if nivel_actual == 2 else 6
	var minutos := MINUTOS_RESERVA.duplicate()
	for i in range(cantidad):
		# Algunos horarios se repiten a propósito para que haya que repartir mesas.
		var minuto: int = minutos[rng.randi_range(0, minutos.size() - 1)]
		reservaciones.append({
			"id": "R-%d%02d" % [nivel_actual, i + 1],
			"nombre": NOMBRES_RESERVA[rng.randi_range(0, NOMBRES_RESERVA.size() - 1)],
			"minuto": minuto,
			"personas": 2 if rng.randf() < 0.5 else 4,
			"mesa": 0,
			"estado": "pendiente",
		})
	reservaciones.sort_custom(func(a, b): return int(a["minuto"]) < int(b["minuto"]))
	reservaciones_cambiadas.emit()

func buscar_reservacion(id: String) -> Dictionary:
	for r in reservaciones:
		if r["id"] == id:
			return r
	return {}

## Asigna una mesa. Devuelve "ok", "duplicada", "capacidad" o "invalida".
func asignar_reservacion(id: String, mesa: int) -> String:
	var reserva := buscar_reservacion(id)
	if reserva.is_empty() or reserva["estado"] in ["llego", "atendida"] or mesa < 1 or mesa > numero_mesas():
		return "invalida"
	if int(reserva["personas"]) > capacidad_mesa(mesa):
		aviso.emit("La Mesa %d es para %d personas; %s son %d." % [mesa, capacidad_mesa(mesa), reserva["nombre"], reserva["personas"]])
		return "capacidad"
	for otra in reservaciones:
		if otra["id"] != id and int(otra["mesa"]) == mesa and int(otra["minuto"]) == int(reserva["minuto"]) and otra["estado"] != "atendida":
			estadisticas["duplicados"] += 1
			reserva["mesa"] = mesa
			reserva["estado"] = "asignada"
			reservaciones_cambiadas.emit()
			cambiar_reputacion(-8.0, "¡Reservación duplicada! Mesa %d a los %d'" % [mesa, reserva["minuto"]])
			AudioManager.sfx("cliente_perdido")
			return "duplicada"
	reserva["mesa"] = mesa
	reserva["estado"] = "asignada"
	reservaciones_cambiadas.emit()
	return "ok"

func reservacion_para_mesa(mesa: int, minuto_actual: float, ventana: float = 10.0) -> Dictionary:
	for r in reservaciones:
		if int(r["mesa"]) == mesa and r["estado"] == "asignada" and float(r["minuto"]) - minuto_actual <= ventana and float(r["minuto"]) + 5.0 >= minuto_actual:
			return r
	return {}

# ---------------------------------------------------------------- Cierre de jornada

func objetivo_cumplido() -> bool:
	match nivel_actual:
		1:
			return estadisticas["quiebres"] == 0 and estadisticas["perdidos"] <= MAX_CLIENTES_PERDIDOS_N1
		2:
			return estadisticas["duplicados"] == 0 and estadisticas["ventas"] >= meta_ventas()
		_:
			return reputacion >= config.reputacion_minima

func detalle_objetivo() -> Array[String]:
	var lineas: Array[String] = []
	match nivel_actual:
		1:
			lineas.append("%s Quiebres de stock: %d (máx. 0)" % [_marca(estadisticas["quiebres"] == 0), estadisticas["quiebres"]])
			lineas.append("%s Clientes perdidos: %d (máx. %d)" % [_marca(estadisticas["perdidos"] <= MAX_CLIENTES_PERDIDOS_N1), estadisticas["perdidos"], MAX_CLIENTES_PERDIDOS_N1])
		2:
			lineas.append("%s Reservaciones duplicadas: %d (máx. 0)" % [_marca(estadisticas["duplicados"] == 0), estadisticas["duplicados"]])
			lineas.append("%s Ventas: %s de %s" % [_marca(estadisticas["ventas"] >= meta_ventas()), UIKit.dinero(estadisticas["ventas"]), UIKit.dinero(meta_ventas())])
		_:
			lineas.append("%s Reputación: %d%% (meta %d%%)" % [_marca(reputacion >= config.reputacion_minima), int(reputacion), int(config.reputacion_minima)])
	return lineas

func _marca(ok: bool) -> String:
	return "✔" if ok else "✘"

## Cierra la jornada, calcula la merma nocturna y la progresión. Devuelve el informe.
func cerrar_jornada(motivo_derrota: String = "") -> Dictionary:
	var exito := motivo_derrota == "" and objetivo_cumplido()
	var nivel_jugado := nivel_actual
	var lineas_objetivo := detalle_objetivo()
	dia += 1
	var merma := inventario.retirar_caducados(dia, config.dias_caducidad)
	var costo_merma := 0
	for insumo in merma:
		costo_merma += int(merma[insumo]) * precio_insumo(insumo)
	inventario_cambiado.emit()
	ultimo_informe = {
		"dia": dia - 1,
		"nivel": nivel_jugado,
		"nombre_nivel": info_nivel(nivel_jugado)["nombre"],
		"exito": exito,
		"motivo": motivo_derrota,
		"objetivo": info_nivel(nivel_jugado)["objetivo"],
		"lineas_objetivo": lineas_objetivo,
		"estadisticas": estadisticas.duplicate(),
		"merma": merma,
		"costo_merma": costo_merma,
		"reputacion": reputacion,
		"dinero": dinero,
		"temporada_completa": false,
		"reto": modo_reto,
	}
	ultimo_informe["puntos"] = calcular_puntos(estadisticas, reputacion, costo_merma, exito)
	if exito and not modo_reto:
		historial.append(ultimo_informe)
		nivel_desbloqueado = maxi(nivel_desbloqueado, mini(nivel_jugado + 1, 3))
		if nivel_jugado >= 3:
			temporada_completada = true
			terraza_desbloqueada = true
			ultimo_informe["temporada_completa"] = true
		else:
			nivel_actual = nivel_jugado + 1
		_guardar_datos(_capturar())
	return ultimo_informe

## Puntuación de una jornada (sistema de recompensa): premia ventas, pedidos, VIP,
## reservaciones y reputación, y castiga clientes perdidos, quiebres, duplicados y merma.
const PUNTOS_JORNADA_SUPERADA := 500

func calcular_puntos(e: Dictionary, reputacion_final: float, costo_merma: int, exito: bool) -> int:
	var puntos := int(e.get("ventas", 0))
	puntos += int(e.get("pedidos", 0)) * 10
	puntos += int(e.get("vip_atendidos", 0)) * 25
	puntos += int(e.get("reservas_atendidas", 0)) * 30
	puntos += int(reputacion_final) * 10
	puntos -= int(e.get("perdidos", 0)) * 50
	puntos -= int(e.get("quiebres", 0)) * 20
	puntos -= int(e.get("duplicados", 0)) * 100
	puntos -= costo_merma
	if exito:
		puntos += PUNTOS_JORNADA_SUPERADA
	return maxi(0, puntos)

## Suma de los puntos de las jornadas superadas en la temporada.
func puntos_temporada() -> int:
	var total := 0
	for informe in historial:
		total += int(informe.get("puntos", 0))
	return total

## Compra una mejora en el reporte de cierre.
func comprar_mejora(id: String) -> bool:
	if not MEJORAS.has(id):
		return false
	var costo := costo_mejora(id)
	if costo < 0 or dinero < costo:
		return false
	cambiar_dinero(-costo)
	mejoras[id] = int(mejoras[id]) + 1
	AudioManager.sfx("mejora")
	_guardar_datos(_capturar())
	return true

func _reiniciar_estadisticas() -> void:
	estadisticas = {
		"ventas": 0, "propinas": 0, "pedidos": 0, "perdidos": 0, "quiebres": 0, "urgentes": 0,
		"gasto_urgente": 0, "sustitutos": 0, "agotados": 0, "duplicados": 0, "reservas_atendidas": 0,
		"reservas_sin_mesa": 0, "vip_atendidos": 0, "compras": 0, "goles": 0, "reputacion_inicial": reputacion,
	}

# ---------------------------------------------------------------- Guardado

func _capturar() -> Dictionary:
	return {
		"version": 1, "dificultad": dificultad, "dia": dia, "nivel_actual": nivel_actual,
		"nivel_desbloqueado": nivel_desbloqueado, "dinero": dinero, "reputacion": reputacion,
		"inventario": inventario.a_datos(), "mejoras": mejoras.duplicate(),
		"terraza": terraza_desbloqueada, "temporada_completada": temporada_completada,
		"intro_vista": intro_vista, "historial": historial.duplicate(true),
		"tutoriales": tutoriales.duplicate(),
	}

func _restaurar(datos: Dictionary) -> void:
	dificultad = str(datos.get("dificultad", ConfiguracionDificultad.NORMAL))
	config = ConfiguracionDificultad.obtener(dificultad)
	dia = int(datos.get("dia", 1))
	nivel_actual = clampi(int(datos.get("nivel_actual", 1)), 1, 3)
	nivel_desbloqueado = clampi(int(datos.get("nivel_desbloqueado", 1)), 1, 3)
	dinero = int(datos.get("dinero", config.dinero_inicial))
	reputacion = float(datos.get("reputacion", REPUTACION_INICIAL))
	inventario = Inventario.new()
	inventario.desde_datos(datos.get("inventario", []))
	var guardadas: Dictionary = datos.get("mejoras", {})
	for clave in mejoras:
		mejoras[clave] = int(guardadas.get(clave, 0))
	terraza_desbloqueada = bool(datos.get("terraza", false))
	temporada_completada = bool(datos.get("temporada_completada", false))
	intro_vista = bool(datos.get("intro_vista", false))
	tutoriales = datos.get("tutoriales", {}).duplicate()
	historial = []
	for informe in datos.get("historial", []):
		if informe is Dictionary:
			historial.append(informe)

func guardar() -> void:
	_guardar_datos(_capturar())

func _guardar_datos(datos: Dictionary) -> void:
	if modo_reto:
		return
	var archivo := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if archivo == null:
		push_warning("No se pudo guardar la partida: %s" % error_string(FileAccess.get_open_error()))
		return
	archivo.store_string(JSON.stringify(datos, "\t"))

func hay_partida_guardada() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func cargar() -> bool:
	if not hay_partida_guardada():
		return false
	var datos = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not datos is Dictionary:
		return false
	modo_reto = false
	_restaurar(datos)
	partida_activa = true
	iniciar_manana()
	return true

func borrar_guardado() -> void:
	if hay_partida_guardada():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

# ---------------------------------------------------------------- Escenas y controles

func cambiar_escena(ruta: String) -> void:
	var entrada := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	entrada.tween_property(_transicion, "color:a", 1.0, 0.25)
	await entrada.finished
	get_tree().paused = false
	get_tree().change_scene_to_file(ruta)
	var salida := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	salida.tween_property(_transicion, "color:a", 0.0, 0.25)

func _crear_capa_transicion() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 100
	add_child(capa)
	_transicion = ColorRect.new()
	_transicion.color = Color(0, 0, 0, 0)
	_transicion.set_anchors_preset(Control.PRESET_FULL_RECT)
	_transicion.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(_transicion)

func _configurar_controles() -> void:
	var acciones := {
		"mover_izquierda": [KEY_A, KEY_LEFT],
		"mover_derecha": [KEY_D, KEY_RIGHT],
		"mover_arriba": [KEY_W, KEY_UP],
		"mover_abajo": [KEY_S, KEY_DOWN],
		"interactuar": [KEY_SPACE, KEY_ENTER],
		"correr": [KEY_SHIFT],
		"tablet": [KEY_E],
		"pedido_urgente": [KEY_Q],
		"reservaciones": [KEY_R],
		"inventario": [KEY_I],
		"pausa": [KEY_ESCAPE],
	}
	for accion in acciones:
		if not InputMap.has_action(accion):
			InputMap.add_action(accion)
		for tecla in acciones[accion]:
			var evento := InputEventKey.new()
			evento.physical_keycode = tecla
			if not InputMap.action_has_event(accion, evento):
				InputMap.action_add_event(accion, evento)
