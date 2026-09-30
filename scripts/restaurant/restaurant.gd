extends Node2D

## Fase de jornada: Dani atiende La 501 durante el partido.
## Distribución (sección 9 del documento): cocina y barra a la izquierda, mesas al centro,
## pantallas en la pared superior, entrada abajo y panel de gestión a la derecha.

const AREA_JUEGO := Rect2(0, 100, 1000, 620)
const PUERTA := Vector2(552, 770)
const INICIO_FILA := Vector2(660, 652)
const ORIGEN_TILES := Vector2(0, 4)
const COLUMNAS_TILES := 21
const MAX_FILA := 5
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
# Eventos del partido
var _eventos: Array[Dictionary] = []      # {"minuto": float, "tipo": String}
var _retraso_hasta := -1.0                # Minuto hasta el que el proveedor viene retrasado
var _apagon := 0.0                        # Segundos restantes de apagón
var _velo_apagon: ColorRect
var penales := false
var _penales_restante := 0.0
const DURACION_PENALES := 20.0
var _equipos := ["LOCAL", "VISITA"]
# Práctica de la Jornada 1: antes del partido, un cliente de prueba y el tutorial.
var practica := false
var _cliente_practica: Cliente
var _mesa_practica: Mesa
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
var _lateral := {}
var _pantallas: Array[Label] = []
var _televisores: Array[Sprite2D] = []
var _neon: Sprite2D
var _cuadro_tv := 0.0
var _gol_en_pantalla := 0.0
var _parpadeo := 0.0

func _ready() -> void:
	randomize()
	var info := GameState.info_nivel()
	duracion = GameState.duracion_partido()
	var partido: String = info["partido"]
	if ":" in partido:
		partido = partido.split(":")[1].strip_edges()
	var partes := partido.split(" vs ")
	if partes.size() == 2:
		_equipos = [partes[0].strip_edges(), partes[1].strip_edges()]
	_generar_goles()
	_generar_eventos()
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
	practica = GameState.tutorial_pendiente("restaurante")
	if practica:
		GameState.aviso.emit("Antes del partido: una práctica rápida con un cliente de prueba.")
		_iniciar_practica.call_deferred()
	else:
		_arrancar_partido()
	_actualizar_hud()

func _arrancar_partido() -> void:
	AudioManager.sfx("silbato")
	GameState.aviso.emit("¡Arranca el partido! %s" % GameState.info_nivel()["partido"])
	if GameState.promo_activa:
		GameState.aviso.emit("Promoción 2x1 activa: llegarán más clientes.")

# ---------------------------------------------------------------- Práctica (Jornada 1)

func _iniciar_practica() -> void:
	_cliente_practica = ClientePractica.new()
	_agregar_a_fila(_cliente_practica, true)
	var pasos: Array[Dictionary] = [
		{"texto": "Llegó un cliente de práctica: cuando se siente, acércate a su mesa y presiona Espacio.",
			"detalle": "La barra sobre cada cliente es su paciencia; si se vacía, se va molesto y baja la reputación.",
			"hecho": func() -> bool: return _practica_en(Cliente.Estado.ESPERANDO_COMIDA)},
		{"texto": "Recoge su refresco en la Barra de bebidas cuando esté listo (Espacio).",
			"detalle": "La comida sale en el Pase de cocina y las bebidas en la Barra. Cargas hasta 3 platillos en la bandeja.",
			"hecho": func() -> bool: return dani.tiene_platillo(Catalogo.REFRESCO) or _practica_en(Cliente.Estado.COMIENDO)},
		{"texto": "Llévalo a la mesa y presiona Espacio para servir.",
			"detalle": "Mientras más rápido sirvas, más propina deja el cliente.",
			"hecho": func() -> bool: return _practica_en(Cliente.Estado.COMIENDO)},
		{"texto": "Cuando se vaya, la mesa queda sucia: mantén Espacio sobre ella hasta limpiarla.",
			"detalle": "Una mesa sucia no puede recibir clientes nuevos.",
			"hecho": func() -> bool: return _practica_en(Cliente.Estado.SALIENDO) and _mesa_practica != null and _mesa_practica.estado == Mesa.EstadoMesa.LIMPIA},
		{"texto": "Presiona E para abrir la tablet; ciérrala con Esc.",
			"detalle": "Ahí ves el stock de cada insumo, la cola de cocina y los avisos del partido.",
			"hecho": func() -> bool: return _tablet.esta_abierto()},
		{"texto": "Si un insumo se acaba, Q hace un pedido urgente. Presiona Espacio para empezar el partido.",
			"detalle": "El urgente cuesta más y tarda en llegar. Objetivo de hoy: no quedarte sin stock y perder máximo 3 clientes.",
			"hecho": func() -> bool: return PanelModal.abiertos == 0 and Input.is_action_just_pressed("interactuar")},
	]
	var tutorial := Tutorial.new("restaurante", pasos)
	tutorial.terminado.connect(_terminar_practica)
	add_child(tutorial)

