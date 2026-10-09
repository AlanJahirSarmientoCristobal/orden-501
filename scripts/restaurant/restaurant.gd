extends Node2D

## Fase de jornada: Dani atiende La 501 durante el partido.
## Distribución (sección 9 del documento): cocina y barra a la izquierda, mesas al centro,
## pantallas en la pared superior, entrada abajo y panel de gestión a la derecha.

const AREA_JUEGO := Rect2(0, 100, 1000, 620)
const PUERTA := Vector2(552, 770)
const INICIO_FILA := Vector2(660, 652)
const MAX_FILA := 5
const MINUTOS_PARTIDO := 90.0


var dani: Dani
# Nodos de la escena scenes/restaurant/restaurant.tscn
@onready var cocina: Estacion = $Cocina
@onready var barra: Estacion = $Barra
@onready var _neon: Sprite2D = $Neon
@onready var _televisores: Array[Sprite2D] = [$Pantallas/TV1, $Pantallas/TV2]
@onready var _pantallas: Array[Label] = [$Pantallas/Marcador1, $Pantallas/Marcador2]
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

# Interfaz: nodos de la escena (HUD, ventanas y avisos).
@onready var _tablet: Tablet = $Tablet
@onready var _urgente: PanelUrgente = $Urgente
@onready var _dialogo: DialogoOpciones = $Dialogo
@onready var _notificaciones: Notificaciones = $Notificaciones
@onready var _pausa: MenuPausa = $Pausa
@onready var _hud_nivel: Label = $HUD/BarraSuperior/Fila/Nivel
@onready var _hud_reloj: Label = $HUD/BarraSuperior/Fila/Reloj
@onready var _hud_dinero: Label = $HUD/BarraSuperior/Fila/Dinero
@onready var _hud_reputacion: Label = $HUD/BarraSuperior/Fila/Reputacion
@onready var _hud_bandeja: Label = $HUD/BarraSuperior/Fila/Bandeja
@onready var _panel_lateral: VBoxContainer = $HUD/Lateral/Contenido
var _lateral := {}
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
	_preparar_mesas()

	dani = $Dani
	dani.bandeja_cambiada.connect(func(_b): _actualizar_hud())

	_tablet.notificaciones = _notificaciones
	_tablet.proveedor_cocina = _cola_cocina_texto
	_urgente.restaurante = self
	_hud_nivel.text = "NIVEL %d · %s" % [GameState.nivel_actual, GameState.info_nivel()["nombre"].to_upper()]
	_actualizar_panel_lateral()

	GameState.dinero_cambiado.connect(_al_cambiar_valor)
	GameState.inventario_cambiado.connect(_revisar_agotados)
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
	_cliente_practica = Cliente.crear("cliente_practica")
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
	var tutorial := Tutorial.crear("restaurante", pasos)
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

## Las mesas 1-6 siempre están; las 7-8 (nodo Terraza) solo después de ganar la Gran Final.
func _preparar_mesas() -> void:
	for mesa in $Mesas.get_children():
		mesas.append(mesa)
	if GameState.terraza_desbloqueada:
		$Terraza.visible = true
		$Interior/PisoTerraza.visible = true
		for hijo in $Terraza.get_children():
			if hijo is Mesa:
				mesas.append(hijo)
	else:
		$Terraza.queue_free()
	for mesa in mesas:
		mesa.restaurante = self

func _al_usar_telefono(_dani: Node) -> void:
	abrir_urgente()

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
		cliente = Cliente.crear("cliente_vip")
	else:
		cliente = Cliente.crear("cliente_habitual")
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
			var cliente: ClienteReservacion = Cliente.crear("cliente_reservacion")
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
			var critico: ClienteCritico = Cliente.crear("cliente_critico")
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

## Un platillo marcado como agotado vuelve al menú en cuanto hay insumos otra vez
## (por ejemplo, al llegar un pedido urgente).
func _revisar_agotados() -> void:
	for platillo in agotados.duplicate():
		if GameState.inventario.puede_preparar(platillo, 1):
			agotados.erase(platillo)
			GameState.aviso.emit("%s vuelve al menú: ya hay insumos." % platillo)

## Platillos del menú que ya no se pueden preparar porque algún insumo llegó a cero.
func platillos_sin_insumos() -> Array[String]:
	var menu: Array[String] = []
	menu.assign(Catalogo.MENU_HABITUAL)
	if GameState.nivel_actual >= 2:
		menu.append(Catalogo.COMBO)
	var sin: Array[String] = []
	for platillo in menu:
		if not agotados.has(platillo) and not GameState.inventario.puede_preparar(platillo, 1):
			sin.append(platillo)
	return sin

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
	# Regla 11: lo que no se puede preparar aparece agotado en el menú. Si un cliente lo pide,
	# Dani decide qué hacer (agotar, urgente o sustituto).
	var sin := platillos_sin_insumos()
	var lineas_agotado: Array[String] = []
	if not agotados.is_empty():
		lineas_agotado.append("Agotado: " + ", ".join(agotados))
	if not sin.is_empty():
		lineas_agotado.append("Sin insumos: " + ", ".join(sin))
	_lateral["agotados"].visible = not lineas_agotado.is_empty()
	_fijar(_lateral["agotados"], "\n".join(lineas_agotado), UIKit.ROJO)
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

## Reúne las etiquetas del panel lateral y agrega las que dependen del día (reservaciones y objetivo).
func _construir_panel_lateral() -> void:
	var p := _panel_lateral
	var stock := {}
	for insumo in Catalogo.INSUMOS:
		stock[insumo] = p.get_node("Stock/" + insumo)
	var reservas: Array[Label] = []
	if GameState.reservaciones.is_empty():
		p.get_node("Reservas").add_child(UIKit.etiqueta("Sin reservaciones hoy", 12, UIKit.TEXTO_TENUE))
	for i in range(GameState.reservaciones.size()):
		var l := UIKit.etiqueta("", 12)
		p.get_node("Reservas").add_child(l)
		reservas.append(l)
	var objetivo: Array[Label] = []
	for i in range(GameState.detalle_objetivo().size()):
		var l := UIKit.etiqueta("", 11)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.custom_minimum_size.x = 244
		p.get_node("Objetivo").add_child(l)
		objetivo.append(l)
	_lateral = {"stock": stock, "agotados": p.get_node("Agotados"), "cocina": p.get_node("Cocina"), "barra": p.get_node("Barra"),
		"fila": p.get_node("Fila"), "reservas": reservas, "objetivo": objetivo}

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
