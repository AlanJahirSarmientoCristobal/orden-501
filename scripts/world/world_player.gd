extends CharacterBody2D
class_name WorldPlayer

@export var base_speed: float = 280.0

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var detector: Area2D = $InteractionDetector
@onready var prompt_label: Label = $PromptLabel

var nearby_interactables: Array[Area2D] = []

func _ready() -> void:
	detector.area_entered.connect(_on_area_entered)
	detector.area_exited.connect(_on_area_exited)
	prompt_label.visible = false

func _physics_process(_delta: float) -> void:
	var input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var speed_bonus = 1.0 + float(GameManager.upgrade_speed_level) * 0.15
	velocity = input_vector.normalized() * base_speed * speed_bonus
	if input_vector != Vector2.ZERO:
		_update_animation(input_vector)
		move_and_slide()
	else:
		sprite.stop()
		sprite.frame = 1
	_update_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var target = _get_closest_interactable()
		if target and target.has_method("interact"):
			target.interact(self)
			get_viewport().set_input_as_handled()

func _update_animation(direction: Vector2) -> void:
	if abs(direction.x) > abs(direction.y):
		sprite.animation = &"side"
		sprite.flip_h = direction.x < 0
	elif direction.y < 0:
		sprite.animation = &"up"
		sprite.flip_h = false
	else:
		sprite.animation = &"down"
		sprite.flip_h = false
	sprite.play()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("world_interactable") and not nearby_interactables.has(area):
		nearby_interactables.append(area)

func _on_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)

func _get_closest_interactable() -> Area2D:
	var closest: Area2D
	var closest_distance := INF
	for area in nearby_interactables:
		if not is_instance_valid(area) or not area.visible:
			continue
		var distance = global_position.distance_squared_to(area.global_position)
		if distance < closest_distance:
			closest = area
			closest_distance = distance
	return closest

func _update_prompt() -> void:
	var target = _get_closest_interactable()
	if target and target.has_method("get_interaction_prompt"):
		prompt_label.text = "[Espacio] " + target.get_interaction_prompt()
		prompt_label.visible = true
	else:
		prompt_label.visible = false
