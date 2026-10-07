extends Node

## Pruebas del restaurante: ciclo completo de un cliente, faltantes con sus 3 opciones,
## paciencia agotada, VIP, reservaciones, goles, pedido urgente y fin de jornada.
## Ejecutar: godot --headless --path . res://tests/test_restaurante.tscn

var fallos: Array[String] = []
var _respaldo := ""
var _habia_guardado := false
var r: Node

func _ready() -> void:
	GameState.tutoriales_habilitados = false
	_run.call_deferred()

func _run() -> void:
	_respaldar()
	GameState.nueva_partida("normal")
	GameState.nivel_desbloqueado = 2
	GameState.seleccionar_nivel(2)
	GameState.dinero = 5000
	for insumo in Catalogo.INSUMOS:
		GameState.inventario.agregar(insumo, 8, GameState.dia)
	GameState.iniciar_jornada()
	r = load("res://scenes/restaurant/restaurant.tscn").instantiate()
	add_child(r)
	await get_tree().process_frame
	r.set_process(false)   # El partido se controla a mano en la prueba.

	_probar_estamina()
	_probar_ciclo_cliente()
	_probar_faltante_sustituto()
	_probar_faltante_agotado()
	_probar_urgente()
	_probar_agotado_vuelve()
	_probar_paciencia()
	_probar_vip()
	_probar_grupos()
	_probar_reservacion()
	_probar_gol()
	_probar_eventos()
	await _probar_fin()
	await _probar_practica()

	_restaurar()
	if fallos.is_empty():
		print("TEST_RESTAURANTE: PASS")
		get_tree().quit(0)
	else:
		for f in fallos:
			push_error("TEST_RESTAURANTE: " + f)
		get_tree().quit(1)

func _check(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)

## Sienta a un cliente en una mesa sin esperar la animación.
func _sentar(cliente: Cliente, mesa: Mesa, pedido: String) -> void:
	cliente.restaurante = r
	cliente.position = mesa.posicion_asiento()
	r.add_child(cliente)
	mesa.ocupar(cliente)
	cliente.mesa = mesa
	cliente.estado = Cliente.Estado.CAMINANDO
	cliente._sentarse()
	cliente.pedido = pedido

func _avanzar_estaciones(segundos: float) -> void:
	var paso := 0.1
	var t := 0.0
	while t < segundos:
		r.cocina._process(paso)
		r.barra._process(paso)
		t += paso

func _probar_estamina() -> void:
	var d: Dani = r.dani
	_check(d.actualizar_estamina(0.1, true, true), "Con Shift y moviéndose, Dani debe correr")
	_check(not d.actualizar_estamina(0.1, true, false), "Quieto no debe contar como correr")
	# Correr hasta agotarse (100 / 35 ≈ 2.9 s)
	for i in range(40):
		d.actualizar_estamina(0.1, true, true)
	_check(d.agotado and d.estamina < Dani.MINIMO_PARA_CORRER, "La estamina debe agotarse al correr sin parar")
	_check(not d.actualizar_estamina(0.1, true, true), "Agotado no debe poder correr")
	# Recupera: con 25 de estamina vuelve a poder correr
	for i in range(12):
		d.actualizar_estamina(0.1, false, true)
	_check(not d.agotado and d.actualizar_estamina(0.1, true, true), "Tras recuperar el mínimo debe poder correr de nuevo")
	d.estamina = Dani.ESTAMINA_MAX

func _probar_ciclo_cliente() -> void:
	var mesa: Mesa = r.mesas[0]
	var cliente := ClienteHabitual.new()
	_sentar(cliente, mesa, Catalogo.HAMBURGUESA)
	_check(cliente.estado == Cliente.Estado.ORDENANDO, "El cliente sentado debe estar ordenando")
	var carne := GameState.inventario.total("carne")
	mesa.interactuar(r.dani)
	_check(cliente.estado == Cliente.Estado.ESPERANDO_COMIDA, "Tomar el pedido no lo envió a cocina")
	_check(GameState.inventario.total("carne") == carne - 1, "El pedido no consumió la receta")
	_check(r.cocina.pendientes() == 1, "La cocina no recibió la comanda")
	_avanzar_estaciones(8.0)
	_check(r.cocina.listos.size() == 1, "La cocina no terminó el platillo")
	r.cocina.interactuar(r.dani)
	_check(r.dani.tiene_platillo(Catalogo.HAMBURGUESA), "Dani no recogió el platillo")
	var dinero := GameState.dinero
	mesa.interactuar(r.dani)
	_check(cliente.estado == Cliente.Estado.COMIENDO, "Servir no dejó al cliente comiendo")
	_check(GameState.dinero > dinero + Catalogo.precio(Catalogo.HAMBURGUESA) - 1, "Servir no pagó el platillo")
	_check(GameState.estadisticas["pedidos"] == 1, "No se contó el pedido entregado")
	cliente._process(20.0)
	_check(mesa.estado == Mesa.EstadoMesa.SUCIA, "La mesa debe quedar sucia al irse el cliente")
	_check(mesa.tiempo_mantener(r.dani) > 0.0, "Limpiar debe requerir mantener Espacio")
	mesa.interactuar(r.dani)
	_check(mesa.esta_libre(), "La mesa no quedó limpia")

