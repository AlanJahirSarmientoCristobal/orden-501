extends CanvasLayer

@onready var panel: Control = $CenterContainer
@onready var result_title: Label = $CenterContainer/Panel/Margin/VBox/ResultHeader/Title
@onready var result_subtitle: Label = $CenterContainer/Panel/Margin/VBox/ResultHeader/Subtitle
@onready var coins_label: Label = $CenterContainer/Panel/Margin/VBox/CoinsBanner/CoinsText

@onready var btn_speed: Button = $CenterContainer/Panel/Margin/VBox/UpgradesGrid/CardSpeed/VBox/BtnBuy
@onready var btn_tray: Button = $CenterContainer/Panel/Margin/VBox/UpgradesGrid/CardTray/VBox/BtnBuy
@onready var btn_chef: Button = $CenterContainer/Panel/Margin/VBox/UpgradesGrid/CardChef/VBox/BtnBuy
@onready var btn_datapad: Button = $CenterContainer/Panel/Margin/VBox/UpgradesGrid/CardDatapad/VBox/BtnBuy

@onready var btn_next: Button = $CenterContainer/Panel/Margin/VBox/Actions/BtnNext
@onready var btn_retry: Button = $CenterContainer/Panel/Margin/VBox/Actions/BtnRetry
@onready var btn_menu: Button = $CenterContainer/Panel/Margin/VBox/Actions/BtnMenu

var last_success: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	
	GameManager.level_finished.connect(_on_level_finished)
	GameManager.coins_changed.connect(_update_coins)
	
	btn_speed.pressed.connect(func(): _buy("speed", 120, btn_speed))
	btn_tray.pressed.connect(func(): _buy("tray", 180, btn_tray))
	btn_chef.pressed.connect(func(): _buy("chef", 200, btn_chef))
	btn_datapad.pressed.connect(func(): _buy("datapad", 150, btn_datapad))
	
	btn_next.pressed.connect(_on_next_pressed)
	btn_retry.pressed.connect(_on_retry_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)

func _on_level_finished(success: bool, coins_gained: int) -> void:
	last_success = success
	get_tree().paused = true
	panel.visible = true
	_update_coins(GameManager.coins)
	
	if success:
		result_title.text = ("NIVEL %d SUPERADO · %s" % [GameManager.current_level,BusinessManager.get_level_title(GameManager.current_level)]) if BusinessManager.management_mode else ("🏆 ¡JORNADA %d SUPERADA!" % GameManager.current_level)
		result_title.add_theme_color_override("font_color", Color(1, 0.85, 0.2, 1))
		result_subtitle.text = "Ingresos de la jornada: $%d · Reputación final: %d%%" % [coins_gained, int(GameManager.reputation)]
		btn_next.visible = true
		btn_next.text = "Volver al Barrio 501" if GameManager.return_to_hub_after_level else "Siguiente Jornada"
		btn_retry.text = "↺ Repetir Jornada"
	else:
		result_title.text = "❌ JORNADA %d NO SUPERADA" % GameManager.current_level
		result_title.add_theme_color_override("font_color", Color(1, 0.3, 0.3, 1))
		var operational_reason = BusinessManager.get_failure_reason() if BusinessManager.management_mode else ""
		result_subtitle.text = (operational_reason + "\n" if operational_reason != "" else "") + "Ingresos: $%d/$%d · Reputación: %d%%" % [GameManager.level_earnings, GameManager.current_target_coins, int(GameManager.reputation)]
		btn_next.visible = false
		btn_retry.text = "↺ Reintentar Jornada"

func _update_coins(amount: int) -> void:
	coins_label.text = "💰 Fondo Disponible: $%d" % amount
	_check_buttons()

func _check_buttons() -> void:
	btn_speed.disabled = GameManager.coins < 120 or GameManager.upgrade_speed_level >= 3
	if GameManager.upgrade_speed_level >= 3:
		btn_speed.text = "✓ Nivel Máx"
		
	btn_tray.disabled = GameManager.coins < 180 or GameManager.upgrade_inventory_capacity >= 4
	if GameManager.upgrade_inventory_capacity >= 4:
		btn_tray.text = "✓ Comprado"
		
	btn_chef.disabled = GameManager.coins < 200 or GameManager.upgrade_chef_speed_multiplier < 1.0
	if GameManager.upgrade_chef_speed_multiplier < 1.0:
		btn_chef.text = "✓ Comprado"
		
	btn_datapad.disabled = GameManager.coins < 150 or GameManager.upgrade_datapad_cooldown <= 15.0
	if GameManager.upgrade_datapad_cooldown <= 15.0:
		btn_datapad.text = "✓ Comprado"

func _buy(type: String, cost: int, btn: Button) -> void:
	if GameManager.buy_upgrade(type, cost):
		_check_buttons()
		if MissionManager.campaign_started:
			MissionManager.save_game()
		elif BusinessManager.management_mode:
			BusinessManager.save_game()

func _on_next_pressed() -> void:
	get_tree().paused = false
	panel.visible = false
	if GameManager.return_to_hub_after_level:
		GameManager.return_to_hub_after_level = false
		MissionManager.save_game()
		GameManager.change_scene_smooth("res://scenes/world/main_hub.tscn")
		return
	
	var next_lvl = GameManager.current_level + 1
	if next_lvl > 3:
		GameManager.change_scene_smooth("res://scenes/ui/victory_championship.tscn")
	else:
		GameManager.change_scene_smooth("res://scenes/levels/jornada_%d.tscn" % next_lvl)

func _on_retry_pressed() -> void:
	get_tree().paused = false
	panel.visible = false
	GameManager.change_scene_smooth("res://scenes/levels/jornada_%d.tscn" % GameManager.current_level)

func _on_menu_pressed() -> void:
	get_tree().paused = false
	panel.visible = false
	if GameManager.return_to_hub_after_level:
		GameManager.return_to_hub_after_level = false
		MissionManager.save_game()
		GameManager.change_scene_smooth("res://scenes/world/main_hub.tscn")
		return
	GameManager.change_scene_smooth("res://scenes/menu/main_menu_rush.tscn")
