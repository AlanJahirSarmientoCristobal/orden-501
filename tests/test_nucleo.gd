extends Node

## Pruebas del núcleo: dificultad, inventario, compras, caducidad, reservaciones,
## condiciones de nivel, reinicio de jornada y guardado.
## Ejecutar: godot --headless --path . res://tests/test_nucleo.tscn

var fallos: Array[String] = []
var _respaldo := ""
var _habia_guardado := false

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	_respaldar()
	_probar_dificultad()
	_probar_inventario()
	_probar_compras()
	_probar_reservaciones()
	_probar_condiciones_y_cierre()
	_probar_reinicio_y_guardado()
	_probar_mejoras()
	_probar_reto_imposible()
	_restaurar()
	if fallos.is_empty():
		print("TEST_NUCLEO: PASS")
		get_tree().quit(0)
	else:
		for f in fallos:
			push_error("TEST_NUCLEO: " + f)
		get_tree().quit(1)

func _check(condicion: bool, mensaje: String) -> void:
	if not condicion:
		fallos.append(mensaje)

func _probar_dificultad() -> void:
	var f := ConfiguracionDificultad.obtener("facil")
	var n := ConfiguracionDificultad.obtener("normal")
	var d := ConfiguracionDificultad.obtener("dificil")
	_check(f.paciencia_cliente == 60.0 and n.paciencia_cliente == 40.0 and d.paciencia_cliente == 25.0, "Paciencia no coincide con la tabla")
	_check(f.multiplicador_cocina == 0.8 and n.multiplicador_cocina == 1.0 and d.multiplicador_cocina == 1.3, "Cocina no coincide")
	_check(f.intervalo_llegada == 12.0 and n.intervalo_llegada == 8.0 and d.intervalo_llegada == 5.0, "Llegada no coincide")
	_check(is_equal_approx(f.probabilidad_vip, 0.10) and is_equal_approx(n.probabilidad_vip, 0.25) and is_equal_approx(d.probabilidad_vip, 0.40), "VIP no coincide")
	_check(f.dinero_inicial == 1500 and n.dinero_inicial == 1000 and d.dinero_inicial == 700, "Dinero inicial no coincide")
	_check(f.urgente_multiplicador_costo == 1.5 and n.urgente_multiplicador_costo == 2.0 and d.urgente_multiplicador_costo == 3.0, "Costo urgente no coincide")
	_check(f.urgente_demora == 15.0 and n.urgente_demora == 25.0 and d.urgente_demora == 40.0, "Demora urgente no coincide")
	_check(f.dias_caducidad == 3 and n.dias_caducidad == 2 and d.dias_caducidad == 1, "Caducidad no coincide")
	_check(f.tiempo_pueblo == 0.0 and n.tiempo_pueblo == 180.0 and d.tiempo_pueblo == 120.0, "Tiempo en el pueblo no coincide")
	_check(f.reputacion_minima == 50.0 and n.reputacion_minima == 70.0 and d.reputacion_minima == 85.0, "Reputación mínima no coincide")
	_check(ConfiguracionDificultad.obtener("inventada").id == "normal", "Una dificultad desconocida no cae en Normal")

func _probar_inventario() -> void:
	var inv := Inventario.new()
	inv.agregar("carne", 2, 1)
	inv.agregar("carne", 3, 2)
	inv.agregar("pan", 5, 1)
	inv.agregar("verdura", 5, 1)
	_check(inv.total("carne") == 5 and inv.total_unidades() == 15, "Totales del inventario incorrectos")
	_check(inv.puede_preparar(Catalogo.HAMBURGUESA), "Debería poder preparar hamburguesa")
	_check(not inv.puede_preparar(Catalogo.ALITAS), "No debería poder preparar alitas sin pollo")
	_check(inv.faltantes(Catalogo.ALITAS).get("pollo", 0) == 2, "Faltantes de alitas incorrectos")
	inv.consumir_receta(Catalogo.HAMBURGUESA)
	inv.consumir_receta(Catalogo.HAMBURGUESA)
	inv.consumir_receta(Catalogo.HAMBURGUESA)
	# FIFO: se gastaron las 2 del día 1 y 1 del día 2.
	_check(inv.total("carne") == 2, "Consumo de receta incorrecto")
	_check(inv.dias_restantes("carne", 2, 2) == 2, "La carne vieja debió consumirse primero (FIFO)")
	inv.agregar("cerveza", 4, 1)
	var merma := inv.retirar_caducados(3, 2)
	_check(merma.get("pan", 0) == 2 and merma.get("verdura", 0) == 2, "La merma de perecederos es incorrecta: %s" % merma)
	_check(not merma.has("cerveza") and inv.total("cerveza") == 4, "La cerveza no debe caducar")
	_check(inv.total("carne") == 2, "La carne del día 2 no debía caducar el día 3")
	var copia := inv.copia()
	copia.agregar("pollo", 1, 3)
	_check(inv.total("pollo") == 0, "La copia del inventario comparte datos con el original")

