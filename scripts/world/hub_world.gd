extends Node2D

const MAP_SIZE := Vector2(2560, 1440)
const TREE = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0286.png")
const TREE_ALT = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0287.png")
const CAR_RED = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0378.png")
const CAR_GREEN = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0381.png")
const BENCH = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0249.png")
const LAMP = preload("res://Assets/sprites/rpg_urban/Tiles/tile_0169.png")

func _ready() -> void:
	z_index = -5
	_create_bounds()
	_create_building_collision(Rect2(120, 120, 520, 300))
	_create_building_collision(Rect2(1030, 1030, 520, 250))
	_add_zone_labels()
	_add_decorations()
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, MAP_SIZE), Color("173c35"))
	# Vialidades y banquetas del barrio.
	draw_rect(Rect2(0, 575, 2560, 300), Color("343b49"))
	draw_rect(Rect2(1080, 0, 400, 1440), Color("343b49"))
	draw_rect(Rect2(0, 555, 2560, 20), Color("a7a79a"))
	draw_rect(Rect2(0, 875, 2560, 20), Color("a7a79a"))
	draw_rect(Rect2(1060, 0, 20, 1440), Color("a7a79a"))
	draw_rect(Rect2(1480, 0, 20, 1440), Color("a7a79a"))
	for x in range(30, 2560, 120):
		draw_rect(Rect2(x, 718, 62, 9), Color(1, 0.85, 0.25, 0.75))
	for y in range(30, 1440, 120):
		draw_rect(Rect2(1274, y, 9, 62), Color(1, 0.85, 0.25, 0.75))

	# Restaurante.
	draw_rect(Rect2(120, 120, 520, 300), Color("8f3e32"))
	draw_rect(Rect2(150, 160, 460, 220), Color("d06845"))
	draw_rect(Rect2(310, 350, 140, 70), Color("142b32"))
	# Mercado abierto.
	draw_rect(Rect2(750, 100, 270, 360), Color("28665b"))
	for y in range(145, 430, 80):
		draw_rect(Rect2(790, y, 190, 48), Color("e49d45"))
	# Estadio accesible.
	draw_rect(Rect2(1650, 75, 760, 455), Color("202936"))
	draw_rect(Rect2(1710, 125, 640, 355), Color("2d754b"))
	draw_arc(Vector2(2030, 302), 165, 0, TAU, 64, Color("e9e4c8"), 5)
	draw_line(Vector2(2030, 130), Vector2(2030, 475), Color("e9e4c8"), 4)
	# Plaza central.
	draw_rect(Rect2(850, 500, 850, 390), Color("8b8178"))
	draw_circle(Vector2(1275, 695), 120, Color("64748b"))
	draw_circle(Vector2(1275, 695), 84, Color("249d91"))
	# Parque.
	draw_rect(Rect2(100, 930, 790, 390), Color("2d7047"))
	draw_arc(Vector2(490, 1125), 170, 0, TAU, 72, Color("d2bc75"), 24)
	# Taller.
	draw_rect(Rect2(1030, 1030, 520, 250), Color("40516b"))
	draw_rect(Rect2(1100, 1090, 380, 190), Color("75839a"))
	# Distrito residencial y zona de reparto.
	draw_rect(Rect2(1720, 930, 700, 390), Color("485b68"))
	for x in range(1760, 2360, 190):
		draw_rect(Rect2(x, 990, 135, 230), Color("b86e52"))
		draw_rect(Rect2(x + 42, 1140, 52, 80), Color("293747"))

func _add_zone_labels() -> void:
	_add_label("LA 501 SPORTS BISTRO", Vector2(170, 72), Vector2(420, 42), Color("ffd166"), 22)
	_add_label("MERCADO CENTRAL", Vector2(735, 52), Vector2(300, 42), Color("6ee7c8"), 20)
	_add_label("ESTADIO DEL BARRIO", Vector2(1820, 25), Vector2(420, 42), Color("75c9ff"), 22)
	_add_label("PLAZA 501", Vector2(1110, 520), Vector2(330, 40), Color("fff0a6"), 20)
	_add_label("PARQUE DE ENTRENAMIENTO", Vector2(235, 900), Vector2(520, 40), Color("b8f28b"), 19)
	_add_label("TALLER Y TECNOLOGÍA", Vector2(1040, 980), Vector2(500, 40), Color("b8d5ff"), 19)
	_add_label("DISTRITO DE REPARTO", Vector2(1800, 900), Vector2(500, 40), Color("ffc3a0"), 19)

func _add_label(text_value: String, pos: Vector2, label_size: Vector2, color: Color, font_size: int) -> void:
	var label = Label.new()
	label.position = pos
	label.size = label_size
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color("07151b"))
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)

func _add_decorations() -> void:
	var tree_positions = [Vector2(55,80),Vector2(690,90),Vector2(70,470),Vector2(1580,90),Vector2(2460,120),Vector2(80,880),Vector2(940,960),Vector2(1630,960),Vector2(2470,870),Vector2(930,1350),Vector2(1640,1350),Vector2(2470,1340)]
	for index in range(tree_positions.size()):
		_add_sprite(TREE if index % 2 == 0 else TREE_ALT, tree_positions[index], 4.5)
	for pos in [Vector2(960,610),Vector2(1570,610),Vector2(960,820),Vector2(1570,820)]:
		_add_sprite(BENCH, pos, 3.5)
	for pos in [Vector2(1040,500),Vector2(1515,500),Vector2(1040,920),Vector2(1515,920)]:
		_add_sprite(LAMP, pos, 3.5)
	_add_sprite(CAR_RED, Vector2(310,720), 4.0)
	_add_sprite(CAR_GREEN, Vector2(2200,720), 4.0)

func _add_sprite(texture: Texture2D, pos: Vector2, sprite_scale: float) -> void:
	var sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	add_child(sprite)

func _create_bounds() -> void:
	_create_wall(Vector2(1280, -20), Vector2(2600, 40))
	_create_wall(Vector2(1280, 1460), Vector2(2600, 40))
	_create_wall(Vector2(-20, 720), Vector2(40, 1480))
	_create_wall(Vector2(2580, 720), Vector2(40, 1480))

func _create_building_collision(rect: Rect2) -> void:
	_create_wall(rect.position + rect.size * 0.5, rect.size)

func _create_wall(pos: Vector2, wall_size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 2
	body.position = pos
	var shape_node = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = wall_size
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)
