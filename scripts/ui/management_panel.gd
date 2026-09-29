extends CanvasLayer

var overlay: ColorRect
var content: VBoxContainer
var mini_label: Label
var event_banner: Label
var refresh_timer := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not BusinessManager.management_mode:
		queue_free()
		return
	_build_interface()
	BusinessManager.inventory_changed.connect(_refresh)
	BusinessManager.reservations_changed.connect(_refresh)
	BusinessManager.promotion_changed.connect(_refresh)
	BusinessManager.event_logged.connect(_on_event_logged)
	BusinessManager.panel_toggle_requested.connect(_toggle_panel)
	_refresh()

func _process(delta: float) -> void:
	refresh_timer += delta
	if refresh_timer >= 0.25:
		refresh_timer = 0.0
		_update_mini_panel()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("report"):
		_toggle_panel("report")
		get_viewport().set_input_as_handled()

func _build_interface() -> void:
	var mini = PanelContainer.new()
	mini.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mini.position = Vector2(-300,74)
	mini.size = Vector2(284,245)
	add_child(mini)
	var mini_margin = MarginContainer.new()
	mini_margin.add_theme_constant_override("margin_left",12)
	mini_margin.add_theme_constant_override("margin_top",10)
	mini_margin.add_theme_constant_override("margin_right",12)
	mini_margin.add_theme_constant_override("margin_bottom",10)
	mini.add_child(mini_margin)
	mini_label = Label.new()
	mini_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mini_label.add_theme_font_size_override("font_size",12)
	mini_margin.add_child(mini_label)

	event_banner = Label.new()
	event_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	event_banner.position = Vector2(-330,65)
	event_banner.size = Vector2(660,42)
	event_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	event_banner.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	event_banner.add_theme_color_override("font_color",Color(1.0,0.82,0.25))
	event_banner.add_theme_color_override("font_outline_color",Color(0.03,0.04,0.06))
	event_banner.add_theme_constant_override("outline_size",6)
	event_banner.visible = false
	add_child(event_banner)

	overlay = ColorRect.new()
	overlay.color = Color(0.025,0.035,0.05,0.93)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.visible = false
	add_child(overlay)
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-555,-300)
	panel.size = Vector2(1110,600)
	overlay.add_child(panel)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left",20)
	margin.add_theme_constant_override("margin_top",16)
	margin.add_theme_constant_override("margin_right",20)
	margin.add_theme_constant_override("margin_bottom",16)
	panel.add_child(margin)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",10)
	margin.add_child(content)

func _refresh() -> void:
	if not is_instance_valid(content):
		return
	for child in content.get_children():
		child.queue_free()
	var header = HBoxContainer.new()
	content.add_child(header)
	var title = Label.new()
	title.text = "ORDEN 501 · PANEL DE GESTIÓN"
	title.add_theme_font_size_override("font_size",22)
	title.add_theme_color_override("font_color",Color(1.0,0.78,0.25))
	header.add_child(title)
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close = Button.new()
	close.text = "Cerrar [E]"
	close.pressed.connect(_toggle_panel.bind("management"))
	header.add_child(close)

	var objective = Label.new()
	objective.text = "%s  |  %s  |  %s" % [BusinessManager.get_level_title(BusinessManager.current_level),_objective_text(),BusinessManager.difficulty.to_upper()]
	objective.add_theme_color_override("font_color",Color(0.55,0.9,1.0))
	content.add_child(objective)
	content.add_child(HSeparator.new())
	var columns = HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("separation",18)
	content.add_child(columns)
	_build_inventory_column(columns)
	_build_reservations_column(columns)
	_build_operations_column(columns)
	_update_mini_panel()

func _build_inventory_column(parent: HBoxContainer) -> void:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(300,0)
	box.add_theme_constant_override("separation",7)
	parent.add_child(box)
	var heading = Label.new()
	heading.text = "INVENTARIO / PROVEEDOR"
	heading.add_theme_font_size_override("font_size",16)
	box.add_child(heading)
	for ingredient in BusinessManager.INGREDIENT_LABELS:
		var row = HBoxContainer.new()
		box.add_child(row)
		var amount = int(BusinessManager.inventory.get(ingredient,0))
		var label = Label.new()
		label.text = "%s: %d%s" % [BusinessManager.INGREDIENT_LABELS[ingredient],amount,"  ¡BAJO!" if amount <= 2 else ""]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color",Color(1.0,0.38,0.3) if amount <= 2 else Color(0.78,0.95,0.78))
		row.add_child(label)
		var button = Button.new()
		button.text = "En camino" if BusinessManager.restocks_in_transit.has(ingredient) else "Pedir $25"
		button.disabled = BusinessManager.restocks_in_transit.has(ingredient)
		button.pressed.connect(_request_restock.bind(ingredient))
		row.add_child(button)
	var recipe_help = Label.new()
	recipe_help.text = "RECETAS\nPizza: 2 masa, 2 queso, 1 salsa\nPapas: 2 papa, 1 aceite\nRefresco: 1 jarabe, 1 hielo"
	recipe_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_help.add_theme_color_override("font_color",Color(0.7,0.78,0.86))
	box.add_child(recipe_help)

