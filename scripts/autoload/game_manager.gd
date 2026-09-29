extends Node

signal coins_changed(total_coins: int)
signal reputation_changed(reputation_percentage: float)
signal datapad_activated(forecasts: Dictionary)
signal datapad_cooldown_updated(remaining: float, total: float)
signal order_completed(dish_name: String, payout: int)
signal customer_walkout(table_num: int)
signal match_announcement(title: String, subtitle: String)
signal level_finished(success: bool, coins_gained: int)

# Nuevo menu del Restaurante Deportivo La 501
const DISH_PIZZA = "Pizza del Estadio"
const DISH_FRIES = "Papas MVP"
const DISH_SODA = "Refresco de la Casa"

const DISH_ICONS = {
	DISH_PIZZA: "🍕",
	DISH_FRIES: "🍟",
	DISH_SODA: "🥤"
}

const DISH_PRICES = {
	DISH_PIZZA: 55,
	DISH_FRIES: 35,
	DISH_SODA: 25
}

# Economía y progresión
var coins: int = 0
var reputation: float = 100.0
var campaign_reputation: int = 0
var max_reputation: float = 100.0
var lost_customers_count: int = 0
var orders_delivered_count: int = 0
var season_orders_delivered: int = 0
var level_earnings: int = 0

# Mejoras (Tienda)
var upgrade_speed_level: int = 0       # +30% velocidad por nivel
var upgrade_inventory_capacity: int = 3 # Base 3, max 4
var upgrade_chef_speed_multiplier: float = 1.0 # Reducción de tiempo
var upgrade_datapad_cooldown: float = 20.0     # Base 20s, upgrade 15s

# Estado del nivel actual
var current_level: int = 1
var is_game_active: bool = false
var match_timer: float = 90.0
var max_match_time: float = 90.0
var is_halftime_triggered: bool = false
var current_target_coins: int = 0

# Recarga del escáner de demanda
var datapad_timer: float = 0.0
var is_datapad_ready: bool = true

var transition_rect: ColorRect
var return_to_hub_after_level: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_transition_layer()
	_setup_input_actions()

func _setup_input_actions() -> void:
	var bindings = {
		"move_left": [KEY_A, KEY_LEFT],
		"move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP],
		"move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_SPACE, KEY_ENTER],
		"datapad": [KEY_E],
		"discard_dish": [KEY_Q],
		"report": [KEY_TAB],
		"pause": [KEY_ESCAPE]
	}
	
	for act in bindings:
		if not InputMap.has_action(act):
			InputMap.add_action(act)
		for key in bindings[act]:
			var ev = InputEventKey.new()
			ev.physical_keycode = key
			if not InputMap.action_has_event(act, ev):
				InputMap.action_add_event(act, ev)

func _setup_transition_layer() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)
	
	transition_rect = ColorRect.new()
	transition_rect.color = Color(0, 0, 0, 0)
	transition_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	transition_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(transition_rect)

func _process(delta: float) -> void:
	if is_game_active:
		# Reloj del partido
		match_timer -= delta
		if match_timer <= (max_match_time / 2.0) and not is_halftime_triggered:
			is_halftime_triggered = true
			trigger_halftime_rush()
		
		if match_timer <= 0.0:
			match_timer = 0.0
			_check_level_end()
		
		# Recarga de la habilidad de escaneo
		if not is_datapad_ready:
			datapad_timer -= delta
			datapad_cooldown_updated.emit(max(0.0, datapad_timer), upgrade_datapad_cooldown)
			if datapad_timer <= 0.0:
				is_datapad_ready = true
				datapad_timer = 0.0
				AudioManager.play_sfx_bell()

func start_level(level_num: int) -> void:
	current_level = level_num
	is_game_active = true
	is_halftime_triggered = false
	lost_customers_count = 0
	orders_delivered_count = 0
	level_earnings = 0
	reputation = 100.0
	is_datapad_ready = true
	datapad_timer = 0.0
	
	match level_num:
		1:
			max_match_time = 75.0
			current_target_coins = 220
		2:
			max_match_time = 90.0
			current_target_coins = 420
		3:
			max_match_time = 105.0
			current_target_coins = 650
	if MissionManager.campaign_started:
		max_match_time *= MissionManager.get_restaurant_time_multiplier()
		current_target_coins = int(round(float(current_target_coins) * MissionManager.get_restaurant_target_multiplier()))
	if BusinessManager.management_mode:
		max_match_time = {1:150.0,2:180.0,3:210.0}.get(level_num,150.0)
		current_target_coins = {1:300,2:520,3:760}.get(level_num,300)
		var time_multiplier = {"easy":1.2,"normal":1.0,"hard":0.85}.get(BusinessManager.difficulty,1.0)
		var target_multiplier = {"easy":0.82,"normal":1.0,"hard":1.2}.get(BusinessManager.difficulty,1.0)
		max_match_time *= time_multiplier
		current_target_coins = int(round(current_target_coins * target_multiplier))
	
	match_timer = max_match_time
	AudioManager.play_sfx_whistle()
	reputation_changed.emit(reputation)
	coins_changed.emit(coins)

