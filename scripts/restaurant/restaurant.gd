extends Node2D

## Fase de jornada: Dani atiende La 501 durante el partido.
## Distribución (sección 9 del documento): cocina y barra a la izquierda, mesas al centro,
## pantallas en la pared superior, entrada abajo y panel de gestión a la derecha.

const AREA_JUEGO := Rect2(0, 100, 1000, 620)
const PUERTA := Vector2(540, 770)
const INICIO_FILA := Vector2(620, 668)
const MAX_FILA := 6
const MINUTOS_PARTIDO := 90.0

const POS_MESAS := [Vector2(330, 250), Vector2(540, 250), Vector2(750, 250), Vector2(330, 450), Vector2(540, 450), Vector2(750, 450)]
const POS_TERRAZA := [Vector2(930, 250), Vector2(930, 450)]

var dani: Dani
var cocina: Estacion
var barra: Estacion
var mesas: Array[Mesa] = []
var fila: Array[Cliente] = []
var entregas: Array[Dictionary] = []     # {"insumo", "cantidad", "restante"}
var agotados: Array[String] = []

var tiempo := 0.0
var duracion := 180.0
var minuto := 0.0
var marcador := [0, 0]
var terminado := false

var _siguiente_llegada := 3.0
var _acumulado_llegada := 0.0
var _medio_tiempo := false
var _final_cerca := false
var _goles: Array[float] = []
var _equipos := ["LOCAL", "VISITA"]
var _refresco_panel := 0.0

var _tablet: Tablet
var _urgente: PanelUrgente
var _dialogo: DialogoOpciones
var _notificaciones: Notificaciones
var _pausa: MenuPausa
var _hud_reloj: Label
var _hud_dinero: Label
var _hud_reputacion: Label
var _hud_bandeja: Label
var _panel_lateral: VBoxContainer
var _pantallas: Array[Label] = []

func _ready() -> void:
	randomize()
	var info := GameState.info_nivel()
	duracion = float(info["duracion"])
	var partido: String = info["partido"]
	if ":" in partido:
		partido = partido.split(":")[1].strip_edges()
	var partes := partido.split(" vs ")
	if partes.size() == 2:
		_equipos = [partes[0].strip_edges(), partes[1].strip_edges()]
	_generar_goles()
	_construir_escenario()
	_construir_estaciones()
	_construir_mesas()

	dani = Dani.new()
	dani.position = Vector2(560, 600)
	add_child(dani)
	dani.bandeja_cambiada.connect(func(_b): _actualizar_hud())

	_notificaciones = Notificaciones.new()
	add_child(_notificaciones)
	_tablet = Tablet.new()
	_tablet.notificaciones = _notificaciones
	_tablet.proveedor_cocina = _cola_cocina_texto
	add_child(_tablet)
	_urgente = PanelUrgente.new()
	_urgente.restaurante = self
	add_child(_urgente)
	_dialogo = DialogoOpciones.new()
	add_child(_dialogo)
	_pausa = MenuPausa.new()
	add_child(_pausa)
	_construir_hud()

	GameState.dinero_cambiado.connect(_al_cambiar_valor)
	GameState.reputacion_cambiada.connect(_al_cambiar_valor)
	GameState.reputacion_agotada.connect(_al_agotar_reputacion)

	AudioManager.musica("jornada")
	AudioManager.sfx("silbato")
	GameState.aviso.emit("¡Arranca el partido! %s" % info["partido"])
	if GameState.promo_activa:
		GameState.aviso.emit("Promoción 2x1 activa: llegarán más clientes.")
	_actualizar_hud()

func _al_cambiar_valor(_valor) -> void:
	_actualizar_hud()

func _al_agotar_reputacion() -> void:
	terminar_jornada("La reputación de La 501 llegó a 0%. Los clientes dejaron de venir.")

# ---------------------------------------------------------------- Construcción

