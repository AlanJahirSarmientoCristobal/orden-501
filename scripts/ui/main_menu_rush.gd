extends Control

@onready var btn_play: Button = $CenterContainer/MainBox/Buttons/BtnPlay
@onready var btn_continue: Button = $CenterContainer/MainBox/Buttons/BtnContinue
@onready var btn_order: Button = $CenterContainer/MainBox/Buttons/BtnOrder501
@onready var btn_order_continue: Button = $CenterContainer/MainBox/Buttons/BtnOrderContinue
@onready var btn_levels: Button = $CenterContainer/MainBox/Buttons/BtnLevels
@onready var btn_tutorial: Button = $CenterContainer/MainBox/Buttons/BtnTutorial
@onready var btn_fullscreen: Button = $CenterContainer/MainBox/Buttons/BtnFullscreen
@onready var btn_quit: Button = $CenterContainer/MainBox/Buttons/BtnQuit

@onready var level_select_modal: PanelContainer = $LevelSelectModal
@onready var tutorial_modal: PanelContainer = $TutorialModal
@onready var difficulty_modal: PanelContainer = $DifficultyModal

@onready var btn_lvl_1: Button = $LevelSelectModal/Margin/VBox/Grid/BtnLvl1
@onready var btn_lvl_2: Button = $LevelSelectModal/Margin/VBox/Grid/BtnLvl2
@onready var btn_lvl_3: Button = $LevelSelectModal/Margin/VBox/Grid/BtnLvl3
@onready var btn_close_levels: Button = $LevelSelectModal/Margin/VBox/BtnCloseLevels
@onready var btn_close_tutorial: Button = $TutorialModal/Margin/VBox/BtnCloseTutorial
@onready var btn_easy: Button = $DifficultyModal/Margin/VBox/BtnEasy
@onready var btn_normal: Button = $DifficultyModal/Margin/VBox/BtnNormal
@onready var btn_hard: Button = $DifficultyModal/Margin/VBox/BtnHard
@onready var btn_close_difficulty: Button = $DifficultyModal/Margin/VBox/BtnClose
@onready var difficulty_help: Label = $DifficultyModal/Margin/VBox/Help

var pending_mode := "exploration"

func _ready() -> void:
	level_select_modal.visible = false
	tutorial_modal.visible = false
	difficulty_modal.visible = false
	
	btn_play.pressed.connect(_on_play_pressed)
	btn_continue.pressed.connect(_on_continue_pressed)
	btn_order.pressed.connect(_on_order_pressed)
	btn_order_continue.pressed.connect(_on_order_continue_pressed)
	btn_levels.pressed.connect(_on_levels_pressed)
	btn_tutorial.pressed.connect(_on_tutorial_pressed)
	btn_fullscreen.pressed.connect(_on_fullscreen_pressed)
	btn_quit.pressed.connect(_on_quit_pressed)
	btn_continue.visible = MissionManager.has_save()
	btn_order_continue.visible = BusinessManager.has_save()
	
	btn_lvl_1.pressed.connect(func(): _load_jornada(1))
	btn_lvl_2.pressed.connect(func(): _load_jornada(2))
	btn_lvl_3.pressed.connect(func(): _load_jornada(3))
	btn_easy.pressed.connect(func(): _start_campaign("easy"))
	btn_normal.pressed.connect(func(): _start_campaign("normal"))
	btn_hard.pressed.connect(func(): _start_campaign("hard"))
	btn_close_difficulty.pressed.connect(func(): difficulty_modal.visible = false)
	
	btn_close_levels.pressed.connect(func():
		AudioManager.play_sfx_click()
		level_select_modal.visible = false
	)
	btn_close_tutorial.pressed.connect(func():
		AudioManager.play_sfx_click()
		tutorial_modal.visible = false
	)

func _on_play_pressed() -> void:
	AudioManager.play_sfx_click()
	pending_mode = "exploration"
	difficulty_help.text = "Selecciona la dificultad para la campaña de exploración."
	difficulty_modal.visible = true

func _on_order_pressed() -> void:
	AudioManager.play_sfx_click()
	pending_mode = "management"
	difficulty_help.text = "Afecta inventario inicial, proveedor, metas, tiempo y presión operativa."
	difficulty_modal.visible = true

func _start_campaign(selected_difficulty: String) -> void:
	AudioManager.play_sfx_click()
	difficulty_modal.visible = false
	if pending_mode == "management":
		BusinessManager.begin_campaign(selected_difficulty)
		GameManager.change_scene_smooth("res://scenes/levels/jornada_1.tscn")
		return
	BusinessManager.leave_management_mode()
	MissionManager.new_game(selected_difficulty)
	GameManager.change_scene_smooth("res://scenes/world/main_hub.tscn")

func _on_continue_pressed() -> void:
	AudioManager.play_sfx_click()
	BusinessManager.leave_management_mode()
	if MissionManager.load_game():
		var scenes = {"hub":"main_hub","market":"market_district","stadium":"stadium_district","park":"park_district","industrial":"industrial_district"}
		var scene_name: String = scenes.get(MissionManager.current_map, "main_hub")
		GameManager.change_scene_smooth("res://scenes/world/%s.tscn" % scene_name)

func _on_order_continue_pressed() -> void:
	AudioManager.play_sfx_click()
	if BusinessManager.load_game():
		if BusinessManager.completed_level >= 3:
			GameManager.change_scene_smooth("res://scenes/ui/victory_championship.tscn")
		else:
			GameManager.change_scene_smooth("res://scenes/levels/jornada_%d.tscn" % (BusinessManager.completed_level + 1))

func _on_levels_pressed() -> void:
	AudioManager.play_sfx_click()
	level_select_modal.visible = true

func _on_tutorial_pressed() -> void:
	AudioManager.play_sfx_click()
	tutorial_modal.visible = true

func _on_fullscreen_pressed() -> void:
	AudioManager.play_sfx_click()
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _on_quit_pressed() -> void:
	AudioManager.play_sfx_click()
	get_tree().quit()

func _load_jornada(num: int) -> void:
	AudioManager.play_sfx_click()
	level_select_modal.visible = false
	MissionManager.campaign_started = false
	BusinessManager.leave_management_mode()
	GameManager.reset_season()
	GameManager.return_to_hub_after_level = false
	GameManager.change_scene_smooth("res://scenes/levels/jornada_%d.tscn" % num)
