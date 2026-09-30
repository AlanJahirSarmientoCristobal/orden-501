extends Node

## Simulador de balance: un "jugador" automático juega la temporada completa respetando
## las limitaciones reales de Dani (camina a su velocidad, usa sprint con estamina,
## mantiene Espacio para limpiar, carga máximo 3 platillos y tarda en decidir).
## No es una prueba de pasa/falla: imprime las estadísticas de cada jornada.
##
## Uso: godot --headless --path . res://tests/simulador_partida.tscn -- <dificultad> [intentos]
## Para verlo jugar (con ventana): godot --path . res://tests/simulador_partida.tscn -- dificil 3 ver
## En modo "ver" muestra la mañana (pueblo y compras), la jornada a x2 y el reporte de cierre.

const VELOCIDAD_SIM := 12.0          # Engine.time_scale durante la jornada
const VELOCIDAD_VER := 2.0           # Engine.time_scale en modo "ver"
const ALCANCE := 70.0                # distancia a la que Dani puede interactuar
const REACCION := 0.35               # segundos que tarda el jugador entre acciones
const DECISION_DIALOGO := 1.2        # segundos para leer y elegir en el diálogo de faltantes

var dificultad := "dificil"
var intentos_por_nivel := 2
var resultados: Array[Dictionary] = []
var _respaldo := ""
var _habia_guardado := false

# Estado del jugador simulado
var _accion := {}
var _espera := 0.0
var _urgentes_recientes := {}

# Modo "ver"
var ver := false
var _estado: Label
var _compras: Dictionary = {}

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		dificultad = args[0]
	if args.size() > 1:
		intentos_por_nivel = int(args[1])
	ver = args.size() > 2 and args[2] == "ver"
	if ver:
		_crear_estado()
	_run.call_deferred()

func _crear_estado() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 90
	add_child(capa)
	var panel := UIKit.panel(Color(0.05, 0.07, 0.1, 0.88), UIKit.ACENTO, 8)
	panel.position = Vector2(340, 664)
	panel.size = Vector2(600, 44)
	_estado = UIKit.etiqueta("", 16, UIKit.ACENTO, true)
	panel.add_child(_estado)
	capa.add_child(panel)

func _mostrar_estado(texto: String) -> void:
	if _estado:
		_estado.text = texto
		print("BOT ", texto)

func _run() -> void:
	_habia_guardado = FileAccess.file_exists(GameState.SAVE_PATH)
	if _habia_guardado:
		_respaldo = FileAccess.get_file_as_string(GameState.SAVE_PATH)
	var marcador := Node.new()
	get_tree().root.add_child(marcador)
	get_tree().current_scene = marcador

	if dificultad == ConfiguracionDificultad.IMPOSIBLE:
		await _jugar_reto()
		return
	GameState.nueva_partida(dificultad)
	GameState.intro_vista = true
	var nivel_maximo := 0
	while GameState.nivel_actual <= 3 and not GameState.temporada_completada:
		var nivel := GameState.nivel_actual
		var superado := false
		for intento in range(intentos_por_nivel):
			if intento > 0:
				GameState.reiniciar_jornada()
			_mostrar_estado("BOT · %s · Nivel %d: %s · intento %d · MAÑANA" % [GameState.config.nombre.to_upper(), nivel, GameState.info_nivel()["nombre"], intento + 1])
			_compras_de_la_manana()
			_asignar_reservaciones()
			await _ver_manana()
			_mostrar_estado("BOT · %s · Nivel %d: %s · intento %d · JORNADA x%d" % [GameState.config.nombre.to_upper(), nivel, GameState.info_nivel()["nombre"], intento + 1, int(VELOCIDAD_VER)])
			GameState.iniciar_jornada()
			var informe: Dictionary = await _jugar_jornada()
			var e: Dictionary = informe["estadisticas"]
			var fila := {
				"nivel": nivel, "intento": intento + 1, "exito": informe["exito"],
				"ventas": e["ventas"], "pedidos": e["pedidos"], "perdidos": e["perdidos"],
				"quiebres": e["quiebres"], "urgentes": e["urgentes"], "rep": int(informe["reputacion"]),
				"dinero": GameState.dinero, "motivo": informe["motivo"],
			}
			resultados.append(fila)
			print("RESULTADO ", JSON.stringify(fila))
			if informe["exito"]:
				superado = true
				nivel_maximo = nivel
				var antes := GameState.mejoras.duplicate()
				_comprar_mejoras()
				if ver:
					var nuevas: Array[String] = []
					for id in GameState.mejoras:
						if GameState.mejoras[id] != antes.get(id):
							nuevas.append(str(GameState.MEJORAS[id]["nombre"]))
					_mostrar_estado("¡Nivel %d superado! Mejoras: %s" % [nivel, ", ".join(nuevas) if not nuevas.is_empty() else "ninguna"])
					await get_tree().create_timer(3.0).timeout
				if not GameState.temporada_completada:
					GameState.iniciar_manana()
				break
		if not superado:
			break
	print("RESUMEN dificultad=%s nivel_maximo_superado=%d" % [dificultad, nivel_maximo])
	if ver:
		_mostrar_estado("FIN · %s · niveles superados: %d de 3" % [GameState.config.nombre.to_upper(), nivel_maximo])
		if GameState.temporada_completada:
			var victoria: Node = load(GameState.ESCENA_VICTORIA).instantiate()
			add_child(victoria)
		await get_tree().create_timer(10.0).timeout
	if _habia_guardado:
		var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		f.store_string(_respaldo)
	else:
		GameState.borrar_guardado()
	get_tree().quit(0)

