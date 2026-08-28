extends Tower
class_name CannonTower

@export var cannon_scene: PackedScene = preload("res://src/entities/projectiles/cannon/cannon.tscn")
@export var damage: float = 4.0
@export var max_weapon_rotation_degrees: float = 20.0
@export var explosion_radius: float = 24.0

@onready var muzzle: Marker2D = $Visuals/Weapon/Muzzle
@onready var base_tower: Sprite2D = $Visuals/BaseTower
@onready var weapon: Sprite2D = $Visuals/Weapon
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var physical_damage_boost: float = 1.35


func _setup_upgrade_costs() -> void:
	damage_upgrade_base_cost = 75
	damage_upgrade_cost_mult = 1.35
	reload_upgrade_base_cost = 90
	reload_upgrade_cost_mult = 1.3
	range_upgrade_base_cost = 70
	range_upgrade_cost_mult = 1.45


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if current_target:
		var dir: Vector2 = current_target.global_position - weapon.global_position
		# Calcul de l'angle par rapport au HAUT (Vector2.UP)
		var angle_to_target: float = Vector2.UP.angle_to(dir)
		var max_rad: float = deg_to_rad(max_weapon_rotation_degrees)
		var clamped_angle: float = clampf(angle_to_target, -max_rad, max_rad)
		weapon.rotation = lerp_angle(weapon.rotation, clamped_angle, 10.0 * delta)
	else:
		weapon.rotation = lerp_angle(weapon.rotation, 0.0, 10.0 * delta)


func _on_reload_timer_timeout() -> void:
	if not _is_target_valid(current_target):
		_update_current_target()
	if current_target:
		animation_player.play("shoot")
		
		if cannon_scene:
			var cannon_instance = ProjectilePool.spawn_projectile(cannon_scene) as Cannon
			if cannon_instance:
				cannon_instance.launch(muzzle.global_position, current_target, damage, explosion_radius)
				SoundManager.play_shoot("cannon", muzzle.global_position)



func get_special_description() -> String:
	return "AoE Artillery (Radius: %d px)" % int(explosion_radius)


func _append_custom_upgrades(upgrades: Array[Dictionary]) -> void:
	var next_rad = explosion_radius * 1.2
	upgrades.append({
		"id": "explosion_radius",
		"name": "Explosion Radius",
		"level": get_upgrade_level("explosion_radius"),
		"cost": _calc_cost(95, 1.35, "explosion_radius"),
		"current_text": "%d px" % int(explosion_radius),
		"next_text": "%d px (+20%%)" % int(next_rad),
	})


func _apply_custom_upgrade(upgrade_id: String) -> void:
	if upgrade_id == "explosion_radius":
		explosion_radius *= 1.2
