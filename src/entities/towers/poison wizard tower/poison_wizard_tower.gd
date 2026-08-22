extends Tower
class_name PoisonWizardTower

@export var projectile: PackedScene
@export var damage: float = 1.0
@export var speed: float = 125.0

@export_group("Poison Settings")
## Ratio/pourcentage des dégâts de base de la tour appliqués à chaque tick de poison (ex: 0.5 = 50% des dégâts de base)
@export_range(0.05, 2.0, 0.05) var poison_damage_ratio: float = 0.5
## Durée totale du poison en secondes
@export var poison_duration: float = 3.0
## Intervalle entre chaque tick de dégâts de poison en secondes
@export var poison_tick_interval: float = 0.5

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
	
	var instance: PoisonBall = projectile.instantiate() as PoisonBall
	if not instance:
		return
	
	instance.damage = damage
	instance.speed = speed
	instance.poison_damage = damage * poison_damage_ratio
	instance.poison_duration = poison_duration
	instance.poison_tick_interval = poison_tick_interval
	
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
