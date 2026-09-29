extends Control

## Menú principal: nueva partida con selección de dificultad, continuar, niveles y controles.

var _principal: VBoxContainer
var _secundario: VBoxContainer
var _panel_secundario: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	AudioManager.musica("manana")
	var fondo := ColorRect.new()
	fondo.color = Color("14202b")
	fondo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(fondo)
	_decorar()

	var columnas := UIKit.hbox(30)
	columnas.position = Vector2(80, 90)
	columnas.size = Vector2(1120, 560)
	add_child(columnas)

	var izquierda := UIKit.vbox(10)
	izquierda.custom_minimum_size.x = 380
	izquierda.add_child(UIKit.etiqueta("ORDEN 501", 64, UIKit.ACENTO))
	var lema := UIKit.etiqueta("Pon en orden el restaurante deportivo La 501: compra por la mañana, atiende durante el partido y llega a la Gran Final.", 15, UIKit.TEXTO_TENUE)
	lema.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lema.custom_minimum_size.x = 380
	izquierda.add_child(lema)
	izquierda.add_child(Control.new())
	_principal = UIKit.vbox(10)
	izquierda.add_child(_principal)
	columnas.add_child(izquierda)

	_panel_secundario = UIKit.panel()
	_panel_secundario.custom_minimum_size = Vector2(660, 520)
	_panel_secundario.visible = false
	_secundario = UIKit.vbox(10)
	_panel_secundario.add_child(_secundario)
	columnas.add_child(_panel_secundario)

	var creditos := UIKit.etiqueta("Alan Jahir Sarmiento Cristóbal · Luis Ángel Hernández Hernández · Optativa 1: Creación de Videojuegos · Gráficos temporales: Kenney (CC0)", 12, UIKit.TEXTO_TENUE, true)
	creditos.position = Vector2(0, 690)
	creditos.size = Vector2(1280, 20)
	add_child(creditos)
	_construir_principal()

func _decorar() -> void:
	var claves := ["cliente_1", "cliente_vip", "dani", "chef", "cliente_2", "cliente_3"]
	for i in range(claves.size()):
		var s := AnimatedSprite2D.new()
		s.sprite_frames = AssetPaths.frames_personaje(claves[i])
		s.animation = &"down"
		s.scale = Vector2(4, 4)
		s.position = Vector2(110 + i * 64, 600)
		s.play()
		add_child(s)
	for i in range(5):
		var t := UIKit.icono(Catalogo.icono_platillo(Catalogo.PLATILLOS.keys()[i]), 40)
		t.position = Vector2(100 + i * 70, 520)
		add_child(t)

func _construir_principal() -> void:
	UIKit.limpiar(_principal)
	_principal.add_child(UIKit.boton("Nueva partida", _mostrar_dificultad, 20, 320))
	if GameState.hay_partida_guardada():
		_principal.add_child(UIKit.boton("Continuar", _continuar, 20, 320))
		_principal.add_child(UIKit.boton("Seleccionar nivel", _mostrar_niveles, 20, 320))
	_principal.add_child(UIKit.boton("Cómo jugar", _mostrar_controles, 20, 320))
	_principal.add_child(UIKit.boton("Pantalla completa", _pantalla_completa, 20, 320))
	_principal.add_child(UIKit.boton("Salir", func(): get_tree().quit(), 20, 320))

func _abrir_secundario(titulo: String) -> void:
	UIKit.limpiar(_secundario)
	_panel_secundario.visible = true
	_secundario.add_child(UIKit.etiqueta(titulo, 24, UIKit.ACENTO))

func _mostrar_dificultad() -> void:
	_abrir_secundario("ELIGE LA DIFICULTAD")
	for id in ConfiguracionDificultad.TODAS:
		var config := ConfiguracionDificultad.obtener(id)
		var tarjeta := UIKit.panel(UIKit.FONDO_CLARO, Color(UIKit.BORDE, 0.4), 10)
		var caja := UIKit.vbox(4)
		caja.add_child(UIKit.boton("Jugar en %s" % config.nombre, _nueva_partida.bind(id), 18, 600))
		caja.add_child(UIKit.etiqueta(config.describir(), 13, UIKit.TEXTO_TENUE))
		tarjeta.add_child(caja)
		_secundario.add_child(tarjeta)

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
	if not GameState.cargar():
		return
	_abrir_secundario("SELECCIONAR NIVEL · %s" % GameState.config.nombre)
	for nivel in [1, 2, 3]:
		var info := GameState.info_nivel(nivel)
		var desbloqueado: bool = nivel <= GameState.nivel_desbloqueado
		var boton := UIKit.boton("%d. %s%s" % [nivel, info["nombre"], "" if desbloqueado else "  (bloqueado)"], _jugar_nivel.bind(nivel), 18, 600)
		boton.disabled = not desbloqueado
		_secundario.add_child(boton)
		var objetivo := UIKit.etiqueta(info["objetivo"], 13, UIKit.TEXTO_TENUE)
		objetivo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		objetivo.custom_minimum_size.x = 600
		_secundario.add_child(objetivo)

func _jugar_nivel(nivel: int) -> void:
	GameState.seleccionar_nivel(nivel)
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)

func _mostrar_controles() -> void:
	_abrir_secundario("CÓMO JUGAR")
	var texto := """MAÑANA (pueblo): recorre el pueblo y compra insumos en el Mercado (carne, pollo, papas, verdura, pan) y la Cervecería (cerveza, refresco, hielo). Tienes dinero y almacén limitados, y algunos insumos caducan.

JORNADA (restaurante): toma pedidos en las mesas, recoge los platillos en el pase de cocina o la barra, sirve y limpia las mesas antes de que se agote la paciencia. En el medio tiempo y con cada gol llegan olas de pedidos.

FALTANTE: si un insumo se acaba, elige entre marcar el platillo como agotado, pedir urgente por teléfono u ofrecer un sustituto.

CIERRE: revisa el reporte del día y compra mejoras.

W A S D / Flechas: moverse
Shift: correr (gasta estamina; si se agota, espera a que se recupere)
Espacio: interactuar (mantener para limpiar mesas)
E: tablet (stock, cocina, reservaciones, avisos)
Q: pedido urgente al proveedor
R: asignar reservaciones
I: inventario (en el pueblo)
Esc: pausa"""
	var l := UIKit.etiqueta(texto, 14)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 620
	_secundario.add_child(l)

func _pantalla_completa() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
