extends Node2D
class_name Cliente

## Cliente base. Máquina de estados:
## EN_FILA → CAMINANDO → ORDENANDO → ESPERANDO_COMIDA → COMIENDO → SALIENDO
## Cada cliente tiene su propia paciencia y temporizadores independientes.
## Subclases: ClienteHabitual, ClienteVIP, ClienteReservacion.

signal se_fue(cliente: Cliente, enojado: bool)

enum Estado { EN_FILA, CAMINANDO, ORDENANDO, ESPERANDO_COMIDA, COMIENDO, SALIENDO }

const VELOCIDAD_CAMINAR := 160.0

var estado: Estado = Estado.EN_FILA
var mesa: Node = null                 # Mesa asignada
var restaurante: Node = null          # Controlador del restaurante
var pedido := ""
var pedido_enviado := false           # Ya está en cocina/barra
var factor_propina := 1.0             # Baja si se ofreció un sustituto
var paciencia_max := 40.0
var paciencia := 40.0
var tiempo_comiendo := 0.0
var extras_pedidos := 0
var quiebre_registrado := ""           # Platillo cuyo faltante ya se contó
var personas := 1                      # 1, 2 (pareja) o 4 (familia); se fija antes de agregarlo

# Posición de los acompañantes mientras caminan o esperan en la fila.
const FORMACION := [Vector2(-22, 8), Vector2(22, 8), Vector2(0, 16)]
var _acompanantes: Array[AnimatedSprite2D] = []

static var _estilos_barra := {}
var _color_barra := -1

var _sprite: AnimatedSprite2D
var _barra: ProgressBar
var _burbuja: PanelContainer
var _icono: TextureRect
var _texto: Label
var _insignia: Label

func _ready() -> void:
	z_index = 5
	add_to_group("clientes")
	paciencia_max = GameState.paciencia_base() * multiplicador_paciencia()
	paciencia = paciencia_max
	_construir()

# ---------------------------------------------------------------- Comportamiento por tipo (polimorfismo)

func clave_sprite() -> String:
	return "cliente_1"

func nombre_tipo() -> String:
	return "Cliente"

func color_insignia() -> Color:
	return UIKit.TEXTO

func multiplicador_paciencia() -> float:
	return 1.0

## Porcentaje del precio que deja de propina si se le atiende al instante.
func propina_base() -> float:
	return 0.15

func penalizacion_reputacion() -> float:
	return 8.0

func bonificacion_reputacion() -> float:
	return 1.5

func elegir_pedido() -> String:
	return Catalogo.MENU_HABITUAL.pick_random()

func es_vip() -> bool:
	return false

## Texto de la insignia: tipo de cliente y tamaño del grupo.
func texto_grupo() -> String:
	match personas:
		2:
			return "Pareja"
		4:
			return "Familia de 4"
	return nombre_tipo()

func _sufijo() -> String:
	return " x%d" % personas if personas > 1 else ""

func _formar_grupo() -> void:
	for i in range(_acompanantes.size()):
		_acompanantes[i].position = FORMACION[i % FORMACION.size()] + Vector2(0, AssetPaths.ALTURA_PERSONAJE)

## Acomoda a los acompañantes en las demás sillas de la mesa.
func _sentar_grupo() -> void:
	if mesa == null:
		return
	var asientos: Array[Vector2] = mesa.asientos_globales()
	for i in range(_acompanantes.size()):
		var a := _acompanantes[i]
		a.stop()
		a.frame = 0
		if i + 1 < asientos.size():
			a.position = asientos[i + 1] - global_position + Vector2(0, AssetPaths.ALTURA_PERSONAJE)
			a.animation = &"up" if asientos[i + 1].y > mesa.global_position.y else &"down"

# ---------------------------------------------------------------- Construcción visual

