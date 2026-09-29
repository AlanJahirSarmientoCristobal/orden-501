extends CanvasLayer
class_name MenuPausa

## Pausa con Esc: continuar o volver al menú principal.

var _raiz: Control

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_raiz = Control.new()
	_raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_raiz.visible = false
	add_child(_raiz)
	_raiz.add_child(UIKit.velo(0.75))
	var panel := UIKit.panel()
	var caja := UIKit.vbox(12)
	caja.add_child(UIKit.etiqueta("PAUSA", 30, UIKit.ACENTO, true))
	caja.add_child(UIKit.etiqueta("Presiona Esc para continuar", 14, UIKit.TEXTO_TENUE, true))
	caja.add_child(UIKit.boton("Continuar", alternar, 18, 260))
	caja.add_child(UIKit.boton("Reiniciar jornada", _reiniciar, 18, 260))
	caja.add_child(UIKit.boton("Menú principal", _menu, 18, 260))
	panel.add_child(caja)
	UIKit.centrar(panel, _raiz)

func _unhandled_input(evento: InputEvent) -> void:
	if evento.is_action_pressed("pausa") and (PanelModal.abiertos == 0 or _raiz.visible):
		get_viewport().set_input_as_handled()
		alternar()

func alternar() -> void:
	_raiz.visible = not _raiz.visible
	get_tree().paused = _raiz.visible

func esta_abierto() -> bool:
	return _raiz.visible

func _reiniciar() -> void:
	get_tree().paused = false
	GameState.reiniciar_jornada()
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _menu() -> void:
	get_tree().paused = false
	GameState.cambiar_escena(GameState.ESCENA_MENU)
