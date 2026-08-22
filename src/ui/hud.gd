extends CanvasLayer
class_name HUD

enum SpeedMode { PAUSE, SPEED_1X, SPEED_2X, SPEED_3X }

@onready var gold_label: Label = $MarginContainer/GoldLabel
@onready var health_bar: HealthBar = $MarginContainer/HealthBar
@onready var pause_button: AnimatedButton = $MarginContainer/SpeedControls/PauseButton
@onready var speed_1x_button: AnimatedButton = $MarginContainer/SpeedControls/Speed1xButton
@onready var speed_2x_button: AnimatedButton = $MarginContainer/SpeedControls/Speed2xButton
@onready var speed_3x_button: AnimatedButton = $MarginContainer/SpeedControls/Speed3xButton

var current_speed_mode: SpeedMode = SpeedMode.SPEED_1X
var last_active_speed_mode: SpeedMode = SpeedMode.SPEED_1X


func _ready() -> void:
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	GoldManager.gold_changed.connect(_update_gold_label)
	GameEvents.castle_health_changed.connect(_on_castle_health_changed)
	GameEvents.game_over.connect(_on_game_over)
	_update_gold_label(GoldManager.gold)
	
	pause_button.pressed.connect(_on_pause_pressed)
	speed_1x_button.pressed.connect(_on_speed_1x_pressed)
	speed_2x_button.pressed.connect(_on_speed_2x_pressed)
	speed_3x_button.pressed.connect(_on_speed_3x_pressed)
	
	set_speed_mode(SpeedMode.SPEED_1X)


func _unhandled_input(event: InputEvent) -> void:
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
	var dim_color: Color = Color(1.0, 1.0, 1.0, 0.506)
	
	match current_speed_mode:
		SpeedMode.PAUSE:
			pause_button.modulate = Color(1.0, 0.85, 0.2, 1.0) # Jaune / Ambre
			speed_1x_button.modulate = dim_color
			speed_2x_button.modulate = dim_color
			speed_3x_button.modulate = dim_color
		SpeedMode.SPEED_1X:
			pause_button.modulate = dim_color
			speed_1x_button.modulate = Color(0.35, 0.9, 1.0, 1.0) # Cyan
			speed_2x_button.modulate = dim_color
			speed_3x_button.modulate = dim_color
		SpeedMode.SPEED_2X:
			pause_button.modulate = dim_color
			speed_1x_button.modulate = dim_color
			speed_2x_button.modulate = Color(0.3, 1.0, 0.5, 1.0) # Vert
			speed_3x_button.modulate = dim_color
		SpeedMode.SPEED_3X:
			pause_button.modulate = dim_color
			speed_1x_button.modulate = dim_color
			speed_2x_button.modulate = dim_color
			speed_3x_button.modulate = Color(1.0, 0.45, 0.65, 1.0) # Rose / Corail vif


func _update_gold_label(amount: int) -> void:
	gold_label.text = "Gold: " + str(amount)


func _on_castle_health_changed(current: int, max_health: int) -> void:
	health_bar.update_bar(current, max_health)


func _on_game_over() -> void:
	print("Game Over")
