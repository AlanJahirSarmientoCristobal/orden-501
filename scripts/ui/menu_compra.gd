extends CanvasLayer
class_name MenuCompra

## Menú de compra al estilo de las tiendas de Pokémon Rojo Fuego:
## ventana de dinero, lista de productos con cursor, descripción con ícono,
## selector de cantidad ("¿Cuántos?") y confirmación Sí / No.
## Controles: flechas/WASD para moverse, Espacio/Enter para elegir, Esc para regresar.

signal cerrado

enum Estado { CERRADO, LISTA, CANTIDAD, CONFIRMAR, MENSAJE }

const RUTA_FUENTE := "res://Assets/fonts/kenney_pixel.ttf"
const TINTA := Color("303040")
const SOMBRA := Color("c8c8c0")
const PAPEL := Color("f8f8f0")
const MARCO := Color("4f6a8f")
const MARCO_CLARO := Color("a8c0dc")

const DESCRIPCIONES := {
	"carne": "Carne de res fresca del mercado.",
	"pollo": "Pollo entero para las alitas del estadio.",
	"papas": "Costal de papas para las Papas MVP.",
	"verdura": "Lechuga, jitomate y cebolla del día.",
	"pan": "Pan para hamburguesa recién horneado.",
	"cerveza": "Cerveza bien fría para el partido.",
	"refresco": "Refresco de la casa en lata.",
	"hielo": "Bolsa de hielo. Se derrite: cómprala al día.",
	"monster": "Bebida energética. Cada lata trae un diseño distinto.",
}

static var _fuente: FontFile

var tienda := Catalogo.MERCADO
var vendedor := ""
var estado := Estado.CERRADO
var productos: Array[String] = []
var indice := 0
var cantidad := 1
var confirmar_si := true

var _raiz: Control
var _dinero: Label
var _almacen: Label
var _filas: Array[Dictionary] = []   # {"cursor": Control, "nombre": Label, "precio": Label}
var _lista: VBoxContainer
var _icono: TextureRect
var _descripcion: Label
var _retrato: TextureRect
var _nombre_retrato: Label
var _caja_cantidad: PanelContainer
var _en_almacen: Label
var _texto_cantidad: Label
var _caja_si_no: PanelContainer
var _cursor_si: Control
var _cursor_no: Control

## Fuente pixel sin suavizado (Kenney Pixel).
static func fuente() -> FontFile:
	if _fuente == null:
		_fuente = load(RUTA_FUENTE)
		_fuente.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		_fuente.hinting = TextServer.HINTING_NONE
		_fuente.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return _fuente

func _ready() -> void:
	layer = 45
	process_mode = Node.PROCESS_MODE_ALWAYS
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.visible = false
	add_child(_raiz)
	var velo := UIKit.velo(0.25)
	_raiz.add_child(velo)
	_construir()
	GameState.dinero_cambiado.connect(_al_cambiar_dinero)

# ---------------------------------------------------------------- Construcción

func _caja(pos: Vector2, tam: Vector2) -> PanelContainer:
	var caja := PanelContainer.new()
	caja.position = pos
	caja.size = tam
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = PAPEL
	estilo.border_color = MARCO
	estilo.set_border_width_all(6)
	estilo.set_corner_radius_all(10)
	estilo.set_content_margin_all(18)
	estilo.shadow_color = Color(0, 0, 0, 0.35)
	estilo.shadow_size = 4
	caja.add_theme_stylebox_override("panel", estilo)
	# Segundo borde interior claro, como en el juego original
	var interior := Panel.new()
	var estilo_int := StyleBoxFlat.new()
	estilo_int.bg_color = Color.TRANSPARENT
	estilo_int.border_color = MARCO_CLARO
	estilo_int.set_border_width_all(2)
	estilo_int.set_corner_radius_all(6)
	interior.add_theme_stylebox_override("panel", estilo_int)
	interior.mouse_filter = Control.MOUSE_FILTER_IGNORE
	interior.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	interior.offset_left = 6
	interior.offset_top = 6
	interior.offset_right = -6
	interior.offset_bottom = -6
	caja.add_child(interior)
	_raiz.add_child(caja)
	return caja

func _texto(texto: String, tam: int = 32, color: Color = TINTA) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_override("font", fuente())
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", SOMBRA)
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	# La fuente pixel dibuja las minúsculas acentuadas como mayúsculas: todo en mayúsculas.
	l.uppercase = true
	return l

