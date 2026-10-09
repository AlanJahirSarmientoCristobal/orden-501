extends Control

## Reporte de cierre (scenes/ui/closing_report.tscn): resultados del día, merma, condición del
## nivel, mejoras y "Reiniciar jornada". Cada mejora es una escena fila_mejora.tscn.

const FILA_MEJORA := preload("res://scenes/ui/fila_mejora.tscn")

@onready var _contenido: VBoxContainer = $Margen/Columnas/Informe/Desplazable/Contenido
@onready var _acciones: VBoxContainer = $Margen/Columnas/Derecha/Columna/Acciones
@onready var _mejoras: VBoxContainer = $Margen/Columnas/Derecha/Columna/Mejoras

func _ready() -> void:
	GameState.dinero_cambiado.connect(_al_cambiar_dinero)
	AudioManager.musica("manana")
	_construir_informe()
	_construir_mejoras()

func _al_cambiar_dinero(_valor: int) -> void:
	_construir_mejoras()

func _construir_informe() -> void:
	var inf: Dictionary = GameState.ultimo_informe
	var titulo: Label = _contenido.get_node("Titulo")
	if inf.is_empty():
		titulo.text = "No hay jornada que reportar."
		return
	var e: Dictionary = inf["estadisticas"]
	titulo.text = "REPORTE DE CIERRE · DÍA %d" % inf["dia"]
	_contenido.get_node("Nivel").text = "Nivel %d · %s" % [inf["nivel"], inf["nombre_nivel"]]
	var exito: bool = inf["exito"]
	var resultado: Label = _contenido.get_node("Resultado")
	resultado.text = "✔ JORNADA SUPERADA" if exito else "✘ JORNADA NO SUPERADA"
	resultado.add_theme_color_override("font_color", UIKit.VERDE if exito else UIKit.ROJO)
	var motivo: Label = _contenido.get_node("Motivo")
	motivo.text = str(inf["motivo"])
	motivo.visible = motivo.text != ""
	_contenido.get_node("Objetivo").text = "Objetivo: " + str(inf["objetivo"])
	for linea in inf["lineas_objetivo"]:
		_contenido.get_node("LineasObjetivo").add_child(UIKit.etiqueta(str(linea), 16, UIKit.VERDE if str(linea).begins_with("✔") else UIKit.ROJO))

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
	var tabla: GridContainer = _contenido.get_node("Tabla")
	for fila in filas:
		tabla.add_child(UIKit.etiqueta(fila[0], 15, UIKit.TEXTO_TENUE))
		tabla.add_child(UIKit.etiqueta(fila[1], 15))
	_mostrar_acciones(inf, exito)

## Los botones están en la escena; aquí solo se muestran los que aplican.
func _mostrar_acciones(inf: Dictionary, exito: bool) -> void:
	if bool(inf.get("reto", false)):
		var reto: Label = _acciones.get_node("Reto")
		reto.text = "RETO IMPOSIBLE: %s" % ("¡SUPERADO!" if exito else "no superado")
		reto.add_theme_color_override("font_color", UIKit.VERDE if exito else UIKit.ROJO)
		reto.visible = true
		_acciones.get_node("ReintentarReto").visible = true
		_acciones.get_node("MenuPrincipal").visible = true
		return
	var temporada := bool(inf.get("temporada_completa", false))
	_acciones.get_node("VerFinal").visible = exito and temporada
	_acciones.get_node("SiguienteDia").visible = exito and not temporada
	_acciones.get_node("Reiniciar").visible = true
	_acciones.get_node("MenuPrincipal").visible = true
	_acciones.get_node("Ayuda").visible = not exito

func _texto_merma(merma: Dictionary) -> String:
	if merma.is_empty():
		return "sin merma"
	var partes := []
	for insumo in merma:
		partes.append("%d %s" % [merma[insumo], Catalogo.nombre_insumo(insumo)])
	return ", ".join(partes)

func _construir_mejoras() -> void:
	_mejoras.get_node("Dinero").text = "Dinero: %s" % UIKit.dinero(GameState.dinero)
	var lista: VBoxContainer = _mejoras.get_node("Desplazable/Lista")
	UIKit.limpiar(lista)
	var sin_mejoras := ""
	if GameState.modo_reto:
		sin_mejoras = "En el Reto Imposible no hay mejoras."
	elif not bool(GameState.ultimo_informe.get("exito", false)):
		sin_mejoras = "Supera la jornada para comprar mejoras."
	var aviso: Label = _mejoras.get_node("Aviso")
	aviso.text = sin_mejoras
	aviso.visible = sin_mejoras != ""
	_mejoras.get_node("Desplazable").visible = sin_mejoras == ""
	_mejoras.get_node("Recordatorio").visible = sin_mejoras == ""
	if sin_mejoras != "":
		return
	for id in GameState.MEJORAS:
		var datos: Dictionary = GameState.MEJORAS[id]
		var costo := GameState.costo_mejora(id)
		var consumible := bool(datos.get("consumible", false))
		var fila: PanelContainer = FILA_MEJORA.instantiate()
		fila.get_node("Fila/Caja/Titulo").text = datos["nombre"] if consumible else "%s  (nivel %d/%d)" % [datos["nombre"], int(GameState.mejoras[id]), GameState.maximo_mejora(id)]
		fila.get_node("Fila/Caja/Descripcion").text = datos["descripcion"]
		var boton: Button = fila.get_node("Fila/Comprar")
		boton.text = UIKit.dinero(costo) if costo >= 0 else ("Lista para mañana" if consumible else "Máximo")
		boton.disabled = costo < 0 or GameState.dinero < costo
		boton.pressed.connect(_comprar.bind(id))
		lista.add_child(fila)

func _comprar(id: String) -> void:
	if GameState.comprar_mejora(id):
		GameState.aviso.emit("Mejora comprada: %s" % GameState.MEJORAS[id]["nombre"])
	_construir_mejoras()

func _ver_final() -> void:
	GameState.cambiar_escena(GameState.ESCENA_VICTORIA)

func _reintentar_reto() -> void:
	GameState.iniciar_reto_imposible()
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _siguiente_dia() -> void:
	GameState.iniciar_manana()
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _reiniciar() -> void:
	GameState.reiniciar_jornada()
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _menu_principal() -> void:
	GameState.cambiar_escena(GameState.ESCENA_MENU)
