extends Node

## Herramienta de desarrollo: abre cada pantalla y guarda una captura PNG.
## Ejecutar SIN --headless: godot --path . res://tests/captura_pantallas.tscn -- <carpeta>

var carpeta := "user://capturas"
var _actual: Node

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty():
		carpeta = args[0]
	DirAccess.make_dir_recursive_absolute(carpeta)
	_run.call_deferred()

func _abrir(ruta: String) -> Node:
	if _actual:
		_actual.queue_free()
		await get_tree().process_frame
	PanelModal.abiertos = 0
	_actual = load(ruta).instantiate()
	add_child(_actual)
	await _esperar(0.6)
	return _actual

func _esperar(segundos: float) -> void:
	await get_tree().create_timer(segundos).timeout

func _capturar(nombre: String) -> void:
	await RenderingServer.frame_post_draw
	var imagen := get_viewport().get_texture().get_image()
	imagen.save_png("%s/%s.png" % [carpeta, nombre])
	print("captura: ", nombre)

func _run() -> void:
	var respaldo := FileAccess.get_file_as_string(GameState.SAVE_PATH) if FileAccess.file_exists(GameState.SAVE_PATH) else ""
	await _abrir("res://scenes/menu/main_menu.tscn")
	await _capturar("01_menu")
	_actual._mostrar_dificultad()
	await _capturar("02_dificultad")

	GameState.nueva_partida("normal")
	var pueblo := await _abrir("res://scenes/town/town.tscn")
	await _capturar("03_pueblo_intro")
	pueblo._dialogo.cerrar()
	pueblo._cerrar_intro()
	await _esperar(0.8)
	await _capturar("04a_pueblo_inicio")
	pueblo.dani.position = pueblo.puerta("mercado") + Vector2(0, 40)
	await _esperar(0.8)
	await _capturar("04b_pueblo_mercado")
	pueblo.dani.position = pueblo.puerta("cerveceria") + Vector2(0, 40)
	await _esperar(0.8)
	await _capturar("04c_pueblo_cerveceria")
	pueblo.dani.position = pueblo._posicion_consejo(pueblo.CONSEJOS[1]) + Vector2(0, 60)
	await _esperar(0.8)
	await _capturar("04d_pueblo_parque")

	GameState.tienda_actual = Catalogo.MERCADO
	var mercado := await _abrir("res://scenes/town/store.tscn")
	await _capturar("05a_interior_mercado")
	mercado.abrir_menu()
	await _esperar(0.3)
	await _capturar("05b_menu_mercado")
	mercado._menu.indice = 1
	mercado._menu._elegir_producto()
	mercado._menu.cantidad = 5
	mercado._menu._actualizar()
	await _capturar("05b2_menu_cantidad")
	mercado._menu.confirmar_si = true
	mercado._menu._ir_a(MenuCompra.Estado.CONFIRMAR)
	await _capturar("05b3_menu_confirmar")
	mercado._menu.cerrar()
	GameState.tienda_actual = Catalogo.CERVECERIA
	var cerveceria := await _abrir("res://scenes/town/store.tscn")
	cerveceria.dani.position = cerveceria.interior.a_mundo(12.5, 10.3)
	await _esperar(1.5)
	await _capturar("05c_interior_cerveceria")
	cerveceria.abrir_menu()
	cerveceria._menu.indice = cerveceria._menu.productos.find("monster")
	cerveceria._menu._actualizar()
	await _capturar("05d_menu_monster")
	cerveceria._menu.cerrar()
	pueblo = await _abrir("res://scenes/town/town.tscn")
	for insumo in Catalogo.INSUMOS:
		GameState.comprar(insumo, 8)
	pueblo._inventario.abrir("INVENTARIO DEL ALMACÉN")
	await _capturar("06_inventario")
	pueblo._inventario.cerrar()

	GameState.nivel_desbloqueado = 2
	GameState.nivel_actual = 2
	var dinero := GameState.dinero
	var inv := GameState.inventario.a_datos()
	GameState.seleccionar_nivel(2)
	GameState.dinero = dinero
	GameState.inventario.desde_datos(inv)
	GameState.iniciar_jornada()
	var resto := await _abrir("res://scenes/restaurant/restaurant.tscn")
	Engine.time_scale = 4.0
	await _esperar(18.0)
	Engine.time_scale = 1.0
	# Toma el pedido de la primera mesa ocupada para mostrar el flujo.
	for mesa in resto.mesas:
		if mesa.cliente and mesa.cliente.estado == Cliente.Estado.ORDENANDO:
			resto.dani.position = mesa.position + Vector2(0, 60)
			mesa.interactuar(resto.dani)
			break
	await _esperar(0.5)
	await _capturar("07_restaurante")
	# Una familia de 4 y una pareja sentadas
	for grupo in [4, 2]:
		for m in resto.mesas:
			if m.esta_libre() and m.capacidad >= grupo and (grupo == 4 or m.capacidad == 2):
				var c := ClienteHabitual.new()
				c.personas = grupo
				c.restaurante = resto
				c.position = m.posicion_asiento()
				resto.add_child(c)
				m.ocupar(c)
				c.mesa = m
				c.estado = Cliente.Estado.CAMINANDO
				c._sentarse()
				break
	await _esperar(0.3)
	await _capturar("07b_grupos")
	resto._tablet.abrir_seccion("reservaciones")
	await _capturar("08_tablet_reservaciones")
	resto._tablet.cerrar()
	resto._urgente.abrir("PEDIDO URGENTE POR TELÉFONO")
	await _capturar("09_pedido_urgente")
	resto._urgente.cerrar()
	var cliente := ClienteHabitual.new()
	var mesa_libre: Mesa = null
	for m in resto.mesas:
		if m.esta_libre():
			mesa_libre = m
			break
	if mesa_libre:
		GameState.inventario._retirar("pollo", GameState.inventario.total("pollo"))
		cliente.restaurante = resto
		cliente.position = mesa_libre.posicion_asiento()
		resto.add_child(cliente)
		mesa_libre.ocupar(cliente)
		cliente.mesa = mesa_libre
		cliente.estado = Cliente.Estado.CAMINANDO
		cliente._sentarse()
		cliente.pedido = Catalogo.ALITAS
		resto.procesar_pedido(cliente)
		await _esperar(0.3)
		await _capturar("10_faltante")
		resto._dialogo.cerrar()

	resto.set_process(false)
	GameState.cerrar_jornada()
	await _abrir("res://scenes/ui/closing_report.tscn")
	await _capturar("11_reporte")
	GameState.ultimo_informe["exito"] = true
	GameState.dinero = 1500
	await _abrir("res://scenes/ui/closing_report.tscn")
	await _capturar("11b_reporte_exito")
	GameState.historial = [GameState.ultimo_informe]
	GameState.terraza_desbloqueada = true
	await _abrir("res://scenes/ui/victory.tscn")
	await _capturar("12_victoria")
	var terraza := await _abrir("res://scenes/restaurant/restaurant.tscn")
	terraza.set_process(false)
	await _capturar("13_terraza")

	if respaldo != "":
		var f := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		f.store_string(respaldo)
	else:
		GameState.borrar_guardado()
	get_tree().quit()