func _construir() -> void:
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = AssetPaths.frames_personaje(clave_sprite())
	_sprite.animation = &"down"
	_sprite.frame = 0
	_sprite.scale = AssetPaths.escala(clave_sprite())
	_sprite.position = Vector2(0, AssetPaths.ALTURA_PERSONAJE)
	add_child(_sprite)
	for i in range(personas - 1):
		var acompanante := AnimatedSprite2D.new()
		var clave_acompanante: String = ["cliente_1", "cliente_2", "cliente_3"][randi() % 3]
		acompanante.sprite_frames = AssetPaths.frames_personaje(clave_acompanante)
		acompanante.animation = &"down"
		acompanante.frame = 0
		acompanante.scale = AssetPaths.escala(clave_acompanante)
		acompanante.z_index = -1
		add_child(acompanante)
		_acompanantes.append(acompanante)
	_formar_grupo()

	_insignia = UIKit.etiqueta(texto_grupo(), 10, color_insignia(), true)
	_insignia.position = Vector2(-50, 19)
	_insignia.size = Vector2(100, 14)
	_insignia.visible = false      # Se muestra al sentarse (en la fila se enciman)
	add_child(_insignia)

	_barra = ProgressBar.new()
	_barra.position = Vector2(-26, -52)
	_barra.size = Vector2(52, 7)
	_barra.show_percentage = false
	_barra.max_value = 1.0
	_barra.value = 1.0
	_barra.add_theme_stylebox_override("background", UIKit.estilo(Color(0, 0, 0, 0.6), 3, Color.TRANSPARENT, 0, 0))
	add_child(_barra)

	_burbuja = UIKit.panel(Color("f4efe3"), Color("1b1f2a"), 4)
	_burbuja.position = Vector2(-60, -90)
	_burbuja.custom_minimum_size = Vector2(120, 32)
	var fila := UIKit.hbox(4)
	_icono = TextureRect.new()
	_icono.custom_minimum_size = Vector2(24, 24)
	_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	fila.add_child(_icono)
	_texto = Label.new()
	_texto.add_theme_font_size_override("font_size", 11)
	_texto.add_theme_color_override("font_color", Color("1b1f2a"))
	fila.add_child(_texto)
	_burbuja.add_child(fila)
	_burbuja.visible = false
	add_child(_burbuja)
	_actualizar_barra()

# ---------------------------------------------------------------- Ciclo

func _process(delta: float) -> void:
	match estado:
		Estado.EN_FILA:
			# En la fila la paciencia baja más despacio (35 % del ritmo normal en la campaña).
			_gastar_paciencia(delta * GameState.config.paciencia_fila)
		Estado.ORDENANDO, Estado.ESPERANDO_COMIDA:
			_gastar_paciencia(delta)
		Estado.COMIENDO:
			tiempo_comiendo -= delta
			if tiempo_comiendo <= 0.0:
				terminar()

func _gastar_paciencia(cantidad: float) -> void:
	paciencia -= cantidad
	_actualizar_barra()
	if paciencia <= 0.0:
		irse_enojado()

func _actualizar_barra() -> void:
	if _barra == null:
		return
	var razon := clampf(paciencia / paciencia_max, 0.0, 1.0)
	_barra.value = razon
	var nivel := 0 if razon <= 0.3 else (1 if razon <= 0.6 else 2)
	if nivel == _color_barra:
		return
	_color_barra = nivel
	if not _estilos_barra.has(nivel):
		var color: Color = [UIKit.ROJO, Color("f2d16b"), UIKit.VERDE][nivel]
		_estilos_barra[nivel] = UIKit.estilo(color, 3, Color.TRANSPARENT, 0, 0)
	_barra.add_theme_stylebox_override("fill", _estilos_barra[nivel])

func razon_paciencia() -> float:
	return clampf(paciencia / paciencia_max, 0.0, 1.0)

# ---------------------------------------------------------------- Transiciones

func ir_a_mesa(nueva_mesa: Node) -> void:
	mesa = nueva_mesa
	_insignia.visible = true
	estado = Estado.CAMINANDO
	_barra.visible = false
	var destino: Vector2 = mesa.posicion_asiento()
	_caminar(destino, _sentarse)

func _sentarse() -> void:
	if estado != Estado.CAMINANDO:
		return
	pedido = elegir_pedido()
	_sentar_grupo()
	estado = Estado.ORDENANDO
	paciencia = maxf(paciencia, paciencia_max * 0.85)
	_barra.visible = true
	_mostrar_burbuja("", "¡Ordenar!")
	AudioManager.sfx("pedido")

## Dani toma la comanda en la mesa.
func tomar_pedido() -> void:
	if estado != Estado.ORDENANDO:
		return
	restaurante.procesar_pedido(self)

## Llamado por el restaurante cuando la comanda llegó a cocina o barra.
func pedido_confirmado(platillo: String, sustituto: bool = false) -> void:
	pedido = platillo
	pedido_enviado = true
	if sustituto:
		factor_propina = 0.4
	estado = Estado.ESPERANDO_COMIDA
	_mostrar_burbuja(Catalogo.icono_platillo(pedido), _abreviar(pedido) + _sufijo())

## El pedido espera insumos (pedido urgente en camino).
func esperar_insumo() -> void:
	_mostrar_burbuja(Catalogo.icono_platillo(pedido), "Esperando insumo")

