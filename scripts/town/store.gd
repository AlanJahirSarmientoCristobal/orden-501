extends FaseManana

## Interior del Mercado o la Cervecería (escenas mercado.tscn y cerveceria.tscn), pintado con tiles
## de Kenney en sus TileMapLayer. La tienda está decorada con los productos en sus muebles; para
## comprar se habla con el vendedor de la caja, que abre un menú al estilo de Pokémon Rojo Fuego.

## Tienda de esta escena: "mercado" (mercado.tscn) o "cerveceria" (cerveceria.tscn).
@export_enum("mercado", "cerveceria") var tienda := "mercado"

var _rotacion := 0.0
var _menu: MenuCompra
var _nombre_vendedor := ""
var _clave_vendedor := ""

# Solo la Cervecería tiene el exhibidor de Monster.
@onready var _exhibidor: Sprite2D = get_node_or_null("ExhibidorMonster")

func nombre_lugar() -> String:
	return "MERCADO CENTRAL" if tienda == Catalogo.MERCADO else "CERVECERÍA LA ESQUINA"

func _ready() -> void:
	_clave_vendedor = "vendedor_mercado" if tienda == Catalogo.MERCADO else "encargado_cerveceria"
	_nombre_vendedor = "Don Chema" if tienda == Catalogo.MERCADO else "Lupita"
	preparar_fase()
	_menu = MenuCompra.new()
	add_child(_menu)
	GameState.aviso.emit("Habla con %s en la caja para comprar." % _nombre_vendedor)
	if GameState.tutorial_pendiente("pueblo"):
		GameState.completar_tutorial("pueblo")
	if GameState.tutorial_pendiente("tienda"):
		_iniciar_tutorial()

## Jornada 1: cómo comprar con el menú del vendedor.
func _iniciar_tutorial() -> void:
	var inicial := GameState.inventario.total_unidades()
	var pasos: Array[Dictionary] = [
		{"texto": "Habla con %s en la caja: acércate y presiona Espacio." % _nombre_vendedor,
			"detalle": "Los muebles con productos son decoración: todo se compra en la caja.",
			"hecho": func() -> bool: return _menu.esta_abierto()},
		{"texto": "Elige un producto con W / S (o las flechas) y presiona Espacio.",
			"detalle": "Abajo ves en qué platillos se usa y cuántos días dura antes de caducar.",
			"hecho": func() -> bool: return _menu.estado == MenuCompra.Estado.CANTIDAD},
		{"texto": "Elige la cantidad y confirma con Espacio y luego «Sí».",
			"detalle": "Arriba / abajo cambia de 1 en 1 y los lados de 10 en 10. Cuida tu dinero y el espacio del almacén.",
			"hecho": func() -> bool: return GameState.inventario.total_unidades() > inicial},
		{"texto": "Compra lo que necesites y cierra el menú con SALIR o Esc.",
			"detalle": "Después sal por la puerta de abajo. Si te falta algo, visita la otra tienda.",
			"hecho": func() -> bool: return not _menu.esta_abierto()},
	]
	add_child(Tutorial.new("tienda", pasos))

func _process(delta: float) -> void:
	super._process(delta)
	# La lata del refrigerador de Monster cambia de diseño cada momento.
	if _exhibidor:
		_rotacion += delta
		if _rotacion >= 1.2:
			_rotacion = 0.0
			_exhibidor.texture = AssetPaths.siguiente_diseno("monster")
			_ajustar_exhibidor()

func _ajustar_exhibidor() -> void:
	if _exhibidor and _exhibidor.texture:
		var escala := 56.0 / float(_exhibidor.texture.get_height())
		_exhibidor.scale = Vector2(escala, escala)

func abrir_menu() -> void:
	_menu.abrir(tienda, _nombre_vendedor, _clave_vendedor)

func _al_usar_caja(_dani: Node) -> void:
	abrir_menu()

## La puerta (Area2D "Salida"): al cruzarla Dani sale al pueblo.
func _al_cruzar_puerta(cuerpo: Node) -> void:
	if cuerpo is Dani:
		_salir()

func _salir() -> void:
	if terminando:
		return
	terminando = true
	GameState.tienda_actual = ""
	GameState.cambiar_escena(GameState.ESCENA_PUEBLO)