## El cliente de práctica ya llegó (o pasó) a ese estado. Si ya se fue, cuenta como pasado.
func _practica_en(estado: Cliente.Estado) -> bool:
	if not is_instance_valid(_cliente_practica):
		return true
	if _cliente_practica.mesa:
		_mesa_practica = _cliente_practica.mesa
	return _cliente_practica.estado >= estado and _cliente_practica.estado != Cliente.Estado.EN_FILA

func _terminar_practica() -> void:
	if not practica:
		return
	practica = false
	if is_instance_valid(_cliente_practica) and _cliente_practica.estado != Cliente.Estado.SALIENDO:
		cancelar_pedidos(_cliente_practica)
		fila.erase(_cliente_practica)
		if _cliente_practica.mesa:
			_cliente_practica.mesa.liberar(false)
		_cliente_practica.retirarse()
	_acumulado_llegada = 0.0
	_siguiente_llegada = 3.0
	_arrancar_partido()
	_actualizar_hud()

func _al_cambiar_valor(_valor) -> void:
	_actualizar_hud()

func _al_agotar_reputacion() -> void:
	terminar_jornada("La reputación de La 501 llegó a 0%. Los clientes dejaron de venir.")

# ---------------------------------------------------------------- Construcción

func _construir_escenario() -> void:
	# Interior con tiles de Kenney (Roguelike RPG + Indoors). Cada tile mide 48 px;
	# la fila 0 empieza en y = 4, así la fila 2 (el piso) empieza en y = 100.
	var fondo := ColorRect.new()
	fondo.color = Color("15171f")
	fondo.size = Vector2(1280, 720)
	fondo.z_index = -20
	add_child(fondo)
	var interior := Interior.new()
	interior.position = ORIGEN_TILES
	interior.z_index = -10
	add_child(interior)
	var R := Interior.RPG
	var I := Interior.INDOOR
	for x in range(COLUMNAS_TILES):
		interior.poner(x, 0, R, Interior.PARED_ALTA, 0)
		interior.poner(x, 1, R, Interior.PARED_BAJA, 0)
	interior.rellenar(3, 2, COLUMNAS_TILES - 3, 13, R, Interior.PISO_MADERA)
	interior.rellenar(0, 2, 3, 13, R, Interior.PISO_PIEDRA)
	if GameState.terraza_desbloqueada:
		interior.rellenar(18, 2, 3, 13, R, Interior.PISO_CLARO)
	# Ventanas entre las pantallas
	for x in [10, 11]:
		interior.columna(x, 0, R, [158, 215], 0)
	# Cocina: estufa, horno y mostradores con trastes; pase de cocina (mostrador gris)
	interior.fila(0, 2, I, [392, 393])
	interior.columna(0, 3, I, [328, 329, 330, 331])
	interior.columna(2, 3, I, [361, 361, 361, 388])
	# Barra de bebidas (madera), refrigerador y repisa con botellas
	interior.columna(2, 8, I, [390, 417, 444])
	interior.columna(0, 8, R, [207, 264])
	interior.columna(1, 8, R, [784, 785])
	interior.columna(1, 8, R, [738, 852], 2)
	interior.fila(0, 11, R, [23, 24])
	interior.fila(0, 12, R, [24, 23])
	# Mueble del teléfono
	interior.poner(2, 12, I, 408)
	interior.poner(2, 12, R, 1017, 2)
	# Pared inferior con la entrada al centro y tapete
	for x in range(COLUMNAS_TILES):
		if x < 10 or x > 12:
			interior.poner(x, 14, R, Interior.BORDE_INF[1], 0)
	interior.poner(9, 14, R, Interior.BORDE_INF_CORTE[0], 0)
	interior.poner(13, 14, R, Interior.BORDE_INF_CORTE[1], 0)
	interior.fila(10, 12, R, [922, 923, 924], 0)
	interior.fila(10, 13, R, [1036, 1037, 1038], 0)
	# Plantas
	interior.poner(20, 2, I, 16)
	interior.poner(3, 13, I, 17)

	_pared(Rect2(0, 52, 1000, 48))                 # Pared superior
	_pared(Rect2(-40, 60, 40, 700))                # Izquierda
	_pared(Rect2(1000, 60, 40, 700))               # Derecha (panel lateral)
	_pared(Rect2(0, 700, 480, 40))                 # Pared inferior (entrada entre x 480 y 624)
	_pared(Rect2(624, 700, 376, 40))
	_pared(Rect2(480, 740, 144, 20))
	_pared(Rect2(96, 148, 48, 192))                # Mostrador del pase
	_pared(Rect2(96, 388, 48, 144))                # Barra
	_pared(Rect2(96, 580, 48, 48))                 # Mueble del teléfono
	_pared(Rect2(0, 100, 96, 628))                 # Cocina y trastienda
	_pared(Rect2(144, 628, 48, 48))                # Maceta
	for i in range(2):
		var tv := Sprite2D.new()
		tv.texture = AssetPaths.textura("tv_1")
		tv.scale = Vector2(2.5, 2.5)
		tv.position = Vector2(350 + i * 380, 80)
		add_child(tv)
		_televisores.append(tv)
		var marcador := UIKit.etiqueta("", 10, Color("d9ffd9"), true)
		marcador.position = Vector2(tv.position.x - 90, 57)
		marcador.size = Vector2(180, 16)
		marcador.add_theme_constant_override("outline_size", 0)
		add_child(marcador)
		_pantallas.append(marcador)
	_neon = Sprite2D.new()
	_neon.texture = AssetPaths.textura("neon_on")
	_neon.scale = Vector2(2.5, 2.5)
	_neon.position = Vector2(110, 79)
	add_child(_neon)
	var chef := AnimatedSprite2D.new()
	chef.sprite_frames = AssetPaths.frames_personaje("chef")
	chef.animation = &"side"
	chef.flip_h = false
	chef.scale = AssetPaths.escala("chef")
	chef.position = Vector2(72, 215)
	chef.play()
	add_child(chef)
	var etiqueta_chef := UIKit.etiqueta("CHEF", 10, UIKit.ACENTO, true)
	etiqueta_chef.position = Vector2(37, 240)
	etiqueta_chef.size = Vector2(70, 14)
	add_child(etiqueta_chef)
	var etiqueta_tel := UIKit.etiqueta("TELÉFONO", 9, UIKit.TEXTO, true)
	etiqueta_tel.position = Vector2(80, 626)
	etiqueta_tel.size = Vector2(80, 12)
	add_child(etiqueta_tel)
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
	# El piso, las paredes y los muebles son tiles (ver _construir_escenario).
	# Separador del panel lateral
	draw_rect(Rect2(1000, 52, 280, 668), Color("1b1f2a"))

