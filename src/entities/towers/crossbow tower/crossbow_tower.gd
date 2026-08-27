class_name CrossbowTower
extends Tower

@export var projectile: PackedScene
@export var damage: float = 3.0
@export var speed: float = 200.0
@export var max_targets: int = 3

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var muzzle: Marker2D = $Visuals/Weapon/Muzzle


func _setup_upgrade_costs() -> void:
	damage_upgrade_base_cost = 50
	damage_upgrade_cost_mult = 1.5
	reload_upgrade_base_cost = 50
	reload_upgrade_cost_mult = 1.5
	range_upgrade_base_cost = 40
	range_upgrade_cost_mult = 1.45


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if current_target:
		weapon.look_at(current_target.global_position)


func _shoot() -> void:
	if not projectile:
		return
	if not _is_target_valid(current_target):
		_update_current_target()
	if not current_target:
		return
		
	var instance: CrossbowProjectile = ProjectilePool.spawn_projectile(projectile) as CrossbowProjectile
	if not instance:
		return
	
	instance.damage = damage
	instance.speed = speed
	instance.max_targets = max_targets
	var cur_range = get_detection_range()
	instance.lifetime = maxf(1.0, (cur_range * 1.3) / maxf(1.0, speed))
	instance.shoot(muzzle.global_position, weapon.rotation)
	SoundManager.play_shoot("crossbow", muzzle.global_position)


func _on_reload_timer_timeout() -> void:
	if not _is_target_valid(current_target):
		_update_current_target()
	if current_target and projectile:
		animation_player.play("shoot")
		_shoot()



func get_special_description() -> String:
	return "Go through enemies (Up to %d targets)" % max_targets


func _append_custom_upgrades(upgrades: Array[Dictionary]) -> void:
	var next_targets = max_targets + 1
	upgrades.append({
		"id": "max_targets",
		"name": "Max Targets",
		"level": get_upgrade_level("max_targets"),
		"cost": _calc_cost(75, 1.45, "max_targets"),
		"current_text": "%d targets" % max_targets,
		"next_text": "%d targets (+1)" % next_targets,
	})


func _apply_custom_upgrade(upgrade_id: String) -> void:
	if upgrade_id == "max_targets":
		max_targets += 1
