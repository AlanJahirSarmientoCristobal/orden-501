extends Node

## Prueba de extremo a extremo: un "bot" juega un día completo con el partido real
## (pueblo → restaurante → reporte → siguiente día) a velocidad acelerada.
## Ejecutar: godot --headless --path . res://tests/test_flujo_dia.tscn

const VELOCIDAD := 20.0
const LIMITE_SEGUNDOS := 120.0

var fallos: Array[String] = []
var _respaldo := ""
var _habia_guardado := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	_respaldar()
	# El nodo de prueba sobrevive a los cambios de escena.
	var marcador := Node.new()
	get_tree().root.add_child(marcador)
	get_tree().current_scene = marcador

	GameState.nueva_partida("facil")
	GameState.intro_vista = true
	var compras := {"carne": 10, "pollo": 14, "papas": 12, "verdura": 10, "pan": 10, "cerveza": 7, "refresco": 7, "hielo": 10}
	for insumo in compras:
		_check(GameState.comprar(insumo, compras[insumo]) == "", "No se pudo comprar %s" % insumo)
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)
	await _esperar_escena("Town")
	var pueblo := get_tree().current_scene
	_check(pueblo != null and pueblo.name == "Town", "No se abrió el pueblo")
	pueblo._ir_al_restaurante()
	await _esperar_escena("Restaurant")
	var resto := get_tree().current_scene
	_check(resto.name == "Restaurant", "No se abrió el restaurante")

	Engine.time_scale = VELOCIDAD
	var inicio := Time.get_ticks_msec()
	while is_instance_valid(resto) and get_tree().current_scene == resto:
		_jugar_un_paso(resto)
		await get_tree().process_frame
		if (Time.get_ticks_msec() - inicio) / 1000.0 > LIMITE_SEGUNDOS:
			fallos.append("La jornada no terminó a tiempo")
			break
	Engine.time_scale = 1.0
	await _esperar_escena("ClosingReport")

	var inf := GameState.ultimo_informe
	_check(not inf.is_empty(), "No hubo informe de cierre")
	if not inf.is_empty():
		var e: Dictionary = inf["estadisticas"]
		print("Informe: ventas=%d pedidos=%d perdidos=%d quiebres=%d goles=%d exito=%s rep=%d" % [e["ventas"], e["pedidos"], e["perdidos"], e["quiebres"], e["goles"], inf["exito"], int(inf["reputacion"])])
		_check(e["pedidos"] >= 5, "El bot debió entregar al menos 5 pedidos (entregó %d)" % e["pedidos"])
		_check(e["goles"] >= 1, "Debió haber al menos un gol")
		_check(inf["exito"], "Con buen servicio el nivel 1 en Fácil debe superarse")
		_check(GameState.nivel_actual == 2, "No se avanzó al nivel 2")

	get_tree().current_scene._siguiente_dia()
	await _esperar_escena("Town")
	_check(GameState.dia == 2 and GameState.reservaciones.size() == 4, "El día 2 (Liguilla) no se preparó")

	_restaurar()
	if fallos.is_empty():
		print("TEST_FLUJO_DIA: PASS")
		get_tree().quit(0)
	else:
		for f in fallos:
			push_error("TEST_FLUJO_DIA: " + f)
		get_tree().quit(1)

func _check(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)

func _esperar_escena(nombre: String) -> void:
	for i in range(600):
		var escena := get_tree().current_scene
		if escena and escena.name == nombre and escena.is_node_ready():
			await get_tree().process_frame
			return
		await get_tree().process_frame
	fallos.append("No se llegó a la escena %s" % nombre)

## El bot: toma pedidos, resuelve faltantes, recoge, sirve y limpia.
func _jugar_un_paso(resto: Node) -> void:
	if resto.terminado:
		return
	var dani: Dani = resto.dani
	# Anticipa el desabasto con pedidos urgentes, como haría un buen gerente.
	for insumo in Catalogo.INSUMOS:
		var en_camino: bool = resto.entregas.any(func(e): return e["insumo"] == insumo)
		if GameState.inventario.total(insumo) <= 5 and not en_camino:
			resto.pedir_urgente(insumo, 6)
	if resto._dialogo.esta_abierto():
		# Elige la primera opción del diálogo de faltante (sustituto si existe).
		var opcion: Array = resto._dialogo._opciones[0]
		resto._dialogo._elegir(opcion[1])
	for estacion in [resto.cocina, resto.barra]:
		if not estacion.listos.is_empty() and dani.puede_cargar():
			estacion.interactuar(dani)
	for mesa in resto.mesas:
		if mesa.estado == Mesa.EstadoMesa.SUCIA:
			mesa.interactuar(dani)
		elif mesa.cliente:
			var c: Cliente = mesa.cliente
			if c.estado == Cliente.Estado.ORDENANDO and not resto._dialogo.esta_abierto():
				mesa.interactuar(dani)
			elif c.estado == Cliente.Estado.ESPERANDO_COMIDA and dani.tiene_platillo(c.pedido):
				mesa.interactuar(dani)
	# Si la bandeja se llena con platillos sin cliente, se devuelven.
	if not dani.puede_cargar():
		resto.cocina.interactuar(dani)

func _respaldar() -> void:
	_habia_guardado = FileAccess.file_exists(GameState.SAVE_PATH)
	if _habia_guardado:
		_respaldo = FileAccess.get_file_as_string(GameState.SAVE_PATH)

func _restaurar() -> void:
	if _habia_guardado:
		var archivo := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		if archivo:
			archivo.store_string(_respaldo)
	else:
		GameState.borrar_guardado()
