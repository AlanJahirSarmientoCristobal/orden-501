extends Node2D

const ACTIVITY_SCENE = preload("res://scenes/world/activity_spot.tscn")
const OBJECTIVE_CATALOG = preload("res://scripts/world/world_objective_catalog.gd")

@onready var player: CharacterBody2D = $WorldPlayer
@onready var objective_markers: Node2D = $ObjectiveMarkers
@onready var coins_label: Label = $HUD/TopBar/Margin/HBox/Coins
@onready var reputation_label: Label = $HUD/TopBar/Margin/HBox/Reputation
@onready var level_label: Label = $HUD/TopBar/Margin/HBox/Level
@onready var time_label: Label = $HUD/TopBar/Margin/HBox/Time
@onready var mission_title: Label = $HUD/MissionPanel/Margin/VBox/Title
@onready var mission_description: Label = $HUD/MissionPanel/Margin/VBox/Description
@onready var mission_progress: Label = $HUD/MissionPanel/Margin/VBox/Progress
@onready var notification_panel: PanelContainer = $HUD/Notification
@onready var notification_label: Label = $HUD/Notification/Margin/Label
@onready var pause_overlay: Control = $PauseLayer/PauseOverlay
@onready var pause_menu_button: Button = $PauseLayer/PauseOverlay/BtnMenu
@onready var day_overlay: ColorRect = $DayLayer/DayOverlay
@onready var trivia_panel: PanelContainer = $HUD/TriviaPanel
@onready var trivia_question: Label = $HUD/TriviaPanel/Margin/VBox/Question
@onready var trivia_buttons: Array[Button] = [$HUD/TriviaPanel/Margin/VBox/Option0, $HUD/TriviaPanel/Margin/VBox/Option1, $HUD/TriviaPanel/Margin/VBox/Option2]

var autosave_timer := 0.0
var notification_version := 0
var trivia_answer := 0