func _construir_escenario() -> void:
	_pared(Rect2(0, 60, 1000, 40))                 # Pared superior
	_pared(Rect2(-40, 60, 40, 700))                # Izquierda
	_pared(Rect2(1000, 60, 40, 700))               # Derecha (panel lateral)
	_pared(Rect2(0, 710, 470, 30))                 # Pared inferior (con entrada al centro)
	_pared(Rect2(610, 710, 390, 30))
	_pared(Rect2(470, 740, 140, 20))
	_pared(Rect2(90, 140, 50, 190))                # Mostrador del pase
	_pared(Rect2(90, 410, 50, 140))                # Barra
	_pared(Rect2(90, 570, 50, 60))                 # Mueble del teléfono
	_pared(Rect2(0, 100, 90, 560))                 # Zona del chef y refrigerador
	for i in range(2):
		var pantalla := UIKit.etiqueta("", 12, Color("d9ffd9"), true)
		pantalla.position = Vector2(250 + i * 380, 66)
		pantalla.size = Vector2(200, 30)
		add_child(pantalla)
		_pantallas.append(pantalla)
	var chef := AnimatedSprite2D.new()
	chef.sprite_frames = AssetPaths.frames_personaje("chef")
	chef.animation = &"side"
	chef.flip_h = false
	chef.scale = Vector2(3, 3)
	chef.position = Vector2(55, 225)
	chef.play()
	add_child(chef)
	var etiqueta_chef := UIKit.etiqueta("CHEF", 10, UIKit.ACENTO, true)
	etiqueta_chef.position = Vector2(20, 250)
	etiqueta_chef.size = Vector2(70, 14)
	add_child(etiqueta_chef)
	var refri := AssetPaths.textura("refrigerador")
	if refri:
		var s := Sprite2D.new()
		s.texture = refri
		s.scale = Vector2(3, 3)
		s.position = Vector2(45, 460)
		add_child(s)
	for pos in [Vector2(975, 130), Vector2(20, 690)]:
		var planta := AssetPaths.textura("planta")
		if planta:
			var p := Sprite2D.new()
			p.texture = planta
			p.scale = Vector2(2.5, 2.5)
			p.position = pos
			add_child(p)
	queue_redraw()

func _pared(rect: Rect2) -> void:
	var cuerpo := StaticBody2D.new()
	cuerpo.collision_layer = 1
	cuerpo.position = rect.get_center()
	var forma := CollisionShape2D.new()
	var caja := RectangleShape2D.new()
	caja.size = rect.size
	forma.shape = caja
	cuerpo.add_child(forma)
	add_child(cuerpo)

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1280, 720), Color("15171f"))
	# Piso de madera
	draw_rect(Rect2(0, 100, 1000, 620), Color("7a4f2e"))
	for y in range(100, 720, 24):
		draw_line(Vector2(0, y), Vector2(1000, y), Color(0, 0, 0, 0.12), 1.0)
	# Cocina y barra (piso de azulejo)
	draw_rect(Rect2(0, 100, 150, 560), Color("3d4a5c"))
	for x in range(0, 150, 30):
		for y in range(100, 660, 30):
			if (x / 30 + y / 30) % 2 == 0:
				draw_rect(Rect2(x, y, 30, 30), Color("46556a"))
	# Mostradores
	draw_rect(Rect2(90, 140, 50, 190), Color("b8b8c8"))
	draw_rect(Rect2(90, 140, 50, 190), Color("6c6c80"), false, 3.0)
	draw_rect(Rect2(90, 410, 50, 140), Color("8a5a34"))
	draw_rect(Rect2(90, 410, 50, 140), Color("5a3a20"), false, 3.0)
	draw_rect(Rect2(90, 570, 50, 60), Color("8a5a34"))
	draw_rect(Rect2(102, 584, 26, 30), Color("d9534f"))   # Teléfono
	draw_rect(Rect2(10, 150, 60, 50), Color("2b2b33"))    # Estufa
	for i in range(2):
		draw_circle(Vector2(26 + i * 28, 175), 9, Color("f28c38"))
	# Pared superior con pantallas del partido
	draw_rect(Rect2(0, 60, 1000, 40), Color("2a2f3d"))
	for i in range(2):
		draw_rect(Rect2(240 + i * 380, 62, 220, 36), Color("0e3b1f"))
		draw_rect(Rect2(240 + i * 380, 62, 220, 36), Color("111111"), false, 3.0)
	# Letrero de neón
	draw_rect(Rect2(20, 64, 180, 32), Color("1b1f2a"))
	draw_rect(Rect2(20, 64, 180, 32), Color("ff5fa2"), false, 2.0)
	# Terraza
	if GameState.terraza_desbloqueada:
		draw_rect(Rect2(860, 100, 140, 610), Color("9a8a6a"))
		draw_rect(Rect2(860, 100, 140, 610), Color("5fd38d"), false, 3.0)
	# Entrada y tapete
	draw_rect(Rect2(470, 700, 140, 20), Color("5a3a20"))
	draw_rect(Rect2(490, 680, 100, 20), Color("a33b3b"))
	# Paredes inferiores
	draw_rect(Rect2(0, 710, 470, 10), Color("2a2f3d"))
	draw_rect(Rect2(610, 710, 390, 10), Color("2a2f3d"))
	# Separador del panel lateral
	draw_rect(Rect2(1000, 60, 280, 660), Color("1b1f2a"))

