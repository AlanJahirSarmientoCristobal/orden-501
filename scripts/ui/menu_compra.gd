extends CanvasLayer
class_name MenuCompra

## Menú de compra al estilo de las tiendas de Pokémon Rojo Fuego:
## ventana de dinero, lista de productos con cursor, descripción con ícono,
## selector de cantidad ("¿Cuántos?") y confirmación Sí / No.
## Controles: flechas/WASD para moverse, Espacio/Enter para elegir, Esc para regresar.

signal cerrado

enum Estado { CERRADO, LISTA, CANTIDAD, CONFIRMAR, MENSAJE }

const FILA := preload("res://scenes/ui/fila_producto.tscn")

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

var tienda := Catalogo.MERCADO
var vendedor := ""
var estado := Estado.CERRADO
var productos: Array[String] = []
var indice := 0
var cantidad := 1
var confirmar_si := true

var _filas: Array[Dictionary] = []   # {"cursor": Control, "nombre": Label, "precio": Label}

# Nodos de la escena scenes/ui/menu_compra.tscn (estilo en Assets/tema/tema_tienda.tres)
@onready var _raiz: Control = $Raiz
@onready var _dinero: Label = $Raiz/CajaDinero/Columna/Dinero
@onready var _almacen: Label = $Raiz/CajaDinero/Columna/Almacen
@onready var _retrato: TextureRect = $Raiz/CajaRetrato/Columna/Fondo/Retrato
@onready var _nombre_retrato: Label = $Raiz/CajaRetrato/Columna/Vendedor
@onready var _lista: VBoxContainer = $Raiz/CajaLista/Lista
@onready var _icono: TextureRect = $Raiz/CajaDescripcion/Fila/Icono
@onready var _descripcion: Label = $Raiz/CajaDescripcion/Fila/Descripcion
@onready var _caja_cantidad: PanelContainer = $Raiz/CajaCantidad
@onready var _en_almacen: Label = $Raiz/CajaCantidad/Columna/EnAlmacen
@onready var _texto_cantidad: Label = $Raiz/CajaCantidad/Columna/Cantidad
@onready var _caja_si_no: PanelContainer = $Raiz/CajaSiNo
@onready var _cursor_si: Control = $Raiz/CajaSiNo/Columna/FilaSi/Cursor
@onready var _cursor_no: Control = $Raiz/CajaSiNo/Columna/FilaNo/Cursor

func _ready() -> void:
	GameState.dinero_cambiado.connect(_al_cambiar_dinero)

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
		var fila: HBoxContainer = FILA.instantiate()
		fila.gui_input.connect(_clic_fila.bind(i))
		var nombre: Label = fila.get_node("Nombre")
		nombre.text = Catalogo.nombre_insumo(insumo) if insumo != "" else "SALIR"
		var precio: Label = fila.get_node("Precio")
		precio.text = UIKit.dinero(GameState.precio_insumo(insumo)) if insumo != "" else ""
		_lista.add_child(fila)
		_filas.append({"cursor": fila.get_node("Cursor"), "nombre": nombre, "precio": precio})

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
	return GameState.precio_insumo(insumo)

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
