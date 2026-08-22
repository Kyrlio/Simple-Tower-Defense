extends Tower
class_name ArcherTower

@export var projectile: PackedScene = preload("res://src/entities/projectiles/arrow/arrow.tscn")
@export var damage: float = 1.0
@export var speed: float = 125.0

@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle: Marker2D = $Visuals/Weapon/Muzzle


func _physics_process(_delta: float) -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies.size() > 0:
		weapon.look_at(enemies[0].global_position)


func _shoot() -> void:
	if not projectile or enemies.is_empty():
		return
	
	var instance: Arrow = projectile.instantiate() as Arrow
	if not instance:
		return
	
	instance.damage = damage
	instance.speed = speed
	
	var projectile_node: Node2D = get_tree().current_scene.get_node_or_null("Projectiles")
	if projectile_node:
		projectile_node.add_child(instance)
	else:
		get_tree().current_scene.add_child(instance)
	
	instance.shoot(muzzle.global_position, weapon.rotation)


func _on_reload_timer_timeout() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies.size() > 0 and projectile:
		animation_player.play("shoot")
		_shoot()


func get_special_description() -> String:
	return "Tir de flèches rapide (Vitesse: %d px/s)" % int(speed)
