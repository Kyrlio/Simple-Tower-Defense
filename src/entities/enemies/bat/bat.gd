extends Area2D
class_name Bat

@export var stats: EnemyStats
@export var hit_particles_scene: PackedScene = preload("uid://dtr5lw5ocrg3p")
@export var death_particles_scene: PackedScene = preload("uid://d4fjkvjerbdpm")

@onready var sprite: Sprite2D = $Visuals/Sprite2D

var path_follow: PathFollow2D
var cur_hp: int


func _ready() -> void:
	if stats:
		cur_hp = stats.max_hp


func setup(new_path_follow: PathFollow2D) -> void:
	path_follow = new_path_follow
	path_follow.loop = false
	path_follow.rotates = false


func _physics_process(delta: float) -> void:
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
	GoldManager.add_gold(stats.gold_reward)
	spawn_death_particles()
	if is_instance_valid(path_follow):
		path_follow.queue_free.call_deferred()


func _damage_effects() -> void:	
	sprite.modulate = Color(18.892, 0.0, 0.0, 1.0)
	$Visuals.scale = Vector2(0.8, 0.8)
	
	var tw: Tween = get_tree().create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.2)
	tw.tween_property($Visuals, "scale", Vector2.ONE, 0.2)


func _on_area_entered(projectile: Area2D) -> void:
	if projectile.is_in_group("projectile"):
		if projectile.has_method("try_hit"):
			if projectile.try_hit(self):
				take_damage(projectile.damage)
		else:
			take_damage(projectile.damage)
			projectile.queue_free()
