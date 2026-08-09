extends Area2D
class_name Goblin

@export var stats: EnemyStats

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
	
	if cur_hp <= 0:
		die()


func die() -> void:
	GoldManager.add_gold(stats.gold_reward)
	if is_instance_valid(path_follow):
		path_follow.queue_free.call_deferred()


func _damage_effects() -> void:
	visible = false
	await get_tree().create_timer(0.07).timeout
	visible = true


func _on_area_entered(projectile: Area2D) -> void:
	if projectile.is_in_group("projectile"):
		take_damage(projectile.damage)
		projectile.queue_free()