func _construir_estaciones() -> void:
	cocina = Estacion.new()
	cocina.configurar(Catalogo.COCINA, Vector2(170, 235))
	add_child(cocina)
	barra = Estacion.new()
	barra.configurar(Catalogo.BARRA, Vector2(170, 480))
	add_child(barra)
	add_child(PuntoInteraccion.crear("Teléfono: pedido urgente al proveedor", Vector2(170, 600), abrir_urgente, 40))

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
	if practica:
		# Antes del partido: solo se mueve el cliente de práctica; el reloj no corre.
		_sentar_clientes()
		_animar_decoracion(delta)
		_refresco_panel += delta
		if _refresco_panel >= 0.4:
			_refresco_panel = 0.0
			_actualizar_hud()
			_actualizar_panel_lateral()
			_actualizar_carteles()
		return
	tiempo += delta
	minuto = minf(MINUTOS_PARTIDO, tiempo / duracion * MINUTOS_PARTIDO)
	_procesar_llegadas(delta)
	_procesar_reservaciones()
	_sentar_clientes()
	_procesar_entregas(delta)
	_procesar_eventos()
	_procesar_eventos_especiales(delta)
	_animar_decoracion(delta)
	_refresco_panel += delta
	if _refresco_panel >= 0.4:
		_refresco_panel = 0.0
		_actualizar_hud()
		_actualizar_panel_lateral()
		_actualizar_carteles()
		AudioManager.murmullo(float(_clientes_sentados()) / float(mesas.size()))
	if minuto >= MINUTOS_PARTIDO:
		_final_del_partido(delta)

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
	var cliente: Cliente
	if randf() < GameState.probabilidad_vip():
		cliente = ClienteVIP.new()
	else:
		cliente = ClienteHabitual.new()
		cliente.personas = GameState.tamano_grupo()
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
		fila[i].mover_en_fila(INICIO_FILA + Vector2(i * 68, 0))