func _construir_estaciones() -> void:
	cocina = Estacion.new()
	cocina.configurar(Catalogo.COCINA, Vector2(170, 235))
	add_child(cocina)
	barra = Estacion.new()
	barra.configurar(Catalogo.BARRA, Vector2(170, 480))
	add_child(barra)
	add_child(PuntoInteraccion.crear("Teléfono: pedido urgente al proveedor", Vector2(170, 600), abrir_urgente, 40))
	var neon := UIKit.etiqueta("LA 501", 18, Color("ff9fd0"), true)
	neon.position = Vector2(20, 66)
	neon.size = Vector2(180, 28)
	add_child(neon)

func _construir_mesas() -> void:
	var posiciones: Array = POS_MESAS.duplicate()
	if GameState.terraza_desbloqueada:
		posiciones.append_array(POS_TERRAZA)
	for i in range(posiciones.size()):
		var mesa := Mesa.new()
		mesa.configurar(i + 1, posiciones[i], i >= 6)
		mesa.restaurante = self
		add_child(mesa)
		mesas.append(mesa)
	if GameState.terraza_desbloqueada:
		var l := UIKit.etiqueta("TERRAZA", 14, UIKit.VERDE, true)
		l.position = Vector2(860, 110)
		l.size = Vector2(140, 20)
		add_child(l)

func _generar_goles() -> void:
	var cantidad := randi_range(1, 2) if GameState.nivel_actual < 3 else 3
	for i in range(cantidad):
		_goles.append(randf_range(8.0, 86.0))
	_goles.sort()

# ---------------------------------------------------------------- Ciclo del partido

func _process(delta: float) -> void:
	if terminado:
		return
	tiempo += delta
	minuto = minf(MINUTOS_PARTIDO, tiempo / duracion * MINUTOS_PARTIDO)
	_procesar_llegadas(delta)
	_procesar_reservaciones()
	_sentar_clientes()
	_procesar_entregas(delta)
	_procesar_eventos()
	_refresco_panel += delta
	if _refresco_panel >= 0.4:
		_refresco_panel = 0.0
		_actualizar_hud()
		_actualizar_panel_lateral()
		_actualizar_carteles()
		AudioManager.murmullo(float(_clientes_sentados()) / float(mesas.size()))
	if minuto >= MINUTOS_PARTIDO:
		terminar_jornada("")

func _procesar_llegadas(delta: float) -> void:
	if minuto >= 85.0:
		return
	_acumulado_llegada += delta
	if _acumulado_llegada >= _siguiente_llegada:
		_acumulado_llegada = 0.0
		_siguiente_llegada = GameState.intervalo_llegada() * randf_range(0.75, 1.25)
		_llegar_cliente()

func _llegar_cliente() -> Cliente:
	if fila.size() >= MAX_FILA:
		return null
	var cliente: Cliente = ClienteVIP.new() if randf() < GameState.probabilidad_vip() else ClienteHabitual.new()
	_agregar_a_fila(cliente, false)
	return cliente

func _agregar_a_fila(cliente: Cliente, prioridad: bool) -> void:
	cliente.restaurante = self
	cliente.position = PUERTA
	add_child(cliente)
	if prioridad:
		fila.push_front(cliente)
	else:
		fila.append(cliente)
	cliente.se_fue.connect(_al_irse_cliente)
	_reordenar_fila()

func _reordenar_fila() -> void:
	for i in range(fila.size()):
		fila[i].mover_en_fila(INICIO_FILA + Vector2(i * 50, 0))