func _probar_faltante_sustituto() -> void:
	var mesa: Mesa = r.mesas[1]
	var pollo := GameState.inventario.total("pollo")
	GameState.inventario._retirar("pollo", pollo)
	var cliente := ClienteHabitual.new()
	_sentar(cliente, mesa, Catalogo.ALITAS)
	var quiebres: int = GameState.estadisticas["quiebres"]
	mesa.interactuar(r.dani)
	_check(r._dialogo.esta_abierto(), "Sin insumo debe aparecer el diálogo de faltante")
	_check(GameState.estadisticas["quiebres"] == quiebres + 1, "No se registró el quiebre de stock")
	_check(r._sustituto_disponible(Catalogo.ALITAS) == Catalogo.HAMBURGUESA, "El sustituto de alitas debe ser hamburguesa")
	r._dialogo.cerrar()
	r._usar_sustituto(cliente, Catalogo.HAMBURGUESA)
	_check(cliente.estado == Cliente.Estado.ESPERANDO_COMIDA and cliente.pedido == Catalogo.HAMBURGUESA, "El sustituto no se envió")
	_check(cliente.factor_propina < 1.0, "El sustituto debe dar menos propina")
	r.cancelar_pedidos(cliente)
	cliente.retirarse()
	mesa.liberar(false)

func _probar_faltante_agotado() -> void:
	var mesa: Mesa = r.mesas[2]
	var cliente := ClienteHabitual.new()
	_sentar(cliente, mesa, Catalogo.ALITAS)
	r._marcar_agotado(cliente, Catalogo.ALITAS)
	_check(r.agotados.has(Catalogo.ALITAS), "No se marcó el platillo como agotado")
	_check(cliente.estado == Cliente.Estado.ESPERANDO_COMIDA and cliente.pedido != Catalogo.ALITAS, "El cliente no cambió a otro platillo disponible")
	r.cancelar_pedidos(cliente)
	cliente.retirarse()
	mesa.liberar(false)

## Un platillo agotado regresa al menú cuando vuelve a haber insumos.
func _probar_agotado_vuelve() -> void:
	var pollo := GameState.inventario.total("pollo")
	GameState.inventario._retirar("pollo", pollo)
	_check(r.platillos_sin_insumos().has(Catalogo.ALITAS), "Sin pollo, las alitas deben aparecer sin insumos")
	r.agotados.append(Catalogo.ALITAS)
	GameState.recibir_urgente("pollo", 6)
	_check(not r.agotados.has(Catalogo.ALITAS), "Las alitas debían volver al menú al llegar el pollo")
	_check(not r.platillos_sin_insumos().has(Catalogo.ALITAS), "Con pollo, las alitas no deben marcarse sin insumos")

func _probar_urgente() -> void:
	var dinero := GameState.dinero
	_check(r.pedir_urgente("pollo", 3), "No se pudo hacer el pedido urgente")
	_check(GameState.dinero == dinero - GameState.costo_urgente("pollo", 3), "El pedido urgente no cobró ×2")
	_check(r.entregas.size() == 1, "La entrega no quedó en camino")
	r._procesar_entregas(GameState.config.urgente_demora + 0.1)
	_check(GameState.inventario.total("pollo") == 3 and r.entregas.is_empty(), "La entrega urgente no llegó")

func _probar_paciencia() -> void:
	var mesa: Mesa = r.mesas[3]
	var cliente := ClienteHabitual.new()
	_sentar(cliente, mesa, Catalogo.PAPAS)
	var perdidos: int = GameState.estadisticas["perdidos"]
	var rep := GameState.reputacion
	cliente._process(cliente.paciencia_max + 1.0)
	_check(GameState.estadisticas["perdidos"] == perdidos + 1, "El cliente sin paciencia no se contó como perdido")
	_check(GameState.reputacion < rep, "Perder un cliente debe bajar la reputación")
	_check(mesa.estado == Mesa.EstadoMesa.SUCIA, "La mesa del cliente molesto debe quedar sucia")
	mesa.interactuar(r.dani)