func _procesar_reservaciones() -> void:
	for reserva in GameState.reservaciones:
		if reserva["estado"] in ["pendiente", "asignada"] and minuto >= float(reserva["minuto"]):
			var sin_mesa: bool = reserva["estado"] == "pendiente"
			reserva["estado"] = "llego"
			var cliente := ClienteReservacion.new()
			cliente.reserva = reserva
			cliente.personas = int(reserva["personas"])
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
	# La mesa libre más chica en la que quepa el grupo (las de 4 quedan para familias).
	var mejor: Mesa = null
	for mesa in mesas:
		if mesa.esta_libre() and mesa.capacidad >= cliente.personas and GameState.reservacion_para_mesa(mesa.numero, minuto).is_empty():
			if mejor == null or mesa.capacidad < mejor.capacidad:
				mejor = mesa
	return mejor

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

# ---------------------------------------------------------------- Eventos del partido

## Nivel 1: un evento; Liguilla: uno o dos; Gran Final: dos. Nunca se repite el mismo.
func _generar_eventos() -> void:
	var cantidad: int = {1: 1, 2: randi_range(1, 2), 3: 2}.get(GameState.nivel_actual, 1)
	var tipos := ["retraso", "critico", "apagon"]
	tipos.shuffle()
	var minutos := [randf_range(15.0, 38.0), randf_range(52.0, 75.0)]
	for i in range(mini(cantidad, tipos.size())):
		_eventos.append({"minuto": minutos[i % minutos.size()], "tipo": tipos[i]})
	_eventos.sort_custom(func(a, b): return a["minuto"] < b["minuto"])

func _procesar_eventos_especiales(delta: float) -> void:
	if not _eventos.is_empty() and minuto >= float(_eventos[0]["minuto"]):
		_evento(_eventos.pop_front()["tipo"])
	if _apagon > 0.0:
		_apagon -= delta
		if _apagon <= 0.0:
			_fin_apagon()

func _evento(tipo: String) -> void:
	match tipo:
		"retraso":
			_retraso_hasta = minuto + 20.0
			for entrega in entregas:
				entrega["restante"] = float(entrega["restante"]) + GameState.demora_urgente() * 0.5
			AudioManager.sfx("telefono")
			GameState.aviso.emit("EVENTO: el proveedor avisa que viene retrasado. Los pedidos urgentes tardarán 50% más un rato.")
		"critico":
			var critico := ClienteCritico.new()
			_agregar_a_fila(critico, true)
			AudioManager.sfx("pedido")
			GameState.aviso.emit("EVENTO: ¡llegó un crítico gastronómico! Atiéndelo rápido: una buena reseña da +10% de reputación.")
		"apagon":
			_apagon = 10.0
			cocina.pausada = true
			barra.pausada = true
			if _velo_apagon == null:
				_velo_apagon = ColorRect.new()
				_velo_apagon.color = Color(0.02, 0.02, 0.08, 0.5)
				_velo_apagon.size = Vector2(1000, 620)
				_velo_apagon.position = Vector2(0, 100)
				_velo_apagon.z_index = 70
				_velo_apagon.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(_velo_apagon)
			_velo_apagon.visible = true
			for tv in _televisores:
				tv.visible = false
			AudioManager.sfx("error")
			GameState.aviso.emit("EVENTO: ¡se fue la luz! La cocina y la barra se detienen 10 segundos.")

