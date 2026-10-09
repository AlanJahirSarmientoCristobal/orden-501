extends CanvasLayer
class_name PanelModal

## Base para ventanas que se abren sobre el juego (tablet, inventario, pedidos urgentes, diálogos).
## Mientras hay una abierta, Dani no se mueve; Esc o el botón Cerrar la cierran.

signal cerrado

static var abiertos := 0

# Nodos de la escena scenes/ui/panel_modal.tscn (cada ventana es una escena heredada).
@onready var raiz: Control = $Raiz
@onready var contenido: VBoxContainer = $Raiz/Centro/Panel/Marco/Desplazable/Contenido
@onready var _titulo: Label = $Raiz/Centro/Panel/Marco/Cabecera/Titulo
var _abierto := false

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
