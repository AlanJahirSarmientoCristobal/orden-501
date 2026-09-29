extends Control

@onready var stats_label: Label = $VBox/Stats
@onready var trophy_label: Label = $VBox/Trophy
@onready var subtitle_label: Label = $VBox/Subtitle
@onready var body_label: Label = $VBox/Body
@onready var author_label: Label = $VBox/Author
@onready var btn_replay: Button = $VBox/Buttons/BtnReplay
@onready var btn_menu: Button = $VBox/Buttons/BtnMenu

func _ready() -> void:
	AudioManager.play_sfx_upgrade()
	stats_label.text = "Caja final: $%d | Pedidos entregados: %d" % [GameManager.coins, GameManager.season_orders_delivered]
	if BusinessManager.management_mode:
		trophy_label.text = "ORDEN 501 · OPERACIÓN ESTABILIZADA"
		subtitle_label.text = "LA 501 YA ES UN RESTAURANTE DE REFERENCIA LOCAL"
		body_label.text = "Organizaste inventario, reservaciones y pedidos; además utilizaste reportes y promociones para recuperar las ventas.\nHas desbloqueado el Panel de Reportes Maestro."
		author_label.text = "Proyecto Transversal · Alan Jahir Sarmiento Cristobal · Luis Angel Hernandez Hernandez"
	
	btn_replay.pressed.connect(func():
		AudioManager.play_sfx_click()
		if BusinessManager.management_mode:
			BusinessManager.begin_campaign(BusinessManager.difficulty)
		else:
			GameManager.reset_season()
		GameManager.change_scene_smooth("res://scenes/levels/jornada_1.tscn")
	)
	btn_menu.pressed.connect(func():
		AudioManager.play_sfx_click()
		GameManager.change_scene_smooth("res://scenes/menu/main_menu_rush.tscn")
	)
