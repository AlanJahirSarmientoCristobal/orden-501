extends Node

signal mission_changed(mission: Dictionary)
signal mission_progress_changed(progress: int, goal: int)
signal notification_requested(message: String)
signal time_changed(day: int, minute_of_day: float)

const SAVE_PATH := "user://la501_campaign.json"

const MISSIONS: Array[Dictionary] = [
	{"id":"welcome", "title":"Bienvenido al Barrio 501", "description":"Habla con Sofía en la plaza central.", "event":"talk_sofia", "goal":1, "scalable":false, "coins":40, "rep":4, "xp":35},
	{"id":"explore", "title":"Reconoce el territorio", "description":"Viaja entre distritos y documenta lugares importantes.", "event":"visit_zone", "goal":8, "scalable":true, "coins":120, "rep":6, "xp":90},
	{"id":"pantry", "title":"La despensa vacía", "description":"Busca suministros entre el mercado y la zona industrial.", "event":"market_supply", "goal":12, "scalable":true, "coins":180, "rep":7, "xp":120},
	{"id":"first_shift", "title":"Primer turno", "description":"Completa un turno de servicio en La 501.", "event":"restaurant_shift", "goal":1, "scalable":false, "coins":160, "rep":8, "xp":110},
	{"id":"fans", "title":"La voz de la afición", "description":"Entrevista aficionados en varios distritos.", "event":"fan_interview", "goal":12, "scalable":true, "coins":210, "rep":9, "xp":130},
	{"id":"training", "title":"Circuito metropolitano", "description":"Completa puntos de entrenamiento en parque y estadio.", "event":"park_checkpoint", "goal":16, "scalable":true, "coins":240, "rep":8, "xp":150},
	{"id":"screens", "title":"Pantallas fuera de línea", "description":"Recupera componentes dispersos por dos mapas.", "event":"screen_part", "goal":12, "scalable":true, "coins":260, "rep":9, "xp":160},
	{"id":"delivery", "title":"Reparto metropolitano", "description":"Entrega pedidos cruzando todos los distritos.", "event":"delivery_stop", "goal":16, "scalable":true, "coins":320, "rep":10, "xp":190},
	{"id":"league_shift", "title":"Noche de liguilla", "description":"Supera el segundo turno especial del restaurante.", "event":"restaurant_shift", "goal":1, "scalable":false, "coins":280, "rep":11, "xp":180},
	{"id":"posters", "title":"Campaña del campeonato", "description":"Coloca publicidad en los cinco mapas del juego.", "event":"promo_poster", "goal":18, "scalable":true, "coins":340, "rep":11, "xp":200},
	{"id":"vip", "title":"Invitados de honor", "description":"Localiza y entrega invitaciones a aficionados VIP.", "event":"vip_invite", "goal":12, "scalable":true, "coins":360, "rep":12, "xp":210},
	{"id":"supplier", "title":"Proveedor estrella", "description":"Reúne productos especiales en mercado e industria.", "event":"market_supply", "goal":18, "scalable":true, "coins":420, "rep":12, "xp":230},
	{"id":"marathon", "title":"Maratón del campeonato", "description":"Supera el circuito largo del parque y el estadio.", "event":"park_checkpoint", "goal":24, "scalable":true, "coins":480, "rep":14, "xp":260},
	{"id":"final_shift", "title":"La Gran Final", "description":"Supera el turno definitivo del Restaurante La 501.", "event":"restaurant_shift", "goal":1, "scalable":false, "coins":550, "rep":16, "xp":300},
	{"id":"finale", "title":"Leyenda de La 501", "description":"Regresa con Sofía para celebrar la temporada.", "event":"talk_sofia", "goal":1, "scalable":false, "coins":750, "rep":20, "xp":400}
]

