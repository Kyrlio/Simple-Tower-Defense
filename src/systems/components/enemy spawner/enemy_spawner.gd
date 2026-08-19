extends Node
class_name EnemySpawner


#@export var enemy_scenes: Array[PackedScene]
@export var spawn_path: Path2D
#@export var enemy_count_wave_multiplier: int = 3
@export var is_active: bool = false
@export var spawn_pool: Array[Dictionary] = [
	{ "scene": preload("uid://x81tgyj3keel"), "chance": 60 },
	{ "scene": preload("uid://bvtnqclywhugm"), "chance": 30 }
]

#var current_wave: int = 1


#func start_next_wave() -> void:
	#var enemy_count: int = current_wave * enemy_count_wave_multiplier
	#spawn_wave(enemy_count)
	#current_wave += 1


#func spawn_random_enemy() -> void:
	#var random_index = randi_range(0, enemy_scenes.size() - 1)
	#var enemy_scene_to_spawn = enemy_scenes[random_index]
	#
	#var path_follow: PathFollow2D = PathFollow2D.new()
	#path_follow.rotates = false
	#path_follow.y_sort_enabled = true
	#spawn_path.add_child(path_follow)
	#
	#var enemy_instance = enemy_scene_to_spawn.instantiate()
	#path_follow.add_child(enemy_instance)
	#enemy_instance.setup(path_follow)


func spawn_enemy(difficulty_factor: float) -> void:
	if not is_active or spawn_pool.is_empty():
		return
	
	var roll: int = randi_range(1, 100)
	var chosen_scene: PackedScene = null
	var cumulative_chance: int = 0
	
	for entry in spawn_pool:
		cumulative_chance += entry["chance"]
		if roll <= cumulative_chance:
			chosen_scene = entry["scene"]
			break
	
	if chosen_scene:
		var path_follow = PathFollow2D.new()
		spawn_path.add_child(path_follow)
		
		var enemy_instance = chosen_scene.instantiate()
		path_follow.add_child(enemy_instance)
		
		enemy_instance.setup(path_follow)
		if enemy_instance.has_method("apply_scale_difficulty"):
			enemy_instance.apply_scale_difficulty(difficulty_factor)


func spawn_wave(count: int, difficulty_factor: float) -> void:
	for i in range(count):
		spawn_enemy(difficulty_factor)
		await get_tree().create_timer(0.8).timeout
