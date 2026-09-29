extends CanvasLayer
class_name PanelModal

## Base para ventanas que se abren sobre el juego (tablet, tiendas, pedidos urgentes...).
## Mientras hay una abierta, Dani no se mueve; Esc la cierra.

signal cerrado

static var abiertos := 0

var raiz: Control
var contenido: VBoxContainer
var _titulo: Label
var _abierto := false

func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	raiz = Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.visible = false
	add_child(raiz)
	raiz.add_child(UIKit.velo(0.55))
	var panel := UIKit.panel()
	panel.custom_minimum_size = tamano()
	var marco := UIKit.vbox(10)
	var cabecera := UIKit.hbox(10)
	_titulo = UIKit.etiqueta("", 22, UIKit.ACENTO)
	_titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cabecera.add_child(_titulo)
	cabecera.add_child(UIKit.boton("Cerrar [Esc]", cerrar, 14))
	marco.add_child(cabecera)
	var desplazable := ScrollContainer.new()
	desplazable.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desplazable.custom_minimum_size = tamano() - Vector2(40, 90)
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	contenido = UIKit.vbox(8)
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazable.add_child(contenido)
	marco.add_child(desplazable)
	panel.add_child(marco)
	UIKit.centrar(panel, raiz)

func tamano() -> Vector2:
	return Vector2(640, 480)

func abrir(titulo: String = "") -> void:
	if titulo != "":
		_titulo.text = titulo
	if not _abierto:
		_abierto = true
		abiertos += 1
	raiz.visible = true
	_bloquear_dani(true)
	construir()

func cerrar() -> void:
	if not _abierto:
		return
	_abierto = false
	abiertos = maxi(0, abiertos - 1)
	raiz.visible = false
	if abiertos == 0:
		_bloquear_dani(false)
	cerrado.emit()

func esta_abierto() -> bool:
	return _abierto

## Las subclases reconstruyen aquí su contenido.
func construir() -> void:
	pass

func refrescar() -> void:
	if _abierto:
		construir()

func _unhandled_input(evento: InputEvent) -> void:
	if _abierto and evento.is_action_pressed("pausa"):
		get_viewport().set_input_as_handled()
		cerrar()

func _bloquear_dani(valor: bool) -> void:
	for dani in get_tree().get_nodes_in_group("dani"):
		dani.bloqueado = valor

func _exit_tree() -> void:
	if _abierto:
		abiertos = maxi(0, abiertos - 1)
