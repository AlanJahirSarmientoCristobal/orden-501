extends Interactuable
class_name Mesa

## Mesa del restaurante. Estados: LIMPIA, OCUPADA o SUCIA.
## Una mesa desocupada queda sucia y nadie puede sentarse hasta que Dani la limpie.

enum EstadoMesa { LIMPIA, OCUPADA, SUCIA }

var numero := 1
var capacidad := 2
var estado: EstadoMesa = EstadoMesa.LIMPIA
var cliente: Cliente = null
var terraza := false
var restaurante: Node = null

var _cuerpo: StaticBody2D
var _etiqueta: Label
var _cartel: Label
var _platos: TextureRect

func configurar(nuevo_numero: int, pos: Vector2, es_terraza: bool = false) -> void:
	numero = nuevo_numero
	capacidad = GameState.capacidad_mesa(numero)
	position = pos
	terraza = es_terraza
	radio = 64.0

func _ready() -> void:
	super._ready()
	add_to_group("mesas")
	_cuerpo = StaticBody2D.new()
	_cuerpo.collision_layer = 1
	var forma := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = _tamano_mesa() - Vector2(8, 8)
	forma.shape = rect
	_cuerpo.add_child(forma)
	add_child(_cuerpo)

	_etiqueta = UIKit.etiqueta("MESA %d · %d pers." % [numero, capacidad], 11, UIKit.TEXTO, true)
	_etiqueta.position = Vector2(-60, _tamano_mesa().y * 0.5 + 18)
	_etiqueta.size = Vector2(120, 14)
	add_child(_etiqueta)

	_cartel = UIKit.etiqueta("", 11, UIKit.AZUL, true)
	_cartel.position = Vector2(-70, -_tamano_mesa().y * 0.5 - 40)
	_cartel.size = Vector2(140, 14)
	add_child(_cartel)

	_platos = UIKit.icono("plato_sucio", 30)
	_platos.position = Vector2(-15, -15)
	_platos.visible = false
	add_child(_platos)
	queue_redraw()

func _tamano_mesa() -> Vector2:
	return Vector2(70, 50) if capacidad <= 2 else Vector2(100, 56)

func _draw() -> void:
	var t := _tamano_mesa()
	# Sillas
	var color_silla := Color("6b4a2b")
	var sillas := [Vector2(-t.x * 0.5 - 14, -8), Vector2(t.x * 0.5 + 2, -8)]
	if capacidad > 2:
		sillas.append(Vector2(-t.x * 0.25 - 6, -t.y * 0.5 - 16))
		sillas.append(Vector2(t.x * 0.25 - 6, -t.y * 0.5 - 16))
	for s in sillas:
		draw_rect(Rect2(s, Vector2(12, 16)), color_silla)
	# Mesa
	var madera := Color("a0652f") if not terraza else Color("c9a26b")
	draw_rect(Rect2(-t * 0.5 + Vector2(0, 4), t), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(-t * 0.5, t), madera)
	draw_rect(Rect2(-t * 0.5, t), madera.darkened(0.35), false, 3.0)
	if estado == EstadoMesa.SUCIA:
		draw_circle(Vector2(-t.x * 0.3, t.y * 0.2), 5, Color("7a5230"))
		draw_circle(Vector2(t.x * 0.25, -t.y * 0.15), 4, Color("7a5230"))

func posicion_asiento() -> Vector2:
	return position + Vector2(0, -_tamano_mesa().y * 0.5 - 14)

func esta_libre() -> bool:
	return estado == EstadoMesa.LIMPIA and cliente == null

func ocupar(nuevo_cliente: Cliente) -> void:
	cliente = nuevo_cliente
	estado = EstadoMesa.OCUPADA
	queue_redraw()

## El cliente se fue: la mesa queda sucia (si llegó a sentarse) o libre.
func liberar(ensuciar: bool) -> void:
	cliente = null
	estado = EstadoMesa.SUCIA if ensuciar else EstadoMesa.LIMPIA
	_platos.visible = ensuciar
	queue_redraw()

func actualizar_cartel(texto_cartel: String) -> void:
	_cartel.text = texto_cartel

# ---------------------------------------------------------------- Interacción con Dani

func disponible(_dani: Node) -> bool:
	if estado == EstadoMesa.SUCIA:
		return true
	return cliente != null and cliente.estado in [Cliente.Estado.ORDENANDO, Cliente.Estado.ESPERANDO_COMIDA, Cliente.Estado.COMIENDO]

func obtener_texto(dani: Node) -> String:
	if estado == EstadoMesa.SUCIA:
		return "Limpiar Mesa %d" % numero
	if cliente:
		return "%s · Mesa %d" % [cliente.texto_interaccion(dani), numero]
	return "Mesa %d" % numero

func tiempo_mantener(_dani: Node) -> float:
	return GameState.tiempo_limpieza() if estado == EstadoMesa.SUCIA else 0.0

func interactuar(dani: Node) -> void:
	super.interactuar(dani)
	if estado == EstadoMesa.SUCIA:
		estado = EstadoMesa.LIMPIA
		_platos.visible = false
		AudioManager.sfx("limpiar")
		queue_redraw()
		return
	if cliente == null:
		return
	match cliente.estado:
		Cliente.Estado.ORDENANDO:
			cliente.tomar_pedido()
		Cliente.Estado.ESPERANDO_COMIDA:
			if not cliente.servir(dani):
				AudioManager.sfx("error")
				GameState.aviso.emit("Mesa %d espera: %s. Recógelo en %s." % [numero, cliente.pedido, "la barra" if Catalogo.estacion(cliente.pedido) == Catalogo.BARRA else "el pase de cocina"])