func _fin_apagon() -> void:
	cocina.pausada = false
	barra.pausada = false
	if _velo_apagon:
		_velo_apagon.visible = false
	for tv in _televisores:
		tv.visible = true
	GameState.aviso.emit("Regresó la luz. ¡A seguir!")

func _demora_actual() -> float:
	return GameState.demora_urgente() * (1.5 if minuto < _retraso_hasta else 1.0)

## Al llegar al 90': si el partido va empatado hay penales (20 s más y otra ronda de bebidas).
func _final_del_partido(delta: float) -> void:
	if not penales and marcador[0] == marcador[1] and _penales_restante == 0.0:
		penales = true
		_penales_restante = DURACION_PENALES
		AudioManager.sfx("silbato")
		AudioManager.intensidad(1.35)
		var rondas := 0
		for cliente in get_tree().get_nodes_in_group("clientes"):
			if randf() < 0.7 and cliente.pedir_extra():
				rondas += 1
		GameState.aviso.emit("¡EMPATE! Se va a penales: 20 s más de partido y %d mesa(s) piden otra ronda." % rondas)
		return
	if penales:
		_penales_restante -= delta
		if _penales_restante > 0.0:
			return
		penales = false
		_penales_restante = -1.0
		var ganador := 0 if randf() < 0.6 else 1
		marcador[ganador] += 1
		GameState.aviso.emit("¡%s gana en penales!" % _equipos[ganador])
	terminar_jornada("")

func _gol() -> void:
	var equipo := 0 if randf() < 0.6 else 1
	marcador[equipo] += 1
	GameState.registrar_estadistica("goles")
	AudioManager.sfx("gol")
	_gol_en_pantalla = 2.5
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

## Pantallas: la jugada alterna dos cuadros; en un gol muestran "GOL!". El neón parpadea a ratos.
func _animar_decoracion(delta: float) -> void:
	_cuadro_tv += delta
	if _gol_en_pantalla > 0.0:
		_gol_en_pantalla -= delta
	var clave := "tv_gol" if _gol_en_pantalla > 0.0 else ("tv_1" if int(_cuadro_tv / 0.6) % 2 == 0 else "tv_2")
	for tv in _televisores:
		tv.texture = AssetPaths.textura(clave)
	_parpadeo -= delta
	if _parpadeo <= 0.0:
		var apagado := randf() < 0.18
		_neon.texture = AssetPaths.textura("neon_off" if apagado else "neon_on")
		_parpadeo = randf_range(0.05, 0.15) if apagado else randf_range(0.8, 3.0)

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
	if cliente is ClientePractica:
		_enviar(cliente, cliente.pedido, false)
		return
	var platillo := cliente.pedido
	if agotados.has(platillo):
		var alternativa := _alternativa(cliente, platillo)
		if alternativa != "":
			cliente.cambiar_pedido(alternativa)
			platillo = alternativa
	if GameState.preparar(platillo, cliente.personas):
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
	var faltan := GameState.inventario.faltantes(platillo, cliente.personas)
	var partes := []
	for insumo in faltan:
		partes.append("%d %s" % [faltan[insumo], Catalogo.nombre_insumo(insumo)])
	var para := " para %d personas" % cliente.personas if cliente.personas > 1 else ""
	var mensaje := "Mesa %d pidió %s%s, pero falta: %s.\n¿Qué hacemos?" % [cliente.mesa.numero, platillo, para, ", ".join(partes)]
	var opciones := []
	var sustituto := _sustituto_disponible(platillo, cliente.personas)
	if sustituto != "":
		opciones.append(["Ofrecer sustituto: %s (menos propina)" % sustituto, _usar_sustituto.bind(cliente, sustituto)])
	opciones.append(["Pedido urgente al proveedor (más caro, tarda %d s)" % int(_demora_actual()), _faltante_urgente.bind(cliente)])
	opciones.append(["Marcar %s como agotado" % platillo, _marcar_agotado.bind(cliente, platillo)])
	_dialogo.mostrar("¡INSUMO AGOTADO!", mensaje, opciones)

