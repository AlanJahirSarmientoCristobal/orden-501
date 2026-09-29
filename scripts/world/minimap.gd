extends Control

const WORLD_SIZE := Vector2(2560, 1440)

@onready var player: Node2D = get_node("../../WorldPlayer")
@onready var objectives: Node2D = get_node("../../ObjectiveMarkers")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var rect = Rect2(Vector2.ZERO, size)
	draw_rect(rect, Color(0.025, 0.055, 0.075, 0.92))
	draw_rect(Rect2(0, size.y * 0.4, size.x, size.y * 0.2), Color(0.22, 0.25, 0.31))
	draw_rect(Rect2(size.x * 0.42, 0, size.x * 0.16, size.y), Color(0.22, 0.25, 0.31))
	# Zonas principales.
	draw_rect(_world_rect(Rect2(120,120,520,300)), Color(0.75, 0.3, 0.2, 0.9))
	draw_rect(_world_rect(Rect2(750,100,270,360)), Color(0.2, 0.7, 0.5, 0.9))
	draw_rect(_world_rect(Rect2(1650,75,760,455)), Color(0.2, 0.55, 0.8, 0.9))
	draw_rect(_world_rect(Rect2(100,930,790,390)), Color(0.25, 0.72, 0.35, 0.9))
	draw_rect(_world_rect(Rect2(1030,1030,520,250)), Color(0.45, 0.55, 0.75, 0.9))
	for objective in objectives.get_children():
		draw_circle(_world_point(objective.global_position), 4.0, Color(1, 0.82, 0.15))
	draw_circle(_world_point(player.global_position), 5.0, Color(0.2, 1, 0.9))
	draw_arc(_world_point(player.global_position), 7.0, 0.0, TAU, 16, Color.WHITE, 1.5)

func _world_point(world_position: Vector2) -> Vector2:
	return Vector2(world_position.x / WORLD_SIZE.x * size.x, world_position.y / WORLD_SIZE.y * size.y)

func _world_rect(world_rect: Rect2) -> Rect2:
	return Rect2(_world_point(world_rect.position), Vector2(world_rect.size.x / WORLD_SIZE.x * size.x, world_rect.size.y / WORLD_SIZE.y * size.y))
