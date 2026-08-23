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
	var cur_range = get_detection_range()
	instance.lifetime = maxf(2.0, (cur_range * 1.3) / maxf(1.0, speed))
	
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
	return "Shoots fast arrows (Speed: %d px/s)" % int(speed)


func _append_custom_upgrades(upgrades: Array[Dictionary]) -> void:
	var next_spd = speed * 1.25
	upgrades.append({
		"id": "arrow_speed",
		"name": "Arrow Speed",
		"level": get_upgrade_level("arrow_speed"),
		"cost": _calc_cost(20, 1.30, "arrow_speed"),
		"current_text": "%d px/s" % int(speed),
		"next_text": "+25%% (%d px/s)" % int(next_spd),
	})


func _apply_custom_upgrade(upgrade_id: String) -> void:
	if upgrade_id == "arrow_speed":
		speed *= 1.25
