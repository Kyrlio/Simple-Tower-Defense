extends Node

signal tower_selected(tower_data: TowerStats)
signal tower_inspected(tower: Tower)
signal tower_uninspected
signal castle_health_changed(current_health: int, max_health: int)
signal game_over
signal game_speed_changed(speed_multiplier: float, is_paused: bool)
