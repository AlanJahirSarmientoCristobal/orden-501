extends Node

signal inventory_changed
signal reservations_changed
signal event_logged(message: String)
signal promotion_changed
signal panel_toggle_requested(section: String)

const SAVE_PATH := "user://orden501_management.json"
const INGREDIENT_LABELS := {
	"masa":"Masa", "queso":"Queso", "salsa":"Salsa",
	"papa":"Papa", "aceite":"Aceite", "jarabe":"Jarabe", "hielo":"Hielo"
}
const RECIPES := {
	"Pizza del Estadio":{"masa":2,"queso":2,"salsa":1},
	"Papas MVP":{"papa":2,"aceite":1},
	"Refresco de la Casa":{"jarabe":1,"hielo":1}
}

var management_mode := false
var difficulty := "normal"
var completed_level := 0
var current_level := 1
var inventory: Dictionary = {}
var reservations: Array[Dictionary] = []
var event_log: Array[String] = []
var stockout_events := 0
var reservation_errors := 0
var confirmed_reservations := 0
var promotions_used := 0
var active_promotion := ""
var promotion_time := 0.0
var restocks_in_transit: Dictionary = {}
var blocked_orders: Array[String] = []
var panel_open := false
var turn_start_coins := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.level_finished.connect(_on_level_finished)

func _process(delta: float) -> void:
	if not management_mode or get_tree().paused:
		return
	if promotion_time > 0.0:
		promotion_time = max(0.0, promotion_time - delta)
		if promotion_time <= 0.0:
			_log("La promoción terminó; el flujo de clientes volvió a la normalidad.")
			active_promotion = ""
			promotion_changed.emit()

func begin_campaign(selected_difficulty: String) -> void:
	management_mode = true
	difficulty = selected_difficulty if selected_difficulty in ["easy","normal","hard"] else "normal"
	completed_level = 0
	current_level = 1
	MissionManager.campaign_started = false
	MissionManager.difficulty = difficulty
	GameManager.reset_season()
	GameManager.coins = 120
	GameManager.coins_changed.emit(GameManager.coins)
	save_game()

func leave_management_mode() -> void:
	management_mode = false
	panel_open = false

func begin_turn(level_number: int) -> void:
	current_level = level_number
	panel_open = false
	turn_start_coins = GameManager.coins
	stockout_events = 0
	reservation_errors = 0
	confirmed_reservations = 0
	promotions_used = 0
	active_promotion = ""
	promotion_time = 0.0
	restocks_in_transit = {}
	blocked_orders = []
	event_log = []
	_setup_inventory()
	_setup_reservations()
	_log("Turno %d iniciado: %s" % [level_number, get_level_title(level_number)])

func _setup_inventory() -> void:
	var base = 8 if current_level == 1 else (7 if current_level == 2 else 6)
	var stock_multiplier = {"easy":1.35,"normal":1.0,"hard":0.75}.get(difficulty,1.0)
	inventory = {}
	for ingredient in INGREDIENT_LABELS:
		inventory[ingredient] = int(max(3, round(base * stock_multiplier)))
	inventory_changed.emit()

func _setup_reservations() -> void:
	reservations = []
	if current_level == 1:
		reservations.append(_reservation("R-101","18:00",2))
	elif current_level == 2:
		reservations = [
			_reservation("R-201","18:00",2), _reservation("R-202","18:00",4),
			_reservation("R-203","18:30",3), _reservation("R-204","19:00",2)
		]
	else:
		reservations = [
			_reservation("R-301","18:00",4), _reservation("R-302","18:00",2),
			_reservation("R-303","18:30",3), _reservation("R-304","18:30",4),
			_reservation("R-305","19:00",2), _reservation("R-306","19:30",4)
		]
	reservations_changed.emit()

func _reservation(id: String, time: String, party: int) -> Dictionary:
	return {"id":id,"time":time,"party":party,"table":0,"status":"pending"}

func can_prepare(dish_name: String) -> bool:
	var recipe: Dictionary = RECIPES.get(dish_name,{})
	for ingredient in recipe:
		if int(inventory.get(ingredient,0)) < int(recipe[ingredient]):
			return false
	return true

