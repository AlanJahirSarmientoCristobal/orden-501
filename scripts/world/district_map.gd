extends Node2D

const PLAYER_SCENE = preload("res://scenes/world/world_player.tscn")
const ACTIVITY_SCENE = preload("res://scenes/world/activity_spot.tscn")
const OBJECTIVE_CATALOG = preload("res://scripts/world/world_objective_catalog.gd")

@export_enum("market", "stadium", "park", "industrial") var map_id: String = "market"
@export var display_name: String = "Distrito"
@export var default_spawn := Vector2(1280, 720)

var player: CharacterBody2D
var objective_markers: Node2D
var mission_label: Label
var stats_label: Label
var notification_panel: PanelContainer
var notification_label: Label
var pause_overlay: ColorRect
var autosave_timer := 0.0
var notification_version := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("world_controller")
	if not MissionManager.campaign_started and not MissionManager.load_game():
		MissionManager.new_game()
	MissionManager.current_map = map_id
	_build_world()
	_build_hud()
	player.position = MissionManager.get_map_position(map_id, default_spawn)
	MissionManager.mission_changed.connect(_on_mission_changed)
	MissionManager.mission_progress_changed.connect(_on_progress_changed)
	MissionManager.notification_requested.connect(_show_notification)
	GameManager.coins_changed.connect(_on_coins_changed)
	_refresh_objectives()
	_update_hud()
	_show_notification("Llegaste a %s | Los portales conectan todos los distritos" % display_name)

func _process(delta: float) -> void:
	if not get_tree().paused:
		player.position.x = clamp(player.position.x, 55.0, 2505.0)
		player.position.y = clamp(player.position.y, 55.0, 1385.0)
		MissionManager.advance_time(delta)
		autosave_timer += delta
		if autosave_timer >= 15.0:
			autosave_timer = 0.0
			_save_position()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_tree().paused = not get_tree().paused
		pause_overlay.visible = get_tree().paused
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	if is_instance_valid(player):
		_save_position()

func _build_world() -> void:
	objective_markers = Node2D.new()
	objective_markers.name = "ObjectiveMarkers"
	add_child(objective_markers)
	player = PLAYER_SCENE.instantiate()
	player.name = "WorldPlayer"
	add_child(player)
	for portal in _portal_definitions():
		var spot = ACTIVITY_SCENE.instantiate()
		spot.position = portal["position"]
		spot.action = "warp"
		spot.display_name = "Viajar a " + portal["label"]
		spot.details = "Zona de traslado"
		spot.icon_type = 6
		spot.target_scene = portal["scene"]
		spot.target_map = portal["map"]
		spot.target_position = portal["spawn"]
		add_child(spot)
	var job = ACTIVITY_SCENE.instantiate()
	job.position = Vector2(2250, 1180)
	job.action = "repeatable"
	job.event_id = map_id + "_daily"
	job.display_name = "Trabajo diario: " + display_name
	job.details = "Una fuente adicional de recursos, disponible cada día."
	job.repeatable_reward = {"market":45,"stadium":50,"park":40,"industrial":60}.get(map_id,45)
	job.icon_type = 1
	add_child(job)

func _build_hud() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 20
	add_child(canvas)
	var top = PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 16
	top.offset_top = 12
	top.offset_right = -16
	top.offset_bottom = 62
	canvas.add_child(top)
	var top_margin = MarginContainer.new()
	top_margin.add_theme_constant_override("margin_left",16)
	top_margin.add_theme_constant_override("margin_right",16)
	top.add_child(top_margin)
	stats_label = Label.new()
	stats_label.add_theme_font_size_override("font_size",16)
	top_margin.add_child(stats_label)
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-440,78)
	panel.size = Vector2(420,132)
	canvas.add_child(panel)
	var mission_margin = MarginContainer.new()
	mission_margin.add_theme_constant_override("margin_left",14)
	mission_margin.add_theme_constant_override("margin_top",10)
	mission_margin.add_theme_constant_override("margin_right",14)
	mission_margin.add_theme_constant_override("margin_bottom",10)
	panel.add_child(mission_margin)
	mission_label = Label.new()
	mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_label.add_theme_font_size_override("font_size",14)
	mission_margin.add_child(mission_label)
	notification_panel = PanelContainer.new()
	notification_panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	notification_panel.position = Vector2(-330,230)
	notification_panel.size = Vector2(660,58)
	canvas.add_child(notification_panel)
	var note_margin = MarginContainer.new()
	note_margin.add_theme_constant_override("margin_left",18)
	note_margin.add_theme_constant_override("margin_right",18)
	notification_panel.add_child(note_margin)
	notification_label = Label.new()
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note_margin.add_child(notification_label)
	pause_overlay = ColorRect.new()
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.color = Color(0.02,0.03,0.06,0.9)
	pause_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	canvas.add_child(pause_overlay)
	var pause_text = Label.new()
	pause_text.text = "PAUSA\n\nESC para continuar\nEspacio = interactuar"
	pause_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_text.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_text.add_theme_font_size_override("font_size",28)
	pause_overlay.add_child(pause_text)
	var menu_button = Button.new()
	menu_button.text = "Guardar y volver al menú"
	menu_button.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	menu_button.position = Vector2(-130,-110)
	menu_button.size = Vector2(260,46)
	menu_button.pressed.connect(_return_to_menu)
	pause_overlay.add_child(menu_button)

