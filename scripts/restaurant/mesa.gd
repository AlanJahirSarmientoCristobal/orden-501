extends Interactuable
class_name Mesa

## Mesa del restaurante (escenas mesa_2.tscn y mesa_4.tscn). Estados: LIMPIA, OCUPADA o SUCIA.
## Una mesa desocupada queda sucia y nadie puede sentarse hasta que Dani la limpie.

enum EstadoMesa { LIMPIA, OCUPADA, SUCIA }

## Número de mesa (en el Inspector). La capacidad sale del número: 1-3 para 2 personas, el resto para 4.
@export var numero := 1
@export var terraza := false

var capacidad := 2
var estado: EstadoMesa = EstadoMesa.LIMPIA
var cliente: Cliente = null
var restaurante: Node = null

# Nodos de la escena (scenes/restaurant/mesa_2.tscn o mesa_4.tscn)
@onready var _etiqueta: Label = $Etiqueta
@onready var _cartel: Label = $Cartel
@onready var _platos: Node2D = $Platos

func _ready() -> void:
	capacidad = GameState.capacidad_mesa(numero)
	_etiqueta.text = "MESA %d · %d pers." % [numero, capacidad]
	if terraza:
		$Muebles.modulate = Color(1.08, 1.05, 0.95)

## Sillas en coordenadas locales: primero las de arriba (el cliente principal usa la primera).
func asientos_locales() -> Array[Vector2]:
	if capacidad <= 2:
		return [Vector2(0, -44), Vector2(0, 44)]
	return [Vector2(-24, -44), Vector2(24, -44), Vector2(-24, 44), Vector2(24, 44)]

## Dónde se para cada persona sentada (los pies quedan sobre la silla).
func asientos_globales() -> Array[Vector2]:
	var lista: Array[Vector2] = []
	for asiento in asientos_locales():
		lista.append(global_position + asiento + Vector2(0, 10))
	return lista

func posicion_asiento() -> Vector2:
	return position + asientos_locales()[0] + Vector2(0, 10)

func esta_libre() -> bool:
	return estado == EstadoMesa.LIMPIA and cliente == null

func ocupar(nuevo_cliente: Cliente) -> void:
	cliente = nuevo_cliente
	estado = EstadoMesa.OCUPADA

## El cliente se fue: la mesa queda sucia (si llegó a sentarse) o libre.
func liberar(ensuciar: bool) -> void:
	cliente = null
	estado = EstadoMesa.SUCIA if ensuciar else EstadoMesa.LIMPIA
	_platos.visible = ensuciar

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
