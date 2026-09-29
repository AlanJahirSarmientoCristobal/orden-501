extends PanelModal
class_name PanelTienda

## Menú de compra del Mercado o la Cervecería (fase de mañana).

const SALUDOS := {
	Catalogo.MERCADO: "Don Chema, vendedor del mercado: \"¡Buenos días, gerente! Todo fresco. Ojo: la carne, el pollo, la verdura y el pan caducan.\"",
	Catalogo.CERVECERIA: "Lupita, encargada de la cervecería: \"Para el partido nunca sobra la cerveza. El hielo se derrite, cómpralo al día.\"",
}

var tienda := Catalogo.MERCADO
var _producto := ""                    # Si no está vacío, solo se muestra ese insumo (estante)
var _cantidades := {}

func tamano() -> Vector2:
	return Vector2(760, 300) if _producto != "" else Vector2(760, 520)

func abrir_tienda(nueva: String) -> void:
	tienda = nueva
	_producto = ""
	_cantidades = {}
	for insumo in Catalogo.insumos_de_tienda(tienda):
		_cantidades[insumo] = 5
	abrir("MERCADO CENTRAL" if tienda == Catalogo.MERCADO else "CERVECERÍA LA ESQUINA")

## Compra de un solo producto, desde su estante dentro de la tienda.
func abrir_producto(insumo: String, titulo: String) -> void:
	tienda = Catalogo.INSUMOS[insumo]["tienda"]
	_producto = insumo
	_cantidades = {insumo: 5}
	abrir(titulo)

func construir() -> void:
	UIKit.limpiar(contenido)
	if _producto == "":
		var saludo := UIKit.etiqueta(SALUDOS.get(tienda, ""), 14, UIKit.TEXTO_TENUE)
		saludo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		saludo.custom_minimum_size.x = 700
		contenido.add_child(saludo)
	contenido.add_child(UIKit.etiqueta("Dinero: %s    ·    Almacén: %d / %d (libre %d)" % [UIKit.dinero(GameState.dinero), GameState.inventario.total_unidades(), GameState.capacidad_almacen(), GameState.espacio_libre()], 17, UIKit.ACENTO))
	contenido.add_child(HSeparator.new())
	var lista: Array[String] = Catalogo.insumos_de_tienda(tienda)
	if _producto != "":
		lista = [_producto]
	for insumo in lista:
		contenido.add_child(_fila(insumo))

func _fila(insumo: String) -> HBoxContainer:
	var datos: Dictionary = Catalogo.INSUMOS[insumo]
	var fila := UIKit.hbox(6)
	fila.add_child(UIKit.icono(datos["icono"], 32))
	var nombre := UIKit.etiqueta("%s  %s c/u%s" % [datos["nombre"], UIKit.dinero(datos["precio"]), "  (caduca)" if datos["perecedero"] else ""], 15)
	nombre.custom_minimum_size.x = 230
	fila.add_child(nombre)
	fila.add_child(UIKit.etiqueta("Tienes %d" % GameState.inventario.total(insumo), 14, UIKit.TEXTO_TENUE))
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fila.add_child(espacio)
	for delta in [-5, -1]:
		fila.add_child(UIKit.boton("%d" % delta, _ajustar.bind(insumo, delta), 14))
	var cantidad := UIKit.etiqueta(str(_cantidades[insumo]), 16, UIKit.TEXTO, true)
	cantidad.custom_minimum_size.x = 34
	fila.add_child(cantidad)
	for delta in [1, 5]:
		fila.add_child(UIKit.boton("+%d" % delta, _ajustar.bind(insumo, delta), 14))
	var total := int(datos["precio"]) * int(_cantidades[insumo])
	fila.add_child(UIKit.boton("Comprar %s" % UIKit.dinero(total), _comprar.bind(insumo), 14, 150))
	return fila

func _ajustar(insumo: String, delta: int) -> void:
	_cantidades[insumo] = clampi(int(_cantidades[insumo]) + delta, 1, 99)
	construir()

func _comprar(insumo: String) -> void:
	var error := GameState.comprar(insumo, int(_cantidades[insumo]))
	if error == "":
		AudioManager.sfx("caja")
		GameState.aviso.emit("Compraste %d %s." % [_cantidades[insumo], Catalogo.nombre_insumo(insumo)])
	else:
		AudioManager.sfx("error")
		GameState.aviso.emit(error)
	construir()