func _sustituto_disponible(platillo: String, porciones: int = 1) -> String:
	for opcion in Catalogo.SUSTITUTOS.get(platillo, []):
		if not agotados.has(opcion) and GameState.inventario.puede_preparar(opcion, porciones):
			return opcion
	return ""

func _alternativa(cliente: Cliente, platillo: String) -> String:
	var candidatos: Array = Catalogo.SUSTITUTOS.get(platillo, []).duplicate()
	if not cliente.es_vip():
		for p in Catalogo.MENU_HABITUAL:
			if not candidatos.has(p):
				candidatos.append(p)
	for opcion in candidatos:
		if opcion != platillo and not agotados.has(opcion) and GameState.inventario.puede_preparar(opcion, cliente.personas):
			return opcion
	return ""

func _usar_sustituto(cliente: Cliente, sustituto: String) -> void:
	if not is_instance_valid(cliente) or cliente.estado != Cliente.Estado.ORDENANDO:
		return
	if GameState.preparar(sustituto, cliente.personas):
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
	var demora := _demora_actual()
	entregas.append({"insumo": insumo, "cantidad": cantidad, "restante": demora})
	GameState.aviso.emit("Pedido urgente: %d %s llegará en %d s." % [cantidad, Catalogo.nombre_insumo(insumo), int(demora)])
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

	var ayuda := UIKit.etiqueta("Shift Correr · Espacio Usar · E Tablet\nQ Urgente · R Reservas · Esc Pausa", 10, UIKit.TEXTO_TENUE, true)
	ayuda.position = Vector2(1006, 689)
	ayuda.size = Vector2(268, 30)
	capa.add_child(ayuda)
	_actualizar_panel_lateral()

func _actualizar_hud() -> void:
	if _hud_reloj == null:
		return
	var reloj := "PENALES" if penales else "%d'" % int(minuto)
	if practica:
		reloj = "PRÁCTICA"
	_fijar(_hud_reloj, "%s · %s %d - %d %s" % [reloj, _equipos[0].left(10), marcador[0], marcador[1], _equipos[1].left(10)], Color("d9ffd9"))
	_fijar(_hud_dinero, "Dinero %s" % UIKit.dinero(GameState.dinero), UIKit.TEXTO)
	_fijar(_hud_reputacion, "%s %d%%" % [UIKit.estrellas(GameState.reputacion), int(GameState.reputacion)], UIKit.TEXTO)
	_fijar(_hud_bandeja, "Bandeja %d/%d" % [dani.bandeja.size() if dani else 0, GameState.capacidad_bandeja()], UIKit.TEXTO)
	var texto_pantalla := "%s %d-%d %s  %d'" % [_equipos[0].left(8), marcador[0], marcador[1], _equipos[1].left(8), int(minuto)]
	for p in _pantallas:
		p.text = texto_pantalla

