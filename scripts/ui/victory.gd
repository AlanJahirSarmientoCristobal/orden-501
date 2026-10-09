extends Control

## Final de la temporada (scenes/ui/victory.tscn): La 501 se vuelve el restaurante de referencia
## del pueblo, se desbloquea la terraza y se muestra el reporte de la temporada.

@onready var _subtitulo: Label = $Centro/Panel/Caja/Subtitulo
@onready var _tabla: GridContainer = $Centro/Panel/Caja/CentroTabla/Tabla

func _ready() -> void:
	AudioManager.musica("manana")
	AudioManager.sfx("gol")
	_subtitulo.text = "REPORTE FINAL DE TEMPORADA · Dificultad %s" % GameState.config.nombre

	var ventas := 0
	var pedidos := 0
	var perdidos := 0
	var merma := 0
	var mejor := {}
	for informe in GameState.historial:
		var e: Dictionary = informe.get("estadisticas", {})
		ventas += int(e.get("ventas", 0))
		pedidos += int(e.get("pedidos", 0))
		perdidos += int(e.get("perdidos", 0))
		merma += int(informe.get("costo_merma", 0))
		if mejor.is_empty() or int(informe.get("puntos", 0)) > int(mejor.get("puntos", 0)):
			mejor = informe
	for fila in [
		["PUNTUACIÓN DE LA TEMPORADA", "%d puntos" % GameState.puntos_temporada()],
		["Jornadas superadas", str(GameState.historial.size())],
		["Ventas totales", UIKit.dinero(ventas)],
		["Pedidos entregados", str(pedidos)],
		["Clientes perdidos", str(perdidos)],
		["Merma total", UIKit.dinero(merma)],
		["Reputación final", "%d%% %s" % [int(GameState.reputacion), UIKit.estrellas(GameState.reputacion)]],
		["Mejor jornada", "Día %d · %s (%d puntos)" % [int(mejor.get("dia", 0)), mejor.get("nombre_nivel", "-"), int(mejor.get("puntos", 0))] if not mejor.is_empty() else "-"],
		["Dinero final", UIKit.dinero(GameState.dinero)],
	]:
		_tabla.add_child(UIKit.etiqueta(fila[0], 16, UIKit.TEXTO_TENUE))
		_tabla.add_child(UIKit.etiqueta(fila[1], 16))

func _jugar_terraza() -> void:
	GameState.seleccionar_nivel(3)
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _menu_principal() -> void:
	GameState.cambiar_escena(GameState.ESCENA_MENU)
