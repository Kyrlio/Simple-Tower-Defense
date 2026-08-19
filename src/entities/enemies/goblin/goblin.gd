extends Area2D
class_name Goblin

@export var stats: EnemyStats
@export var hit_particles_scene: PackedScene = preload("uid://dtr5lw5ocrg3p")
@export var death_particles_scene: PackedScene = preload("uid://d4fjkvjerbdpm")

@onready var hit_flash_anim_player: AnimationPlayer = $HitFlashAnimPlayer
@onready var sprite: Sprite2D = $Visuals/Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var path_follow: PathFollow2D
var cur_hp: int

# Hitstops
var hitstop_frames: int = 0
var hitstop_amount: int = 3

func _ready() -> void:
	if stats:
		cur_hp = stats.max_hp


func setup(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow
	path_follow.loop = false
	path_follow.rotates = false


func _physics_process(delta: float) -> void:
	
	# Hitstop
	if hitstop_frames > 0:
		hitstop_frames -= 1
		if hitstop_frames <= 0:
			stop_hitstop()
		return
	
	if is_instance_valid(path_follow) and stats:
		path_follow.progress += stats.speed * delta
		global_position = path_follow.global_position
		
		if path_follow.progress_ratio >= 0.99:
			print("damage")
			
			#TODO Au lieu de bêtement mourir, l'ennemi reste et attaque le chateau. Le chateau lui se défend
			queue_free()


func take_damage(amount: int, damage_type: String = "physical") -> void:
	var final_damage: int = amount
	
	match damage_type:
		"physical": final_damage *= (1.0 - stats.physical_resist)
		"ice": final_damage *= (1.0 - stats.ice_resist)
		"poison": final_damage *= (1.0 - stats.poison_resist)
		"lightning": final_damage *= (1.0 - stats.lightning_resist)
	
	cur_hp -= final_damage
	_damage_effects()
	spawn_hit_particles()
	
	if cur_hp <= 0:
		die()


func spawn_hit_particles() -> void:
	var instance: GPUParticles2D = hit_particles_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = global_position


func spawn_death_particles() -> void:
	var instance: GPUParticles2D = death_particles_scene.instantiate()
	get_tree().current_scene.add_child(instance)
	instance.global_position = global_position


func die() -> void:
	_damage_effects()
	spawn_death_particles()
	GoldManager.add_gold(stats.gold_reward)
	if is_instance_valid(path_follow):
		path_follow.queue_free.call_deferred()


func start_hitstop() -> void:
	animation_player.pause()
	hit_flash_anim_player.pause()
	hitstop_frames = hitstop_amount


func stop_hitstop() -> void:
	animation_player.play()
	hit_flash_anim_player.play()
	hitstop_frames = 0


func _damage_effects() -> void:
	hit_flash_anim_player.play("hit_flash")


func _on_area_entered(projectile: Area2D) -> void:
	if projectile.is_in_group("projectile"):
		if projectile.has_method("try_hit"):
			if projectile.try_hit(self):
				take_damage(projectile.damage)
		else:
			take_damage(projectile.damage)
			projectile.queue_free()