func _build_reservations_column(parent: HBoxContainer) -> void:
	var box = VBoxContainer.new()
	box.custom_minimum_size = Vector2(390,0)
	box.add_theme_constant_override("separation",7)
	parent.add_child(box)
	var heading = Label.new()
	heading.text = "CALENDARIO DE RESERVACIONES"
	heading.add_theme_font_size_override("font_size",16)
	box.add_child(heading)
	for index in range(BusinessManager.reservations.size()):
		var reservation: Dictionary = BusinessManager.reservations[index]
		var row = HBoxContainer.new()
		box.add_child(row)
		var label = Label.new()
		label.text = "%s · %s · %d pers." % [reservation["time"],reservation["id"],reservation["party"]]
		label.custom_minimum_size = Vector2(190,0)
		row.add_child(label)
		if reservation["status"] == "pending":
			var option = OptionButton.new()
			var table_count = 4 if BusinessManager.current_level == 1 else 6
			for table_number in range(1,table_count+1):
				option.add_item("Mesa %d" % table_number,table_number)
			option.select(index % table_count)
			row.add_child(option)
			var confirm = Button.new()
			confirm.text = "Confirmar"
			confirm.pressed.connect(_confirm_reservation.bind(str(reservation["id"]),option))
			row.add_child(confirm)
		else:
			var status = Label.new()
			status.text = "Mesa %d · %s" % [reservation["table"],str(reservation["status"]).to_upper()]
			status.add_theme_color_override("font_color",Color(0.35,1.0,0.55))
			row.add_child(status)
	var warning = Label.new()
	warning.text = "No asignes la misma mesa a dos grupos en el mismo horario."
	warning.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning.add_theme_color_override("font_color",Color(1.0,0.68,0.35))
	box.add_child(warning)

func _build_operations_column(parent: HBoxContainer) -> void:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation",8)
	parent.add_child(box)
	var heading = Label.new()
	heading.text = "PROMOCIONES Y REPORTE"
	heading.add_theme_font_size_override("font_size",16)
	box.add_child(heading)
	var social = Button.new()
	social.text = "Campaña en redes · $40"
	social.disabled = BusinessManager.current_level < 3
	social.pressed.connect(_activate_promotion.bind("social"))
	box.add_child(social)
	var combo = Button.new()
	combo.text = "Combo 501 · $60"
	combo.disabled = BusinessManager.current_level < 3
	combo.pressed.connect(_activate_promotion.bind("combo"))
	box.add_child(combo)
	var active = Label.new()
	active.text = "Promoción: %s%s" % [BusinessManager.active_promotion if BusinessManager.active_promotion != "" else "ninguna"," (%.0fs)" % BusinessManager.promotion_time if BusinessManager.promotion_time > 0 else ""]
	active.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(active)
	box.add_child(HSeparator.new())
	var report = Label.new()
	report.text = BusinessManager.get_report_text()
	report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	report.add_theme_font_size_override("font_size",12)
	box.add_child(report)
	box.add_child(HSeparator.new())
	var log_label = Label.new()
	log_label.text = "EVENTOS RECIENTES\n" + ("\n".join(BusinessManager.event_log.slice(0,5)) if not BusinessManager.event_log.is_empty() else "Sin incidencias")
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_label.add_theme_color_override("font_color",Color(0.78,0.84,0.92))
	box.add_child(log_label)

func _objective_text() -> String:
	match BusinessManager.current_level:
		1: return "Evita quiebres de stock"
		2: return "Confirma %d reservas sin duplicar" % BusinessManager.get_required_reservations()
		3: return "Activa promociones y alcanza la meta de ventas"
	return "Organiza el restaurante"

func _update_mini_panel() -> void:
	if not is_instance_valid(mini_label):
		return
	var low: Array[String] = []
	for ingredient in BusinessManager.inventory:
		if int(BusinessManager.inventory[ingredient]) <= 2:
			low.append(BusinessManager.INGREDIENT_LABELS[ingredient])
	mini_label.text = "PANEL DE GESTIÓN [E]\n%s\n\nReservas: %d confirmadas / %d errores\nStock bajo: %s\nPromoción: %s\n\n[TAB] Reporte completo" % [_objective_text(),BusinessManager.confirmed_reservations,BusinessManager.reservation_errors,", ".join(low) if not low.is_empty() else "ninguno",BusinessManager.active_promotion if BusinessManager.active_promotion != "" else "ninguna"]

func _toggle_panel(_section: String = "management") -> void:
	overlay.visible = not overlay.visible
	BusinessManager.panel_open = overlay.visible
	if overlay.visible:
		_refresh()

func _request_restock(ingredient: String) -> void:
	BusinessManager.request_restock(ingredient)
	_refresh()

func _confirm_reservation(reservation_id: String, option: OptionButton) -> void:
	BusinessManager.assign_reservation(reservation_id,option.get_selected_id())
	_refresh()

func _activate_promotion(promotion_id: String) -> void:
	BusinessManager.activate_promotion(promotion_id)
	_refresh()

func _on_event_logged(message: String) -> void:
	_update_mini_panel()
	event_banner.text = message
	event_banner.modulate.a = 1.0
	event_banner.visible = true
	var version = Time.get_ticks_msec()
	event_banner.set_meta("version",version)
	await get_tree().create_timer(3.0,true).timeout
	if event_banner.get_meta("version",0) != version:
		return
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(event_banner,"modulate:a",0.0,0.25)
	await tween.finished
	event_banner.visible = false
