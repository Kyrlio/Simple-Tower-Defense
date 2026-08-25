extends Control
class_name GameOverMenu

@onready var game_over_container: PanelContainer = %GameOverContainer
@onready var waves_survived_label: Label = %WavesSurvivedLabel
@onready var restart_button: Button = %RestartButton
@onready var quit_button: Button = %QuitButton

var current_wave: int = 1
var is_open: bool = false
var _menu_tween: Tween


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	modulate.a = 0.0
	
	GameEvents.wave_changed.connect(_on_wave_changed)
	GameEvents.game_over.connect(_on_game_over)
	
	restart_button.pressed.connect(_on_restart_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _on_wave_changed(wave_num: int) -> void:
	current_wave = wave_num


func _on_game_over() -> void:
	open_game_over_menu()


func open_game_over_menu() -> void:
	if is_open:
		return
	is_open = true
	visible = true
	
	var waves_survived: int = max(0, current_wave - 1)
	if waves_survived == 1:
		waves_survived_label.text = "Wave Survived: 1"
	else:
		waves_survived_label.text = "Waves Survived: " + str(waves_survived)
	
	get_tree().paused = true
	Engine.time_scale = 1.0
	
	game_over_container.visible = true
	game_over_container.modulate.a = 1.0
	game_over_container.scale = Vector2.ONE
	
	if _menu_tween and _menu_tween.is_valid():
		_menu_tween.kill()
		
	_menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_menu_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_menu_tween.tween_property(self, "modulate:a", 1.0, 0.25).from(0.0)
	_menu_tween.tween_property(game_over_container, "offset_transform_scale", Vector2.ONE, 0.3).from(Vector2(0.85, 0.85))


func _on_restart_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GoldManager.reset()
	get_tree().reload_current_scene()


func _on_quit_pressed() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	GoldManager.reset()
	get_tree().change_scene_to_file("res://src/ui/main_menu/main_menu.tscn")