## Reto Imposible: una sola Gran Final, con reintentos.
func _jugar_reto() -> void:
	GameState.iniciar_reto_imposible()
	for intento in range(intentos_por_nivel):
		if intento > 0:
			GameState.iniciar_reto_imposible()
		_compras_de_la_manana()
		_asignar_reservaciones()
		GameState.iniciar_jornada()
		var informe: Dictionary = await _jugar_jornada()
		var e: Dictionary = informe["estadisticas"]
		var fila := {"nivel": "RETO", "intento": intento + 1, "exito": informe["exito"], "ventas": e["ventas"],
			"pedidos": e["pedidos"], "perdidos": e["perdidos"], "quiebres": e["quiebres"], "rep": int(informe["reputacion"])}
		print("RESULTADO ", JSON.stringify(fila))
	print("RESUMEN dificultad=imposible")
	if _habia_guardado:
		var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		f.store_string(_respaldo)
	get_tree().quit(0)

# ---------------------------------------------------------------- Mañana

## Compra razonable: estima la demanda del partido y reparte dinero y almacén,
## guardando una reserva para pedidos urgentes.
func _compras_de_la_manana() -> void:
	var config := GameState.config
	var llegadas := GameState.duracion_partido() * (85.0 / 90.0) / GameState.intervalo_llegada() + 2 + GameState.nivel_actual
	var personas_promedio := 1.0 + config.probabilidad_pareja * 1.0 + config.probabilidad_familia * 3.0
	var porciones := llegadas * personas_promedio * 1.15      # rondas extra por goles
	var bebida := GameState.probabilidad_bebida() + 0.1
	var comida := 1.0 - bebida
	var demanda := {}
	for platillo in [Catalogo.HAMBURGUESA, Catalogo.ALITAS, Catalogo.PAPAS]:
		_sumar_receta(demanda, platillo, porciones * comida / 3.0)
	for platillo in Catalogo.BEBIDAS:
		_sumar_receta(demanda, platillo, porciones * bebida / 3.0)
	if GameState.nivel_actual >= 2:
		_sumar_receta(demanda, Catalogo.COMBO, llegadas * GameState.probabilidad_vip())
	# Resta lo que ya hay en el almacén
	for insumo in demanda:
		demanda[insumo] = maxf(0.0, demanda[insumo] - GameState.inventario.total(insumo))
	var reserva := int(GameState.dinero * 0.10)
	var presupuesto := GameState.dinero - reserva
	var total_unidades := 0.0
	var costo_total := 0.0
	for insumo in demanda:
		total_unidades += demanda[insumo]
		costo_total += demanda[insumo] * GameState.precio_insumo(insumo)
	var factor := minf(1.0, minf(float(GameState.espacio_libre()) / maxf(1.0, total_unidades), float(presupuesto) / maxf(1.0, costo_total)))
	for insumo in demanda:
		var cantidad := int(floor(demanda[insumo] * factor))
		if cantidad > 0 and GameState.comprar(insumo, cantidad) == "":
			_compras[insumo] = cantidad

