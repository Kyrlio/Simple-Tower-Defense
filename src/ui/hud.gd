extends CanvasLayer
class_name HUD

enum SpeedMode { PAUSE, SPEED_1X, SPEED_2X, SPEED_3X }

@onready var gold_label: Label = $MarginContainer/TopLeftContainer/GoldLabel
@onready var wave_label: Label = $MarginContainer/TopLeftContainer/WaveLabel
@onready var next_wave_label: Label = $MarginContainer/TopLeftContainer/NextWaveLabel
@onready var health_bar: HealthBar = $MarginContainer/HealthBar
@onready var pause_button: AnimatedButton = $MarginContainer/SpeedControls/PauseButton
@onready var speed_1x_button: AnimatedButton = $MarginContainer/SpeedControls/Speed1xButton
@onready var speed_2x_button: AnimatedButton = $MarginContainer/SpeedControls/Speed2xButton
@onready var speed_3x_button: AnimatedButton = $MarginContainer/SpeedControls/Speed3xButton
@onready var warning_banner: PanelContainer = $WarningBanner
@onready var warning_label: Label = $WarningBanner/VBox/WarningLabel

var current_speed_mode: SpeedMode = SpeedMode.SPEED_1X
var last_active_speed_mode: SpeedMode = SpeedMode.SPEED_1X
var is_game_over: bool = false
var wave_manager: WaveManager = null
var _warning_tween: Tween = null


func _ready() -> void:
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	GoldManager.gold_changed.connect(_update_gold_label)
	GameEvents.castle_health_changed.connect(_on_castle_health_changed)
	GameEvents.game_over.connect(_on_game_over)
	GameEvents.wave_changed.connect(_update_wave_label)
	GameEvents.spawner_warning.connect(_on_spawner_warning)
	_update_gold_label(GoldManager.gold)
	_update_wave_label(1)
	
	pause_button.pressed.connect(_on_pause_pressed)
	speed_1x_button.pressed.connect(_on_speed_1x_pressed)
	speed_2x_button.pressed.connect(_on_speed_2x_pressed)
	speed_3x_button.pressed.connect(_on_speed_3x_pressed)
	
	set_speed_mode(SpeedMode.SPEED_1X)


func _process(_delta: float) -> void:
	_update_next_wave_timer()


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		return
	if event is InputEventKey and event.pressed and not event.is_echo():
		if event.keycode == KEY_SPACE:
			_toggle_pause()
		elif event.keycode == KEY_1 or event.keycode == KEY_KP_1:
			set_speed_mode(SpeedMode.SPEED_1X)
		elif event.keycode == KEY_2 or event.keycode == KEY_KP_2:
			set_speed_mode(SpeedMode.SPEED_2X)
		elif event.keycode == KEY_3 or event.keycode == KEY_KP_3:
			set_speed_mode(SpeedMode.SPEED_3X)
		elif event.keycode == KEY_0 or event.keycode == KEY_KP_0:
			set_speed_mode(SpeedMode.PAUSE)


func _toggle_pause() -> void:
	if current_speed_mode == SpeedMode.PAUSE:
		set_speed_mode(last_active_speed_mode if last_active_speed_mode != SpeedMode.PAUSE else SpeedMode.SPEED_1X)
	else:
		set_speed_mode(SpeedMode.PAUSE)


func _on_pause_pressed() -> void:
	set_speed_mode(SpeedMode.PAUSE)


func _on_speed_1x_pressed() -> void:
	set_speed_mode(SpeedMode.SPEED_1X)


func _on_speed_2x_pressed() -> void:
	set_speed_mode(SpeedMode.SPEED_2X)


func _on_speed_3x_pressed() -> void:
	set_speed_mode(SpeedMode.SPEED_3X)