func activate_datapad(predictions: Dictionary) -> bool:
	if not is_datapad_ready or not is_game_active:
		return false
	
	is_datapad_ready = false
	datapad_timer = upgrade_datapad_cooldown
	AudioManager.play_sfx_datapad()
	datapad_activated.emit(predictions)
	match_announcement.emit("ESCÁNER DE DEMANDA ACTIVADO", "Las mesas indecisas enviaron su comanda automáticamente")
	return true

func add_order_success(dish_name: String, is_vip: bool = false) -> void:
	var base_price = DISH_PRICES.get(dish_name, 35)
	var payout = base_price * (2 if is_vip else 1) + (20 if is_vip else 5) # Propina
	
	coins += payout
	level_earnings += payout
	orders_delivered_count += 1
	season_orders_delivered += 1
	reputation = min(100.0, reputation + (3.0 if is_vip else 1.5))
	
	coins_changed.emit(coins)
	reputation_changed.emit(reputation)
	order_completed.emit(dish_name, payout)
	AudioManager.play_sfx_register()

func record_lost_customer(table_num: int, is_vip: bool = false) -> void:
	lost_customers_count += 1
	var penalty = 25.0 if is_vip else 15.0
	reputation = max(0.0, reputation - penalty)
	
	customer_walkout.emit(table_num)
	reputation_changed.emit(reputation)
	AudioManager.play_sfx_lost_customer()
	
	if reputation <= 0.0:
		_fail_game("La reputación de La 501 cayó a 0%. Los clientes cancelaron sus visitas.")

func trigger_halftime_rush() -> void:
	AudioManager.play_sfx_whistle()
	if BusinessManager.management_mode:
		match_announcement.emit("PICO DE DEMANDA", "Revisa inventario, reservas y pedidos antes de que se acumulen")
	else:
		match_announcement.emit("⚽ ¡MEDIO TIEMPO - PICO DE DEMANDA!", "¡Llegada masiva de hinchas hambrientos! Usa tu escáner")

func _check_level_end() -> void:
	is_game_active = false
	var minimum_reputation = 70.0 if BusinessManager.management_mode else (40.0 if current_level == 1 else (50.0 if current_level == 2 else 55.0))
	var success = level_earnings >= current_target_coins and reputation >= minimum_reputation
	var reason = ""
	var management_failure = BusinessManager.get_failure_reason()
	if management_failure != "":
		success = false
		reason = management_failure
	
	if reason != "":
		pass
	elif reputation < minimum_reputation:
		reason = "La reputación terminó en %d%%; necesitabas al menos %d%%." % [int(reputation), int(minimum_reputation)]
	elif level_earnings < current_target_coins:
		reason = "Recaudaste $%d de la meta de $%d de esta jornada." % [level_earnings, current_target_coins]
	
	if success:
		AudioManager.play_sfx_upgrade()
		level_finished.emit(true, level_earnings)
	else:
		_fail_game(reason)

func _fail_game(reason: String) -> void:
	is_game_active = false
	level_finished.emit(false, 0)
	match_announcement.emit("TURNO NO SUPERADO" if BusinessManager.management_mode else "FIN DEL PARTIDO - JORNADA NO SUPERADA", reason)

# Compras en la Tienda
func buy_upgrade(upgrade_type: String, cost: int) -> bool:
	if coins < cost:
		return false
	
	coins -= cost
	coins_changed.emit(coins)
	AudioManager.play_sfx_upgrade()
	
	match upgrade_type:
		"speed":
			upgrade_speed_level += 1
		"tray":
			upgrade_inventory_capacity = 4
		"chef":
			upgrade_chef_speed_multiplier = 0.65
		"datapad":
			upgrade_datapad_cooldown = 15.0
	return true

func reset_season() -> void:
	coins = 0
	reputation = 100.0
	campaign_reputation = 0
	lost_customers_count = 0
	orders_delivered_count = 0
	season_orders_delivered = 0
	level_earnings = 0
	current_level = 1
	is_game_active = false
	upgrade_speed_level = 0
	upgrade_inventory_capacity = 3
	upgrade_chef_speed_multiplier = 1.0
	upgrade_datapad_cooldown = 20.0
	is_datapad_ready = true
	datapad_timer = 0.0
	return_to_hub_after_level = false
	coins_changed.emit(coins)
	reputation_changed.emit(reputation)

func change_scene_smooth(scene_path: String) -> void:
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(transition_rect, "color", Color(0, 0, 0, 1), 0.3)
	await tween.finished
	
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	
	var tween_in = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(transition_rect, "color", Color(0, 0, 0, 0), 0.3)
