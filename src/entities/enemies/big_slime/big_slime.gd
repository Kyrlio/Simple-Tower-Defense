class_name BigSlime
extends Enemy

@export_group("Division Settings")
## La scène du slime normal à instancier à la mort
@export var normal_slime_scene: PackedScene
## Distance de recul (en pixels) entre chaque slime pour éviter qu'ils ne se superposent
@export var split_offset: float = 15.0
## Nombre de bébés qu'il va drop à sa mort
@export var number_babies: int = 2


## Override Enemy die function
func die() -> void:
	if is_dead:
		return
	is_dead = true
	
	hitstop_frames = 0
	if is_instance_valid(hit_flash_anim_player):
		hit_flash_anim_player.stop()
	
	if attack_timer:
		attack_timer.queue_free()
	
	# Désactiver les collisions pour ne plus être ciblé ou blessé pendant l'animation de mort
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	
	GoldManager.add_gold(stats.gold_reward)
	spawn_death_particles()
	
	if animation_player and animation_player.has_animation("death"):
		animation_player.play("death")
		await animation_player.animation_finished
	
	_spawn_baby_slimes()
	
	# Supprimer le BigSlime et son PathFollow2D
	if is_instance_valid(path_follow):
		path_follow.queue_free()
	else:
		queue_free()


func _spawn_baby_slimes() -> void:
	if not normal_slime_scene:
		push_error("Error: no normal_slime_scene assigned")
		return
	
	if not is_instance_valid(path_follow):
		push_error("Big Slime has no valid path_follow")
		return
	
	var path_2d = path_follow.get_parent() as Path2D
	if not path_2d:
		push_error("PathFollow2D parent is not a Path2D")
		return
	
	# Facteur de difficulté local hérité du spawner
	var current_difficulty: float = self.difficulty_factor
	
	var current_progress: float = path_follow.progress
	
	# Instanciation et placement de chaque bébé slime sur son propre PathFollow2D
	for i in range(number_babies):
		var baby_path_follow: PathFollow2D = PathFollow2D.new()
		baby_path_follow.loop = false
		baby_path_follow.rotates = false
		path_2d.add_child(baby_path_follow)
		
		var offset: float = -split_offset * i
		baby_path_follow.progress = maxf(0.0, current_progress + offset)
		
		var baby: Enemy = normal_slime_scene.instantiate() as Enemy
		if not baby:
			continue
		
		baby_path_follow.add_child(baby)
		baby.setup(baby_path_follow)
		
		if baby.has_method("apply_scale_difficulty"):
			baby.apply_scale_difficulty(current_difficulty)
