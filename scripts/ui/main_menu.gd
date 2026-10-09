extends Control

@onready var _secundario: PanelContainer = $Columnas/Secundario
@onready var _paneles := {
	"dificultad": $Columnas/Secundario/Dificultad,
	"niveles": $Columnas/Secundario/Niveles,
	"controles": $Columnas/Secundario/Controles,
}
@onready var _boton_continuar: Button = $Columnas/Izquierda/Principal/Continuar

func _ready() -> void:
	AudioManager.musica("manana")
	_boton_continuar.visible = GameState.hay_partida_guardada()
	for id in ConfiguracionDificultad.TODAS:
		var tarjeta: Node = _paneles["dificultad"].get_node(id.capitalize())
		tarjeta.get_node("Caja/Descripcion").text = ConfiguracionDificultad.obtener(id).describir()

func _mostrar(panel: String) -> void:
	_secundario.visible = true
	for clave in _paneles:
		_paneles[clave].visible = clave == panel

func _mostrar_dificultad() -> void:
	_mostrar("dificultad")

func _nueva_partida(dificultad: String) -> void:
	GameState.nueva_partida(dificultad)
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _continuar() -> void:
	if not GameState.cargar():
		GameState.aviso.emit("No se pudo cargar la partida.")
		return
	if GameState.temporada_completada and GameState.nivel_actual == 3 and GameState.historial.size() >= 3:
		GameState.cambiar_escena(GameState.ESCENA_VICTORIA)
	else:
		GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _mostrar_niveles() -> void:
	var hay_partida := GameState.cargar()
	var niveles: VBoxContainer = _paneles["niveles"]
	niveles.get_node("Titulo").text = "SELECCIONAR NIVEL · %s" % GameState.config.nombre if hay_partida else "SELECCIONAR NIVEL"
	for nivel in [1, 2, 3]:
		var info := GameState.info_nivel(nivel)
		var superado: bool = hay_partida and GameState.nivel_superado(nivel)
		var boton: Button = niveles.get_node("Nivel%d" % nivel)
		boton.text = "%d. %s%s" % [nivel, info["nombre"], "" if superado else "  (supéralo en la campaña)"]
		boton.disabled = not superado
		niveles.get_node("Objetivo%d" % nivel).text = info["objetivo"]
	_mostrar("niveles")

func _jugar_reto() -> void:
	GameState.iniciar_reto_imposible()
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _jugar_nivel(nivel: int) -> void:
	GameState.seleccionar_nivel(nivel)
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _mostrar_controles() -> void:
	_mostrar("controles")

func _pantalla_completa() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _salir() -> void:
	get_tree().quit()
