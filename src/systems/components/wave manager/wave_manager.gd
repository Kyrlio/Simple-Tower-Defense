class_name WaveManager
extends Node


@export_group("References")
## La ressource contenant votre courbe logarithmique ondulée
@export var difficulty_curve: DifficultyCurve
@export var wave_timer: Timer
@export var spawners: Array[EnemySpawner]

@export_group("Pacing Configuration")
## Nombre de base d'ennemis à la vague 1 (multiplié ensuite par le facteur de difficulté)
@export var base_enemy_count: int = 5
## Multiplicateur appliqué au temps de pause entre les vagues
@export var wave_timer_multiplier: float = 1.15

var difficulty_factor: float = 1.0
var current_wave: int = 1


func _ready() -> void:
	add_to_group("wave_manager")
	if not difficulty_curve:
		push_error("No DifficultyCurve resource")
		return
	
	if spawners.size() > 0:
		spawners[0].is_active = true
	
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	wave_timer.start()
	
	spawners[0].spawn_wave(1, 1.0)
	GameEvents.wave_changed.emit(current_wave)


func _on_wave_timer_timeout() -> void:
	difficulty_factor = difficulty_curve.get_difficulty_factor(current_wave)
	
	print("\n--- DEBUT VAGUE ", current_wave, " ---")
	print("Facteur de Difficulté : ", difficulty_factor)
	print("Pause de préparation suivante : ", wave_timer.wait_time, " secondes")
	
	GameEvents.wave_changed.emit(current_wave)
	
	
	if current_wave == 15:
		_activate_spawner(1, "North")
	elif current_wave == 25:
		_activate_spawner(2, "East")
	elif current_wave == 35:
		_activate_spawner(3, "South")
	
	var enemy_count: int = roundi(base_enemy_count * difficulty_factor)
	enemy_count = max(enemy_count, base_enemy_count)
	
	for spawner in spawners:
		if spawner.is_active:
			spawner.spawn_wave(enemy_count, difficulty_factor)
	
	current_wave += 1
	wave_timer.wait_time = wave_timer.wait_time * wave_timer_multiplier


func _activate_spawner(index: int, direction_name: String) -> void:
	if spawners.size() > index and is_instance_valid(spawners[index]):
		spawners[index].is_active = true
		print("Alert! New threat approaching from the ", direction_name)
		GameEvents.spawner_warning.emit(direction_name)
