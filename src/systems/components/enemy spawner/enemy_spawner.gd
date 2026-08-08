extends Node
class_name EnemySpawner

@export var enemy_scene: PackedScene
@export var spawn_path: Path2D

var current_wave: int = 1


func start_next_wave() -> void:
	var enemy_count: int = current_wave * 3
	spawn_wave(enemy_count)
	current_wave += 1


func spawn_wave(count: int) -> void:
	for i in range(count):
		var enemy_instance = enemy_scene.instantiate()
		spawn_path.add_child(enemy_instance)
		enemy_instance.progress = 0
		
		await get_tree().create_timer(0.8).timeout
