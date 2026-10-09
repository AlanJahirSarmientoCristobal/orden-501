extends CanvasLayer
class_name MenuPausa

@onready var _raiz: Control = $Raiz

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
