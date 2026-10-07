extends Control

## Reporte de cierre: resultados del día, merma, condición del nivel, mejoras y "Reiniciar jornada".

var _contenido: VBoxContainer
var _mejoras: VBoxContainer
var _acciones: VBoxContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var fondo := ColorRect.new()
	fondo.color = Color("12151d")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	var capa := Notificaciones.new()
	add_child(capa)
	var margen := MarginContainer.new()
	margen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "right", "top", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 24)
	add_child(margen)
	var columnas := UIKit.hbox(20)
	margen.add_child(columnas)

	var izquierda := UIKit.panel()
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var desplazable := ScrollContainer.new()
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_contenido = UIKit.vbox(6)
	_contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazable.add_child(_contenido)
	izquierda.add_child(desplazable)
	columnas.add_child(izquierda)

	var derecha := UIKit.panel()
	derecha.custom_minimum_size.x = 440
	var columna_derecha := UIKit.vbox(10)
	_acciones = UIKit.vbox(8)
	columna_derecha.add_child(_acciones)
	columna_derecha.add_child(HSeparator.new())
	_mejoras = UIKit.vbox(8)
	columna_derecha.add_child(_mejoras)
	derecha.add_child(columna_derecha)
	columnas.add_child(derecha)

	GameState.dinero_cambiado.connect(_al_cambiar_dinero)
	AudioManager.musica("manana")
	_construir_informe()
	_construir_mejoras()

func _al_cambiar_dinero(_valor: int) -> void:
	_construir_mejoras()

func _construir_informe() -> void:
	var inf: Dictionary = GameState.ultimo_informe
	if inf.is_empty():
		_contenido.add_child(UIKit.etiqueta("No hay jornada que reportar.", 18))
		return
	var e: Dictionary = inf["estadisticas"]
	_contenido.add_child(UIKit.etiqueta("REPORTE DE CIERRE · DÍA %d" % inf["dia"], 26, UIKit.ACENTO))
	_contenido.add_child(UIKit.etiqueta("Nivel %d · %s" % [inf["nivel"], inf["nombre_nivel"]], 18))
	var exito: bool = inf["exito"]
	_contenido.add_child(UIKit.etiqueta("✔ JORNADA SUPERADA" if exito else "✘ JORNADA NO SUPERADA", 24, UIKit.VERDE if exito else UIKit.ROJO))
	if str(inf["motivo"]) != "":
		_texto_largo(str(inf["motivo"]), 15, UIKit.ROJO)
	_texto_largo("Objetivo: " + str(inf["objetivo"]), 15, UIKit.TEXTO_TENUE)
	for linea in inf["lineas_objetivo"]:
		_contenido.add_child(UIKit.etiqueta(str(linea), 16, UIKit.VERDE if str(linea).begins_with("✔") else UIKit.ROJO))
	_contenido.add_child(HSeparator.new())

	var rep_inicial := float(e.get("reputacion_inicial", inf["reputacion"]))
	var filas := [
		["Ventas del partido", UIKit.dinero(e["ventas"])],
		["Propinas incluidas", UIKit.dinero(e["propinas"])],
		["Pedidos entregados", str(e["pedidos"])],
		["Clientes VIP atendidos", str(e["vip_atendidos"])],
		["Clientes perdidos", str(e["perdidos"])],
		["Quiebres de stock", str(e["quiebres"])],
		["Pedidos urgentes", "%d (%s)" % [e["urgentes"], UIKit.dinero(e["gasto_urgente"])]],
		["Sustitutos ofrecidos", str(e["sustitutos"])],
		["Platillos marcados agotados", str(e["agotados"])],
		["Reservaciones atendidas", str(e["reservas_atendidas"])],
		["Reservaciones duplicadas", str(e["duplicados"])],
		["Reservaciones sin mesa", str(e["reservas_sin_mesa"])],
		["Compras de la mañana", UIKit.dinero(e["compras"])],
		["Merma por caducidad", "%s (%s)" % [_texto_merma(inf["merma"]), UIKit.dinero(inf["costo_merma"])]],
		["Reputación", "%d%% → %d%%  %s" % [int(rep_inicial), int(inf["reputacion"]), UIKit.estrellas(inf["reputacion"])]],
		["Dinero disponible", UIKit.dinero(GameState.dinero)],
		["PUNTUACIÓN", "%d puntos%s" % [int(inf.get("puntos", 0)), "  (+%d por superar la jornada)" % GameState.PUNTOS_JORNADA_SUPERADA if exito else ""]],
	]
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 24)
	grid.add_theme_constant_override("v_separation", 4)
	for fila in filas:
		grid.add_child(UIKit.etiqueta(fila[0], 15, UIKit.TEXTO_TENUE))
		grid.add_child(UIKit.etiqueta(fila[1], 15))
	_contenido.add_child(grid)
	_contenido.add_child(HSeparator.new())

	if bool(inf.get("reto", false)):
		_acciones.add_child(UIKit.etiqueta("RETO IMPOSIBLE: %s" % ("¡SUPERADO!" if exito else "no superado"), 18, UIKit.VERDE if exito else UIKit.ROJO))
		_acciones.add_child(UIKit.boton("Reintentar el reto", _reintentar_reto, 17, 400))
		_acciones.add_child(UIKit.boton("Menú principal", func(): GameState.cambiar_escena(GameState.ESCENA_MENU), 17, 400))
		return
	if exito and bool(inf.get("temporada_completa", false)):
		_acciones.add_child(UIKit.boton("Ver final de temporada", func(): GameState.cambiar_escena(GameState.ESCENA_VICTORIA), 17, 400))
	elif exito:
		_acciones.add_child(UIKit.boton("Siguiente día", _siguiente_dia, 17, 400))
	_acciones.add_child(UIKit.boton("Reiniciar jornada", _reiniciar, 17, 400))
	_acciones.add_child(UIKit.boton("Menú principal", func(): GameState.cambiar_escena(GameState.ESCENA_MENU), 17, 400))
	if not exito:
		var ayuda := UIKit.etiqueta("\"Reiniciar jornada\" repite el día desde la mañana con el dinero y el inventario que tenías al inicio. Los niveles superados siguen desbloqueados; se pierden las monedas de esta jornada.", 13, UIKit.TEXTO_TENUE)
		ayuda.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ayuda.custom_minimum_size.x = 400
		_acciones.add_child(ayuda)