func _construir() -> void:
	# Dinero y almacén (arriba a la izquierda)
	var caja_dinero := _caja(Vector2(32, 64), Vector2(420, 160))
	var columna := VBoxContainer.new()
	columna.add_theme_constant_override("separation", 2)
	_dinero = _texto("")
	_almacen = _texto("")
	columna.add_child(_texto("DINERO", 32, MARCO))
	columna.add_child(_dinero)
	columna.add_child(_almacen)
	caja_dinero.add_child(columna)

	# Retrato del vendedor (debajo del dinero)
	var caja_retrato := _caja(Vector2(32, 236), Vector2(420, 272))
	var col_retrato := VBoxContainer.new()
	col_retrato.alignment = BoxContainer.ALIGNMENT_CENTER
	var fondo := PanelContainer.new()
	var estilo_fondo := StyleBoxFlat.new()
	estilo_fondo.bg_color = Color("d8e8f8")
	estilo_fondo.set_corner_radius_all(6)
	fondo.add_theme_stylebox_override("panel", estilo_fondo)
	fondo.custom_minimum_size = Vector2(0, 180)
	_retrato = TextureRect.new()
	_retrato.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_retrato.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_retrato.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_retrato.custom_minimum_size = Vector2(176, 176)
	fondo.add_child(_retrato)
	col_retrato.add_child(fondo)
	_nombre_retrato = _texto("")
	_nombre_retrato.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col_retrato.add_child(_nombre_retrato)
	caja_retrato.add_child(col_retrato)

	# Lista de productos (derecha)
	var caja_lista := _caja(Vector2(560, 64), Vector2(688, 444))
	_lista = VBoxContainer.new()
	_lista.add_theme_constant_override("separation", 4)
	caja_lista.add_child(_lista)

	# Descripción con ícono (abajo)
	var caja_desc := _caja(Vector2(32, 524), Vector2(1216, 168))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 24)
	_icono = TextureRect.new()
	_icono.custom_minimum_size = Vector2(112, 112)
	_icono.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icono.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icono.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	fila.add_child(_icono)
	_descripcion = _texto("")
	_descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_descripcion.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_descripcion.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	fila.add_child(_descripcion)
	caja_desc.add_child(fila)

	# Selector de cantidad
	_caja_cantidad = _caja(Vector2(768, 360), Vector2(480, 148))
	var col_cant := VBoxContainer.new()
	_en_almacen = _texto("", 32, MARCO)
	_texto_cantidad = _texto("")
	col_cant.add_child(_en_almacen)
	col_cant.add_child(_texto_cantidad)
	_caja_cantidad.add_child(col_cant)
	_caja_cantidad.visible = false

	# Confirmación Sí / No
	_caja_si_no = _caja(Vector2(1016, 344), Vector2(232, 164))
	var col_sn := VBoxContainer.new()
	var fila_si := HBoxContainer.new()
	_cursor_si = Cursor.new()
	fila_si.add_child(_cursor_si)
	fila_si.add_child(_texto("SÍ"))
	var fila_no := HBoxContainer.new()
	_cursor_no = Cursor.new()
	fila_no.add_child(_cursor_no)
	fila_no.add_child(_texto("NO"))
	col_sn.add_child(fila_si)
	col_sn.add_child(fila_no)
	_caja_si_no.add_child(col_sn)
	_caja_si_no.visible = false

## Cursor triangular (la fuente no trae el carácter ▶).
class Cursor extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(28, 36)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var puntos := PackedVector2Array([Vector2(6, 8), Vector2(22, 18), Vector2(6, 28)])
		draw_colored_polygon(puntos + PackedVector2Array([Vector2(2, 2), Vector2(2, 2), Vector2(2, 2)]), SOMBRA)
		draw_colored_polygon(puntos, TINTA)

# ---------------------------------------------------------------- Abrir / cerrar

