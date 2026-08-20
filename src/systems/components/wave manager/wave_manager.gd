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
	if not difficulty_curve:
		push_error("No DifficultyCurve resource")
		return
	
	if spawners.size() > 0:
		spawners[0].is_active = true
	
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	wave_timer.start()
	
	spawners[0].spawn_wave(base_enemy_count, 1.0)


func _on_wave_timer_timeout() -> void:
	difficulty_factor = difficulty_curve.get_difficulty_factor(current_wave)
	
	print("\n--- DEBUT VAGUE ", current_wave, " ---")
	print("Facteur de Difficulté : ", difficulty_factor)
	print("Pause de préparation suivante : ", wave_timer.wait_time, " secondes")
	
	
	if current_wave == 1:
		_activate_spawner(1, "Nord")
	elif current_wave == 2:
		_activate_spawner(2, "Est")
	elif current_wave == 3:
		_activate_spawner(3, "Sud")
	
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
		print("Alerte ! Nouvelle menace approche par le ", direction_name)
