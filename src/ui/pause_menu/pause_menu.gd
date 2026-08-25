extends Control
class_name PauseMenu

@onready var pause_container: PanelContainer = %PauseContainer
@onready var resume_button: Button = %ResumeButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var settings_close_button: Button = %SettingsCloseButton

@onready var master_slider: HSlider = %MasterVolumeSlider
@onready var master_label: Label = %MasterVolumeLabel
@onready var sfx_slider: HSlider = %SfxVolumeSlider
@onready var sfx_label: Label = %SfxVolumeLabel
@onready var ui_slider: HSlider = %UiVolumeSlider
@onready var ui_label: Label = %UiVolumeLabel
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckBox

var is_open: bool = false
var is_game_over: bool = false
var _menu_tween: Tween
var _settings_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0
	
	GameEvents.game_over.connect(func() -> void: is_game_over = true)
	
	settings_panel.visible = false
	settings_panel.modulate.a = 0.0
	
	# Connect buttons
	resume_button.pressed.connect(resume_game)
	settings_button.pressed.connect(open_settings)
	quit_button.pressed.connect(quit_to_menu)
	settings_close_button.pressed.connect(close_settings)
	
	# Settings controls
	master_slider.value_changed.connect(_on_master_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if is_game_over:
		return
	if event is InputEventKey and event.pressed and not event.is_echo() and event.keycode == KEY_ESCAPE:
		if is_open:
			if settings_panel.visible:
				close_settings()
			else:
				resume_game()
			get_viewport().set_input_as_handled()
		else:
			open_pause_menu()
			get_viewport().set_input_as_handled()


func open_pause_menu() -> void:
	if is_open or is_game_over:
		return
	is_open = true
	visible = true
	get_tree().paused = true
	
	# Update settings controls to match current AudioServer state
	_init_settings_values()
	
	pause_container.visible = true
	pause_container.modulate.a = 1.0
	pause_container.scale = Vector2.ONE
	settings_panel.visible = false
	
	if _menu_tween and _menu_tween.is_valid():
		_menu_tween.kill()
		
	_menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_menu_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_menu_tween.tween_property(self, "modulate:a", 1.0, 0.2).from(0.0)
	_menu_tween.tween_property(pause_container, "scale", Vector2.ONE, 0.25).from(Vector2(0.85, 0.85))


func resume_game() -> void:
	if not is_open:
		return
	is_open = false
	
	if _menu_tween and _menu_tween.is_valid():
		_menu_tween.kill()
		
	_menu_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_menu_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_menu_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	_menu_tween.tween_callback(func():
		visible = false
		get_tree().paused = false
	)


func open_settings() -> void:
	_init_settings_values()
	settings_panel.visible = true
	settings_panel.pivot_offset = settings_panel.size / 2.0
	pause_container.visible = false
	
	if _settings_tween and _settings_tween.is_valid():
		_settings_tween.kill()
		
	_settings_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_settings_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_settings_tween.tween_property(settings_panel, "modulate:a", 1.0, 0.25).from(0.0)
	_settings_tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.25).from(Vector2(0.85, 0.85))


func close_settings() -> void:
	if _settings_tween and _settings_tween.is_valid():
		_settings_tween.kill()
		
	_settings_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_settings_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_settings_tween.tween_property(settings_panel, "modulate:a", 0.0, 0.15)
	_settings_tween.tween_callback(func():
		settings_panel.visible = false
		pause_container.visible = true
		pause_container.modulate.a = 1.0
		pause_container.scale = Vector2.ONE
	)


func quit_to_menu() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://src/ui/main_menu/main_menu.tscn")


## --- Settings Synchronization ---

func _init_settings_values() -> void:
	_init_bus_slider("Master", master_slider, master_label)
	_init_bus_slider("SFX", sfx_slider, sfx_label)
	_init_bus_slider("UI", ui_slider, ui_label)
	
	var is_fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_checkbox.button_pressed = is_fullscreen


func _init_bus_slider(bus_name: String, slider: HSlider, label: Label) -> void:
	if not slider or not label:
		return
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		var is_muted: bool = AudioServer.is_bus_mute(bus_idx)
		var current_vol: float = db_to_linear(AudioServer.get_bus_volume_db(bus_idx))
		slider.value = 0.0 if is_muted else current_vol * 100.0
		label.text = str(int(round(slider.value))) + "%"


func _apply_bus_volume(bus_name: String, value: float, label: Label) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx != -1:
		if value <= 1.0:
			AudioServer.set_bus_mute(bus_idx, true)
		else:
			AudioServer.set_bus_mute(bus_idx, false)
			var linear_val: float = value / 100.0
			AudioServer.set_bus_volume_db(bus_idx, linear_to_db(linear_val))
	if label:
		label.text = str(int(round(value))) + "%"


func _on_master_volume_changed(value: float) -> void:
	_apply_bus_volume("Master", value, master_label)


func _on_sfx_volume_changed(value: float) -> void:
	_apply_bus_volume("SFX", value, sfx_label)


func _on_ui_volume_changed(value: float) -> void:
	_apply_bus_volume("UI", value, ui_label)


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
