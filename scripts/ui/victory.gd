extends Control

## Final de la temporada: La 501 se vuelve el restaurante de referencia del pueblo,
## se desbloquea la terraza y se muestra el reporte de la temporada.

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color("0f2a1d")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	AudioManager.musica("manana")
	AudioManager.sfx("gol")

	var panel := UIKit.panel(UIKit.FONDO, UIKit.BORDE, 24)
	panel.custom_minimum_size = Vector2(820, 560)
	var caja := UIKit.vbox(10)
	panel.add_child(caja)
	caja.add_child(UIKit.etiqueta("¡CAMPEONES DE LA TEMPORADA!", 32, UIKit.ACENTO, true))
	var historia := UIKit.etiqueta("Gracias a Dani, La 501 superó la Gran Final y se convirtió en el restaurante de referencia del pueblo para ver los partidos. Se desbloqueó la TERRAZA con dos mesas nuevas.", 16, UIKit.TEXTO, true)
	historia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	historia.custom_minimum_size.x = 760
	caja.add_child(historia)
	caja.add_child(HSeparator.new())
	caja.add_child(UIKit.etiqueta("REPORTE FINAL DE TEMPORADA · Dificultad %s" % GameState.config.nombre, 18, UIKit.ACENTO, true))

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
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 40)
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
		grid.add_child(UIKit.etiqueta(fila[0], 16, UIKit.TEXTO_TENUE))
		grid.add_child(UIKit.etiqueta(fila[1], 16))
	var centro := CenterContainer.new()
	centro.add_child(grid)
	caja.add_child(centro)
	caja.add_child(HSeparator.new())
	var botones := UIKit.hbox(12)
	botones.alignment = BoxContainer.ALIGNMENT_CENTER
	botones.add_child(UIKit.boton("Jugar la Gran Final con terraza", _jugar_terraza, 16))
	botones.add_child(UIKit.boton("Menú principal", func(): GameState.cambiar_escena(GameState.ESCENA_MENU), 16))
	caja.add_child(botones)
	UIKit.centrar(panel, self)

func _jugar_terraza() -> void:
	GameState.seleccionar_nivel(3)
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)