func _procesar_reservaciones() -> void:
	for reserva in GameState.reservaciones:
		if reserva["estado"] in ["pendiente", "asignada"] and minuto >= float(reserva["minuto"]):
			var sin_mesa: bool = reserva["estado"] == "pendiente"
			reserva["estado"] = "llego"
			var cliente := ClienteReservacion.new()
			cliente.reserva = reserva
			if sin_mesa:
				reserva["mesa"] = 0
				GameState.registrar_estadistica("reservas_sin_mesa")
				GameState.cambiar_reputacion(-5.0, "Llegó %s y no tenía mesa asignada" % reserva["nombre"])
			else:
				GameState.aviso.emit("Llegó la reservación %s (%s) para la Mesa %d." % [reserva["id"], reserva["nombre"], reserva["mesa"]])
			_agregar_a_fila(cliente, true)
			GameState.reservaciones_cambiadas.emit()

func _sentar_clientes() -> void:
	for cliente in fila.duplicate():
		if not is_instance_valid(cliente) or cliente.estado != Cliente.Estado.EN_FILA:
			fila.erase(cliente)
			continue
		var mesa := _mesa_para(cliente)
		if mesa:
			fila.erase(cliente)
			mesa.ocupar(cliente)
			cliente.ir_a_mesa(mesa)
	_reordenar_fila()

func _mesa_para(cliente: Cliente) -> Mesa:
	if cliente is ClienteReservacion and cliente.mesa_reservada() > 0:
		var propia := _mesa_numero(cliente.mesa_reservada())
		return propia if propia and propia.esta_libre() else null
	for mesa in mesas:
		if mesa.esta_libre() and GameState.reservacion_para_mesa(mesa.numero, minuto).is_empty():
			return mesa
	return null

func _mesa_numero(numero: int) -> Mesa:
	for mesa in mesas:
		if mesa.numero == numero:
			return mesa
	return null

func _actualizar_carteles() -> void:
	for mesa in mesas:
		var reserva := GameState.reservacion_para_mesa(mesa.numero, minuto, 15.0)
		mesa.actualizar_cartel("RESERVADA %d'" % reserva["minuto"] if not reserva.is_empty() else "")

func _procesar_entregas(delta: float) -> void:
	for entrega in entregas.duplicate():
		entrega["restante"] = float(entrega["restante"]) - delta
		if float(entrega["restante"]) <= 0.0:
			entregas.erase(entrega)
			GameState.recibir_urgente(entrega["insumo"], entrega["cantidad"])
			AudioManager.sfx("pedido_listo")

func _procesar_eventos() -> void:
	if not _medio_tiempo and minuto >= 45.0:
		_medio_tiempo = true
		AudioManager.sfx("silbato")
		AudioManager.intensidad(1.12)
		GameState.aviso.emit("¡MEDIO TIEMPO! Llega una ola de aficionados con sed.")
		for i in range(2 + GameState.nivel_actual):
			_llegar_cliente()
	if not _final_cerca and minuto >= 80.0:
		_final_cerca = true
		AudioManager.intensidad(1.25)
		GameState.aviso.emit("¡Últimos minutos del partido!")
	if not _goles.is_empty() and minuto >= _goles[0]:
		_goles.pop_front()
		_gol()

func _gol() -> void:
	var equipo := 0 if randf() < 0.6 else 1
	marcador[equipo] += 1
	GameState.registrar_estadistica("goles")
	AudioManager.sfx("gol")
	var rondas := 0
	for cliente in get_tree().get_nodes_in_group("clientes"):
		if randf() < 0.7 and cliente.pedir_extra():
			rondas += 1
	GameState.aviso.emit("¡GOOOL de %s! %d - %d · %d mesa(s) piden otra ronda." % [_equipos[equipo], marcador[0], marcador[1], rondas])
	var destello := ColorRect.new()
	destello.color = Color(1, 1, 1, 0.35)
	destello.size = Vector2(1000, 620)
	destello.position = Vector2(0, 100)
	destello.z_index = 80
	add_child(destello)
	var tween := destello.create_tween()
	tween.tween_property(destello, "color:a", 0.0, 0.6)
	tween.tween_callback(destello.queue_free)

func probabilidad_bebida() -> float:
	if minuto >= 45.0 and minuto <= 60.0:
		return 0.75
	return GameState.probabilidad_bebida()

func _clientes_sentados() -> int:
	var total := 0
	for mesa in mesas:
		if mesa.cliente != null:
			total += 1
	return total

# ---------------------------------------------------------------- Pedidos y faltantes

