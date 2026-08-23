extends Control

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var settings_close_button: Button = %SettingsCloseButton
@onready var master_slider: HSlider = %MasterVolumeSlider
@onready var master_label: Label = %MasterVolumeLabel
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckBox

@onready var sound_hover: AudioStreamPlayer = $Audio/SoundHover
@onready var sound_click: AudioStreamPlayer = $Audio/SoundClick
@onready var sound_start: AudioStreamPlayer = $Audio/SoundStart
@onready var sound_quit: AudioStreamPlayer = $Audio/SoundQuit

@onready var logo: TextureRect = %Logo
@onready var main_buttons_container: VBoxContainer = %MainButtonsContainer
@onready var logo_animated: AnimatedSprite2D = %Logo_animated

var _settings_tween: Tween
var _logo_tween: Tween
var _is_starting: bool = false


func _ready() -> void:
	# Ensure game state is normal (unpaused and normal speed)
	get_tree().paused = false
	Engine.time_scale = 1.0
	
	# Connect menu buttons
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	settings_close_button.pressed.connect(_on_settings_close_pressed)
	
	# Connect hover sound to all interactive buttons
	for btn: Button in [start_button, settings_button, quit_button, settings_close_button]:
		btn.mouse_entered.connect(_play_hover_sound)
	
	# Connect settings controls
	master_slider.value_changed.connect(_on_master_volume_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	fullscreen_checkbox.mouse_entered.connect(_play_hover_sound)
	
	# Initialize settings UI state
	_init_settings_values()
	
	# Settings panel initial hidden state
	settings_panel.visible = false
	settings_panel.modulate.a = 0.0
	settings_panel.scale = Vector2(0.8, 0.8)
	
	# Start subtle idle animation for the logo
	_start_logo_animation()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		if settings_panel.visible:
			_hide_settings()
			get_viewport().set_input_as_handled()


func _start_logo_animation() -> void:
	if not is_instance_valid(logo):
		return
	logo.pivot_offset = logo.size / 2.0
	if _logo_tween:
		_logo_tween.kill()
	_logo_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_logo_tween.tween_property(logo, "position:y", logo.position.y - 3.0, 1.6)
	_logo_tween.tween_property(logo, "position:y", logo.position.y + 3.0, 1.6)
	
	if not is_instance_valid(logo_animated):
		return
	if _logo_tween:
		_logo_tween.kill()
	_logo_tween = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_logo_tween.tween_property(logo_animated, "position:y", logo_animated.position.y - 3.0, 1.6)
	_logo_tween.tween_property(logo_animated, "position:y", logo_animated.position.y + 3.0, 1.6)


func _on_start_pressed() -> void:
	if _is_starting:
		return
	_is_starting = true
	_play_start_sound()
	
	# Fade out menu smoothly and change scene to level 1
	var tween: Tween = create_tween().set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(self, "modulate:a", 0.0, 0.35)
	tween.tween_callback(func() -> void:
		get_tree().change_scene_to_file("res://src/levels/level_1.tscn")
	)


func _on_settings_pressed() -> void:
	_play_click_sound()
	_show_settings()


func _on_quit_pressed() -> void:
	_play_quit_sound()
	# Small delay so user hears the click/quit sound
	var tween: Tween = create_tween()
	tween.tween_interval(0.25)
	tween.tween_callback(func() -> void:
		get_tree().quit()
	)


func _on_settings_close_pressed() -> void:
	_play_click_sound()
	_hide_settings()


func _show_settings() -> void:
	settings_panel.visible = true
	settings_panel.pivot_offset = settings_panel.size / 2.0
	
	if _settings_tween:
		_settings_tween.kill()
	_settings_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_settings_tween.tween_property(settings_panel, "modulate:a", 1.0, 0.25)
	_settings_tween.tween_property(settings_panel, "scale", Vector2.ONE, 0.25).from(Vector2(0.85, 0.85))
	
	# Make main buttons non-interactable while settings is open
	main_buttons_container.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _hide_settings() -> void:
	if _settings_tween:
		_settings_tween.kill()
	_settings_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_settings_tween.tween_property(settings_panel, "modulate:a", 0.0, 0.15)
	_settings_tween.tween_property(settings_panel, "scale", Vector2(0.85, 0.85), 0.15)
	_settings_tween.chain().tween_callback(func() -> void:
		settings_panel.visible = false
		main_buttons_container.mouse_filter = Control.MOUSE_FILTER_STOP
	)


func _init_settings_values() -> void:
	# Master volume setup
	var master_bus_idx: int = AudioServer.get_bus_index("Master")
	if master_bus_idx != -1:
		var is_muted: bool = AudioServer.is_bus_mute(master_bus_idx)
		var current_vol: float = db_to_linear(AudioServer.get_bus_volume_db(master_bus_idx))
		master_slider.value = 0.0 if is_muted else current_vol * 100.0
		_update_volume_label(master_slider.value)
	
	# Fullscreen checkbox setup
	var is_fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_checkbox.button_pressed = is_fullscreen


func _on_master_volume_changed(value: float) -> void:
	var master_bus_idx: int = AudioServer.get_bus_index("Master")
	if master_bus_idx != -1:
		if value <= 1.0:
			AudioServer.set_bus_mute(master_bus_idx, true)
		else:
			AudioServer.set_bus_mute(master_bus_idx, false)
			var linear_val: float = value / 100.0
			AudioServer.set_bus_volume_db(master_bus_idx, linear_to_db(linear_val))
	_update_volume_label(value)


func _update_volume_label(value: float) -> void:
	master_label.text = str(int(round(value))) + "%"


func _on_fullscreen_toggled(toggled_on: bool) -> void:
	_play_click_sound()
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _play_hover_sound() -> void:
	sound_hover.play()
	#if sound_hover and not sound_hover.playing:
		#sound_hover.play()


func _play_click_sound() -> void:
	if sound_click:
		sound_click.play()


func _play_start_sound() -> void:
	if sound_start:
		sound_start.play()


func _play_quit_sound() -> void:
	if sound_quit:
		sound_quit.play()