func _texto_largo(texto: String, tam: int, color: Color) -> void:
	var l := UIKit.etiqueta(texto, tam, color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 700
	_contenido.add_child(l)

func _texto_merma(merma: Dictionary) -> String:
	if merma.is_empty():
		return "sin merma"
	var partes := []
	for insumo in merma:
		partes.append("%d %s" % [merma[insumo], Catalogo.nombre_insumo(insumo)])
	return ", ".join(partes)

func _construir_mejoras() -> void:
	UIKit.limpiar(_mejoras)
	var exito := bool(GameState.ultimo_informe.get("exito", false))
	_mejoras.add_child(UIKit.etiqueta("MEJORAS DEL RESTAURANTE", 20, UIKit.ACENTO))
	_mejoras.add_child(UIKit.etiqueta("Dinero: %s" % UIKit.dinero(GameState.dinero), 16))
	if GameState.modo_reto:
		_mejoras.add_child(UIKit.etiqueta("En el Reto Imposible no hay mejoras.", 14, UIKit.TEXTO_TENUE))
		return
	if not exito:
		var l := UIKit.etiqueta("Supera la jornada para comprar mejoras.", 14, UIKit.TEXTO_TENUE)
		_mejoras.add_child(l)
		return
	var desplazable := ScrollContainer.new()
	desplazable.custom_minimum_size = Vector2(400, 380)
	desplazable.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var lista := UIKit.vbox(6)
	lista.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazable.add_child(lista)
	_mejoras.add_child(desplazable)
	for id in GameState.MEJORAS:
		var datos: Dictionary = GameState.MEJORAS[id]
		var nivel := int(GameState.mejoras[id])
		var maximo := GameState.maximo_mejora(id)
		var costo := GameState.costo_mejora(id)
		var consumible := bool(datos.get("consumible", false))
		var tarjeta := UIKit.panel(UIKit.FONDO_CLARO, Color(UIKit.BORDE, 0.35), 6)
		var fila := UIKit.hbox(8)
		var caja := UIKit.vbox(0)
		caja.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var titulo: String = datos["nombre"] if consumible else "%s  (nivel %d/%d)" % [datos["nombre"], nivel, maximo]
		caja.add_child(UIKit.etiqueta(titulo, 14, UIKit.TEXTO))
		var descripcion := UIKit.etiqueta(datos["descripcion"], 11, UIKit.TEXTO_TENUE)
		descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		descripcion.custom_minimum_size.x = 250
		caja.add_child(descripcion)
		fila.add_child(caja)
		var texto_boton := UIKit.dinero(costo)
		if costo < 0:
			texto_boton = "Lista para mañana" if consumible else "Máximo"
		var boton := UIKit.boton(texto_boton, _comprar.bind(id), 13, 110)
		boton.disabled = costo < 0 or GameState.dinero < costo
		fila.add_child(boton)
		tarjeta.add_child(fila)
		lista.add_child(tarjeta)
	_mejoras.add_child(UIKit.etiqueta("Recuerda guardar dinero para las compras de mañana.", 12, UIKit.TEXTO_TENUE))

func _comprar(id: String) -> void:
	if GameState.comprar_mejora(id):
		GameState.aviso.emit("Mejora comprada: %s" % GameState.MEJORAS[id]["nombre"])
	_construir_mejoras()

func _reintentar_reto() -> void:
	GameState.iniciar_reto_imposible()
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _siguiente_dia() -> void:
	GameState.iniciar_manana()
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _reiniciar() -> void:
	GameState.reiniciar_jornada()
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)
