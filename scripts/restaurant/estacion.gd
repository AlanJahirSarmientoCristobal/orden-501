extends Interactuable
class_name Estacion

## Estación donde se preparan pedidos: el pase de cocina (Chef) o la barra de bebidas.
## Recibe comandas en cola, las prepara y Dani recoge los platillos listos.

signal cola_cambiada

var tipo := Catalogo.COCINA
var simultaneos := 1
var cola: Array[Dictionary] = []          # {"platillo", "cliente"}
var preparando: Array[Dictionary] = []    # {"platillo", "cliente", "restante", "total"}
var listos: Array[Dictionary] = []        # {"platillo", "cliente"}

var _vista_listos: HBoxContainer
var _barra: ProgressBar
var _estado: Label

func configurar(nuevo_tipo: String, pos: Vector2) -> void:
	tipo = nuevo_tipo
	position = pos
	simultaneos = 1 if tipo == Catalogo.COCINA else 2
	radio = 58.0

func _ready() -> void:
	super._ready()
	add_to_group("estaciones")
	_barra = ProgressBar.new()
	_barra.position = Vector2(-30, -58)
	_barra.size = Vector2(60, 8)
	_barra.show_percentage = false
	_barra.max_value = 1.0
	_barra.visible = false
	_barra.add_theme_stylebox_override("fill", UIKit.estilo(UIKit.ACENTO, 3, Color.TRANSPARENT, 0, 0))
	_barra.add_theme_stylebox_override("background", UIKit.estilo(Color(0, 0, 0, 0.6), 3, Color.TRANSPARENT, 0, 0))
	add_child(_barra)
	_vista_listos = UIKit.hbox(2)
	_vista_listos.position = Vector2(-50, -34)
	_vista_listos.size = Vector2(100, 24)
	add_child(_vista_listos)
	_estado = UIKit.etiqueta("", 10, UIKit.TEXTO_TENUE, true)
	_estado.position = Vector2(-70, 24)
	_estado.size = Vector2(140, 14)
	add_child(_estado)
	_actualizar_vista()

func agregar_pedido(platillo: String, cliente: Cliente) -> void:
	var porciones: int = cliente.personas if cliente else 1
	cola.append({"platillo": platillo, "cliente": cliente, "porciones": porciones})
	_actualizar_vista()

func _process(delta: float) -> void:
	while preparando.size() < simultaneos and not cola.is_empty():
		var orden: Dictionary = cola.pop_front()
		var total := float(Catalogo.PLATILLOS[orden["platillo"]]["tiempo"])
		if tipo == Catalogo.COCINA:
			total *= GameState.multiplicador_cocina()
		# Un pedido para varias personas tarda más (35 % extra por persona adicional).
		total *= 1.0 + 0.35 * float(int(orden.get("porciones", 1)) - 1)
		orden["restante"] = total
		orden["total"] = total
		preparando.append(orden)
		_actualizar_vista()
	if preparando.is_empty():
		_barra.visible = false
		return
	for orden in preparando.duplicate():
		orden["restante"] = float(orden["restante"]) - delta
		if float(orden["restante"]) <= 0.0:
			preparando.erase(orden)
			listos.append({"platillo": orden["platillo"], "cliente": orden["cliente"]})
			AudioManager.sfx("pedido_listo")
			_actualizar_vista()
	if not preparando.is_empty():
		var primero: Dictionary = preparando[0]
		_barra.visible = true
		_barra.value = 1.0 - float(primero["restante"]) / float(primero["total"])

## Quita todo lo relacionado con un cliente que se fue.
func cancelar(cliente: Cliente) -> void:
	cola = cola.filter(func(o): return o["cliente"] != cliente)
	preparando = preparando.filter(func(o): return o["cliente"] != cliente)
	# Lo que ya estaba listo se queda en el pase: otro cliente puede aprovecharlo.
	for o in listos:
		if o["cliente"] == cliente:
			o["cliente"] = null
	_actualizar_vista()

func pendientes() -> int:
	return cola.size() + preparando.size()

func descripcion_cola() -> Array[String]:
	var lineas: Array[String] = []
	for o in preparando:
		lineas.append("Preparando: %s x%d (Mesa %s)" % [o["platillo"], int(o.get("porciones", 1)), _mesa_de(o)])
	for o in cola:
		lineas.append("En cola: %s x%d (Mesa %s)" % [o["platillo"], int(o.get("porciones", 1)), _mesa_de(o)])
	for o in listos:
		lineas.append("LISTO: %s (Mesa %s)" % [o["platillo"], _mesa_de(o)])
	return lineas

func _mesa_de(orden: Dictionary) -> String:
	var c = orden.get("cliente")
	if c != null and is_instance_valid(c) and c.mesa != null:
		return str(c.mesa.numero)
	return "-"

func _actualizar_vista() -> void:
	if _vista_listos == null:
		return
	UIKit.limpiar(_vista_listos)
	for o in listos:
		_vista_listos.add_child(UIKit.icono(Catalogo.icono_platillo(o["platillo"]), 22))
	var nombre := "PASE DE COCINA" if tipo == Catalogo.COCINA else "BARRA DE BEBIDAS"
	_estado.text = "%s · %d en cola" % [nombre, cola.size() + preparando.size()]
	cola_cambiada.emit()

# ---------------------------------------------------------------- Interacción

func obtener_texto(dani: Node) -> String:
	if not listos.is_empty():
		if dani.puede_cargar():
			return "Recoger %d platillo(s)" % listos.size()
		return "Bandeja llena (%d/%d)" % [dani.bandeja.size(), GameState.capacidad_bandeja()]
	if _sobrantes(dani).size() > 0:
		return "Devolver platillos sin cliente"
	return "Pase de cocina" if tipo == Catalogo.COCINA else "Barra de bebidas"

func interactuar(dani: Node) -> void:
	super.interactuar(dani)
	if not listos.is_empty():
		var recogidos := 0
		# Primero lo que tiene cliente esperando.
		listos.sort_custom(func(a, b): return a["cliente"] != null and b["cliente"] == null)
		while not listos.is_empty() and dani.puede_cargar():
			var orden: Dictionary = listos.pop_front()
			dani.agregar_platillo(orden["platillo"])
			recogidos += 1
		if recogidos > 0:
			AudioManager.sfx("servir")
		else:
			AudioManager.sfx("error")
		_actualizar_vista()
		return
	var sobrantes := _sobrantes(dani)
	if not sobrantes.is_empty():
		for platillo in sobrantes:
			dani.quitar_platillo(platillo)
		GameState.registrar_estadistica("desperdicio", sobrantes.size())
		GameState.aviso.emit("Se desecharon %d platillo(s) sin cliente." % sobrantes.size())
		AudioManager.sfx("limpiar")

## Platillos en la bandeja que ya ningún cliente está esperando.
func _sobrantes(dani: Node) -> Array[String]:
	var esperados: Array[String] = []
	for c in get_tree().get_nodes_in_group("clientes"):
		if c.estado == Cliente.Estado.ESPERANDO_COMIDA:
			esperados.append(c.pedido)
	var sobrantes: Array[String] = []
	for platillo in dani.bandeja:
		if esperados.has(platillo):
			esperados.erase(platillo)
		else:
			sobrantes.append(platillo)
	return sobrantes
