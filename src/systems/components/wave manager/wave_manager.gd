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
## Plafond maximal d'ennemis générés par spawner pour une vague (évite la saturation de nœuds)
@export var max_enemies_per_spawner: int = 25
## Multiplicateur appliqué au temps de pause entre les vagues
@export var wave_timer_multiplier: float = 1.15
## Temps d'attente maximal (en secondes) entre deux vagues
@export var max_wave_wait_time: float = 60.0

@export_group("Spawner Scaling & Catch-up")
## Pourcentage du niveau de vague globale auquel démarre un nouveau spawner lors de son activation (ex: 0.8 = 80% du niveau global)
@export_range(0.1, 1.0, 0.05) var spawner_start_wave_ratio: float = 0.8
## Vitesse de rattrapage : nombre de niveaux de difficulté supplémentaires gagnés par vague jusqu'à rejoindre le niveau global
@export var spawner_catchup_rate: int = 2

var difficulty_factor: float = 1.0
var current_wave: int = 1


func _ready() -> void:
	add_to_group("wave_manager")
	if not difficulty_curve:
		push_error("No DifficultyCurve resource")
		return
	
	if spawners.size() > 0:
		spawners[0].is_active = true
	
	if is_instance_valid(wave_timer):
		wave_timer.wait_time = minf(wave_timer.wait_time, max_wave_wait_time)
		wave_timer.timeout.connect(_on_wave_timer_timeout)
		wave_timer.start()
	
	spawners[0].spawn_wave(1, 1.0)
	GameEvents.wave_changed.emit(current_wave)


func _on_wave_timer_timeout() -> void:
	difficulty_factor = difficulty_curve.get_difficulty_factor(current_wave)
	
	print("\n--- DEBUT VAGUE GLOBALE ", current_wave, " ---")
	print("Facteur de Difficulté Global : ", difficulty_factor)
	print("Pause de préparation suivante : ", wave_timer.wait_time, " secondes")
	
	GameEvents.wave_changed.emit(current_wave)
	
	if current_wave == 15:
		_activate_spawner(1, "North")
	elif current_wave == 25:
		_activate_spawner(2, "East")
	elif current_wave == 35:
		_activate_spawner(3, "South")
	
	for spawner in spawners:
		if spawner.is_active:
			if spawner.local_wave_index == 0:
				spawner.local_wave_index = max(1, roundi(current_wave * spawner_start_wave_ratio))
			elif spawner.local_wave_index < current_wave:
				spawner.local_wave_index = mini(current_wave, spawner.local_wave_index + spawner_catchup_rate)
			else:
				spawner.local_wave_index = current_wave
			
			var spawner_factor: float = difficulty_curve.get_difficulty_factor(spawner.local_wave_index)
			var enemy_count: int = clampi(roundi(base_enemy_count * spawner_factor), base_enemy_count, max_enemies_per_spawner)
			var lane_name: String = spawner.get_parent().name if spawner.get_parent() else spawner.name
			print(" -> Spawner [", lane_name, "] : Vague locale ", spawner.local_wave_index, " (Global: ", current_wave, ") | Diff: ", spawner_factor, " | Ennemis: ", enemy_count)
			spawner.spawn_wave(enemy_count, spawner_factor)
	
	current_wave += 1
	wave_timer.wait_time = minf(wave_timer.wait_time * wave_timer_multiplier, max_wave_wait_time)


func _activate_spawner(index: int, direction_name: String) -> void:
	if spawners.size() > index and is_instance_valid(spawners[index]):
		spawners[index].is_active = true
		var start_level: int = max(1, roundi(current_wave * spawner_start_wave_ratio))
		print("Alert! New threat approaching from the ", direction_name, " (Niveau initial de vague : ", start_level, ")")
		GameEvents.spawner_warning.emit(direction_name)