func servir(dani: Dani) -> bool:
	if estado != Estado.ESPERANDO_COMIDA or not dani.quitar_platillo(pedido):
		return false
	var propina := int(round(Catalogo.precio(pedido) * personas * propina_base() * razon_paciencia() * factor_propina))
	GameState.registrar_venta(pedido, propina, personas)
	if es_vip():
		GameState.registrar_estadistica("vip_atendidos")
	GameState.cambiar_reputacion(bonificacion_reputacion() * (0.5 if factor_propina < 1.0 else 1.0))
	AudioManager.sfx("caja")
	restaurante.mostrar_ganancia(global_position, Catalogo.precio(pedido) * personas + propina)
	estado = Estado.COMIENDO
	tiempo_comiendo = randf_range(6.0, 9.0)
	pedido_enviado = false
	_barra.visible = false
	_mostrar_burbuja(Catalogo.icono_platillo(pedido), "¡Gracias!")
	return true

## Ronda extra de bebidas tras un gol o en el medio tiempo.
func pedir_extra() -> bool:
	if estado != Estado.COMIENDO or extras_pedidos >= 2:
		return false
	extras_pedidos += 1
	pedido = Catalogo.BEBIDAS.pick_random()
	estado = Estado.ORDENANDO
	factor_propina = 1.0
	paciencia = paciencia_max * 0.7
	_barra.visible = true
	_mostrar_burbuja(Catalogo.icono_platillo(pedido), "¡Otra ronda!")
	return true

## El platillo pedido está agotado: el cliente elige otro disponible o se va.
func cambiar_pedido(nuevo: String) -> void:
	pedido = nuevo
	_mostrar_burbuja(Catalogo.icono_platillo(pedido), _abreviar(pedido) + _sufijo())

func terminar() -> void:
	if estado == Estado.SALIENDO:
		return
	estado = Estado.SALIENDO
	_burbuja.visible = false
	if mesa:
		mesa.liberar(true)
	se_fue.emit(self, false)
	_salir()

func irse_enojado(motivo: String = "") -> void:
	if estado == Estado.SALIENDO:
		return
	var estaba_sentado := estado != Estado.EN_FILA and estado != Estado.CAMINANDO
	estado = Estado.SALIENDO
	GameState.registrar_estadistica("perdidos")
	GameState.cambiar_reputacion(-penalizacion_reputacion(), motivo if motivo != "" else "%s se fue molesto" % nombre_tipo())
	AudioManager.sfx("cliente_perdido")
	restaurante.cancelar_pedidos(self)
	_barra.visible = false
	_mostrar_burbuja("", "¡Me voy!")
	if mesa:
		mesa.liberar(estaba_sentado)
	se_fue.emit(self, true)
	_salir()

## Se retira sin penalización (fin del partido).
func retirarse() -> void:
	if estado == Estado.SALIENDO:
		return
	estado = Estado.SALIENDO
	_burbuja.visible = false
	_barra.visible = false
	_salir()

func _salir() -> void:
	_formar_grupo()
	var puerta: Vector2 = restaurante.posicion_puerta() if restaurante else position + Vector2(0, 200)
	_caminar(puerta, queue_free)

func _caminar(destino: Vector2, al_llegar: Callable) -> void:
	var direccion := destino - position
	if absf(direccion.x) > absf(direccion.y):
		_sprite.animation = &"side"
		_sprite.flip_h = direccion.x < 0
	else:
		_sprite.animation = &"up" if direccion.y < 0 else &"down"
	_sprite.play()
	for a in _acompanantes:
		a.animation = _sprite.animation
		a.flip_h = _sprite.flip_h
		a.play()
	var duracion := maxf(0.2, direccion.length() / VELOCIDAD_CAMINAR)
	var tween := create_tween()
	tween.tween_property(self, "position", destino, duracion)
	tween.tween_callback(func():
		_sprite.animation = &"down"
		_sprite.stop()
		_sprite.frame = 0
		for a in _acompanantes:
			a.animation = &"down"
			a.stop()
			a.frame = 0
		al_llegar.call()
	)

func mover_en_fila(destino: Vector2) -> void:
	if estado == Estado.EN_FILA:
		var tween := create_tween()
		tween.tween_property(self, "position", destino, 0.4)

func _mostrar_burbuja(icono: String, texto: String) -> void:
	_icono.texture = AssetPaths.textura(icono) if icono != "" else null
	_icono.visible = _icono.texture != null
	_texto.text = texto
	_burbuja.visible = true

static func _abreviar(platillo: String) -> String:
	return platillo if platillo.length() <= 14 else platillo.substr(0, 13) + "."

func texto_interaccion(dani: Dani) -> String:
	match estado:
		Estado.ORDENANDO:
			return "Tomar pedido (%s)" % nombre_tipo()
		Estado.ESPERANDO_COMIDA:
			if dani.tiene_platillo(pedido):
				return "Servir %s%s" % [pedido, _sufijo()]
			return "Espera: %s%s" % [pedido, _sufijo()]
		Estado.COMIENDO:
			return "Comiendo..."
	return nombre_tipo()