## Dani tomó la comanda de un cliente: se consume el inventario y se envía a cocina o barra.
func procesar_pedido(cliente: Cliente) -> void:
	var platillo := cliente.pedido
	if agotados.has(platillo):
		var alternativa := _alternativa(cliente, platillo)
		if alternativa != "":
			cliente.cambiar_pedido(alternativa)
			platillo = alternativa
	if GameState.preparar(platillo):
		_enviar(cliente, platillo, false)
		return
	# Cada pedido cuenta como un solo quiebre aunque Dani vuelva a intentarlo.
	if cliente.quiebre_registrado != platillo:
		cliente.quiebre_registrado = platillo
		GameState.registrar_quiebre(platillo)
	_mostrar_faltante(cliente, platillo)

func _enviar(cliente: Cliente, platillo: String, sustituto: bool) -> void:
	var estacion := cocina if Catalogo.estacion(platillo) == Catalogo.COCINA else barra
	estacion.agregar_pedido(platillo, cliente)
	cliente.pedido_confirmado(platillo, sustituto)
	AudioManager.sfx("pedido")

func _mostrar_faltante(cliente: Cliente, platillo: String) -> void:
	AudioManager.sfx("stock_bajo")
	var faltan := GameState.inventario.faltantes(platillo)
	var partes := []
	for insumo in faltan:
		partes.append("%d %s" % [faltan[insumo], Catalogo.nombre_insumo(insumo)])
	var mensaje := "Mesa %d pidió %s, pero falta: %s.\n¿Qué hacemos?" % [cliente.mesa.numero, platillo, ", ".join(partes)]
	var opciones := []
	var sustituto := _sustituto_disponible(platillo)
	if sustituto != "":
		opciones.append(["Ofrecer sustituto: %s (menos propina)" % sustituto, _usar_sustituto.bind(cliente, sustituto)])
	opciones.append(["Pedido urgente al proveedor (más caro, tarda %d s)" % int(GameState.config.urgente_demora), _faltante_urgente.bind(cliente)])
	opciones.append(["Marcar %s como agotado" % platillo, _marcar_agotado.bind(cliente, platillo)])
	_dialogo.mostrar("¡INSUMO AGOTADO!", mensaje, opciones)

func _sustituto_disponible(platillo: String) -> String:
	for opcion in Catalogo.SUSTITUTOS.get(platillo, []):
		if not agotados.has(opcion) and GameState.inventario.puede_preparar(opcion):
			return opcion
	return ""

func _alternativa(cliente: Cliente, platillo: String) -> String:
	var candidatos: Array = Catalogo.SUSTITUTOS.get(platillo, []).duplicate()
	if not cliente.es_vip():
		for p in Catalogo.MENU_HABITUAL:
			if not candidatos.has(p):
				candidatos.append(p)
	for opcion in candidatos:
		if opcion != platillo and not agotados.has(opcion) and GameState.inventario.puede_preparar(opcion):
			return opcion
	return ""

func _usar_sustituto(cliente: Cliente, sustituto: String) -> void:
	if not is_instance_valid(cliente) or cliente.estado != Cliente.Estado.ORDENANDO:
		return
	if GameState.preparar(sustituto):
		GameState.registrar_estadistica("sustitutos")
		_enviar(cliente, sustituto, true)

func _faltante_urgente(cliente: Cliente) -> void:
	if is_instance_valid(cliente) and cliente.estado == Cliente.Estado.ORDENANDO:
		cliente.esperar_insumo()
	abrir_urgente()

func _marcar_agotado(cliente: Cliente, platillo: String) -> void:
	if not agotados.has(platillo):
		agotados.append(platillo)
		GameState.registrar_estadistica("agotados")
		GameState.aviso.emit("%s marcado como AGOTADO en el menú." % platillo)
	if not is_instance_valid(cliente) or cliente.estado != Cliente.Estado.ORDENANDO:
		return
	var alternativa := _alternativa(cliente, platillo)
	if alternativa == "":
		cliente.irse_enojado("No quedaba nada del menú para %s" % cliente.nombre_tipo())
		return
	cliente.cambiar_pedido(alternativa)
	GameState.aviso.emit("El cliente cambió su pedido a %s." % alternativa)
	procesar_pedido(cliente)

func cancelar_pedidos(cliente: Cliente) -> void:
	cocina.cancelar(cliente)
	barra.cancelar(cliente)

func _al_irse_cliente(cliente: Cliente, _enojado: bool) -> void:
	fila.erase(cliente)