func consume_recipe(dish_name: String, order_id: String) -> bool:
	if not management_mode:
		return true
	if not can_prepare(dish_name):
		if not blocked_orders.has(order_id):
			blocked_orders.append(order_id)
			stockout_events += 1
			_log("QUIEBRE DE STOCK: no se puede preparar %s. Solicita al proveedor." % dish_name)
		return false
	for ingredient in RECIPES.get(dish_name,{}):
		inventory[ingredient] = int(inventory[ingredient]) - int(RECIPES[dish_name][ingredient])
	blocked_orders.erase(order_id)
	inventory_changed.emit()
	_check_low_stock()
	return true

func _check_low_stock() -> void:
	var low: Array[String] = []
	for ingredient in inventory:
		if int(inventory[ingredient]) <= 2:
			low.append(INGREDIENT_LABELS[ingredient])
	if not low.is_empty():
		_log("Stock bajo: " + ", ".join(low))

func request_restock(ingredient: String) -> bool:
	if not management_mode or restocks_in_transit.has(ingredient):
		return false
	var cost := 25
	if GameManager.coins < cost:
		_log("Fondos insuficientes para pedir %s." % INGREDIENT_LABELS.get(ingredient,ingredient))
		return false
	GameManager.coins -= cost
	GameManager.coins_changed.emit(GameManager.coins)
	restocks_in_transit[ingredient] = true
	_log("Proveedor en camino con %s..." % INGREDIENT_LABELS.get(ingredient,ingredient))
	var delay = {"easy":4.0,"normal":6.0,"hard":8.0}.get(difficulty,6.0)
	_deliver_restock(ingredient,delay)
	return true

func _deliver_restock(ingredient: String, delay: float) -> void:
	await get_tree().create_timer(delay,false).timeout
	if not management_mode:
		return
	inventory[ingredient] = int(inventory.get(ingredient,0)) + 7
	restocks_in_transit.erase(ingredient)
	inventory_changed.emit()
	_log("Proveedor: entrega de %s recibida (+7)." % INGREDIENT_LABELS.get(ingredient,ingredient))

func assign_reservation(reservation_id: String, table_number: int) -> bool:
	var selected: Dictionary = {}
	for reservation in reservations:
		if reservation["id"] == reservation_id:
			selected = reservation
			break
	if selected.is_empty() or selected["status"] == "seated":
		return false
	for reservation in reservations:
		if reservation["id"] != reservation_id and reservation["status"] in ["confirmed","seated"] and reservation["time"] == selected["time"] and int(reservation["table"]) == table_number:
			reservation_errors += 1
			GameManager.reputation = max(0.0,GameManager.reputation-10.0)
			GameManager.reputation_changed.emit(GameManager.reputation)
			_log("RESERVA DUPLICADA: Mesa %d ya está ocupada a las %s." % [table_number,selected["time"]])
			return false
	selected["table"] = table_number
	if selected["status"] != "confirmed":
		confirmed_reservations += 1
	selected["status"] = "confirmed"
	reservations_changed.emit()
	_log("%s confirmada: %s, Mesa %d." % [reservation_id,selected["time"],table_number])
	return true

func consume_reservation_for_table(table_number: int) -> bool:
	if not management_mode:
		return false
	for reservation in reservations:
		if reservation["status"] == "confirmed" and int(reservation["table"]) == table_number:
			reservation["status"] = "seated"
			reservations_changed.emit()
			_log("Llegó %s y ocupó la Mesa %d." % [reservation["id"],table_number])
			return true
	return false

func activate_promotion(promotion_id: String) -> bool:
	if current_level < 3:
		_log("Las promociones se desbloquean en el Turno 3.")
		return false
	var costs = {"social":40,"combo":60}
	var cost: int = costs.get(promotion_id,40)
	if GameManager.coins < cost:
		_log("No hay fondos suficientes para activar la promoción.")
		return false
	GameManager.coins -= cost
	GameManager.coins_changed.emit(GameManager.coins)
	active_promotion = promotion_id
	promotion_time = 35.0
	promotions_used += 1
	promotion_changed.emit()
	_log("Promoción activada por 35 segundos: %s." % ("Campaña en redes" if promotion_id == "social" else "Combo 501"))
	return true

