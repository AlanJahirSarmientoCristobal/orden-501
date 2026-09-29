extends Node

const SAVE_PATH := "user://orden501_management.json"
var failures: Array[String] = []
var save_existed := false
var saved_text := ""

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	_backup_save()
	BusinessManager.begin_campaign("hard")
	_check(BusinessManager.management_mode,"No se activó el modo ORDEN 501")
	_check(BusinessManager.difficulty == "hard","No se conservó la dificultad")
	_check(GameManager.coins == 120,"El fondo inicial no es correcto")

	var level = load("res://scenes/levels/jornada_1.tscn").instantiate()
	add_child(level)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(level.get_node_or_null("ManagementPanel") != null,"No se creó el Panel de Gestión")
	_check(is_equal_approx(GameManager.max_match_time,127.5),"La dificultad no ajustó el tiempo del turno")
	_check(GameManager.current_target_coins == 360,"La dificultad no ajustó la meta de ventas")

	var kitchen = level.get_node("KitchenStation")
	var masa_before = int(BusinessManager.inventory["masa"])
	_check(kitchen.receive_order(GameManager.DISH_PIZZA,91),"La cocina rechazó una receta con inventario")
	_check(int(BusinessManager.inventory["masa"]) == masa_before - 2,"La receta no consumió ingredientes")
	BusinessManager.inventory["masa"] = 0
	_check(not kitchen.receive_order(GameManager.DISH_PIZZA,92),"La cocina preparó un plato sin insumos")
	_check(BusinessManager.stockout_events == 1,"No se registró el quiebre de stock")
	GameManager.coins = 200
	_check(BusinessManager.request_restock("masa"),"No se pudo solicitar al proveedor")
	_check(BusinessManager.restocks_in_transit.has("masa"),"El reabasto no quedó en tránsito")

	BusinessManager.begin_turn(2)
	_check(BusinessManager.assign_reservation("R-201",1),"No se confirmó una reservación válida")
	_check(not BusinessManager.assign_reservation("R-202",1),"Se permitió duplicar mesa y horario")
	_check(BusinessManager.reservation_errors == 1,"No se registró el error de reservación")

	BusinessManager.begin_turn(3)
	GameManager.coins = 200
	_check(BusinessManager.activate_promotion("social"),"No se activó la promoción de nivel 3")
	_check(BusinessManager.promotions_used == 1,"No se registró la promoción")
	BusinessManager.request_panel("report")
	await get_tree().process_frame
	_check(BusinessManager.panel_open,"El panel no respondió a la solicitud de apertura")

	GameManager.is_game_active = false
	level.queue_free()
	await get_tree().process_frame
	_restore_save()
	if failures.is_empty():
		print("BUSINESS_MANAGEMENT_SMOKE_TEST: PASS")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error("BUSINESS_MANAGEMENT_SMOKE_TEST: " + message)
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _backup_save() -> void:
	save_existed = FileAccess.file_exists(SAVE_PATH)
	if save_existed:
		saved_text = FileAccess.get_file_as_string(SAVE_PATH)

func _restore_save() -> void:
	if save_existed:
		var file = FileAccess.open(SAVE_PATH,FileAccess.WRITE)
		file.store_string(saved_text)
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
