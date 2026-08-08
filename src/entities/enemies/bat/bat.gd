extends PathFollow2D

@export var speed: float = 15.0
@export var max_hp: int = 3
@export var gold_reward: int = 15

var cur_hp: int


func _ready() -> void:
	cur_hp = max_hp
	loop = false
	rotates = false


func _physics_process(delta: float) -> void:
	progress += speed * delta
	if progress_ratio >= 0.99:
		print("damage")
		
		#TODO Au lieu de bêtement mourir, l'ennemi reste et attaque le chateau. Le chateau lui se défend
		queue_free()


func take_damage(amount: int) -> void:
	cur_hp -= amount
	_damage_flash()
	
	if cur_hp <= 0:
		die()


func die() -> void:
	GoldManager.add_gold(gold_reward)
	queue_free.call_deferred()


func _damage_flash() -> void:
	visible = false
	await get_tree().create_timer(0.07).timeout
	visible = true


func _on_area_entered(projectile: Area2D) -> void:
	if projectile.is_in_group("projectile"):
		take_damage(projectile.damage)
		projectile.queue_free()
