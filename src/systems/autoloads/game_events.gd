extends Node

@warning_ignore("unused_signal")
signal shoot(pos: Vector2, direction: float, projectile_enum: Data.Projectile)
signal tower_selected(tower_data: TowerStats)
signal castle_health_changed(current_health: int, max_health: int)
signal game_over
