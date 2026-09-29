extends Node2D

@export_enum("market", "stadium", "park", "industrial") var theme: String = "market"

func _ready() -> void:
	queue_redraw()

func _draw() -> void:
	var palette = _palette()
	draw_rect(Rect2(0, 0, 2560, 1440), palette[0])
	_draw_roads(palette)
	match theme:
		"market": _draw_market(palette)
		"stadium": _draw_stadium(palette)
		"park": _draw_park(palette)
		"industrial": _draw_industrial(palette)
	draw_rect(Rect2(18, 18, 2524, 1404), Color(0.05, 0.08, 0.12), false, 24.0)

func _palette() -> Array[Color]:
	var result: Array[Color] = []
	result.assign({
		"market":[Color("#cf9c62"), Color("#454b57"), Color("#f3d49c"), Color("#b94f3f")],
		"stadium":[Color("#287c58"), Color("#424957"), Color("#e9edf2"), Color("#e1b52f")],
		"park":[Color("#4b9a5d"), Color("#9b835f"), Color("#b9e48e"), Color("#2e6e99")],
		"industrial":[Color("#687078"), Color("#343941"), Color("#d5a632"), Color("#8f3d3d")]
	}.get(theme))
	return result

func _draw_roads(palette: Array[Color]) -> void:
	draw_rect(Rect2(0, 620, 2560, 200), palette[1])
	draw_rect(Rect2(1180, 0, 200, 1440), palette[1])
	for x in range(40, 2560, 130):
		draw_rect(Rect2(x, 715, 70, 10), Color(0.94, 0.84, 0.38, 0.8))
	for y in range(20, 1440, 130):
		draw_rect(Rect2(1275, y, 10, 70), Color(0.94, 0.84, 0.38, 0.8))

func _draw_market(p: Array[Color]) -> void:
	for row in range(3):
		for column in range(6):
			var r = Rect2(120 + column * 400, 105 + row * 420, 255, 165)
			draw_rect(r, p[2])
			draw_colored_polygon(PackedVector2Array([r.position, r.position + Vector2(r.size.x,0), r.position + Vector2(r.size.x-25,-45), r.position + Vector2(25,-45)]), p[3])
			draw_rect(Rect2(r.position + Vector2(35,55), Vector2(185,18)), Color("#5f8f48"))

func _draw_stadium(p: Array[Color]) -> void:
	draw_circle(Vector2(1280,720), 560, p[2])
	draw_circle(Vector2(1280,720), 455, Color("#304252"))
	draw_circle(Vector2(1280,720), 355, Color("#3f9b61"))
	draw_rect(Rect2(1000,480,560,480), Color("#50ad68"))
	draw_line(Vector2(1280,480),Vector2(1280,960),Color.WHITE,5)
	draw_circle(Vector2(1280,720),75,Color.WHITE,false,5)
	for angle in range(0,360,30):
		var direction = Vector2.RIGHT.rotated(deg_to_rad(angle))
		draw_circle(Vector2(1280,720)+direction*505,22,p[3])

func _draw_park(p: Array[Color]) -> void:
	for index in range(38):
		var x = 90 + (index * 379) % 2320
		var y = 80 + (index * 613) % 1280
		draw_circle(Vector2(x,y),34,p[2])
		draw_circle(Vector2(x,y),21,Color("#277044"))
	draw_circle(Vector2(1280,720),420,Color("#86c871"),false,70)
	draw_circle(Vector2(1280,720),235,p[3])
	draw_circle(Vector2(1280,720),180,Color("#62b9cf"))

func _draw_industrial(p: Array[Color]) -> void:
	for row in range(3):
		for column in range(5):
			var origin = Vector2(90 + column*500, 90 + row*430)
			draw_rect(Rect2(origin,Vector2(330,220)),Color("#4d535c"))
			draw_rect(Rect2(origin+Vector2(25,30),Vector2(280,45)),p[2])
			for stripe in range(6):
				draw_line(origin+Vector2(25+stripe*52,175),origin+Vector2(65+stripe*52,135),p[3],12)
	for x in [410, 2110]:
		draw_rect(Rect2(x,250,65,330),Color("#3b3f47"))
		draw_circle(Vector2(x+32,245),50,Color("#b8c2ca"))