## El panel se construye una sola vez; después solo se actualizan textos y colores.
func _actualizar_panel_lateral() -> void:
	if _panel_lateral == null:
		return
	if _lateral.is_empty():
		_construir_panel_lateral()
	var inv := GameState.inventario
	for insumo in Catalogo.INSUMOS:
		var cantidad := inv.total(insumo)
		var en_camino := 0
		for e in entregas:
			if e["insumo"] == insumo:
				en_camino += int(e["cantidad"])
		var color_stock := UIKit.ROJO if cantidad <= 2 else (Color("f2d16b") if cantidad <= GameState.STOCK_BAJO else UIKit.TEXTO)
		_fijar(_lateral["stock"][insumo], "%s: %d%s" % [Catalogo.nombre_insumo(insumo), cantidad, "  (+%d en camino)" % en_camino if en_camino > 0 else ""], color_stock)
	_lateral["agotados"].visible = not agotados.is_empty()
	_fijar(_lateral["agotados"], "Agotado: " + ", ".join(agotados), UIKit.ROJO)
	_fijar(_lateral["cocina"], "Cocina: %d en cola · %d listos" % [cocina.pendientes(), cocina.listos.size()], UIKit.TEXTO)
	_fijar(_lateral["barra"], "Barra: %d en cola · %d listos" % [barra.pendientes(), barra.listos.size()], UIKit.TEXTO)
	_fijar(_lateral["fila"], "Fila en la entrada: %d" % fila.size(), UIKit.ROJO if fila.size() >= 4 else UIKit.TEXTO)
	var etiquetas_reserva: Array = _lateral["reservas"]
	for i in range(etiquetas_reserva.size()):
		var r: Dictionary = GameState.reservaciones[i]
		var estado: String = {"pendiente": "SIN MESA", "asignada": "Mesa %d" % r["mesa"], "llego": "Llegó", "atendida": "Atendida"}.get(r["estado"], "")
		var color := UIKit.ROJO if r["estado"] == "pendiente" else (UIKit.VERDE if r["estado"] == "atendida" else UIKit.TEXTO)
		_fijar(etiquetas_reserva[i], "%d' %s (%d) · %s" % [r["minuto"], r["id"], r["personas"], estado], color)
	var lineas := GameState.detalle_objetivo()
	var etiquetas_objetivo: Array = _lateral["objetivo"]
	for i in range(mini(lineas.size(), etiquetas_objetivo.size())):
		_fijar(etiquetas_objetivo[i], lineas[i], UIKit.TEXTO)

func _construir_panel_lateral() -> void:
	var p := _panel_lateral
	p.add_child(UIKit.etiqueta("STOCK", 14, UIKit.ACENTO))
	var stock := {}
	for insumo in Catalogo.INSUMOS:
		stock[insumo] = UIKit.etiqueta("", 12)
		p.add_child(stock[insumo])
	var agotado := UIKit.etiqueta("", 11, UIKit.ROJO)
	p.add_child(agotado)
	p.add_child(HSeparator.new())
	p.add_child(UIKit.etiqueta("COLA DE COCINA", 14, UIKit.ACENTO))
	var etiqueta_cocina := UIKit.etiqueta("", 12)
	var etiqueta_barra := UIKit.etiqueta("", 12)
	var etiqueta_fila := UIKit.etiqueta("", 12)
	for l in [etiqueta_cocina, etiqueta_barra, etiqueta_fila]:
		p.add_child(l)
	p.add_child(HSeparator.new())
	p.add_child(UIKit.etiqueta("RESERVACIONES", 14, UIKit.ACENTO))
	var reservas: Array[Label] = []
	if GameState.reservaciones.is_empty():
		p.add_child(UIKit.etiqueta("Sin reservaciones hoy", 12, UIKit.TEXTO_TENUE))
	for i in range(GameState.reservaciones.size()):
		var l := UIKit.etiqueta("", 12)
		p.add_child(l)
		reservas.append(l)
	p.add_child(HSeparator.new())
	p.add_child(UIKit.etiqueta("Objetivo:", 13, UIKit.ACENTO))
	var objetivo: Array[Label] = []
	for i in range(GameState.detalle_objetivo().size()):
		var l := UIKit.etiqueta("", 11)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 244
		p.add_child(l)
		objetivo.append(l)
	_lateral = {"stock": stock, "agotados": agotado, "cocina": etiqueta_cocina, "barra": etiqueta_barra, "fila": etiqueta_fila, "reservas": reservas, "objetivo": objetivo}

## Cambia texto y color solo si son distintos (evita recalcular el diseño de la interfaz).
func _fijar(etiqueta: Label, texto: String, color: Color) -> void:
	if etiqueta.text != texto:
		etiqueta.text = texto
	if etiqueta.get_theme_color("font_color") != color:
		etiqueta.add_theme_color_override("font_color", color)

func _cola_cocina_texto() -> Array:
	var lineas: Array = []
	lineas.append_array(cocina.descripcion_cola())
	lineas.append_array(barra.descripcion_cola())
	return lineas