func _portal_definitions() -> Array[Dictionary]:
	var portals: Array[Dictionary] = [{"position":Vector2(1280,120),"label":"Barrio 501","scene":"res://scenes/world/main_hub.tscn","map":"hub","spawn":Vector2(1280,720)}]
	match map_id:
		"market": portals.append({"position":Vector2(2390,720),"label":"Zona industrial","scene":"res://scenes/world/industrial_district.tscn","map":"industrial","spawn":Vector2(180,720)})
		"industrial": portals.append({"position":Vector2(170,720),"label":"Mercado","scene":"res://scenes/world/market_district.tscn","map":"market","spawn":Vector2(2380,720)})
		"stadium": portals.append({"position":Vector2(2390,720),"label":"Parque y ribera","scene":"res://scenes/world/park_district.tscn","map":"park","spawn":Vector2(180,720)})
		"park": portals.append({"position":Vector2(170,720),"label":"Estadio","scene":"res://scenes/world/stadium_district.tscn","map":"stadium","spawn":Vector2(2380,720)})
	return portals

func warp_to(target_scene: String, target_map: String, target_position: Vector2) -> void:
	_save_position()
	MissionManager.current_map = target_map
	MissionManager.set_map_position(target_map, target_position)
	MissionManager.save_game()
	GameManager.change_scene_smooth(target_scene)

func _return_to_menu() -> void:
	_save_position()
	get_tree().paused = false
	GameManager.change_scene_smooth("res://scenes/menu/main_menu_rush.tscn")

func _save_position() -> void:
	MissionManager.current_map = map_id
	MissionManager.set_map_position(map_id, player.position)
	MissionManager.save_game()

func _refresh_objectives() -> void:
	for child in objective_markers.get_children():
		child.queue_free()
	var mission = MissionManager.get_active_mission()
	if mission.is_empty() or mission["event"] == "restaurant_shift":
		return
	for location in OBJECTIVE_CATALOG.get_locations(mission["event"]):
		if location["map"] != map_id or MissionManager.mission_collected.has(location["id"]):
			continue
		var spot = ACTIVITY_SCENE.instantiate()
		spot.position = location["position"]
		spot.action = "mission"
		spot.event_id = mission["event"]
		spot.objective_id = location["id"]
		spot.display_name = _objective_name(mission["event"])
		spot.details = mission["description"]
		spot.icon_type = _objective_icon(mission["event"])
		objective_markers.add_child(spot)

func _objective_name(event_id: String) -> String:
	return {"talk_sofia":"Hablar con Sofía","visit_zone":"Descubrir lugar","market_supply":"Recoger suministro","fan_interview":"Entrevistar aficionado","park_checkpoint":"Punto de entrenamiento","screen_part":"Recuperar componente","delivery_stop":"Entregar pedido","promo_poster":"Colocar cartel","vip_invite":"Entregar invitación VIP"}.get(event_id,"Objetivo")

func _objective_icon(event_id: String) -> int:
	return {"visit_zone":2,"market_supply":1,"fan_interview":0,"park_checkpoint":2,"screen_part":4,"delivery_stop":5,"promo_poster":3,"vip_invite":4}.get(event_id,0)

func _update_hud() -> void:
	stats_label.text = "%s   |   $%d   |   REP %d   |   NIVEL %d   |   %s" % [display_name.to_upper(),GameManager.coins,GameManager.campaign_reputation,MissionManager.player_level,MissionManager.get_difficulty_label()]
	var mission = MissionManager.get_active_mission()
	if mission.is_empty():
		mission_label.text = "CAMPAÑA COMPLETADA\nExploración libre y trabajos diarios"
	else:
		mission_label.text = "%s\n%s\nProgreso: %d/%d" % [mission["title"],mission["description"],MissionManager.mission_progress,MissionManager.get_current_goal()]

func _on_mission_changed(_mission: Dictionary) -> void:
	call_deferred("_refresh_objectives")
	call_deferred("_update_hud")

func _on_progress_changed(_progress: int, _goal: int) -> void:
	call_deferred("_refresh_objectives")
	_update_hud()

func _on_coins_changed(_amount: int) -> void:
	_update_hud()

func _show_notification(message: String) -> void:
	notification_version += 1
	var version = notification_version
	notification_label.text = message
	notification_panel.modulate.a = 1.0
	notification_panel.visible = true
	await get_tree().create_timer(3.0,true).timeout
	if version != notification_version:
		return
	var tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(notification_panel,"modulate:a",0.0,0.3)
	await tween.finished
	if version == notification_version:
		notification_panel.visible = false