func set_speed_mode(mode: SpeedMode) -> void:
	if mode != SpeedMode.PAUSE:
		last_active_speed_mode = mode
	current_speed_mode = mode
	
	match mode:
		SpeedMode.PAUSE:
			get_tree().paused = true
			Engine.time_scale = 1.0
			GameEvents.game_speed_changed.emit(0.0, true)
		SpeedMode.SPEED_1X:
			get_tree().paused = false
			Engine.time_scale = 1.0
			GameEvents.game_speed_changed.emit(1.0, false)
		SpeedMode.SPEED_2X:
			get_tree().paused = false
			Engine.time_scale = 2.0
			GameEvents.game_speed_changed.emit(2.0, false)
		SpeedMode.SPEED_3X:
			get_tree().paused = false
			Engine.time_scale = 3.0
			GameEvents.game_speed_changed.emit(3.0, false)
	
	_update_speed_buttons_ui()


func _update_speed_buttons_ui() -> void:
	var dim_color: Color = Color(1.0, 1.0, 1.0, 0.784)
	
	match current_speed_mode:
		SpeedMode.PAUSE:
			pause_button.modulate = Color(1.0, 0.635, 0.078, 1.0) # Jaune / Ambre
			speed_1x_button.modulate = dim_color
			speed_2x_button.modulate = dim_color
			speed_3x_button.modulate = dim_color
		SpeedMode.SPEED_1X:
			pause_button.modulate = dim_color
			speed_1x_button.modulate = Color(0.0, 0.661, 0.954, 1.0) # Cyan
			speed_2x_button.modulate = dim_color
			speed_3x_button.modulate = dim_color
		SpeedMode.SPEED_2X:
			pause_button.modulate = dim_color
			speed_1x_button.modulate = dim_color
			speed_2x_button.modulate = Color(0.353, 0.773, 0.31, 1.0) # Vert
			speed_3x_button.modulate = dim_color
		SpeedMode.SPEED_3X:
			pause_button.modulate = dim_color
			speed_1x_button.modulate = dim_color
			speed_2x_button.modulate = dim_color
			speed_3x_button.modulate = Color(0.918, 0.196, 0.235, 1.0) # Rose / Corail vif


func _update_gold_label(amount: int) -> void:
	gold_label.text = "Gold : " + str(amount)


func _update_wave_label(wave_num: int) -> void:
	wave_label.text = "Wave : " + str(wave_num)


func _on_castle_health_changed(current: int, max_health: int) -> void:
	health_bar.update_bar(current, max_health)


func _on_game_over() -> void:
	is_game_over = true
	print("Game Over")


func _get_wave_manager() -> WaveManager:
	if not wave_manager or not is_instance_valid(wave_manager):
		wave_manager = get_tree().get_first_node_in_group("wave_manager") as WaveManager
	return wave_manager


func _update_next_wave_timer() -> void:
	var wm = _get_wave_manager()
	if wm and wm.wave_timer and not wm.wave_timer.is_stopped():
		var time_left: int = int(ceil(wm.wave_timer.time_left))
		next_wave_label.text = "Next wave in " + str(time_left) + "s"
	else:
		next_wave_label.text = ""


func _on_spawner_warning(direction_name: String) -> void:
	show_warning_message("The enemies are coming from the " + direction_name)


func show_warning_message(message: String) -> void:
	if not warning_banner or not warning_label:
		return
	
	SoundManager.play_wave_warning()
	warning_label.text = message
	warning_banner.visible = true
	warning_banner.modulate.a = 0.0
	warning_banner.scale = Vector2(0.8, 0.8)
	warning_banner.pivot_offset = warning_banner.size / 2.0
	
	if _warning_tween and _warning_tween.is_valid():
		_warning_tween.kill()
	
	_warning_tween = create_tween()
	_warning_tween.parallel().tween_property(warning_banner, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_warning_tween.parallel().tween_property(warning_banner, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_warning_tween.tween_property(warning_label, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.15)
	_warning_tween.tween_property(warning_label, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15)
	_warning_tween.tween_interval(3.0)
	_warning_tween.tween_property(warning_banner, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_warning_tween.tween_callback(func(): warning_banner.visible = false)
