extends Control

@onready var start_button: Button = %StartButton
@onready var settings_button: Button = %SettingsButton
@onready var quit_button: Button = %QuitButton

@onready var settings_panel: PanelContainer = %SettingsPanel
@onready var settings_close_button: Button = %SettingsCloseButton

# Tab switching
@onready var tab_general_button: Button = %TabGeneralButton
@onready var tab_waves_button: Button = %TabWavesButton
@onready var general_tab: VBoxContainer = %GeneralTab
@onready var waves_tab: VBoxContainer = %WavesTab

# General / Audio Controls
@onready var master_slider: HSlider = %MasterVolumeSlider
@onready var master_label: Label = %MasterVolumeLabel
@onready var master_reset_btn: Button = %MasterVolumeResetBtn
@onready var sfx_slider: HSlider = %SfxVolumeSlider
@onready var sfx_label: Label = %SfxVolumeLabel
@onready var sfx_reset_btn: Button = %SfxVolumeResetBtn
@onready var ui_slider: HSlider = %UiVolumeSlider
@onready var ui_label: Label = %UiVolumeLabel
@onready var ui_reset_btn: Button = %UiVolumeResetBtn
@onready var fullscreen_checkbox: CheckBox = %FullscreenCheckBox
@onready var deactivate_particles_checkbox: CheckBox = %DeactivateParticlesCheckBox
@onready var show_enemy_debug_labels_checkbox: CheckBox = %ShowEnemyDebugLabelsCheckBox

# Wave Manager & Difficulty Controls
@onready var base_diff_slider: HSlider = %BaseDiffSlider
@onready var base_diff_label: Label = %BaseDiffLabel
@onready var base_diff_reset_btn: Button = %BaseDiffResetBtn

@onready var linear_growth_slider: HSlider = %LinearGrowthSlider
@onready var linear_growth_label: Label = %LinearGrowthLabel
@onready var linear_growth_reset_btn: Button = %LinearGrowthResetBtn

@onready var base_enemy_slider: HSlider = %BaseEnemySlider
@onready var base_enemy_label: Label = %BaseEnemyLabel
@onready var base_enemy_reset_btn: Button = %BaseEnemyResetBtn

@onready var max_enemy_slider: HSlider = %MaxEnemySlider
@onready var max_enemy_label: Label = %MaxEnemyLabel
@onready var max_enemy_reset_btn: Button = %MaxEnemyResetBtn

@onready var timer_mult_slider: HSlider = %TimerMultSlider
@onready var timer_mult_label: Label = %TimerMultLabel
@onready var timer_mult_reset_btn: Button = %TimerMultResetBtn

@onready var spawner_ratio_slider: HSlider = %SpawnerRatioSlider
@onready var spawner_ratio_label: Label = %SpawnerRatioLabel
@onready var spawner_ratio_reset_btn: Button = %SpawnerRatioResetBtn

@onready var expo_power_slider: HSlider = %ExpoPowerSlider
@onready var expo_power_label: Label = %ExpoPowerLabel
@onready var expo_power_reset_btn: Button = %ExpoPowerResetBtn

@onready var gold_scale_slider: HSlider = %GoldScaleSlider
@onready var gold_scale_label: Label = %GoldScaleLabel
@onready var gold_scale_reset_btn: Button = %GoldScaleResetBtn

@onready var reset_all_waves_btn: Button = %ResetAllWavesBtn