## Como haría un jugador en la tablet: cada reservación a una mesa donde quepa,
## sin repetir mesa en el mismo horario.
func _asignar_reservaciones() -> void:
	var ocupadas := {}
	for reserva in GameState.reservaciones:
		var minuto := int(reserva["minuto"])
		for mesa in range(1, GameState.numero_mesas() + 1):
			var clave := "%d_%d" % [mesa, minuto]
			if ocupadas.has(clave) or GameState.capacidad_mesa(mesa) < int(reserva["personas"]):
				continue
			if GameState.asignar_reservacion(reserva["id"], mesa) == "ok":
				ocupadas[clave] = true
				break

## Modo "ver": el pueblo de fondo con la lista de lo que compró el bot.
func _ver_manana() -> void:
	var compras := _compras.duplicate()
	_compras.clear()
	if not ver:
		return
	var pueblo: Node = load(GameState.ESCENA_PUEBLO).instantiate()
	add_child(pueblo)
	await get_tree().process_frame
	pueblo._dialogo.cerrar()
	pueblo._cerrar_intro()
	var capa := CanvasLayer.new()
	capa.layer = 80
	pueblo.add_child(capa)
	var panel := UIKit.panel(Color(0.05, 0.07, 0.1, 0.92), UIKit.BORDE, 14)
	panel.position = Vector2(390, 150)
	panel.custom_minimum_size = Vector2(500, 0)
	var caja := UIKit.vbox(6)
	caja.add_child(UIKit.etiqueta("COMPRAS DE LA MAÑANA", 22, UIKit.ACENTO))
	var gasto := 0
	for insumo in compras:
		var costo: int = GameState.precio_insumo(insumo) * int(compras[insumo])
		gasto += costo
		caja.add_child(UIKit.etiqueta("%s × %d  ($%d)" % [Catalogo.nombre_insumo(insumo), compras[insumo], costo], 16))
	caja.add_child(HSeparator.new())
	caja.add_child(UIKit.etiqueta("Gastó $%d · Queda $%d · Almacén %d/%d" % [gasto, GameState.dinero, GameState.inventario.total_unidades(), GameState.capacidad_almacen()], 16, UIKit.TEXTO_TENUE))
	caja.add_child(UIKit.etiqueta("Reservaciones asignadas: %d" % GameState.reservaciones.filter(func(r): return int(r.get("mesa", 0)) > 0).size(), 16, UIKit.TEXTO_TENUE))
	panel.add_child(caja)
	capa.add_child(panel)
	await get_tree().create_timer(6.0).timeout
	pueblo.queue_free()
	await get_tree().process_frame

func _sumar_receta(demanda: Dictionary, platillo: String, veces: float) -> void:
	var receta := Catalogo.receta(platillo)
	for insumo in receta:
		demanda[insumo] = float(demanda.get(insumo, 0.0)) + float(receta[insumo]) * veces

func _comprar_mejoras() -> void:
	for id in ["limpieza", "bandeja", "proveedor", "velocidad", "almacen", "cocina"]:
		var costo := GameState.costo_mejora(id)
		if costo > 0 and GameState.dinero - costo >= GameState.config.dinero_inicial * 0.7:
			GameState.comprar_mejora(id)

# ---------------------------------------------------------------- Jornada

