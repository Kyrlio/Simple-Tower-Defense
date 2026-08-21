class_name CrossbowTower
extends Tower

@export var projectile: PackedScene

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var muzzle: Marker2D = $Visuals/Weapon/Muzzle


func _physics_process(_delta: float) -> void:
	if enemies.size() > 0:
		weapon.look_at(enemies[0].global_position)


func _shoot() -> void:
	var instance: CrossbowProjectile = projectile.instantiate()
	var target: Enemy = enemies[0]
	if not instance or not target:
		print("no enemy")
		return
	
	instance.damage = 3
	instance.speed = 200.0
	instance.max_targets = 3
	
	var projectile_node: Node2D = get_tree().current_scene.get_node_or_null("Projectiles")
	if projectile_node:
		projectile_node.add_child(instance)
	else:
		get_tree().current_scene.add_child(instance)
	
	#instance.shoot(muzzle.global_position, target, instance.damage)
	instance.shoot(muzzle.global_position, weapon.rotation)


func _on_reload_timer_timeout() -> void:
	if enemies.size() > 0 and projectile:
		animation_player.play("shoot")
		_shoot()