func abrir_urgente() -> void:
	if not _urgente.esta_abierto():
		_urgente.abrir("PEDIDO URGENTE POR TELÉFONO")

func pedir_urgente(insumo: String, cantidad: int) -> bool:
	if not GameState.pagar_urgente(insumo, cantidad):
		AudioManager.sfx("error")
		return false
	AudioManager.sfx("telefono")
	entregas.append({"insumo": insumo, "cantidad": cantidad, "restante": GameState.config.urgente_demora})
	GameState.aviso.emit("Pedido urgente: %d %s llegará en %d s." % [cantidad, Catalogo.nombre_insumo(insumo), int(GameState.config.urgente_demora)])
	return true

func posicion_puerta() -> Vector2:
	return PUERTA

func mostrar_ganancia(pos: Vector2, cantidad: int) -> void:
	var l := UIKit.etiqueta("+%s" % UIKit.dinero(cantidad), 16, UIKit.VERDE, true)
	l.position = pos + Vector2(-50, -110)
	l.size = Vector2(100, 20)
	l.z_index = 60
	add_child(l)
	var tween := l.create_tween()
	tween.tween_property(l, "position:y", l.position.y - 30, 0.9)
	tween.parallel().tween_property(l, "modulate:a", 0.0, 0.9)
	tween.tween_callback(l.queue_free)

# ---------------------------------------------------------------- Entrada del jugador

func _unhandled_input(evento: InputEvent) -> void:
	if terminado or PanelModal.abiertos > 0 or _pausa.esta_abierto():
		return
	if evento.is_action_pressed("tablet"):
		get_viewport().set_input_as_handled()
		_tablet.abrir_seccion("stock")
	elif evento.is_action_pressed("pedido_urgente"):
		get_viewport().set_input_as_handled()
		abrir_urgente()
	elif evento.is_action_pressed("reservaciones"):
		get_viewport().set_input_as_handled()
		_tablet.abrir_seccion("reservaciones")

# ---------------------------------------------------------------- Fin de la jornada

func terminar_jornada(motivo: String) -> void:
	if terminado:
		return
	terminado = true
	AudioManager.sfx("silbato")
	AudioManager.murmullo(0.0)
	AudioManager.intensidad(1.0)
	for panel in [_tablet, _urgente, _dialogo]:
		panel.cerrar()
	dani.bloqueado = true
	for cliente in get_tree().get_nodes_in_group("clientes"):
		cliente.retirarse()
	GameState.aviso.emit("¡Final del partido! %d - %d" % [marcador[0], marcador[1]] if motivo == "" else motivo)
	GameState.cerrar_jornada(motivo)
	await get_tree().create_timer(1.8).timeout
	AudioManager.musica("")
	GameState.cambiar_escena(GameState.ESCENA_REPORTE)

# ---------------------------------------------------------------- HUD y panel lateral

func _construir_hud() -> void:
	var capa := UIKit.capa(20)
	add_child(capa)
	var barra_superior := UIKit.panel(UIKit.FONDO, UIKit.BORDE, 6)
	barra_superior.position = Vector2(6, 4)
	barra_superior.size = Vector2(1268, 50)
	var fila_hud := UIKit.hbox(22)
	barra_superior.add_child(fila_hud)
	fila_hud.add_child(UIKit.etiqueta("NIVEL %d · %s" % [GameState.nivel_actual, GameState.info_nivel()["nombre"].to_upper()], 16, UIKit.ACENTO))
	_hud_reloj = UIKit.etiqueta("", 16, Color("d9ffd9"))
	_hud_dinero = UIKit.etiqueta("", 16)
	_hud_reputacion = UIKit.etiqueta("", 16)
	_hud_bandeja = UIKit.etiqueta("", 16)
	for l in [_hud_reloj, _hud_dinero, _hud_reputacion, _hud_bandeja]:
		fila_hud.add_child(l)
	capa.add_child(barra_superior)

	var lateral := UIKit.panel(UIKit.FONDO_CLARO, Color(UIKit.BORDE, 0.5), 10)
	lateral.position = Vector2(1006, 62)
	lateral.size = Vector2(268, 626)
	lateral.clip_contents = true
	_panel_lateral = UIKit.vbox(3)
	lateral.add_child(_panel_lateral)
	capa.add_child(lateral)

	var ayuda := UIKit.etiqueta("Espacio Interactuar · E Tablet · Esc Pausa\nQ Pedido urgente · R Reservaciones", 10, UIKit.TEXTO_TENUE, true)
	ayuda.position = Vector2(1006, 689)
	ayuda.size = Vector2(268, 30)
	capa.add_child(ayuda)
	_actualizar_panel_lateral()

