extends CanvasLayer

@onready var clock_label: Label = $TopBar/Margin/HBox/MatchClock
@onready var brand_label: Label = $TopBar/Margin/HBox/Brand
@onready var coins_label: Label = $TopBar/Margin/HBox/Coins
@onready var rep_label: Label = $TopBar/Margin/HBox/Reputation
@onready var datapad_btn: Button = $BottomBar/Margin/HBox/DatapadButton
@onready var datapad_cooldown_bar: ProgressBar = $BottomBar/Margin/HBox/DatapadCooldown
@onready var banner_panel: PanelContainer = $CenterBanner
@onready var banner_title: Label = $CenterBanner/Margin/VBox/Title
@onready var banner_subtitle: Label = $CenterBanner/Margin/VBox/Subtitle

func _ready() -> void:
	banner_panel.visible = false
	datapad_btn.pressed.connect(_on_datapad_clicked)
	
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.reputation_changed.connect(_on_reputation_changed)
	GameManager.datapad_cooldown_updated.connect(_on_datapad_cooldown_updated)
	GameManager.match_announcement.connect(_on_match_announcement)
	
	_on_coins_changed(GameManager.coins)
	_on_reputation_changed(GameManager.reputation)
	if BusinessManager.management_mode:
		brand_label.text = "ORDEN 501 · GERENCIA DIGITAL"
		datapad_btn.text = "[E] PANEL DE GESTIÓN"
		datapad_cooldown_bar.visible = false

func _process(_delta: float) -> void:
	if GameManager.is_game_active:
		clock_label.text = ("Turno: %d seg" if BusinessManager.management_mode else "⏱️ Partido: %d seg") % int(GameManager.match_timer)
		if GameManager.match_timer <= 20.0:
			clock_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
		else:
			clock_label.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _on_coins_changed(val: int) -> void:
	coins_label.text = "💰 Caja: $%d | Jornada: $%d/$%d" % [val, GameManager.level_earnings, GameManager.current_target_coins]

func _on_reputation_changed(rep: float) -> void:
	var stars = int(rep / 20.0)
	var star_str = ""
	for i in range(stars):
		star_str += "⭐"
	rep_label.text = "Reputación: %s (%d%%)" % [star_str, int(rep)]
	if rep < 40.0:
		rep_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	else:
		rep_label.modulate = Color(1.0, 0.9, 0.3, 1.0)

func _on_datapad_cooldown_updated(remaining: float, total: float) -> void:
	if remaining > 0.0:
		datapad_btn.disabled = true
		datapad_btn.text = "📡 Escáner: %.1fs" % remaining
		datapad_cooldown_bar.max_value = total
		datapad_cooldown_bar.value = total - remaining
		datapad_cooldown_bar.visible = true
	else:
		datapad_btn.disabled = false
		datapad_btn.text = "📡 [E] ESCÁNER DE DEMANDA (LISTO)"
		datapad_cooldown_bar.visible = false

func _on_datapad_clicked() -> void:
	if BusinessManager.management_mode:
		BusinessManager.request_panel("management")
		return
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("_trigger_datapad"):
		player._trigger_datapad()

func _on_match_announcement(title: String, subtitle: String) -> void:
	banner_title.text = title
	banner_subtitle.text = subtitle
	banner_panel.visible = true
	
	banner_panel.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.tween_property(banner_panel, "scale", Vector2(1.0, 1.0), 0.2).set_trans(Tween.TRANS_BACK)
	
	await get_tree().create_timer(3.0).timeout
	
	var fade = create_tween()
	fade.tween_property(banner_panel, "modulate:a", 0.0, 0.3)
	await fade.finished
	banner_panel.visible = false
	banner_panel.modulate.a = 1.0
