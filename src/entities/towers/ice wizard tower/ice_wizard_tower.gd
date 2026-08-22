extends Tower
class_name IceWizardTower

@export var projectile: PackedScene
@export var damage: float = 1.0
@export var speed: float = 125.0

@export_group("Slow Settings")
## Facteur de vitesse pendant le ralentissement (0.5 = 50% de la vitesse normale)
@export_range(0.0, 1.0, 0.05) var slow_factor: float = 0.5
## Durée du ralentissement en secondes
@export var slow_duration: float = 2.0

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
	
	var instance: IceBall = projectile.instantiate() as IceBall
	if not instance:
		return
	
	instance.damage = damage
	instance.speed = speed
	instance.slow_factor = slow_factor
	instance.slow_duration = slow_duration
	
	var projectile_node: Node2D = get_tree().current_scene.get_node_or_null("Projectiles")
	if projectile_node:
		projectile_node.add_child(instance)
	else:
		get_tree().current_scene.add_child(instance)
	
	instance.shoot(muzzle.global_position, weapon.rotation)


func _on_reload_timer_timeout() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies.size() > 0 and projectile:
		if animation_player and animation_player.has_animation("shoot"):
			animation_player.play("shoot")
		_shoot()