func get_customer_delay_multiplier() -> float:
	return 0.55 if promotion_time > 0.0 else 1.0

func request_panel(section: String = "management") -> void:
	panel_toggle_requested.emit(section)

func get_required_reservations() -> int:
	if current_level == 1:
		return 0
	var base = 3 if current_level == 2 else 4
	return base + (1 if difficulty == "hard" else (-1 if difficulty == "easy" else 0))

func get_failure_reason() -> String:
	if not management_mode:
		return ""
	if current_level == 1 and stockout_events > 0:
		return "Hubo %d quiebre(s) de stock. Debías anticipar el inventario." % stockout_events
	if current_level == 2:
		if reservation_errors > 0:
			return "Se detectaron %d reservaciones duplicadas." % reservation_errors
		if confirmed_reservations < get_required_reservations():
			return "Confirmaste %d de %d reservaciones requeridas." % [confirmed_reservations,get_required_reservations()]
	if current_level == 3 and promotions_used < 1:
		return "Debías activar al menos una promoción durante la temporada baja."
	return ""

func get_level_title(level_number: int) -> String:
	return {1:"Orden en la casa",2:"Reservas sin fallas",3:"Temporada baja, ventas altas"}.get(level_number,"Turno")

func get_report_text() -> String:
	var pending := 0
	for reservation in reservations:
		if reservation["status"] == "pending":
			pending += 1
	return "REPORTE DEL TURNO\nVentas: $%d / $%d\nPedidos entregados: %d\nReputación: %d%%\nQuiebres de stock: %d\nReservas confirmadas: %d\nReservas pendientes: %d\nErrores de duplicidad: %d\nPromociones utilizadas: %d" % [GameManager.level_earnings,GameManager.current_target_coins,GameManager.orders_delivered_count,int(GameManager.reputation),stockout_events,confirmed_reservations,pending,reservation_errors,promotions_used]

func get_inventory_summary() -> String:
	var lines: Array[String] = []
	for ingredient in INGREDIENT_LABELS:
		var amount = int(inventory.get(ingredient,0))
		lines.append("%s: %d%s" % [INGREDIENT_LABELS[ingredient],amount,"  BAJO" if amount <= 2 else ""])
	return "\n".join(lines)

func get_reservation_summary() -> String:
	var lines: Array[String] = []
	for reservation in reservations:
		lines.append("%s %s · %s" % [reservation["time"],reservation["id"],str(reservation["status"]).to_upper()])
	return "\n".join(lines)

func _log(message: String) -> void:
	event_log.push_front(message)
	if event_log.size() > 12:
		event_log.resize(12)
	event_logged.emit(message)

func _on_level_finished(success: bool, _coins_gained: int) -> void:
	if not management_mode:
		return
	if success:
		completed_level = max(completed_level,current_level)
		save_game()
	else:
		GameManager.coins = turn_start_coins
		GameManager.coins_changed.emit(GameManager.coins)

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_game() -> void:
	var data = {"completed_level":completed_level,"difficulty":difficulty,"coins":GameManager.coins,"speed":GameManager.upgrade_speed_level,"tray":GameManager.upgrade_inventory_capacity,"chef":GameManager.upgrade_chef_speed_multiplier,"scanner":GameManager.upgrade_datapad_cooldown}
	var file = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	file.store_string(JSON.stringify(data,"\t"))

func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if not data is Dictionary:
		return false
	management_mode = true
	completed_level = int(data.get("completed_level",0))
	difficulty = str(data.get("difficulty","normal"))
	MissionManager.campaign_started = false
	MissionManager.difficulty = difficulty
	GameManager.reset_season()
	GameManager.coins = int(data.get("coins",120))
	GameManager.upgrade_speed_level = int(data.get("speed",0))
	GameManager.upgrade_inventory_capacity = int(data.get("tray",3))
	GameManager.upgrade_chef_speed_multiplier = float(data.get("chef",1.0))
	GameManager.upgrade_datapad_cooldown = float(data.get("scanner",20.0))
	GameManager.coins_changed.emit(GameManager.coins)
	return true
