extends Node

const SAVE_PATH := "user://la501_campaign.json"
var failures: Array[String] = []
var save_existed := false
var saved_text := ""
var original_state: Dictionary

func _ready() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	_backup_state()
	MissionManager.active_mission_index = 0
	MissionManager.mission_progress = 0
	MissionManager.day = 1
	MissionManager.minute_of_day = 480.0
	MissionManager.player_level = 1
	MissionManager.experience = 0
	MissionManager.player_position = Vector2(1275, 760)
	MissionManager.daily_completed = {}
	MissionManager.difficulty = "normal"
	MissionManager.mission_collected = []
	MissionManager.current_map = "hub"
	MissionManager.map_positions = {"hub":Vector2(1275,760)}
	MissionManager.campaign_started = true
	GameManager.coins = 0
	GameManager.campaign_reputation = 0

	var hub = load("res://scenes/world/main_hub.tscn").instantiate()
	add_child(hub)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(get_tree().get_first_node_in_group("player") != null, "El mapa no creó al jugador")
	_check(get_tree().get_nodes_in_group("world_interactable").size() >= 6, "Faltan actividades del mapa")

	var mission_spot: Node
	for spot in hub.get_node("ObjectiveMarkers").get_children():
		if spot.event_id == "talk_sofia":
			mission_spot = spot
			break
	_check(mission_spot != null, "No apareció el primer objetivo")
	if mission_spot:
		mission_spot.interact(hub.get_node("WorldPlayer"))
		await get_tree().process_frame
		await get_tree().process_frame
		_check(MissionManager.active_mission_index == 1, "La misión inicial no avanzó")
		_check(hub.get_node("ObjectiveMarkers").get_child_count() == 2, "La misión de exploración no repartió sus objetivos del centro")

	var district_scenes = ["market_district", "stadium_district", "park_district", "industrial_district"]
	for scene_name in district_scenes:
		var packed: PackedScene = load("res://scenes/world/%s.tscn" % scene_name)
		_check(packed != null, "No se pudo cargar el distrito " + scene_name)

	MissionManager.active_mission_index = 1
	MissionManager.mission_progress = 0
	MissionManager.mission_collected = []
	MissionManager.difficulty = "easy"
	var easy_goal = MissionManager.get_current_goal()
	MissionManager.difficulty = "hard"
	var hard_goal = MissionManager.get_current_goal()
	_check(easy_goal < hard_goal, "La dificultad no cambia la cantidad de objetivos")
	MissionManager.difficulty = "normal"
	_check(MissionManager.report_event("visit_zone", 1, "unique_test"), "No aceptó un objetivo único")
	_check(not MissionManager.report_event("visit_zone", 1, "unique_test"), "Un objetivo único se pudo repetir")
	_check(MissionManager.mission_progress == 1, "El objetivo repetido alteró el progreso")

	MissionManager.active_mission_index = 3
	MissionManager.mission_progress = 0
	MissionManager.mission_collected = []
	GameManager.return_to_hub_after_level = true
	GameManager.level_finished.emit(true, 250)
	_check(MissionManager.active_mission_index == 4, "El turno de restaurante no completó su misión de campaña")
	GameManager.return_to_hub_after_level = false

	while MissionManager.active_mission_index < MissionManager.MISSIONS.size():
		var mission = MissionManager.get_active_mission()
		var previous_index = MissionManager.active_mission_index
		MissionManager.report_event(mission["event"], MissionManager.get_current_goal())
		_check(MissionManager.active_mission_index == previous_index + 1, "No avanzó la misión " + str(mission["id"]))
	_check(MissionManager.get_active_mission().is_empty(), "La campaña no alcanzó su estado final")

	var coins_before = GameManager.coins
	_check(MissionManager.claim_daily("test_job", 25), "La actividad diaria no entregó recompensa")
	_check(not MissionManager.claim_daily("test_job", 25), "La actividad diaria pudo cobrarse dos veces")
	_check(GameManager.coins == coins_before + 25, "La recompensa diaria fue incorrecta")

	hub.queue_free()
	await get_tree().process_frame
	_restore_state()
	if failures.is_empty():
		print("CAMPAIGN_SMOKE_TEST: PASS")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error("CAMPAIGN_SMOKE_TEST: " + message)
		get_tree().quit(1)

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

func _backup_state() -> void:
	save_existed = FileAccess.file_exists(SAVE_PATH)
	if save_existed:
		saved_text = FileAccess.get_file_as_string(SAVE_PATH)
	original_state = {
		"mission": MissionManager.active_mission_index, "progress": MissionManager.mission_progress,
		"day": MissionManager.day, "time": MissionManager.minute_of_day,
		"level": MissionManager.player_level, "xp": MissionManager.experience,
		"position": MissionManager.player_position, "daily": MissionManager.daily_completed.duplicate(true),
		"difficulty": MissionManager.difficulty, "collected": MissionManager.mission_collected.duplicate(),
		"current_map": MissionManager.current_map, "map_positions": MissionManager.map_positions.duplicate(true),
		"started": MissionManager.campaign_started, "coins": GameManager.coins,
		"reputation": GameManager.campaign_reputation,
		"return_to_hub": GameManager.return_to_hub_after_level
	}

func _restore_state() -> void:
	MissionManager.active_mission_index = original_state["mission"]
	MissionManager.mission_progress = original_state["progress"]
	MissionManager.day = original_state["day"]
	MissionManager.minute_of_day = original_state["time"]
	MissionManager.player_level = original_state["level"]
	MissionManager.experience = original_state["xp"]
	MissionManager.player_position = original_state["position"]
	MissionManager.daily_completed = original_state["daily"]
	MissionManager.difficulty = original_state["difficulty"]
	MissionManager.mission_collected.assign(original_state["collected"])
	MissionManager.current_map = original_state["current_map"]
	MissionManager.map_positions = original_state["map_positions"]
	MissionManager.campaign_started = original_state["started"]
	GameManager.coins = original_state["coins"]
	GameManager.campaign_reputation = original_state["reputation"]
	GameManager.return_to_hub_after_level = original_state["return_to_hub"]
	if save_existed:
		var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
		file.store_string(saved_text)
	elif FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
