extends RefCounted
class_name WorldObjectiveCatalog

static func get_locations(event_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match event_id:
		"talk_sofia":
			_add_points(result, event_id, "hub", [Vector2(1275,625)])
		"visit_zone":
			_add_points(result, event_id, "hub", [Vector2(500,475),Vector2(2030,510)])
			_add_points(result, event_id, "market", [Vector2(360,280),Vector2(2050,320),Vector2(1280,1100)])
			_add_points(result, event_id, "stadium", [Vector2(400,300),Vector2(1280,710),Vector2(2150,1080)])
			_add_points(result, event_id, "park", [Vector2(320,260),Vector2(1280,720)])
			_add_points(result, event_id, "industrial", [Vector2(420,1120),Vector2(2100,300)])
		"market_supply":
			_add_grid(result, event_id, "market", Vector2(280,220), 6, Vector2(340,230), 18)
			_add_grid(result, event_id, "industrial", Vector2(300,260), 5, Vector2(420,300), 15)
		"fan_interview":
			_add_grid(result, event_id, "stadium", Vector2(300,220), 5, Vector2(450,280), 14)
			_add_points(result, event_id, "hub", [Vector2(1030,610),Vector2(1510,610),Vector2(1275,830)])
			_add_grid(result, event_id, "park", Vector2(420,350), 4, Vector2(520,420), 4)
		"park_checkpoint":
			_add_ring(result, event_id, "park", Vector2(1280,720), 470.0, 24)
			_add_ring(result, event_id, "park", Vector2(1280,720), 250.0, 12)
			_add_ring(result, event_id, "stadium", Vector2(1280,720), 430.0, 8)
		"screen_part":
			_add_grid(result, event_id, "industrial", Vector2(300,230), 6, Vector2(380,300), 18)
			_add_grid(result, event_id, "stadium", Vector2(420,1100), 6, Vector2(340,1), 6)
		"delivery_stop":
			_add_grid(result, event_id, "hub", Vector2(250,500), 3, Vector2(900,380), 6)
			_add_grid(result, event_id, "market", Vector2(300,300), 3, Vector2(850,400), 6)
			_add_grid(result, event_id, "stadium", Vector2(260,260), 5, Vector2(480,900), 5)
			_add_grid(result, event_id, "park", Vector2(300,300), 5, Vector2(480,820), 5)
			_add_grid(result, event_id, "industrial", Vector2(300,300), 3, Vector2(850,400), 6)
		"promo_poster":
			_add_grid(result, event_id, "hub", Vector2(180,520), 6, Vector2(420,1), 6)
			_add_grid(result, event_id, "market", Vector2(250,200), 6, Vector2(400,1), 6)
			_add_grid(result, event_id, "stadium", Vector2(250,230), 6, Vector2(400,1), 6)
			_add_grid(result, event_id, "park", Vector2(250,1180), 6, Vector2(400,1), 6)
			_add_grid(result, event_id, "industrial", Vector2(250,1180), 6, Vector2(400,1), 6)
		"vip_invite":
			_add_grid(result, event_id, "stadium", Vector2(300,250), 4, Vector2(600,350), 12)
			_add_grid(result, event_id, "hub", Vector2(900,610), 5, Vector2(190,1), 5)
			_add_grid(result, event_id, "market", Vector2(360,350), 5, Vector2(430,1), 5)
	return result

static func _add_points(result: Array[Dictionary], event_id: String, map_id: String, points: Array) -> void:
	for point in points:
		result.append(_location(event_id, map_id, point, result.size()))

static func _add_grid(result: Array[Dictionary], event_id: String, map_id: String, start: Vector2, columns: int, spacing: Vector2, count: int) -> void:
	for index in range(count):
		var row = index / columns
		var column = index % columns
		var position = start + Vector2(column * spacing.x, row * spacing.y)
		result.append(_location(event_id, map_id, position, result.size()))

static func _add_ring(result: Array[Dictionary], event_id: String, map_id: String, center: Vector2, radius: float, count: int) -> void:
	for index in range(count):
		var angle = TAU * float(index) / float(count)
		var position = center + Vector2(cos(angle), sin(angle)) * radius
		result.append(_location(event_id, map_id, position, result.size()))

static func _location(event_id: String, map_id: String, position: Vector2, index: int) -> Dictionary:
	return {"id":"%s_%s_%03d" % [event_id, map_id, index], "map":map_id, "position":position}
