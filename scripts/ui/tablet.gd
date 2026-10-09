extends PanelModal
class_name Tablet

const SECCIONES := {"stock": "Stock", "cocina": "Cocina", "reservaciones": "Reservaciones", "avisos": "Avisos del partido"}

var seccion := "avisos"
var proveedor_cocina: Callable
var notificaciones: Notificaciones

func _ready() -> void:
	GameState.inventario_cambiado.connect(refrescar)
	GameState.reservaciones_cambiadas.connect(refrescar)

func abrir_seccion(nueva: String) -> void:
	seccion = nueva
	abrir("TABLET DE GESTIÓN")

func _unhandled_input(evento: InputEvent) -> void:
	if esta_abierto() and evento.is_action_pressed("tablet"):
		get_viewport().set_input_as_handled()
		cerrar()
		return
	super._unhandled_input(evento)

func construir() -> void:
	UIKit.limpiar(contenido)
	var pestanas := UIKit.hbox(6)
	for clave in SECCIONES:
		if clave == "cocina" and not proveedor_cocina.is_valid():
			continue
		var b := UIKit.boton(SECCIONES[clave], _cambiar_seccion.bind(clave), 14)
		if clave == seccion:
			b.add_theme_color_override("font_color", UIKit.ACENTO)
		pestanas.add_child(b)
	contenido.add_child(pestanas)
	contenido.add_child(HSeparator.new())
	match seccion:
		"stock":
			_construir_stock(contenido)
		"cocina":
			_construir_cocina()
		"reservaciones":
			_construir_reservaciones()
		_:
			_construir_avisos()

func _cambiar_seccion(nueva: String) -> void:
	seccion = nueva
	construir()

static func llenar_stock(destino: VBoxContainer) -> void:
	var inv := GameState.inventario
	destino.add_child(UIKit.etiqueta("Almacén: %d / %d espacios · Día %d" % [inv.total_unidades(), GameState.capacidad_almacen(), GameState.dia], 16, UIKit.AZUL))
	for insumo in Catalogo.INSUMOS:
		var fila := UIKit.hbox(10)
		fila.add_child(UIKit.icono(Catalogo.INSUMOS[insumo]["icono"], 28))
		var cantidad := inv.total(insumo)
		var color := UIKit.ROJO if cantidad <= 2 else UIKit.TEXTO
		var nombre := UIKit.etiqueta("%s: %d" % [Catalogo.nombre_insumo(insumo), cantidad], 16, color)
		nombre.custom_minimum_size.x = 200
		fila.add_child(nombre)
		var restantes := inv.dias_restantes(insumo, GameState.dia, GameState.config.dias_caducidad)
		var texto_caducidad := "No caduca"
		if restantes == 0:
			texto_caducidad = "¡Caduca hoy al cerrar!"
		elif restantes > 0:
			texto_caducidad = "Caduca en %d día(s)" % restantes
		elif bool(Catalogo.INSUMOS[insumo]["perecedero"]):
			texto_caducidad = "Perecedero"
		fila.add_child(UIKit.etiqueta(texto_caducidad, 14, UIKit.ROJO if restantes == 0 else UIKit.TEXTO_TENUE))
		destino.add_child(fila)
	destino.add_child(HSeparator.new())
	destino.add_child(UIKit.etiqueta("Platillos que se pueden preparar ahora:", 15, UIKit.ACENTO))
	for platillo in Catalogo.PLATILLOS:
		var ok := inv.puede_preparar(platillo)
		destino.add_child(UIKit.etiqueta("%s %s — %s" % ["✔" if ok else "✘", platillo, _texto_receta(platillo)], 14, UIKit.VERDE if ok else UIKit.ROJO))

static func _texto_receta(platillo: String) -> String:
	var partes := []
	var receta := Catalogo.receta(platillo)
	for insumo in receta:
		partes.append("%d %s" % [receta[insumo], Catalogo.nombre_insumo(insumo)])
	return ", ".join(partes)

func _construir_stock(destino: VBoxContainer) -> void:
	llenar_stock(destino)

