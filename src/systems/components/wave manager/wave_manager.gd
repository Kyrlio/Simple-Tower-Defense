class_name WaveManager
extends Node


@export var wave_timer: Timer
@export var difficulty_factor_additioner: float = 0.15
@export var wave_timer_multiplier: float = 1.2
@export var spawners: Array[EnemySpawner]

var difficulty_factor: float = 1.0
var current_wave: int = 1


func _ready() -> void:
	if spawners.size() > 0:
		spawners[0].is_active = true
	wave_timer.timeout.connect(_on_wave_timer_timeout)
	wave_timer.start()
	spawners[0].spawn_wave(3, 1)


func _on_wave_timer_timeout() -> void:
	print("Wave ", current_wave, "\nDifficulty : ", difficulty_factor, "\nNext wave in ", wave_timer.wait_time)
	
	if current_wave == 1:
		_activate_spawner(1, "Nord")
	elif current_wave == 5:
		_activate_spawner(2, "Est")
	elif current_wave == 7:
		_activate_spawner(3, "Sud")
	
	difficulty_factor += 0.2
	var enemy_count = current_wave * 3
	
	for spawner in spawners:
		if spawner.is_active:
			spawner.spawn_wave(enemy_count, difficulty_factor)
	
	current_wave += 1
	difficulty_factor += 0.15
	wave_timer.wait_time = wave_timer.wait_time * wave_timer_multiplier


func _activate_spawner(index: int, direction_name: String) -> void:
	if spawners.size() > index and is_instance_valid(spawners[index]):
		spawners[index].is_active = true
		print("Alerte ! Nouvelle menace approche par le ", direction_name)
