extends RefCounted
class_name UIKit

## Utilidades para construir la interfaz por código con un estilo uniforme.

const FONDO := Color("1b1f2a")
const FONDO_CLARO := Color("262c3b")
const BORDE := Color("f2b544")
const TEXTO := Color("f4efe3")
const TEXTO_TENUE := Color("a9b0c0")
const ACENTO := Color("f2b544")
const VERDE := Color("5fd38d")
const ROJO := Color("ff6b6b")
const AZUL := Color("6fb7ff")

static func estilo(color: Color, radio: int = 8, borde: Color = Color.TRANSPARENT, ancho_borde: int = 0, margen: int = 12) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = color
	caja.set_corner_radius_all(radio)
	caja.border_color = borde
	caja.set_border_width_all(ancho_borde)
	caja.set_content_margin_all(margen)
	return caja

static func panel(color: Color = FONDO, borde: Color = BORDE, margen: int = 14) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", estilo(Color(color, 0.96), 10, borde, 2, margen))
	return p

static func etiqueta(texto: String, tam: int = 16, color: Color = TEXTO, centrado: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.05))
	l.add_theme_constant_override("outline_size", 3)
	if centrado:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

static func boton(texto: String, accion: Callable, tam: int = 16, ancho_min: float = 0.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_size_override("font_size", tam)
	b.add_theme_color_override("font_color", TEXTO)
	b.add_theme_color_override("font_hover_color", Color.WHITE)
	b.add_theme_color_override("font_disabled_color", Color(TEXTO_TENUE, 0.6))
	b.add_theme_stylebox_override("normal", estilo(FONDO_CLARO, 6, Color(BORDE, 0.5), 1, 8))
	b.add_theme_stylebox_override("hover", estilo(Color("34405a"), 6, BORDE, 2, 8))
	b.add_theme_stylebox_override("pressed", estilo(Color("46547a"), 6, BORDE, 2, 8))
	b.add_theme_stylebox_override("focus", estilo(Color("34405a"), 6, BORDE, 2, 8))
	b.add_theme_stylebox_override("disabled", estilo(Color(FONDO_CLARO, 0.5), 6, Color.TRANSPARENT, 0, 8))
	if ancho_min > 0.0:
		b.custom_minimum_size.x = ancho_min
	b.pressed.connect(func():
		AudioManager.sfx("click")
		accion.call()
	)
	return b

static func vbox(separacion: int = 8) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separacion)
	return v

static func hbox(separacion: int = 8) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separacion)
	return h

static func icono(clave: String, tam: float = 28.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = AssetPaths.textura(clave)
	t.custom_minimum_size = Vector2(tam, tam)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return t

static func capa(nivel: int) -> CanvasLayer:
	var c := CanvasLayer.new()
	c.layer = nivel
	return c

static func velo(opacidad: float = 0.7) -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.01, 0.02, 0.05, opacidad)
	r.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	r.mouse_filter = Control.MOUSE_FILTER_STOP
	return r

static func centrar(control: Control, padre: Control) -> CenterContainer:
	var c := CenterContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	c.add_child(control)
	padre.add_child(c)
	return c

static func limpiar(nodo: Node) -> void:
	for hijo in nodo.get_children():
		nodo.remove_child(hijo)
		hijo.queue_free()

static func estrellas(reputacion: float) -> String:
	var llenas := clampi(int(round(reputacion / 20.0)), 0, 5)
	return "★".repeat(llenas) + "☆".repeat(5 - llenas)

static func dinero(valor: int) -> String:
	var signo := "-" if valor < 0 else ""
	var texto := str(absi(valor))
	var partes := []
	while texto.length() > 3:
		partes.push_front(texto.substr(texto.length() - 3))
		texto = texto.substr(0, texto.length() - 3)
	partes.push_front(texto)
	return "%s$%s" % [signo, ",".join(partes)]