func _construir_cocina() -> void:
	var cola: Array = proveedor_cocina.call() if proveedor_cocina.is_valid() else []
	if cola.is_empty():
		contenido.add_child(UIKit.etiqueta("La cocina está libre.", 16, UIKit.TEXTO_TENUE))
	for linea in cola:
		contenido.add_child(UIKit.etiqueta(str(linea), 16))

func _construir_reservaciones() -> void:
	if GameState.reservaciones.is_empty():
		contenido.add_child(UIKit.etiqueta("Hoy no hay reservaciones (se agregan a partir de la Liguilla).", 16, UIKit.TEXTO_TENUE))
		return
	contenido.add_child(UIKit.etiqueta("Asigna una mesa a cada reservación. No repitas mesa en el mismo horario.\nMesas 1-3: 2 personas · Mesas 4-%d: 4 personas." % GameState.numero_mesas(), 14, UIKit.TEXTO_TENUE))
	for reserva in GameState.reservaciones:
		var fila := UIKit.hbox(8)
		var texto := UIKit.etiqueta("%s · %d' · %s (%d pers.)" % [reserva["id"], reserva["minuto"], reserva["nombre"], reserva["personas"]], 15)
		texto.custom_minimum_size.x = 340
		fila.add_child(texto)
		var estado: String = reserva["estado"]
		if estado in ["llego", "atendida"]:
			fila.add_child(UIKit.etiqueta("Mesa %d · %s" % [reserva["mesa"], "Llegó" if estado == "llego" else "Atendida"], 15, UIKit.VERDE))
		else:
			var selector := OptionButton.new()
			selector.add_theme_font_size_override("font_size", 14)
			for mesa in range(1, GameState.numero_mesas() + 1):
				selector.add_item("Mesa %d (%d)" % [mesa, GameState.capacidad_mesa(mesa)], mesa)
			if int(reserva["mesa"]) > 0:
				selector.select(int(reserva["mesa"]) - 1)
			fila.add_child(selector)
			var id: String = reserva["id"]
			fila.add_child(UIKit.boton("Asignar", func(): _asignar(id, selector.get_selected_id()), 14))
			if estado == "asignada":
				fila.add_child(UIKit.etiqueta("✔ Mesa %d" % reserva["mesa"], 14, UIKit.VERDE))
		contenido.add_child(fila)

func _asignar(id: String, mesa: int) -> void:
	var resultado := GameState.asignar_reservacion(id, mesa)
	if resultado == "ok":
		AudioManager.sfx("pedido")
	refrescar()

func _construir_avisos() -> void:
	var info := GameState.info_nivel()
	contenido.add_child(UIKit.etiqueta("Nivel %d · %s · Día %d" % [GameState.nivel_actual, info["nombre"], GameState.dia], 18, UIKit.ACENTO))
	contenido.add_child(UIKit.etiqueta("Partido de hoy: %s" % info["partido"], 16))
	var avisos := ["Medio tiempo (45'): llega una ola de aficionados y se piden muchas bebidas. Ten refresco, cerveza y hielo."]
	avisos.append("Cada gol provoca una ronda extra de bebidas en las mesas ocupadas.")
	if GameState.nivel_actual >= 2:
		avisos.append("Hoy hay %d reservaciones y llegan clientes VIP que piden el Combo VIP." % GameState.reservaciones.size())
	if GameState.nivel_actual == 3:
		avisos.append("Gran Final: olas grandes de clientes y las mesas se ensucian más rápido.")
	if GameState.promo_activa or int(GameState.mejoras["promo"]) > 0:
		avisos.append("Promoción 2x1 activa: llegarán más clientes de lo normal.")
	for aviso in avisos:
		var etiqueta := UIKit.etiqueta("• " + aviso, 15)
		etiqueta.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		etiqueta.custom_minimum_size.x = 640
		contenido.add_child(etiqueta)
	contenido.add_child(HSeparator.new())
	contenido.add_child(UIKit.etiqueta("Objetivo: " + info["objetivo"], 15, UIKit.VERDE))
	if notificaciones and not notificaciones.historial.is_empty():
		contenido.add_child(HSeparator.new())
		contenido.add_child(UIKit.etiqueta("Últimos avisos:", 15, UIKit.ACENTO))
		for linea in notificaciones.historial:
			contenido.add_child(UIKit.etiqueta("· " + linea, 13, UIKit.TEXTO_TENUE))
