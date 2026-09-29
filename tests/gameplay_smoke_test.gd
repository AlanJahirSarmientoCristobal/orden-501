extends Node

var failures: Array[String] = []

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	var level = load("res://scenes/levels/jornada_1.tscn").instantiate()
	add_child(level)
	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player")
	var kitchen = get_tree().get_first_node_in_group("kitchen")
	var tables = get_tree().get_nodes_in_group("tables")
	_check(player != null, "No se encontró al jugador")
	_check(kitchen != null, "No se encontró la cocina")
	_check(tables.size() == 4, "La Jornada 1 debe contener cuatro mesas")
	if not failures.is_empty():
		await _finish(level)
		return

	kitchen.base_dish_time = 0.0
	var first_table = tables[0]
	first_table._spawn_customer()
	first_table.interact(player)
	_check(kitchen.cooking_queue.size() == 1, "La comanda no llegó a la cocina")

	for _frame in range(3):
		await get_tree().process_frame
	_check(kitchen.ready_orders.size() == 1, "La cocina no terminó la comanda")

	kitchen.interact(player)
	_check(player.held_dishes.size() == 1, "El jugador no recogió el plato")
	first_table.interact(player)
	_check(GameManager.level_earnings > 0, "La entrega no registró ingresos")

	var second_table = tables[1]
	second_table._spawn_customer()
	second_table.interact(player)
	second_table._customer_leaves_angry()
	var orphan_found := false
	for order in kitchen.cooking_queue:
		orphan_found = orphan_found or order.get("table", -1) == second_table.table_number
	_check(not orphan_found, "La cocina conservó una comanda cancelada")

	await _finish(level)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _finish(level: Node) -> void:
	level.queue_free()
	await get_tree().process_frame
	if failures.is_empty():
		print("GAMEPLAY_SMOKE_TEST: PASS")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error("GAMEPLAY_SMOKE_TEST: " + message)
		get_tree().quit(1)
