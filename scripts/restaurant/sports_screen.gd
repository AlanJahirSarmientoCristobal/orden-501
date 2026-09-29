extends Node2D

@export var match_teams: String = "ÁME 2 - 1 PAC"
@onready var screen_label: Label = $ScreenFrame/Margin/VBox/ScoreLabel
@onready var clock_label: Label = $ScreenFrame/Margin/VBox/ClockLabel

var game_minute: int = 25
var match_tick: Timer

func _ready() -> void:
	_update_tv()
	match_tick = Timer.new()
	match_tick.wait_time = 2.0
	match_tick.autostart = true
	match_tick.timeout.connect(_tick_match)
	add_child(match_tick)

func _tick_match() -> void:
	if BusinessManager.management_mode:
		_update_tv()
		return
	game_minute += 1
	if game_minute > 90:
		game_minute = 90
		match_tick.stop()
	_update_tv()

func _update_tv() -> void:
	if BusinessManager.management_mode:
		var screen_kind = get_index() % 3
		if screen_kind == 0:
			screen_label.text = "PEDIDOS EN COCINA"
			var kitchen = get_tree().get_first_node_in_group("kitchen")
			var queue_size = kitchen.cooking_queue.size() if kitchen else 0
			clock_label.text = "%d COMANDAS EN COLA" % queue_size
		elif screen_kind == 1:
			screen_label.text = "CONTROL DE INVENTARIO"
			var low := 0
			for ingredient in BusinessManager.inventory:
				if int(BusinessManager.inventory[ingredient]) <= 2:
					low += 1
			clock_label.text = "%d ALERTAS DE STOCK" % low
		else:
			screen_label.text = "RESERVACIONES"
			clock_label.text = "%d CONFIRMADAS" % BusinessManager.confirmed_reservations
		return
	if screen_label:
		screen_label.text = "⚽ " + match_teams
	if clock_label:
		clock_label.text = "LIGA MX | %d' EN VIVO" % game_minute