const TRIVIA_QUESTIONS: Array[Dictionary] = [
	{"q":"¿Cuántos jugadores tiene un equipo de fútbol en el campo?", "a":["9", "11", "13"], "correct":1},
	{"q":"¿Qué tarjeta expulsa a un jugador del partido?", "a":["Azul", "Amarilla", "Roja"], "correct":2},
	{"q":"¿Cuántos minutos dura un partido reglamentario?", "a":["80", "90", "100"], "correct":1},
	{"q":"¿Cómo se llama marcar tres goles en un partido?", "a":["Hat-trick", "Grand slam", "Triple doble"], "correct":0},
	{"q":"¿Desde dónde se cobra un penal?", "a":["El círculo central", "El punto penal", "La esquina"], "correct":1}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hub_controller")
	add_to_group("world_controller")
	if not MissionManager.campaign_started:
		if not MissionManager.load_game():
			MissionManager.new_game()
	MissionManager.current_map = "hub"
	player.position = MissionManager.get_map_position("hub", Vector2(1280, 720))
	notification_panel.visible = false
	pause_overlay.visible = false
	trivia_panel.visible = false
	MissionManager.mission_changed.connect(_on_mission_changed)
	MissionManager.mission_progress_changed.connect(_on_mission_progress)
	MissionManager.notification_requested.connect(_show_notification)
	GameManager.coins_changed.connect(_on_coins_changed)
	pause_menu_button.pressed.connect(_return_to_menu)
	for index in range(trivia_buttons.size()):
		trivia_buttons[index].pressed.connect(_answer_trivia.bind(index))
	_refresh_objectives()
	_update_hud()
	_show_notification("Bienvenido al Barrio 501 · Explora, trabaja y completa misiones")

func _process(delta: float) -> void:
	if not get_tree().paused:
		MissionManager.advance_time(delta)
		autosave_timer += delta
		if autosave_timer >= 15.0:
			autosave_timer = 0.0
			_save_position()
	_update_clock_and_light()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		pause_overlay.visible = get_tree().paused
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if is_instance_valid(player):
		_save_position()

func _save_position() -> void:
	MissionManager.current_map = "hub"
	MissionManager.set_map_position("hub", player.position)
	MissionManager.save_game()

func warp_to(target_scene: String, target_map: String, target_position: Vector2) -> void:
	if target_scene.is_empty():
		return
	_save_position()
	MissionManager.current_map = target_map
	MissionManager.set_map_position(target_map, target_position)
	MissionManager.save_game()
	GameManager.change_scene_smooth(target_scene)

func _return_to_menu() -> void:
	_save_position()
	get_tree().paused = false
	GameManager.change_scene_smooth("res://scenes/menu/main_menu_rush.tscn")

func open_trivia() -> void:
	if int(MissionManager.daily_completed.get("stadium_trivia", -1)) == MissionManager.day:
		MissionManager.notification_requested.emit("La trivia deportiva volverá mañana.")
		return
	var question = TRIVIA_QUESTIONS.pick_random()
	trivia_question.text = question["q"]
	trivia_answer = int(question["correct"])
	for index in range(trivia_buttons.size()):
		trivia_buttons[index].text = question["a"][index]
	trivia_panel.visible = true
	get_tree().paused = true

func _answer_trivia(index: int) -> void:
	trivia_panel.visible = false
	get_tree().paused = false
	if index == trivia_answer:
		MissionManager.claim_daily("stadium_trivia", 60)
	else:
		MissionManager.notification_requested.emit("Respuesta incorrecta. Puedes volver a intentarlo.")

func _refresh_objectives() -> void:
	for child in objective_markers.get_children():
		child.queue_free()
	var mission = MissionManager.get_active_mission()
	if mission.is_empty():
		return
	var event_id: String = mission["event"]
	if event_id == "restaurant_shift":
		return
	var locations: Array[Dictionary] = OBJECTIVE_CATALOG.get_locations(event_id)
	for location in locations:
		if location["map"] != "hub" or MissionManager.mission_collected.has(location["id"]):
			continue
		var spot = ACTIVITY_SCENE.instantiate()
		spot.position = location["position"]
		spot.action = "mission"
		spot.event_id = event_id
		spot.objective_id = location["id"]
		spot.display_name = _objective_name(event_id)
		spot.details = mission["description"]
		spot.icon_type = _objective_icon(event_id)
		objective_markers.add_child(spot)

func _objective_name(event_id: String) -> String:
	return {
		"talk_sofia":"Hablar con Sofía", "visit_zone":"Descubrir zona",
		"market_supply":"Recoger suministro", "fan_interview":"Entrevistar aficionado",
		"park_checkpoint":"Punto de entrenamiento", "screen_part":"Componente electrónico",
		"delivery_stop":"Entregar pedido", "promo_poster":"Colocar cartel",
		"vip_invite":"Entregar invitación VIP"
	}.get(event_id, "Objetivo de misión")

func _objective_icon(event_id: String) -> int:
	return {
		"talk_sofia":0, "visit_zone":2, "market_supply":1, "fan_interview":0,
		"park_checkpoint":2, "screen_part":4, "delivery_stop":5,
		"promo_poster":3, "vip_invite":4
	}.get(event_id, 0)

func _on_mission_changed(_mission: Dictionary) -> void:
	call_deferred("_refresh_objectives")
	call_deferred("_update_hud")

func _on_mission_progress(_progress: int, _goal: int) -> void:
	call_deferred("_refresh_objectives")
	_update_hud()

func _on_coins_changed(_amount: int) -> void:
	_update_hud()

func _update_hud() -> void:
	coins_label.text = "💰 $%d" % GameManager.coins
	reputation_label.text = "★ REP %d" % GameManager.campaign_reputation
	level_label.text = "NIVEL %d · XP %d/%d" % [MissionManager.player_level, MissionManager.experience, MissionManager.player_level * 100]
	var mission = MissionManager.get_active_mission()
	if mission.is_empty():
		mission_title.text = "🏆 CAMPAÑA COMPLETADA"
		mission_description.text = "La 501 ya es una leyenda. Las actividades del barrio siguen disponibles cada día."
		mission_progress.text = "Exploración libre"
	else:
		mission_title.text = "MISIÓN: " + str(mission["title"])
		mission_description.text = mission["description"]
		var adjusted_reward = int(round(float(mission["coins"]) * MissionManager.get_reward_multiplier()))
		mission_progress.text = "Progreso: %d/%d | %s | Recompensa: $%d / %d REP" % [MissionManager.mission_progress, MissionManager.get_current_goal(), MissionManager.get_difficulty_label(), adjusted_reward, mission["rep"]]

func _update_clock_and_light() -> void:
	var total_minutes = int(MissionManager.minute_of_day)
	var hour = total_minutes / 60
	var minute = total_minutes % 60
	time_label.text = "DÍA %d · %02d:%02d" % [MissionManager.day, hour, minute]
	var night_strength := 0.0
	if hour < 6:
		night_strength = 0.48
	elif hour < 8:
		night_strength = lerp(0.48, 0.0, (hour - 6.0) / 2.0)
	elif hour >= 20:
		night_strength = lerp(0.0, 0.48, min(1.0, (hour - 20.0) / 3.0))
	day_overlay.color = Color(0.02, 0.06, 0.18, night_strength)

func _show_notification(message: String) -> void:
	notification_version += 1
	var version = notification_version
	notification_label.text = message
	notification_panel.modulate.a = 1.0
	notification_panel.visible = true
	await get_tree().create_timer(3.2, true).timeout
	if version != notification_version:
		return
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(notification_panel, "modulate:a", 0.0, 0.3)
	await tween.finished
	if version == notification_version:
		notification_panel.visible = false
