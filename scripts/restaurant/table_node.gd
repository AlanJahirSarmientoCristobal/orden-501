extends Node2D
class_name TableNode

enum TableState {
	EMPTY,
	DECIDING,
	WAITING_FOOD,
	EATING,
	DIRTY
}

enum CustomerType {
	COMMON,
	VIP
}

@export var table_number: int = 1
@export var vip_chance: float = 0.25

var state: TableState = TableState.EMPTY
var customer_type: CustomerType = CustomerType.COMMON

var current_order: String = ""
var predicted_order: String = ""
var max_patience: float = 45.0
var current_patience: float = 45.0
var eating_timer: float = 4.0
var order_sent := false
var reserved_customer := false

@onready var table_label: Label = $Visuals/TableLabel
@onready var customer_common: Sprite2D = $Visuals/CustomerSpriteCommon
@onready var customer_vip: Sprite2D = $Visuals/CustomerSpriteVIP
@onready var customer_badge: Label = $Visuals/Badge
@onready var dirty_dishes_visual: Node2D = $Visuals/DirtyDishes
@onready var patience_bar: ProgressBar = $UI/PatienceBar
@onready var bubble_panel: PanelContainer = $UI/OrderBubble
@onready var bubble_icon: TextureRect = $UI/OrderBubble/Margin/HBox/Icon
@onready var bubble_text: Label = $UI/OrderBubble/Margin/HBox/Text
@onready var datapad_forecast_card: PanelContainer = $UI/DatapadCard
@onready var datapad_text: Label = $UI/DatapadCard/Margin/Label

const DISH_TEXTURES = {
	GameManager.DISH_PIZZA: "res://Assets/sprites/food_kit/Previews/pizza.png",
	GameManager.DISH_FRIES: "res://Assets/sprites/food_kit/Previews/fries.png",
	GameManager.DISH_SODA: "res://Assets/sprites/food_kit/Previews/soda-glass.png"
}

func _ready() -> void:
	add_to_group("tables")
	table_label.text = "MESA %d" % table_number
	dirty_dishes_visual.visible = false
	bubble_panel.visible = false
	patience_bar.visible = false
	datapad_forecast_card.visible = false
	customer_common.visible = false
	customer_vip.visible = false
	customer_badge.visible = false
	
	GameManager.datapad_activated.connect(_on_datapad_activated)
	_spawn_customer_timer(randf_range(1.5, 5.0))

func _process(delta: float) -> void:
	match state:
		TableState.DECIDING, TableState.WAITING_FOOD:
			current_patience -= delta
			patience_bar.value = current_patience
			
			if current_patience <= max_patience * 0.3:
				patience_bar.modulate = Color(1.0, 0.2, 0.2, 1.0)
			elif current_patience <= max_patience * 0.6:
				patience_bar.modulate = Color(1.0, 0.85, 0.2, 1.0)
			else:
				patience_bar.modulate = Color(0.2, 0.9, 0.3, 1.0)
			
			if current_patience <= 0.0:
				_customer_leaves_angry()
				
		TableState.EATING:
			eating_timer -= delta
			if eating_timer <= 0.0:
				_finish_eating()

