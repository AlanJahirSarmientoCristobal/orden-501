extends StaticBody2D
class_name KitchenStation

# Órdenes en cola y listas para entrega
var cooking_queue: Array[Dictionary] = []
var ready_orders: Array[Dictionary] = []

var current_cooking_dish: String = ""
var current_order: Dictionary = {}
var current_cook_time: float = 0.0
var base_dish_time: float = 4.5

@onready var chef_sprite: Sprite2D = $Visuals/ChefSprite
@onready var chef_label: Label = $Visuals/ChefBadge
@onready var cooking_bar: ProgressBar = $UI/CookingBar
@onready var ready_display: HBoxContainer = $UI/ReadyContainer/Margin/HBox
@onready var queue_label: Label = $UI/QueueLabel

func _ready() -> void:
	add_to_group("kitchen")
	cooking_bar.visible = false
	_update_ready_display()

func _process(delta: float) -> void:
	# Si no hay plato cocinándose pero hay órdenes en cola, comenzar a cocinar
	if current_cooking_dish == "" and not cooking_queue.is_empty():
		current_order = cooking_queue.pop_front()
		current_cooking_dish = current_order["dish"]
		current_cook_time = base_dish_time * GameManager.upgrade_chef_speed_multiplier
		if MissionManager.campaign_started:
			current_cook_time *= MissionManager.get_cooking_multiplier()
		cooking_bar.max_value = current_cook_time
		cooking_bar.value = current_cook_time
		cooking_bar.visible = true
	
	# Progreso de cocción
	if current_cooking_dish != "":
		current_cook_time -= delta
		cooking_bar.value = cooking_bar.max_value - current_cook_time
		
		if current_cook_time <= 0.0:
			# Platillo listo
			ready_orders.append(current_order.duplicate())
			AudioManager.play_sfx_bell()
			current_cooking_dish = ""
			current_order = {}
			cooking_bar.visible = false
			_update_ready_display()
	
	queue_label.text = "Comandas en Fila: %d" % cooking_queue.size() if not cooking_queue.is_empty() else "Cocina Libre"

func receive_order(dish_name: String, table_num: int) -> bool:
	if BusinessManager.management_mode and not BusinessManager.consume_recipe(dish_name,"mesa_%d" % table_num):
		return false
	cooking_queue.append({"dish": dish_name, "table": table_num})
	return true

func cancel_order(table_num: int) -> void:
	for idx in range(cooking_queue.size() - 1, -1, -1):
		if cooking_queue[idx].get("table", -1) == table_num:
			cooking_queue.remove_at(idx)
	for idx in range(ready_orders.size() - 1, -1, -1):
		if ready_orders[idx].get("table", -1) == table_num:
			ready_orders.remove_at(idx)
	if not current_order.is_empty() and current_order.get("table", -1) == table_num:
		current_order = {}
		current_cooking_dish = ""
		current_cook_time = 0.0
		cooking_bar.visible = false
	_update_ready_display()

func interact(player: PlayerAlex) -> void:
	# Si hay platillos listos y Alex tiene espacio en bandeja
	if not ready_orders.is_empty():
		if player.can_carry_more():
			var order_to_take = ready_orders.pop_front()
			var dish_to_take: String = order_to_take["dish"]
			player.add_dish(dish_to_take)
			_update_ready_display()
		else:
			# Bandeja llena
			AudioManager.play_sfx_click()
	else:
		# No hay platos listos
		AudioManager.play_sfx_click()

const DISH_TEXTURES = {
	GameManager.DISH_PIZZA: "res://Assets/sprites/food_kit/Previews/pizza.png",
	GameManager.DISH_FRIES: "res://Assets/sprites/food_kit/Previews/fries.png",
	GameManager.DISH_SODA: "res://Assets/sprites/food_kit/Previews/soda-glass.png"
}

func _update_ready_display() -> void:
	for c in ready_display.get_children():
		c.queue_free()
	
	if ready_orders.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "Sin pedidos listos"
		empty_lbl.add_theme_font_size_override("font_size", 10)
		ready_display.add_child(empty_lbl)
	else:
		for order in ready_orders:
			var dish: String = order["dish"]
			var tex_path = DISH_TEXTURES.get(dish, "")
			if tex_path != "" and ResourceLoader.exists(tex_path):
				var tr = TextureRect.new()
				tr.texture = load(tex_path)
				tr.custom_minimum_size = Vector2(22, 22)
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				ready_display.add_child(tr)
			else:
				var icon_lbl = Label.new()
				icon_lbl.text = GameManager.DISH_ICONS.get(dish, "🍽️")
				icon_lbl.add_theme_font_size_override("font_size", 14)
				ready_display.add_child(icon_lbl)