func _probar_vip() -> void:
	var vip := ClienteVIP.new()
	var normal := ClienteHabitual.new()
	_sentar(vip, r.mesas[4], Catalogo.COMBO)
	_sentar(normal, r.mesas[5], Catalogo.PAPAS)
	_check(vip.paciencia_max < normal.paciencia_max, "El VIP debe tener menos paciencia")
	_check(vip.elegir_pedido() == Catalogo.COMBO, "El VIP debe pedir el Combo")
	_check(vip.propina_base() > normal.propina_base(), "El VIP debe dejar más propina")
	for c in [vip, normal]:
		c.retirarse()
	r.mesas[4].liberar(false)
	r.mesas[5].liberar(false)

func _probar_grupos() -> void:
	# Mesa según el tamaño del grupo
	var familia := ClienteHabitual.new()
	familia.personas = 4
	var mesa_familia: Mesa = r._mesa_para(familia)
	_check(mesa_familia != null and mesa_familia.capacidad == 4, "La familia de 4 debe ir a una mesa de 4")
	var pareja := ClienteHabitual.new()
	pareja.personas = 2
	var mesa_pareja: Mesa = r._mesa_para(pareja)
	_check(mesa_pareja != null and mesa_pareja.capacidad == 2, "La pareja debe preferir una mesa de 2")
	# Un pedido para 4 consume 4 porciones y cobra 4 platillos
	GameState.inventario.agregar("papas", 10, GameState.dia)
	_sentar(familia, mesa_familia, Catalogo.PAPAS)
	_check(familia._acompanantes.size() == 3, "La familia debe mostrar 3 acompañantes")
	var papas := GameState.inventario.total("papas")
	mesa_familia.interactuar(r.dani)
	_check(GameState.inventario.total("papas") == papas - 8, "El pedido de la familia debía usar 8 papas (4 porciones)")
	var dinero := GameState.dinero
	r.dani.vaciar_bandeja()
	r.dani.agregar_platillo(Catalogo.PAPAS)
	mesa_familia.interactuar(r.dani)
	_check(GameState.dinero >= dinero + Catalogo.precio(Catalogo.PAPAS) * 4, "La familia debía pagar 4 platillos")
	r.cancelar_pedidos(familia)
	familia.retirarse()
	mesa_familia.liberar(false)
	for c in [pareja]:
		c.free()
	# Probabilidades por dificultad
	_check(ConfiguracionDificultad.obtener("facil").probabilidad_familia == 0.0, "En Fácil no llegan familias")
	_check(ConfiguracionDificultad.obtener("dificil").probabilidad_familia > ConfiguracionDificultad.obtener("normal").probabilidad_familia, "En Difícil llegan más familias que en Normal")

func _probar_reservacion() -> void:
	var reserva: Dictionary = GameState.reservaciones[0]
	reserva["personas"] = 2
	_check(GameState.asignar_reservacion(reserva["id"], 2) == "ok", "No se asignó la reservación")
	r.minuto = float(reserva["minuto"]) - 5.0
	_check(r._mesa_para(ClienteHabitual.new()) != r.mesas[1], "Un cliente sin reservación ocupó una mesa reservada")
	r.minuto = float(reserva["minuto"])
	var antes: int = r.fila.size()
	r._procesar_reservaciones()
	_check(reserva["estado"] == "llego" and r.fila.size() >= antes + 1, "La reservación no llegó a su hora")
	var cliente: Cliente = r.fila[0]
	_check(cliente is ClienteReservacion and r._mesa_para(cliente) == r.mesas[1], "El cliente con reservación no fue a su mesa")
	r._sentar_clientes()
	_check(r.mesas[1].cliente == cliente, "La mesa reservada no quedó ocupada por su cliente")

func _probar_gol() -> void:
	var mesa: Mesa = r.mesas[3]
	var cliente := ClienteHabitual.new()
	_sentar(cliente, mesa, Catalogo.PAPAS)
	cliente.estado = Cliente.Estado.COMIENDO
	cliente.tiempo_comiendo = 10.0
	_check(cliente.pedir_extra(), "Un cliente comiendo debe poder pedir otra ronda")
	_check(Catalogo.BEBIDAS.has(cliente.pedido) and cliente.estado == Cliente.Estado.ORDENANDO, "La ronda extra debe ser una bebida")