func abrir(nueva_tienda: String, nombre_vendedor: String, clave_retrato: String = "") -> void:
	tienda = nueva_tienda
	vendedor = nombre_vendedor
	_retrato.texture = AssetPaths.retrato(clave_retrato) if clave_retrato != "" else null
	_nombre_retrato.text = nombre_vendedor
	productos = Catalogo.insumos_de_tienda(tienda)
	indice = 0
	_llenar_lista()
	if estado == Estado.CERRADO:
		PanelModal.abiertos += 1
	_raiz.visible = true
	_bloquear_dani(true)
	_ir_a(Estado.LISTA)
	AudioManager.sfx("click")

func cerrar() -> void:
	if estado == Estado.CERRADO:
		return
	estado = Estado.CERRADO
	_raiz.visible = false
	PanelModal.abiertos = maxi(0, PanelModal.abiertos - 1)
	if PanelModal.abiertos == 0:
		_bloquear_dani(false)
	cerrado.emit()

func esta_abierto() -> bool:
	return estado != Estado.CERRADO

func _bloquear_dani(valor: bool) -> void:
	for dani in get_tree().get_nodes_in_group("dani"):
		dani.bloqueado = valor

func _exit_tree() -> void:
	if estado != Estado.CERRADO:
		PanelModal.abiertos = maxi(0, PanelModal.abiertos - 1)

func _llenar_lista() -> void:
	UIKit.limpiar(_lista)
	_filas.clear()
	var opciones: Array[String] = productos.duplicate()
	opciones.append("")      # SALIR
	for i in range(opciones.size()):
		var insumo := opciones[i]
		var fila := HBoxContainer.new()
		fila.custom_minimum_size.y = 42
		fila.mouse_filter = Control.MOUSE_FILTER_STOP
		fila.gui_input.connect(_clic_fila.bind(i))
		var cursor := Cursor.new()
		fila.add_child(cursor)
		var nombre := _texto(Catalogo.nombre_insumo(insumo).to_upper() if insumo != "" else "SALIR")
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nombre)
		var precio := _texto(UIKit.dinero(int(Catalogo.INSUMOS[insumo]["precio"])) if insumo != "" else "")
		fila.add_child(precio)
		_lista.add_child(fila)
		_filas.append({"cursor": cursor, "nombre": nombre, "precio": precio})

# ---------------------------------------------------------------- Estados

func _ir_a(nuevo: Estado) -> void:
	estado = nuevo
	_caja_cantidad.visible = estado in [Estado.CANTIDAD, Estado.CONFIRMAR]
	_caja_si_no.visible = estado == Estado.CONFIRMAR
	_actualizar()

func _actualizar() -> void:
	_dinero.text = UIKit.dinero(GameState.dinero)
	_almacen.text = "ALMACÉN %d/%d" % [GameState.inventario.total_unidades(), GameState.capacidad_almacen()]
	for i in range(_filas.size()):
		_filas[i]["cursor"].modulate.a = 1.0 if i == indice else 0.0
	var insumo := _seleccionado()
	match estado:
		Estado.LISTA:
			if insumo == "":
				_icono.texture = null
				_descripcion.text = "%s: ¿Necesitas algo más? Vuelve cuando quieras." % vendedor
			else:
				_icono.texture = AssetPaths.textura(Catalogo.INSUMOS[insumo]["icono"])
				_descripcion.text = _texto_producto(insumo)
		Estado.CANTIDAD:
			_descripcion.text = "%s: ¿Cuántos quieres?
(Arriba/abajo: 1 más o menos · Izquierda/derecha: 10)" % vendedor
			_en_almacen.text = "EN ALMACÉN: %d" % GameState.inventario.total(insumo)
			_texto_cantidad.text = "CANTIDAD: %02d   %s" % [cantidad, UIKit.dinero(cantidad * _precio(insumo))]
		Estado.CONFIRMAR:
			_descripcion.text = "%s: Son %d de %s, serían %s. ¿Está bien?" % [vendedor, cantidad, Catalogo.nombre_insumo(insumo), UIKit.dinero(cantidad * _precio(insumo))]
			_cursor_si.modulate.a = 1.0 if confirmar_si else 0.0
			_cursor_no.modulate.a = 0.0 if confirmar_si else 1.0

func _texto_producto(insumo: String) -> String:
	var datos: Dictionary = Catalogo.INSUMOS[insumo]
	var caducidad := "Caduca en %d día(s)." % GameState.config.dias_caducidad if datos["perecedero"] else "No caduca."
	var usos := []
	for platillo in Catalogo.PLATILLOS:
		if Catalogo.receta(platillo).has(insumo):
			usos.append(platillo)
	return "%s %s\nSe usa en: %s." % [DESCRIPCIONES.get(insumo, ""), caducidad, ", ".join(usos)]

