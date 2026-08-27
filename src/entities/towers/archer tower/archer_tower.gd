extends Tower
class_name ArcherTower

@export var projectile: PackedScene = preload("res://src/entities/projectiles/arrow/arrow.tscn")
@export var damage: float = 1.0
@export var speed: float = 125.0

@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var muzzle: Marker2D = $Visuals/Weapon/Muzzle


func _setup_upgrade_costs() -> void:
	damage_upgrade_base_cost = 25
	damage_upgrade_cost_mult = 1.35
	reload_upgrade_base_cost = 20
	reload_upgrade_cost_mult = 1.25
	range_upgrade_base_cost = 15
	range_upgrade_cost_mult = 1.25


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
	
	var instance: Arrow = ProjectilePool.spawn_projectile(projectile) as Arrow
	if not instance:
		return
	
	instance.damage = damage
	instance.speed = speed
	var cur_range = get_detection_range()
	instance.lifetime = maxf(2.0, (cur_range * 1.3) / maxf(1.0, speed))
	instance.shoot(muzzle.global_position, weapon.rotation)
	SoundManager.play_shoot("archer", muzzle.global_position)


func _on_reload_timer_timeout() -> void:
	if not _is_target_valid(current_target):
		_update_current_target()
	if current_target and projectile:
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
		"cost": _calc_cost(15, 1.25, "arrow_speed"),
		"current_text": "%d px/s" % int(speed),
		"next_text": "%d px/s (+25%%)" % int(next_spd),
	})


func _apply_custom_upgrade(upgrade_id: String) -> void:
	if upgrade_id == "arrow_speed":
		speed *= 1.25