func _probar_compras() -> void:
	GameState.nueva_partida("dificil")
	_check(GameState.dinero == 700, "El dinero inicial de Difícil debe ser $700")
	_check(GameState.comprar("carne", 5) == "", "La compra válida falló")
	_check(GameState.dinero == 700 - 5 * int(Catalogo.INSUMOS["carne"]["precio"]), "La compra no descontó el dinero")
	_check(GameState.comprar("carne", 100) != "", "Se permitió comprar sin dinero")
	GameState.dinero = 100000
	var libre := GameState.espacio_libre()
	_check(GameState.comprar("papas", libre + 1) != "", "Se permitió exceder el almacén")
	_check(GameState.comprar("papas", libre) == "", "No se pudo llenar el almacén exactamente")
	_check(GameState.espacio_libre() == 0, "El espacio libre no llegó a 0")
	GameState.mejoras["almacen"] = 1
	_check(GameState.espacio_libre() == 30, "La mejora de almacén no agregó espacio")
	_check(GameState.costo_urgente("carne", 3) == 3 * 3 * int(Catalogo.INSUMOS["carne"]["precio"]), "El pedido urgente en Difícil debe costar ×3")
	_check(is_equal_approx(GameState.tiempo_manana, 120.0), "La mañana en Difícil debe durar 2 min")
	GameState.tiempo_manana = 50.0
	GameState.posicion_pueblo = Vector2(10, 10)
	GameState.iniciar_manana()
	_check(is_equal_approx(GameState.tiempo_manana, 120.0) and GameState.posicion_pueblo == Vector2.ZERO, "Una nueva mañana debe reiniciar el reloj y la posición")
	# Monster: un solo producto con 7 diseños que rotan.
	_check(Catalogo.INSUMOS["monster"]["tienda"] == Catalogo.CERVECERIA, "El Monster se vende en la Cervecería")
	_check(AssetPaths.disenos_de("monster").size() == 7, "El Monster debe tener 7 diseños")
	var primero := AssetPaths.siguiente_diseno("monster")
	_check(AssetPaths.siguiente_diseno("monster") != primero, "El sprite del Monster debe rotar")

func _probar_reservaciones() -> void:
	GameState.nueva_partida("normal")
	GameState.nivel_desbloqueado = 2
	GameState.seleccionar_nivel(2)
	_check(GameState.reservaciones.size() == 4, "El nivel 2 debe tener 4 reservaciones")
	var a: Dictionary = GameState.reservaciones[0]
	var b: Dictionary = GameState.reservaciones[1]
	b["minuto"] = a["minuto"]
	a["personas"] = 2
	b["personas"] = 2
	_check(GameState.asignar_reservacion(a["id"], 4) == "ok", "No se pudo asignar una mesa válida")
	var rep := GameState.reputacion
	_check(GameState.asignar_reservacion(b["id"], 4) == "duplicada", "No se detectó la reservación duplicada")
	_check(GameState.estadisticas["duplicados"] == 1 and GameState.reputacion < rep, "La duplicidad no penalizó")
	a["personas"] = 4
	a["estado"] = "pendiente"
	_check(GameState.asignar_reservacion(a["id"], 1) == "capacidad", "Se permitió sentar a 4 personas en mesa de 2")

func _probar_condiciones_y_cierre() -> void:
	GameState.nueva_partida("normal")
	GameState.iniciar_jornada()
	GameState.estadisticas["perdidos"] = 3
	_check(GameState.objetivo_cumplido(), "Nivel 1 con 0 quiebres y 3 perdidos debe superarse")
	GameState.estadisticas["quiebres"] = 1
	_check(not GameState.objetivo_cumplido(), "Nivel 1 con quiebres no debe superarse")
	GameState.estadisticas["quiebres"] = 0
	GameState.inventario.agregar("pan", 4, GameState.dia)
	GameState.inventario.agregar("cerveza", 4, GameState.dia)
	var informe := GameState.cerrar_jornada()
	_check(informe["exito"], "El cierre debió marcar éxito")
	_check(GameState.nivel_actual == 2 and GameState.nivel_desbloqueado == 2, "No se desbloqueó el nivel 2")
	_check(GameState.dia == 2, "El día no avanzó")
	# En Normal los insumos duran 2 días: el pan del día 1 aún no caduca al pasar al día 2.
	_check(informe["merma"].is_empty(), "No debería haber merma tras un día en Normal")

	GameState.nueva_partida("dificil")
	GameState.inventario.agregar("pan", 4, GameState.dia)
	GameState.iniciar_jornada()
	informe = GameState.cerrar_jornada()
	_check(informe["merma"].get("pan", 0) == 4, "En Difícil el pan debe caducar en 1 día")

	GameState.nueva_partida("dificil")
	GameState.nivel_desbloqueado = 3
	GameState.seleccionar_nivel(3)
	GameState.iniciar_jornada()
	GameState.reputacion = 84.0
	_check(not GameState.objetivo_cumplido(), "La Gran Final en Difícil exige 85%")
	GameState.reputacion = 85.0
	informe = GameState.cerrar_jornada()
	_check(informe["temporada_completa"] and GameState.terraza_desbloqueada, "La Gran Final no desbloqueó la terraza")
	_check(GameState.numero_mesas() == 8, "La terraza debe agregar 2 mesas")

