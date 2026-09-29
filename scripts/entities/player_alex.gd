extends CharacterBody2D
class_name PlayerAlex

@export var base_speed: float = 230.0
@export var sprint_multiplier: float = 1.65
@export var max_stamina: float = 100.0
@export var stamina_drain: float = 35.0
@export var stamina_regen: float = 25.0

var current_stamina: float = 100.0
var is_sprinting: bool = false
var held_dishes: Array[String] = []

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var interaction_detector: Area2D = $InteractionDetector
@onready var tray_display: HBoxContainer = $TrayDisplay
@onready var stamina_bar: ProgressBar = $StaminaBar
@onready var prompt_label: Label = $PromptLabel

var nearby_table: Node = null
var nearby_kitchen: Node = null

func _ready() -> void:
	current_stamina = max_stamina
	prompt_label.visible = false
	_update_tray_ui()
	if BusinessManager.management_mode:
		var role_label = Label.new()
		role_label.position = Vector2(-82,42)
		role_label.size = Vector2(164,24)
		role_label.text = "DANI · GERENTE DIGITAL"
		role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		role_label.add_theme_font_size_override("font_size",10)
		role_label.add_theme_color_override("font_color",Color(1.0,0.86,0.3))
		role_label.add_theme_color_override("font_outline_color",Color(0.03,0.04,0.06))
		role_label.add_theme_constant_override("outline_size",4)
		add_child(role_label)
	
	if interaction_detector:
		interaction_detector.area_entered.connect(_on_area_entered)
		interaction_detector.area_exited.connect(_on_area_exited)

func _physics_process(delta: float) -> void:
	if BusinessManager.management_mode and BusinessManager.panel_open:
		velocity = Vector2.ZERO
		sprite.stop()
		move_and_slide()
		return
	# Cálculo de velocidad y mejoras
	var speed_bonus = 1.0 + (float(GameManager.upgrade_speed_level) * 0.30)
	var speed = base_speed * speed_bonus
	
	# Manejo de Estamina y Sprint
	if Input.is_key_pressed(KEY_SHIFT) and current_stamina > 5.0 and velocity.length() > 10.0:
		is_sprinting = true
		speed *= sprint_multiplier
		current_stamina = max(0.0, current_stamina - stamina_drain * delta)
	else:
		is_sprinting = false
		current_stamina = min(max_stamina, current_stamina + stamina_regen * delta)
	
	stamina_bar.value = current_stamina
	stamina_bar.visible = current_stamina < max_stamina
	
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * speed
		
		# Animación de marcha de cuatro direcciones con sprites CC0.
		if abs(input_vector.x) > abs(input_vector.y):
			sprite.animation = &"side"
			sprite.flip_h = input_vector.x < 0
		elif input_vector.y < 0:
			sprite.animation = &"up"
			sprite.flip_h = false
		else:
			sprite.animation = &"down"
			sprite.flip_h = false
		sprite.speed_scale = 1.6 if is_sprinting else 1.0
		sprite.play()
	else:
		velocity = Vector2.ZERO
		sprite.stop()
		sprite.frame = 1
	
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	# Activar el escáner de demanda con la tecla E.
	if event.is_action_pressed("datapad") or (event is InputEventKey and event.pressed and event.keycode == KEY_E):
		if BusinessManager.management_mode:
			BusinessManager.request_panel("management")
		else:
			_trigger_datapad()
		get_viewport().set_input_as_handled()
	
	# Interactuar con Mesas o Cocina con Espacio o Enter
	if event.is_action_pressed("interact") or (event is InputEventKey and event.pressed and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER)):
		_handle_interaction()

	if event.is_action_pressed("discard_dish"):
		discard_oldest_dish()

func _trigger_datapad() -> void:
	# Recolecta las mesas activas para anticipar y enviar sus comandas.
	var tables = get_tree().get_nodes_in_group("tables")
	var predictions = {}
	
	for t in tables:
		if t.has_method("get_predicted_dish"):
			predictions[t.table_number] = t.get_predicted_dish()
	
	GameManager.activate_datapad(predictions)

func _handle_interaction() -> void:
	# 1. Interactuar con Cocina
	if nearby_kitchen and nearby_kitchen.has_method("interact"):
		nearby_kitchen.interact(self)
		return
	
	# 2. Interactuar con Mesa
	if nearby_table and nearby_table.has_method("interact"):
		nearby_table.interact(self)

func can_carry_more() -> bool:
	return held_dishes.size() < GameManager.upgrade_inventory_capacity

func add_dish(dish_name: String) -> bool:
	if can_carry_more():
		held_dishes.append(dish_name)
		_update_tray_ui()
		AudioManager.play_sfx_clink()
		return true
	return false

func has_dish(dish_name: String) -> bool:
	return held_dishes.has(dish_name)

func remove_dish(dish_name: String) -> bool:
	var idx = held_dishes.find(dish_name)
	if idx != -1:
		held_dishes.remove_at(idx)
		_update_tray_ui()
		AudioManager.play_sfx_clink()
		return true
	return false

func discard_oldest_dish() -> void:
	if held_dishes.is_empty():
		AudioManager.play_sfx_click()
		return
	held_dishes.pop_front()
	_update_tray_ui()
	AudioManager.play_sfx_clean()

const DISH_TEXTURES = {
	GameManager.DISH_PIZZA: "res://Assets/sprites/food_kit/Previews/pizza.png",
	GameManager.DISH_FRIES: "res://Assets/sprites/food_kit/Previews/fries.png",
	GameManager.DISH_SODA: "res://Assets/sprites/food_kit/Previews/soda-glass.png"
}

func _update_tray_ui() -> void:
	for c in tray_display.get_children():
		c.queue_free()
	
	for dish in held_dishes:
		var tex_path = DISH_TEXTURES.get(dish, "")
		if tex_path != "" and ResourceLoader.exists(tex_path):
			var tr = TextureRect.new()
			tr.texture = load(tex_path)
			tr.custom_minimum_size = Vector2(24, 24)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tray_display.add_child(tr)
		else:
			var lbl = Label.new()
			lbl.text = GameManager.DISH_ICONS.get(dish, "🍽️")
			lbl.add_theme_font_size_override("font_size", 16)
			tray_display.add_child(lbl)

func _on_area_entered(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent.is_in_group("tables"):
		nearby_table = parent
		prompt_label.text = "[Espacio] " + parent.get_interaction_prompt()
		prompt_label.visible = true
	elif parent.is_in_group("kitchen"):
		nearby_kitchen = parent
		prompt_label.text = "[Espacio] Cocina / Retirar Pedidos"
		prompt_label.visible = true

func _on_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent == nearby_table:
		nearby_table = null
		prompt_label.visible = false
	elif parent == nearby_kitchen:
		nearby_kitchen = null
		prompt_label.visible = false