var active_mission_index: int = 0
var mission_progress: int = 0
var day: int = 1
var minute_of_day: float = 480.0
var player_level: int = 1
var experience: int = 0
var player_position := Vector2(1280, 720)
var campaign_started := false
var daily_completed: Dictionary = {}
var difficulty: String = "normal"
var mission_collected: Array[String] = []
var current_map: String = "hub"
var map_positions: Dictionary = {"hub": Vector2(1280, 720)}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.level_finished.connect(_on_restaurant_level_finished)

func new_game(selected_difficulty: String = "normal") -> void:
	active_mission_index = 0
	mission_progress = 0
	day = 1
	minute_of_day = 480.0
	player_level = 1
	experience = 0
	player_position = Vector2(1280, 720)
	daily_completed = {}
	difficulty = selected_difficulty if selected_difficulty in ["easy", "normal", "hard"] else "normal"
	mission_collected = []
	current_map = "hub"
	map_positions = {"hub": Vector2(1280, 720)}
	campaign_started = true
	GameManager.reset_season()
	GameManager.campaign_reputation = 0
	save_game()
	mission_changed.emit(get_active_mission())

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if not data is Dictionary:
		return false
	active_mission_index = int(data.get("mission", 0))
	mission_progress = int(data.get("progress", 0))
	mission_collected.assign(data.get("collected", []))
	difficulty = str(data.get("difficulty", "normal"))
	current_map = str(data.get("current_map", "hub"))
	day = int(data.get("day", 1))
	minute_of_day = float(data.get("time", 480.0))
	player_level = int(data.get("level", 1))
	experience = int(data.get("xp", 0))
	GameManager.coins = int(data.get("coins", 0))
	GameManager.campaign_reputation = int(data.get("reputation", 0))
	GameManager.upgrade_speed_level = int(data.get("upgrade_speed", 0))
	GameManager.upgrade_inventory_capacity = int(data.get("upgrade_tray", 3))
	GameManager.upgrade_chef_speed_multiplier = float(data.get("upgrade_chef", 1.0))
	GameManager.upgrade_datapad_cooldown = float(data.get("upgrade_scanner", 20.0))
	var position_data = data.get("position", [1280.0, 720.0])
	player_position = Vector2(float(position_data[0]), float(position_data[1]))
	map_positions = {}
	for map_id in data.get("map_positions", {}).keys():
		var saved_position = data["map_positions"][map_id]
		map_positions[map_id] = Vector2(float(saved_position[0]), float(saved_position[1]))
	if not map_positions.has("hub"):
		map_positions["hub"] = player_position
	daily_completed = data.get("daily_completed", {})
	campaign_started = true
	GameManager.coins_changed.emit(GameManager.coins)
	return true

func save_game() -> void:
	if not campaign_started:
		return
	var serialized_positions := {}
	for map_id in map_positions:
		var map_position: Vector2 = map_positions[map_id]
		serialized_positions[map_id] = [map_position.x, map_position.y]
	var data = {
		"mission": active_mission_index, "progress": mission_progress,
		"collected": mission_collected, "difficulty": difficulty,
		"current_map": current_map, "map_positions": serialized_positions,
		"day": day, "time": minute_of_day, "level": player_level, "xp": experience,
		"coins": GameManager.coins, "reputation": GameManager.campaign_reputation,
		"position": [player_position.x, player_position.y],
		"daily_completed": daily_completed,
		"upgrade_speed": GameManager.upgrade_speed_level,
		"upgrade_tray": GameManager.upgrade_inventory_capacity,
		"upgrade_chef": GameManager.upgrade_chef_speed_multiplier,
		"upgrade_scanner": GameManager.upgrade_datapad_cooldown
	}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

func get_active_mission() -> Dictionary:
	if active_mission_index >= MISSIONS.size():
		return {}
	return MISSIONS[active_mission_index]

func report_event(event_id: String, amount: int = 1, objective_id: String = "") -> bool:
	var mission = get_active_mission()
	if mission.is_empty() or mission["event"] != event_id:
		return false
	if objective_id != "":
		if mission_collected.has(objective_id):
			return false
		mission_collected.append(objective_id)
		mission_progress = mission_collected.size()
	else:
		mission_progress += amount
	var goal = get_current_goal()
	mission_progress = min(goal, mission_progress)
	mission_progress_changed.emit(mission_progress, goal)
	if mission_progress >= goal:
		_complete_current_mission(mission)
	else:
		notification_requested.emit("%s · %d/%d" % [mission["title"], mission_progress, goal])
	save_game()
	return true