func _probar_reinicio_y_guardado() -> void:
	GameState.nueva_partida("normal")
	GameState.comprar("carne", 5)
	GameState.iniciar_manana()   # Nueva foto con la carne comprada
	var dinero_manana := GameState.dinero
	GameState.comprar("pollo", 5)
	GameState.iniciar_jornada()
	GameState.registrar_venta(Catalogo.HAMBURGUESA, 10)
	GameState.cerrar_jornada("prueba de derrota")
	GameState.reiniciar_jornada()
	_check(GameState.dinero == dinero_manana, "Reiniciar jornada no restauró el dinero")
	_check(GameState.inventario.total("pollo") == 0 and GameState.inventario.total("carne") == 5, "Reiniciar jornada no restauró el inventario")
	_check(GameState.dia == 1, "Reiniciar jornada no restauró el día")

	GameState.mejoras["bandeja"] = 1
	GameState.guardar()
	# Se altera el estado en memoria (sin guardar) y se comprueba que la carga lo recupera.
	GameState.dificultad = "facil"
	GameState.mejoras["bandeja"] = 0
	GameState.inventario = Inventario.new()
	_check(GameState.cargar(), "No se pudo cargar la partida")
	_check(GameState.dificultad == "normal" and GameState.capacidad_bandeja() == 4, "La carga no restauró los datos")
	_check(GameState.inventario.total("carne") == 5, "La carga no restauró el inventario")

func _probar_mejoras() -> void:
	GameState.nueva_partida("normal")
	GameState.dinero = 10000
	# Costos escalonados: el segundo nivel cuesta más
	var primero := GameState.costo_mejora("velocidad")
	_check(GameState.comprar_mejora("velocidad"), "No se compró el primer nivel de Tenis")
	var segundo := GameState.costo_mejora("velocidad")
	_check(segundo > primero, "El segundo nivel debe costar más que el primero")
	_check(GameState.comprar_mejora("velocidad"), "No se compró el segundo nivel de Tenis")
	_check(GameState.costo_mejora("velocidad") == -1 and not GameState.comprar_mejora("velocidad"), "Tenis no debe pasar de 2 niveles")
	# Trapeador industrial
	var limpieza := GameState.tiempo_limpieza()
	GameState.comprar_mejora("limpieza")
	_check(is_equal_approx(GameState.tiempo_limpieza(), limpieza * 0.6), "El trapeador debe reducir la limpieza 40%")
	# Proveedor preferente
	var costo := GameState.costo_urgente("carne", 6)
	var demora := GameState.demora_urgente()
	GameState.comprar_mejora("proveedor")
	_check(GameState.costo_urgente("carne", 6) < costo and GameState.demora_urgente() < demora, "El proveedor preferente debe abaratar y acelerar lo urgente")
	# Promoción 2x1: más clientes y bono por pedido
	GameState.comprar_mejora("promo")
	GameState.iniciar_jornada()
	_check(GameState.promo_activa and GameState.intervalo_llegada() < GameState.config.intervalo_llegada, "La promoción debe traer más clientes")
	var dinero := GameState.dinero
	var rep := GameState.reputacion
	GameState.reputacion = 50.0
	GameState.registrar_venta(Catalogo.PAPAS, 0)
	_check(GameState.dinero == dinero + Catalogo.precio(Catalogo.PAPAS) + GameState.BONO_PROMO_DINERO, "La promoción debe dar bono de dinero")
	_check(GameState.reputacion > 50.0, "La promoción debe dar reputación por pedido")
	GameState.reputacion = rep

func _probar_reto_imposible() -> void:
	GameState.nueva_partida("normal")
	GameState.nivel_desbloqueado = 2
	GameState.guardar()
	var guardado_antes := FileAccess.get_file_as_string(GameState.SAVE_PATH)
	_check(GameState.nivel_superado(1) and not GameState.nivel_superado(2), "Solo el nivel 1 debe contar como superado")
	GameState.iniciar_reto_imposible()
	_check(GameState.modo_reto and GameState.nivel_actual == 3 and GameState.dificultad == "imposible", "El reto debe ser una Gran Final en Imposible")
	_check(GameState.precio_insumo("carne") > int(Catalogo.INSUMOS["carne"]["precio"]), "En Imposible los insumos deben costar más")
	GameState.iniciar_jornada()
	GameState.reputacion = 100.0
	var informe := GameState.cerrar_jornada()
	_check(informe["reto"] and not GameState.temporada_completada, "Ganar el reto no debe completar la campaña")
	_check(FileAccess.get_file_as_string(GameState.SAVE_PATH) == guardado_antes, "El reto no debe modificar la partida guardada")
	_check(GameState.cargar() and not GameState.modo_reto and GameState.dificultad == "normal", "Continuar debe volver a la campaña")

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
