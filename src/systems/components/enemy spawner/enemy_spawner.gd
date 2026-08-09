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
		
		var path_follow: PathFollow2D = PathFollow2D.new()
		path_follow.rotates = false
		var enemy = enemy_scene.instantiate()
		enemy.setup(path_follow)
		path_follow.add_child(enemy)
		spawn_path.add_child(path_follow)
		
		await get_tree().create_timer(0.8).timeout