func _jugar_jornada() -> Dictionary:
	var resto: Node = load(GameState.ESCENA_RESTAURANTE).instantiate()
	add_child(resto)
	await get_tree().process_frame
	_accion = {}
	_espera = 0.0
	_urgentes_recientes = {}
	Engine.time_scale = VELOCIDAD_VER if ver else VELOCIDAD_SIM
	if ver:
		# El bot mueve a Dani directamente; se apaga su control por teclado para animarlo.
		resto.dani.set_physics_process(false)
	while is_instance_valid(resto) and not resto.terminado:
		_paso(resto, get_process_delta_time())
		await get_tree().process_frame
	Engine.time_scale = 1.0
	var informe: Dictionary = GameState.ultimo_informe.duplicate(true)
	# terminar_jornada cambia de escena tras una pausa: se espera y se limpia.
	await get_tree().create_timer(2.2).timeout
	if ver:
		var motivo := str(informe["motivo"])
		if motivo == "" and GameState.nivel_actual != 3:
			motivo = str(GameState.info_nivel()["objetivo"])
		elif motivo == "":
			motivo = "reputación %d%% (meta %d%%)" % [int(informe["reputacion"]), int(GameState.config.reputacion_minima)]
		_mostrar_estado("REPORTE DE CIERRE · %s" % ("¡Objetivo cumplido!" if informe["exito"] else "No se cumplió: " + motivo))
		await get_tree().create_timer(7.0).timeout
	if is_instance_valid(resto):
		resto.queue_free()
	var marcador := Node.new()
	get_tree().root.add_child(marcador)
	var anterior := get_tree().current_scene
	get_tree().current_scene = marcador
	if is_instance_valid(anterior) and anterior != self:
		anterior.queue_free()
	await get_tree().process_frame
	return informe

func _paso(resto: Node, delta: float) -> void:
	var dani: Dani = resto.dani
	dani.bloqueado = false
	_pedidos_urgentes(resto)
	if resto._dialogo.esta_abierto():
		_espera += delta
		if _espera >= DECISION_DIALOGO:
			_espera = 0.0
			_resolver_faltante(resto)
		return
	if resto._urgente.esta_abierto():
		resto._urgente.cerrar()
	if _espera > 0.0:
		_espera -= delta
		dani.actualizar_estamina(delta, false, false)
		return
	if _accion.is_empty() or not _accion_valida(_accion):
		_accion = _elegir_accion(resto)
		if _accion.is_empty():
			dani.actualizar_estamina(delta, false, false)
			return
	var destino: Vector2 = _accion["destino"]
	var distancia := dani.global_position.distance_to(destino)
	if distancia > ALCANCE * 0.8:
		# Caminar (con sprint si hay estamina). Se descuenta un 20 % por rodear muebles.
		var corre := dani.actualizar_estamina(delta, true, true)
		var velocidad := Dani.VELOCIDAD_BASE * GameState.multiplicador_velocidad() * (Dani.MULTIPLICADOR_SPRINT if corre else 1.0) * 0.8
		if ver:
			dani._animar(destino - dani.global_position)
			dani._sprite.speed_scale = 1.6 if corre else 1.0
		dani.global_position = dani.global_position.move_toward(destino, velocidad * delta)
		return
	if ver:
		dani._sprite.stop()
		dani._sprite.frame = 0
	dani.actualizar_estamina(delta, false, false)
	# Limpiar requiere mantener Espacio.
	if _accion["tipo"] == "limpiar":
		_accion["progreso"] = float(_accion.get("progreso", 0.0)) + delta
		if _accion["progreso"] < GameState.tiempo_limpieza():
			return
	_ejecutar(resto, _accion)
	_accion = {}
	_espera = REACCION

func _accion_valida(accion: Dictionary) -> bool:
	var objetivo = accion.get("objetivo")
	if objetivo == null or not is_instance_valid(objetivo):
		return false
	match accion["tipo"]:
		"tomar":
			return objetivo.cliente != null and objetivo.cliente.estado == Cliente.Estado.ORDENANDO
		"servir":
			return objetivo.cliente != null and objetivo.cliente.estado == Cliente.Estado.ESPERANDO_COMIDA
		"limpiar":
			return objetivo.estado == Mesa.EstadoMesa.SUCIA
	return true

