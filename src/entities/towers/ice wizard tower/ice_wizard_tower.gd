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


func _setup_upgrade_costs() -> void:
	damage_upgrade_base_cost = 120
	damage_upgrade_cost_mult = 1.5
	reload_upgrade_base_cost = 130
	reload_upgrade_cost_mult = 1.5
	range_upgrade_base_cost = 100
	range_upgrade_cost_mult = 1.30


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
	instance.source_tower = self
	var cur_range = get_detection_range()
	instance.lifetime = maxf(2.0, (cur_range * 1.3) / maxf(1.0, speed))
	
	var projectile_node: Node2D = get_tree().current_scene.get_node_or_null("Projectiles")
	if projectile_node:
		projectile_node.add_child(instance)
	else:
		get_tree().current_scene.add_child(instance)
	
	instance.shoot(muzzle.global_position, weapon.rotation)
	SoundManager.play_shoot("ice_wizard", muzzle.global_position)


func _on_reload_timer_timeout() -> void:
	enemies = enemies.filter(func(e): return is_instance_valid(e) and not e.is_queued_for_deletion())
	
	if enemies.size() > 0 and projectile:
		if animation_player and animation_player.has_animation("shoot"):
			animation_player.play("shoot")
		_shoot()


func get_special_description() -> String:
	var slow_pct = int((1.0 - slow_factor) * 100.0)
	return "Slows enemies by %d%% for %0.1fs" % [slow_pct, slow_duration]


func _append_custom_upgrades(upgrades: Array[Dictionary]) -> void:
	var cur_pct = int((1.0 - slow_factor) * 100.0)
	var next_factor = maxf(0.05, slow_factor * 0.85)
	var next_pct = int((1.0 - next_factor) * 100.0)
	
	upgrades.append({
		"id": "slow_power",
		"name": "Slow Power",
		"level": get_upgrade_level("slow_power"),
		"cost": _calc_cost(140, 1.35, "slow_power"),
		"current_text": "%d%% slow" % cur_pct,
		"next_text": "%d%% slow (+slow)" % next_pct,
	})
	
	var next_dur = slow_duration * 1.2
	upgrades.append({
		"id": "slow_duration",
		"name": "Slow Duration",
		"level": get_upgrade_level("slow_duration"),
		"cost": _calc_cost(120, 1.30, "slow_duration"),
		"current_text": "%0.1fs" % slow_duration,
		"next_text": "%0.1fs (+20%%)" % next_dur,
	})


func _apply_custom_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"slow_power":
			slow_factor = maxf(0.05, slow_factor * 0.85)
		"slow_duration":
			slow_duration *= 1.2