# Sounds & Visuals
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
	
	# Connect tab navigation
	tab_general_button.pressed.connect(func() -> void: _switch_tab(false))
	tab_waves_button.pressed.connect(func() -> void: _switch_tab(true))
	
	# Connect general/audio controls
	master_slider.value_changed.connect(_on_master_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ui_slider.value_changed.connect(_on_ui_volume_changed)
	master_reset_btn.pressed.connect(func() -> void: master_slider.value = 100.0)
	sfx_reset_btn.pressed.connect(func() -> void: sfx_slider.value = 100.0)
	ui_reset_btn.pressed.connect(func() -> void: ui_slider.value = 100.0)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	deactivate_particles_checkbox.toggled.connect(_on_deactivate_particles_toggled)
	show_enemy_debug_labels_checkbox.toggled.connect(_on_show_enemy_debug_labels_toggled)
	
	# Connect wave settings sliders
	base_diff_slider.value_changed.connect(_on_base_diff_changed)
	linear_growth_slider.value_changed.connect(_on_linear_growth_changed)
	base_enemy_slider.value_changed.connect(_on_base_enemy_changed)
	max_enemy_slider.value_changed.connect(_on_max_enemy_changed)
	timer_mult_slider.value_changed.connect(_on_timer_mult_changed)
	spawner_ratio_slider.value_changed.connect(_on_spawner_ratio_changed)
	expo_power_slider.value_changed.connect(_on_expo_power_changed)
	gold_scale_slider.value_changed.connect(_on_gold_scale_changed)
	
	# Connect individual wave reset buttons
	base_diff_reset_btn.pressed.connect(func() -> void: _reset_single_wave_setting("base_difficulty", base_diff_slider))
	linear_growth_reset_btn.pressed.connect(func() -> void: _reset_single_wave_setting("linear_growth", linear_growth_slider))
	base_enemy_reset_btn.pressed.connect(func() -> void: _reset_single_wave_setting("base_enemy_count", base_enemy_slider))
	max_enemy_reset_btn.pressed.connect(func() -> void: _reset_single_wave_setting("max_enemies_per_spawner", max_enemy_slider))
	timer_mult_reset_btn.pressed.connect(func() -> void: _reset_single_wave_setting("wave_timer_multiplier", timer_mult_slider))
	spawner_ratio_reset_btn.pressed.connect(func() -> void: _reset_single_wave_setting("spawner_start_wave_ratio", spawner_ratio_slider))
	expo_power_reset_btn.pressed.connect(func() -> void: _reset_single_wave_setting("exponential_power", expo_power_slider))
	gold_scale_reset_btn.pressed.connect(func() -> void: _reset_single_wave_setting("gold_scale_influence", gold_scale_slider))
	
	# Connect reset all wave settings button
	reset_all_waves_btn.pressed.connect(_on_reset_all_waves_pressed)
	
	# Initialize settings values
	_init_settings_values()
	_init_wave_settings_values()
	_switch_tab(false)
	
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


func _switch_tab(to_waves: bool) -> void:
	_play_click_sound()
	general_tab.visible = not to_waves
	waves_tab.visible = to_waves
	
	if to_waves:
		tab_general_button.modulate = Color(0.7, 0.7, 0.7, 1.0)
		tab_waves_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		tab_general_button.modulate = Color(1.0, 1.0, 1.0, 1.0)
		tab_waves_button.modulate = Color(0.7, 0.7, 0.7, 1.0)


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
	_settings_tween.tween_property(settings_panel, "offset_transform_scale", Vector2.ONE, 0.25).from(Vector2(0.85, 0.85))
	
	# Make main buttons non-interactable while settings is open
	main_buttons_container.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _hide_settings() -> void:
	if _settings_tween:
		_settings_tween.kill()
	_settings_tween = create_tween().set_parallel(true).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_settings_tween.tween_property(settings_panel, "modulate:a", 0.0, 0.15)
	_settings_tween.tween_property(settings_panel, "offset_transform_scale", Vector2(0.85, 0.85), 0.15)
	_settings_tween.chain().tween_callback(func() -> void:
		settings_panel.visible = false
		main_buttons_container.mouse_filter = Control.MOUSE_FILTER_STOP
	)


## --- Initialisation & Gestion Audio / Général ---

func _init_settings_values() -> void:
	_init_bus_slider("Master", master_slider, master_label)
	_init_bus_slider("SFX", sfx_slider, sfx_label)
	_init_bus_slider("UI", ui_slider, ui_label)
	
	# Fullscreen checkbox setup
	var is_fullscreen: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fullscreen_checkbox.button_pressed = is_fullscreen
	if deactivate_particles_checkbox:
		deactivate_particles_checkbox.button_pressed = Data.deactivate_particles
	if show_enemy_debug_labels_checkbox:
		show_enemy_debug_labels_checkbox.button_pressed = Data.show_enemy_debug_labels


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
	_play_click_sound()
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_deactivate_particles_toggled(toggled_on: bool) -> void:
	_play_click_sound()
	Data.deactivate_particles = toggled_on


func _on_show_enemy_debug_labels_toggled(toggled_on: bool) -> void:
	_play_click_sound()
	Data.show_enemy_debug_labels = toggled_on


## --- Initialisation & Gestion Wave Manager & Difficulté ---

func _init_wave_settings_values() -> void:
	base_diff_slider.value = Data.get_wave_setting("base_difficulty", 1.0)
	linear_growth_slider.value = Data.get_wave_setting("linear_growth", 0.15)
	base_enemy_slider.value = Data.get_wave_setting("base_enemy_count", 4)
	max_enemy_slider.value = Data.get_wave_setting("max_enemies_per_spawner", 80)
	timer_mult_slider.value = Data.get_wave_setting("wave_timer_multiplier", 1.015)
	spawner_ratio_slider.value = Data.get_wave_setting("spawner_start_wave_ratio", 0.20)
	expo_power_slider.value = Data.get_wave_setting("exponential_power", 1.05)
	gold_scale_slider.value = Data.get_wave_setting("gold_scale_influence", 0.08)
	
	_update_base_diff_label(base_diff_slider.value)
	_update_linear_growth_label(linear_growth_slider.value)
	_update_base_enemy_label(base_enemy_slider.value)
	_update_max_enemy_label(max_enemy_slider.value)
	_update_timer_mult_label(timer_mult_slider.value)
	_update_spawner_ratio_label(spawner_ratio_slider.value)
	_update_expo_power_label(expo_power_slider.value)
	_update_gold_scale_label(gold_scale_slider.value)


func _on_base_diff_changed(value: float) -> void:
	Data.set_wave_setting("base_difficulty", value)
	_update_base_diff_label(value)


func _on_linear_growth_changed(value: float) -> void:
	Data.set_wave_setting("linear_growth", value)
	_update_linear_growth_label(value)


func _on_base_enemy_changed(value: float) -> void:
	var count: int = int(round(value))
	Data.set_wave_setting("base_enemy_count", count)
	_update_base_enemy_label(value)


func _on_max_enemy_changed(value: float) -> void:
	var count: int = int(round(value))
	Data.set_wave_setting("max_enemies_per_spawner", count)
	_update_max_enemy_label(value)


func _on_timer_mult_changed(value: float) -> void:
	Data.set_wave_setting("wave_timer_multiplier", value)
	_update_timer_mult_label(value)


func _on_spawner_ratio_changed(value: float) -> void:
	Data.set_wave_setting("spawner_start_wave_ratio", value)
	_update_spawner_ratio_label(value)


func _on_expo_power_changed(value: float) -> void:
	Data.set_wave_setting("exponential_power", value)
	_update_expo_power_label(value)


func _on_gold_scale_changed(value: float) -> void:
	Data.set_wave_setting("gold_scale_influence", value)
	_update_gold_scale_label(value)


func _reset_single_wave_setting(key: String, slider: HSlider) -> void:
	_play_click_sound()
	Data.reset_wave_setting(key)
	slider.value = Data.get_wave_setting(key)


func _on_reset_all_waves_pressed() -> void:
	_play_click_sound()
	Data.reset_all_wave_settings()
	_init_wave_settings_values()


func _update_base_diff_label(val: float) -> void:
	base_diff_label.text = "x%.1f" % val


func _update_linear_growth_label(val: float) -> void:
	linear_growth_label.text = "+%.2f" % val


func _update_base_enemy_label(val: float) -> void:
	base_enemy_label.text = str(int(round(val)))


func _update_max_enemy_label(val: float) -> void:
	max_enemy_label.text = str(int(round(val)))


func _update_timer_mult_label(val: float) -> void:
	timer_mult_label.text = "x%.3f" % val


func _update_spawner_ratio_label(val: float) -> void:
	spawner_ratio_label.text = "%d%%" % int(round(val * 100.0))


func _update_expo_power_label(val: float) -> void:
	expo_power_label.text = "%.1f" % val


func _update_gold_scale_label(val: float) -> void:
	gold_scale_label.text = "+%d%%" % int(round(val * 100.0))


## --- Sons Génériques ---

func _play_click_sound() -> void:
	if sound_click:
		sound_click.play()


func _play_start_sound() -> void:
	if sound_start:
		sound_start.play()


func _play_quit_sound() -> void:
	if sound_quit:
		sound_quit.play()