func _spawn_customer_timer(delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if state == TableState.EMPTY and GameManager.is_game_active:
		_spawn_customer()

func _spawn_customer() -> void:
	order_sent = false
	reserved_customer = BusinessManager.consume_reservation_for_table(table_number) if BusinessManager.management_mode else false
	var adjusted_vip_chance = vip_chance
	if GameManager.current_level == 2:
		adjusted_vip_chance = 0.45
	elif GameManager.current_level == 3:
		adjusted_vip_chance = 0.65
	
	if reserved_customer or randf() < adjusted_vip_chance:
		customer_type = CustomerType.VIP
		customer_common.visible = false
		customer_vip.visible = true
		customer_badge.text = "RESERVACIÓN" if reserved_customer else "⭐ VIP"
		customer_badge.modulate = Color(1, 0.85, 0.2, 1)
		max_patience = 24.0
	else:
		customer_type = CustomerType.COMMON
		customer_common.visible = true
		customer_vip.visible = false
		customer_badge.text = "Aficionado"
		customer_badge.modulate = Color(0.9, 0.9, 0.9, 1)
		max_patience = 45.0
	if MissionManager.campaign_started:
		max_patience *= MissionManager.get_patience_multiplier()
	
	current_patience = max_patience
	patience_bar.max_value = max_patience
	patience_bar.value = current_patience
	patience_bar.visible = true
	customer_badge.visible = true
	
	var menu = [GameManager.DISH_PIZZA, GameManager.DISH_FRIES, GameManager.DISH_SODA]
	current_order = menu.pick_random()
	predicted_order = current_order
	
	state = TableState.DECIDING
	bubble_panel.visible = true
	_set_bubble_icon(DISH_TEXTURES.get(current_order, ""))
	bubble_text.text = "¡Ordenar!"
	dirty_dishes_visual.visible = false

func interact(player: PlayerAlex) -> void:
	match state:
		TableState.DECIDING:
			_place_order()
				
		TableState.WAITING_FOOD:
			if player.has_dish(current_order):
				player.remove_dish(current_order)
				state = TableState.EATING
				eating_timer = 3.5
				patience_bar.visible = false
				bubble_icon.texture = null
				bubble_text.text = "Comiendo..."
				datapad_forecast_card.visible = false
				
				var is_vip = customer_type == CustomerType.VIP
				GameManager.add_order_success(current_order, is_vip)
			elif not order_sent:
				_retry_order()
			else:
				AudioManager.play_sfx_click()
				
		TableState.DIRTY:
			state = TableState.EMPTY
			dirty_dishes_visual.visible = false
			bubble_panel.visible = false
			AudioManager.play_sfx_clean()
			var delay_multiplier = BusinessManager.get_customer_delay_multiplier() if BusinessManager.management_mode else 1.0
			_spawn_customer_timer(randf_range(2.0, 5.0) * delay_multiplier)

func _finish_eating() -> void:
	state = TableState.DIRTY
	customer_common.visible = false
	customer_vip.visible = false
	customer_badge.visible = false
	bubble_panel.visible = true
	bubble_icon.texture = null
	bubble_text.text = "🧹 Limpiar"
	dirty_dishes_visual.visible = true

func _customer_leaves_angry() -> void:
	var is_vip = customer_type == CustomerType.VIP
	GameManager.record_lost_customer(table_number, is_vip)
	var kitchen = get_tree().get_first_node_in_group("kitchen")
	if kitchen and kitchen.has_method("cancel_order"):
		kitchen.cancel_order(table_number)
	
	state = TableState.DIRTY
	customer_common.visible = false
	customer_vip.visible = false
	customer_badge.visible = false
	patience_bar.visible = false
	bubble_panel.visible = true
	bubble_icon.texture = null
	bubble_text.text = "¡Se fue enojado!"
	dirty_dishes_visual.visible = true

func get_predicted_dish() -> String:
	return predicted_order if state == TableState.DECIDING or state == TableState.WAITING_FOOD else ""

func _set_bubble_icon(path: String) -> void:
	if path != "" and ResourceLoader.exists(path):
		bubble_icon.texture = load(path)
		bubble_icon.visible = true
	else:
		bubble_icon.visible = false

func _on_datapad_activated(_forecasts: Dictionary) -> void:
	if state == TableState.DECIDING or state == TableState.WAITING_FOOD:
		if state == TableState.DECIDING:
			_place_order()
		var icon = GameManager.DISH_ICONS.get(predicted_order, "🍽️")
		var conf = randi_range(91, 98)
		datapad_text.text = "📡 Demanda: %s %d%%" % [icon, conf]
		datapad_forecast_card.visible = true
		
		var tween = create_tween()
		tween.tween_property(datapad_forecast_card, "scale", Vector2(1.15, 1.15), 0.2)
		tween.tween_property(datapad_forecast_card, "scale", Vector2(1.0, 1.0), 0.2)
		
		await get_tree().create_timer(12.0).timeout
		datapad_forecast_card.visible = false

func _place_order() -> void:
	if state != TableState.DECIDING:
		return
	state = TableState.WAITING_FOOD
	_set_bubble_icon(DISH_TEXTURES.get(current_order, ""))
	bubble_text.text = current_order
	AudioManager.play_sfx_bell()
	var kitchen = get_tree().get_first_node_in_group("kitchen")
	if kitchen and kitchen.has_method("receive_order"):
		order_sent = kitchen.receive_order(current_order, table_number)
		if not order_sent:
			bubble_text.text = "Sin insumos · reabastece y vuelve"

func _retry_order() -> void:
	var kitchen = get_tree().get_first_node_in_group("kitchen")
	if kitchen and kitchen.has_method("receive_order"):
		order_sent = kitchen.receive_order(current_order, table_number)
		if order_sent:
			bubble_text.text = current_order
			AudioManager.play_sfx_bell()

func get_interaction_prompt() -> String:
	match state:
		TableState.DECIDING:
			return "Tomar Comanda (Mesa %d)" % table_number
		TableState.WAITING_FOOD:
			return "Servir %s (Mesa %d)" % [current_order, table_number]
		TableState.DIRTY:
			return "Limpiar Mesa %d" % table_number
		_:
			return "Mesa %d" % table_number
