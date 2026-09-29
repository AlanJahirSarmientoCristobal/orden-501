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
var _platos: Node2D

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
	_etiqueta.position = Vector2(-60, 70)
	_etiqueta.size = Vector2(120, 14)
	add_child(_etiqueta)

	_cartel = UIKit.etiqueta("", 11, UIKit.AZUL, true)
	_cartel.position = Vector2(-70, -94)
	_cartel.size = Vector2(140, 14)
	add_child(_cartel)

	_construir_muebles()
	_platos = Node2D.new()
	_platos.z_index = 1
	var plato := Sprite2D.new()
	plato.texture = Interior.textura(Interior.RPG, 1081)
	plato.scale = Vector2(2.5, 2.5)
	plato.position = Vector2(-10, -4)
	_platos.add_child(plato)
	var tazon := Sprite2D.new()
	tazon.texture = Interior.textura(Interior.RPG, 854)
	tazon.scale = Vector2(2.5, 2.5)
	tazon.position = Vector2(12, 6)
	_platos.add_child(tazon)
	_platos.visible = false
	add_child(_platos)

func _tamano_mesa() -> Vector2:
	return Vector2(48, 48) if capacidad <= 2 else Vector2(96, 48)

## Mesa y sillas con tiles del pack Roguelike Indoors.
## 2 personas: mesa redonda de 1 tile; 4 personas: mesa ovalada de 2x1.
func _construir_muebles() -> void:
	var I := Interior.INDOOR
	if capacidad <= 2:
		_tile(I, 7, Vector2(0, 0))
		_tile(I, 54, Vector2(0, -44))    # Silla de arriba (donde se sienta el cliente)
		_tile(I, 55, Vector2(0, 44))     # Silla de abajo, de espaldas
	else:
		_tile(I, 3, Vector2(-24, 0))
		_tile(I, 4, Vector2(24, 0))
		for x in [-24, 24]:
			_tile(I, 54, Vector2(x, -44))
			_tile(I, 55, Vector2(x, 44))
	if terraza:
		for hijo in _muebles:
			hijo.modulate = Color(1.08, 1.05, 0.95)

var _muebles: Array[Sprite2D] = []

func _tile(fuente: String, id: int, desfase: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = Interior.textura(fuente, id)
	s.scale = Vector2(Interior.ESCALA, Interior.ESCALA)
	s.position = desfase
	s.z_index = -1
	add_child(s)
	_muebles.append(s)
	return s

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