func _ejecutar(resto: Node, accion: Dictionary) -> void:
	var dani: Dani = resto.dani
	var objetivo = accion["objetivo"]
	match accion["tipo"]:
		"tomar", "servir", "limpiar":
			objetivo.interactuar(dani)
		"recoger", "devolver":
			objetivo.interactuar(dani)

## Prioridades de un jugador cuidadoso.
func _elegir_accion(resto: Node) -> Dictionary:
	var dani: Dani = resto.dani
	var pos := dani.global_position
	# 1. Servir lo que trae en la bandeja
	var mejor := {}
	for mesa in resto.mesas:
		var c: Cliente = mesa.cliente
		if c and c.estado == Cliente.Estado.ESPERANDO_COMIDA and dani.tiene_platillo(c.pedido):
			mejor = _mas_cercana(mejor, {"tipo": "servir", "objetivo": mesa, "destino": mesa.global_position}, pos)
	if not mejor.is_empty():
		return mejor
	# 2. Devolver platillos sin cliente si la bandeja está llena
	if not dani.puede_cargar() and not resto.cocina._sobrantes(dani).is_empty():
		return {"tipo": "devolver", "objetivo": resto.cocina, "destino": resto.cocina.global_position}
	# 3. Recoger platillos listos
	if dani.puede_cargar():
		for estacion in [resto.cocina, resto.barra]:
			if not estacion.listos.is_empty():
				mejor = _mas_cercana(mejor, {"tipo": "recoger", "objetivo": estacion, "destino": estacion.global_position}, pos)
		if not mejor.is_empty():
			return mejor
	# 4. Tomar pedidos (primero el de menor paciencia)
	var urgente: Mesa = null
	for mesa in resto.mesas:
		var c: Cliente = mesa.cliente
		if c and c.estado == Cliente.Estado.ORDENANDO and not (c.quiebre_registrado == c.pedido and not GameState.inventario.puede_preparar(c.pedido, c.personas)):
			if urgente == null or c.razon_paciencia() < urgente.cliente.razon_paciencia():
				urgente = mesa
	if urgente:
		return {"tipo": "tomar", "objetivo": urgente, "destino": urgente.global_position}
	# 5. Limpiar mesas sucias
	for mesa in resto.mesas:
		if mesa.estado == Mesa.EstadoMesa.SUCIA:
			mejor = _mas_cercana(mejor, {"tipo": "limpiar", "objetivo": mesa, "destino": mesa.global_position}, pos)
	return mejor

func _mas_cercana(actual: Dictionary, candidata: Dictionary, pos: Vector2) -> Dictionary:
	if actual.is_empty() or pos.distance_to(candidata["destino"]) < pos.distance_to(actual["destino"]):
		return candidata
	return actual

func _resolver_faltante(resto: Node) -> void:
	var opciones: Array = resto._dialogo._opciones
	# Sustituto si existe; si no, pedido urgente si alcanza el dinero; si no, agotado.
	var elegida: Array = opciones[0]
	var texto := str(elegida[0])
	if not texto.begins_with("Ofrecer sustituto") and GameState.dinero < 150:
		elegida = opciones[opciones.size() - 1]
	resto._dialogo._elegir(elegida[1])

## Un buen jugador pide urgente antes de que se acabe un insumo (con dinero de sobra).
func _pedidos_urgentes(resto: Node) -> void:
	for insumo in Catalogo.INSUMOS:
		var en_camino: bool = resto.entregas.any(func(e): return e["insumo"] == insumo)
		# Umbral pensado para que alcance a una familia de 4 mientras llega el proveedor.
		# No tiene caso pedir si el partido termina antes de que llegue.
		var queda: float = (1.0 - resto.minuto / 90.0) * resto.duracion
		if en_camino or GameState.inventario.total(insumo) > 8 or queda < GameState.demora_urgente() + 10.0:
			continue
		var cantidad := 6 if GameState.dinero < 800 else 12
		var costo := GameState.costo_urgente(insumo, cantidad)
		if GameState.dinero - costo > 150:
			resto.pedir_urgente(insumo, cantidad)
