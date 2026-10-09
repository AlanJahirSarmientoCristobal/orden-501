extends RefCounted
class_name UIKit

## Colores del juego y utilidades para las listas que se llenan en tiempo de ejecución
## (filas de stock, reservaciones, reportes). Las pantallas son escenas .tscn con el Theme
## Assets/tema/tema.tres, que define el estilo de botones, paneles y etiquetas.

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

## Etiqueta para listas que se llenan en tiempo de ejecución (el contorno viene del Theme).
static func etiqueta(texto: String, tam: int = 16, color: Color = TEXTO, centrado: bool = false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if centrado:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

## Botón para listas dinámicas (estilo del Theme; el clic lo hace sonar AudioManager).
static func boton(texto: String, accion: Callable, tam: int = 16, ancho_min: float = 0.0) -> Button:
	var b := Button.new()
	b.text = texto
	b.add_theme_font_size_override("font_size", tam)
	if ancho_min > 0.0:
		b.custom_minimum_size.x = ancho_min
	b.pressed.connect(accion)
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
