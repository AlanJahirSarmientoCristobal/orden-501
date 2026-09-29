extends Area2D
class_name WorldActivitySpot

@export_enum("mission", "restaurant", "repeatable", "trivia", "warp") var action: String = "mission"
@export var event_id: String = ""
@export var objective_id: String = ""
@export var display_name: String = "Objetivo"
@export_multiline var details: String = ""
@export_range(0, 6) var icon_type: int = 0
@export var repeatable_reward: int = 20
@export_file("*.tscn") var target_scene: String = ""
@export var target_map: String = "hub"
@export var target_position := Vector2(1280, 720)

const ICONS: Array[Texture2D] = [
	preload("res://Assets/sprites/rpg_urban/Tiles/tile_0186.png"),
	preload("res://Assets/sprites/rpg_urban/Tiles/tile_0273.png"),
	preload("res://Assets/sprites/rpg_urban/Tiles/tile_0166.png"),
	preload("res://Assets/sprites/rpg_urban/Tiles/tile_0282.png"),
	preload("res://Assets/sprites/rpg_urban/Tiles/tile_0253.png"),
	preload("res://Assets/sprites/rpg_urban/Tiles/tile_0276.png"),
	preload("res://Assets/sprites/rpg_urban/Tiles/tile_0024.png")
]

@onready var icon: Sprite2D = $Icon
@onready var name_label: Label = $Name
@onready var marker: Label = $Marker

var base_icon_position := Vector2.ZERO

func _ready() -> void:
	add_to_group("world_interactable")
	icon.texture = ICONS[clamp(icon_type, 0, ICONS.size() - 1)]
	name_label.text = display_name
	marker.text = "!" if action == "mission" else ("R" if action == "restaurant" else ("?" if action == "trivia" else (">>" if action == "warp" else "*")))
	base_icon_position = icon.position

func _process(_delta: float) -> void:
	icon.position.y = base_icon_position.y + sin(Time.get_ticks_msec() * 0.004) * 4.0

func get_interaction_prompt() -> String:
	return display_name

func interact(_player: Node) -> void:
	match action:
		"mission":
			if MissionManager.report_event(event_id, 1, objective_id):
				queue_free()
			else:
				MissionManager.notification_requested.emit(details if details != "" else "Este objetivo pertenece a otra misión.")
		"restaurant":
			GameManager.return_to_hub_after_level = true
			MissionManager.save_game()
			var level = MissionManager.get_restaurant_level()
			GameManager.change_scene_smooth("res://scenes/levels/jornada_%d.tscn" % level)
		"repeatable":
			MissionManager.claim_daily(event_id, repeatable_reward)
		"trivia":
			var controller = get_tree().get_first_node_in_group("world_controller")
			if controller and controller.has_method("open_trivia"):
				controller.open_trivia()
		"warp":
			var controller = get_tree().get_first_node_in_group("world_controller")
			if controller and controller.has_method("warp_to"):
				controller.warp_to(target_scene, target_map, target_position)