func _actualizar_hud() -> void:
	if _hud_reloj == null:
		return
	_hud_reloj.text = "%d' · %s %d - %d %s" % [int(minuto), _equipos[0].left(10), marcador[0], marcador[1], _equipos[1].left(10)]
	_hud_dinero.text = "Dinero %s" % UIKit.dinero(GameState.dinero)
	_hud_reputacion.text = "%s %d%%" % [UIKit.estrellas(GameState.reputacion), int(GameState.reputacion)]
	_hud_bandeja.text = "Bandeja %d/%d" % [dani.bandeja.size() if dani else 0, GameState.capacidad_bandeja()]
	var texto_pantalla := "%s %d-%d %s  %d'" % [_equipos[0].left(8), marcador[0], marcador[1], _equipos[1].left(8), int(minuto)]
	for p in _pantallas:
		p.text = texto_pantalla

func _actualizar_panel_lateral() -> void:
	if _panel_lateral == null:
		return
	UIKit.limpiar(_panel_lateral)
	_panel_lateral.add_child(UIKit.etiqueta("STOCK", 14, UIKit.ACENTO))
	var inv := GameState.inventario
	for insumo in Catalogo.INSUMOS:
		var cantidad := inv.total(insumo)
		var en_camino := 0
		for e in entregas:
			if e["insumo"] == insumo:
				en_camino += int(e["cantidad"])
		var texto := "%s: %d%s" % [Catalogo.nombre_insumo(insumo), cantidad, "  (+%d en camino)" % en_camino if en_camino > 0 else ""]
		_panel_lateral.add_child(UIKit.etiqueta(texto, 12, UIKit.ROJO if cantidad <= 2 else UIKit.TEXTO))
	if not agotados.is_empty():
		_panel_lateral.add_child(UIKit.etiqueta("Agotado: " + ", ".join(agotados), 11, UIKit.ROJO))
	_panel_lateral.add_child(HSeparator.new())
	_panel_lateral.add_child(UIKit.etiqueta("COLA DE COCINA", 14, UIKit.ACENTO))
	_panel_lateral.add_child(UIKit.etiqueta("Cocina: %d en cola · %d listos" % [cocina.pendientes(), cocina.listos.size()], 12))
	_panel_lateral.add_child(UIKit.etiqueta("Barra: %d en cola · %d listos" % [barra.pendientes(), barra.listos.size()], 12))
	_panel_lateral.add_child(UIKit.etiqueta("Fila en la entrada: %d" % fila.size(), 12, UIKit.ROJO if fila.size() >= 4 else UIKit.TEXTO))
	_panel_lateral.add_child(HSeparator.new())
	_panel_lateral.add_child(UIKit.etiqueta("RESERVACIONES", 14, UIKit.ACENTO))
	if GameState.reservaciones.is_empty():
		_panel_lateral.add_child(UIKit.etiqueta("Sin reservaciones hoy", 12, UIKit.TEXTO_TENUE))
	for r in GameState.reservaciones:
		var estado: String = {"pendiente": "SIN MESA", "asignada": "Mesa %d" % r["mesa"], "llego": "Llegó", "atendida": "Atendida"}.get(r["estado"], "")
		var color := UIKit.ROJO if r["estado"] == "pendiente" else (UIKit.VERDE if r["estado"] == "atendida" else UIKit.TEXTO)
		_panel_lateral.add_child(UIKit.etiqueta("%d' %s (%d) · %s" % [r["minuto"], r["id"], r["personas"], estado], 12, color))
	_panel_lateral.add_child(HSeparator.new())
	_panel_lateral.add_child(UIKit.etiqueta("Objetivo:", 13, UIKit.ACENTO))
	for linea in GameState.detalle_objetivo():
		var l := UIKit.etiqueta(linea, 11)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 244
		_panel_lateral.add_child(l)

func _cola_cocina_texto() -> Array:
	var lineas: Array = []
	lineas.append_array(cocina.descripcion_cola())
	lineas.append_array(barra.descripcion_cola())
	return lineas
