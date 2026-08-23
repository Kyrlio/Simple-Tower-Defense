extends Node

signal tower_selected(tower_data: TowerStats)
signal tower_inspected(tower: Tower)
signal tower_uninspected
signal tower_upgraded(tower: Tower)
signal castle_health_changed(current_health: int, max_health: int)
signal game_over
signal game_speed_changed(speed_multiplier: float, is_paused: bool)
signal wave_changed(wave_number: int)
signal spawner_warning(direction: String)