func _probar_eventos() -> void:
	# Apagón: la cocina deja de avanzar y se reanuda a los 10 s
	var cliente := ClienteHabitual.new()
	_sentar(cliente, r.mesas[5], Catalogo.PAPAS)
	GameState.inventario.agregar("papas", 4, GameState.dia)
	r.mesas[5].interactuar(r.dani)
	r._evento("apagon")
	_check(r.cocina.pausada and r.barra.pausada, "El apagón debe detener cocina y barra")
	var listos: int = r.cocina.listos.size()
	_avanzar_estaciones(10.0)
	_check(r.cocina.listos.size() == listos, "Durante el apagón no se debe preparar nada")
	r._procesar_eventos_especiales(10.5)
	_check(not r.cocina.pausada, "La cocina debe reanudarse al volver la luz")
	r.cancelar_pedidos(cliente)
	cliente.retirarse()
	r.mesas[5].liberar(false)
	# Crítico: entra primero a la fila
	r._evento("critico")
	_check(r.fila[0] is ClienteCritico, "El crítico debe entrar al frente de la fila")
	# Retraso del proveedor: los urgentes tardan más
	var normal: float = r._demora_actual()
	r._evento("retraso")
	_check(r._demora_actual() > normal, "El retraso del proveedor debe alargar los pedidos urgentes")
	# Penales: solo si el partido va empatado
	r.marcador = [1, 1]
	r._final_del_partido(0.1)
	_check(r.penales and not r.terminado, "Con empate debe haber penales antes de terminar")
	r.penales = false
	r._penales_restante = -1.0

func _probar_fin() -> void:
	r.minuto = 90.0
	r.terminar_jornada("")
	_check(r.terminado, "La jornada no terminó")
	_check(not GameState.ultimo_informe.is_empty(), "No se generó el informe de cierre")
	_check(GameState.ultimo_informe["estadisticas"]["pedidos"] >= 1, "El informe no tiene los pedidos")
	for cliente in get_tree().get_nodes_in_group("clientes"):
		_check(cliente.estado == Cliente.Estado.SALIENDO, "Quedaron clientes sin retirarse")
	# Evita que la escena cambie al reporte durante la prueba.
	r.queue_free()
	await get_tree().process_frame

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

## Jornada 1 con tutoriales: práctica antes del partido con un cliente que no gasta inventario.
func _probar_practica() -> void:
	GameState.tutoriales_habilitados = true
	GameState.nueva_partida("dificil")
	_check(GameState.tutorial_manana_activo(), "En la Jornada 1 el tutorial de la mañana debe detener el reloj")
	GameState.nivel_actual = 2
	_check(not GameState.tutorial_pendiente("restaurante"), "Los tutoriales solo aparecen en la Jornada 1")
	GameState.nivel_actual = 1
	for insumo in Catalogo.INSUMOS:
		GameState.inventario.agregar(insumo, 5, GameState.dia)
	GameState.iniciar_jornada()
	var p: Node = load("res://scenes/restaurant/restaurant.tscn").instantiate()
	add_child(p)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(p.practica, "La Jornada 1 debe empezar con la práctica")
	_check(p.get_children().any(func(n): return n is Tutorial), "No apareció el tutorial del restaurante")
	var c: Cliente = p._cliente_practica
	_check(c is ClientePractica, "No llegó el cliente de práctica")
	p._process(5.0)
	_check(p.tiempo == 0.0, "El reloj del partido no debe correr durante la práctica")
	c._sentarse()
	var mesa: Mesa = c.mesa
	_check(mesa != null, "El cliente de práctica no tiene mesa")
	var unidades := GameState.inventario.total_unidades()
	var ventas: int = GameState.estadisticas["ventas"]
	mesa.interactuar(p.dani)
	_check(c.estado == Cliente.Estado.ESPERANDO_COMIDA, "No se tomó el pedido de práctica")
	_check(GameState.inventario.total_unidades() == unidades, "La práctica no debe gastar inventario")
	for i in range(100):
		p.barra._process(0.1)
	p.barra.interactuar(p.dani)
	mesa.interactuar(p.dani)
	_check(c.estado == Cliente.Estado.COMIENDO, "No se sirvió al cliente de práctica")
	_check(GameState.estadisticas["ventas"] == ventas, "La práctica no debe contar como venta")
	c._process(5.0)
	_check(mesa.estado == Mesa.EstadoMesa.SUCIA, "La mesa de práctica debe quedar sucia")
	p._terminar_practica()
	_check(not p.practica, "La práctica no terminó")
	p._process(1.0)
	_check(p.tiempo > 0.0, "El partido no arrancó después de la práctica")
	p.set_process(false)
	p.queue_free()
	await get_tree().process_frame
	GameState.tutoriales_habilitados = false