func _complete_current_mission(mission: Dictionary) -> void:
	var coin_reward = int(round(float(mission["coins"]) * get_reward_multiplier()))
	GameManager.coins += coin_reward
	GameManager.campaign_reputation = min(100, GameManager.campaign_reputation + int(mission["rep"]))
	_add_experience(int(mission["xp"]))
	GameManager.coins_changed.emit(GameManager.coins)
	notification_requested.emit("MISIÓN COMPLETADA: %s  ·  +$%d  +%d REP" % [mission["title"], coin_reward, mission["rep"]])
	active_mission_index += 1
	mission_progress = 0
	mission_collected = []
	mission_changed.emit(get_active_mission())

func _add_experience(amount: int) -> void:
	experience += amount
	var needed = player_level * 100
	while experience >= needed:
		experience -= needed
		player_level += 1
		needed = player_level * 100
		notification_requested.emit("¡NIVEL %d ALCANZADO!" % player_level)

func advance_time(delta: float) -> void:
	minute_of_day += delta * 2.0
	if minute_of_day >= 1440.0:
		minute_of_day -= 1440.0
		day += 1
	time_changed.emit(day, minute_of_day)

func get_restaurant_level() -> int:
	var mission_id: String = get_active_mission().get("id", "")
	if mission_id == "league_shift":
		return 2
	if mission_id == "final_shift":
		return 3
	return 1

func get_current_goal() -> int:
	var mission = get_active_mission()
	if mission.is_empty():
		return 0
	if not bool(mission.get("scalable", true)):
		return int(mission["goal"])
	return int(ceil(float(mission["goal"]) * get_objective_multiplier()))

func get_objective_multiplier() -> float:
	return {"easy":0.7, "normal":1.0, "hard":1.5}.get(difficulty, 1.0)

func get_reward_multiplier() -> float:
	return {"easy":1.2, "normal":1.0, "hard":0.82}.get(difficulty, 1.0)

func get_restaurant_target_multiplier() -> float:
	return {"easy":0.78, "normal":1.0, "hard":1.28}.get(difficulty, 1.0)

func get_restaurant_time_multiplier() -> float:
	return {"easy":1.25, "normal":1.0, "hard":0.88}.get(difficulty, 1.0)

func get_patience_multiplier() -> float:
	return {"easy":1.35, "normal":1.0, "hard":0.75}.get(difficulty, 1.0)

func get_cooking_multiplier() -> float:
	return {"easy":0.82, "normal":1.0, "hard":1.18}.get(difficulty, 1.0)

func get_difficulty_label() -> String:
	return {"easy":"FÁCIL", "normal":"NORMAL", "hard":"DIFÍCIL"}.get(difficulty, "NORMAL")

func set_map_position(map_id: String, position: Vector2) -> void:
	map_positions[map_id] = position
	if map_id == "hub":
		player_position = position

func get_map_position(map_id: String, fallback: Vector2) -> Vector2:
	return map_positions.get(map_id, fallback)

func claim_daily(activity_id: String, reward: int) -> bool:
	if int(daily_completed.get(activity_id, -1)) == day:
		notification_requested.emit("Esta actividad volverá a estar disponible mañana.")
		return false
	daily_completed[activity_id] = day
	var adjusted_reward = int(round(float(reward) * get_reward_multiplier()))
	GameManager.coins += adjusted_reward
	GameManager.coins_changed.emit(GameManager.coins)
	notification_requested.emit("Actividad diaria completada · +$%d" % adjusted_reward)
	save_game()
	return true

func _on_restaurant_level_finished(success: bool, _coins_gained: int) -> void:
	if success and GameManager.return_to_hub_after_level:
		report_event("restaurant_shift")