func _seleccionado() -> String:
	return productos[indice] if indice < productos.size() else ""

func _precio(insumo: String) -> int:
	return int(Catalogo.INSUMOS[insumo]["precio"])

func _maximo(insumo: String) -> int:
	return clampi(mini(GameState.dinero / maxi(1, _precio(insumo)), GameState.espacio_libre()), 1, 99)

func _al_cambiar_dinero(_valor: int) -> void:
	if estado != Estado.CERRADO:
		_actualizar()

# ---------------------------------------------------------------- Entrada

func _input(evento: InputEvent) -> void:
	if estado == Estado.CERRADO or not (evento is InputEventKey) or not evento.is_pressed():
		return
	get_viewport().set_input_as_handled()
	var arriba := evento.is_action("mover_arriba")
	var abajo := evento.is_action("mover_abajo")
	var izq := evento.is_action("mover_izquierda")
	var der := evento.is_action("mover_derecha")
	var aceptar := evento.is_action("interactuar") and not evento.is_echo()
	var cancelar := evento.is_action("pausa") and not evento.is_echo()
	match estado:
		Estado.LISTA:
			if arriba or abajo:
				indice = wrapi(indice + (-1 if arriba else 1), 0, productos.size() + 1)
				AudioManager.sfx("click")
				_actualizar()
			elif aceptar:
				_elegir_producto()
			elif cancelar:
				cerrar()
		Estado.CANTIDAD:
			var maximo := _maximo(_seleccionado())
			if arriba or abajo or izq or der:
				var paso := 1 if (arriba or abajo) else 10
				var signo := 1 if (arriba or der) else -1
				cantidad = wrapi(cantidad - 1 + paso * signo, 0, maximo) + 1 if paso == 1 else clampi(cantidad + paso * signo, 1, maximo)
				AudioManager.sfx("click")
				_actualizar()
			elif aceptar:
				confirmar_si = true
				_ir_a(Estado.CONFIRMAR)
			elif cancelar:
				_ir_a(Estado.LISTA)
		Estado.CONFIRMAR:
			if arriba or abajo:
				confirmar_si = not confirmar_si
				AudioManager.sfx("click")
				_actualizar()
			elif aceptar:
				if confirmar_si:
					_mensaje(comprar(_seleccionado(), cantidad))
				else:
					_ir_a(Estado.LISTA)
			elif cancelar:
				_ir_a(Estado.LISTA)
		Estado.MENSAJE:
			if aceptar or cancelar:
				_ir_a(Estado.LISTA)

func _clic_fila(evento: InputEvent, i: int) -> void:
	if estado != Estado.LISTA or not (evento is InputEventMouseButton) or not evento.pressed or evento.button_index != MOUSE_BUTTON_LEFT:
		return
	indice = i
	_actualizar()
	_elegir_producto()

func _elegir_producto() -> void:
	var insumo := _seleccionado()
	if insumo == "":
		cerrar()
		return
	if GameState.dinero < _precio(insumo):
		_mensaje("No te alcanza el dinero.")
		return
	if GameState.espacio_libre() <= 0:
		_mensaje("No hay espacio en el almacén.")
		return
	cantidad = 1
	AudioManager.sfx("click")
	_ir_a(Estado.CANTIDAD)

func _mensaje(texto: String) -> void:
	estado = Estado.MENSAJE
	_caja_cantidad.visible = false
	_caja_si_no.visible = false
	_dinero.text = UIKit.dinero(GameState.dinero)
	_almacen.text = "ALMACÉN %d/%d" % [GameState.inventario.total_unidades(), GameState.capacidad_almacen()]
	_descripcion.text = "%s: %s" % [vendedor, texto]

## Compra directa (también la usan las pruebas). Devuelve el mensaje del vendedor.
func comprar(insumo: String, unidades: int) -> String:
	var error := GameState.comprar(insumo, unidades)
	if error != "":
		AudioManager.sfx("error")
		return error
	AudioManager.sfx("caja")
	return "¡Aquí tienes! %d de %s. ¡Gracias!" % [unidades, Catalogo.nombre_insumo(insumo)]
